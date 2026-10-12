// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Steffan Douglas Haskins
import SwiftUI

@MainActor
final class KairosModel: ObservableObject {
    @Published var signedIn = false
    @Published var busy = false
    @Published var loaded = false
    @Published var journal: JournalEnvelope?
    @Published var message: String?
    @Published var email = ""
    @Published var lastFetched: Date?
    @Published var draft = ""
    @Published var project = ""
    @Published var exportURL: URL?
    private struct HeldDraft {
        let ownerEmail: String
        let text: String
        let project: String
        let unconfirmedSave: Bool
    }
    // In-memory only. Never expose an expired owner's draft to another account.
    private var heldDraft: HeldDraft?
    private var unconfirmedSave = false
    private let unconfirmedSaveMessage = "We couldn't confirm whether an earlier note saved. Your draft is kept. Check your journal before saving again to avoid a duplicate."
    let api: any KairosServing

    init(api: (any KairosServing)? = nil) { self.api = api ?? KairosAPI() }

    func restore() async {
        do {
            signedIn = try api.restoreSession()
            email = api.email ?? ""
            if signedIn { await refresh() }
        } catch { message = error.localizedDescription }
    }

    func signIn(email: String, password: String) async -> Bool {
        guard !busy else { return false }
        busy = true; defer { busy = false }
        do {
            try await api.signIn(email: email, password: password)
            guard let ownerEmail = api.email, !ownerEmail.isEmpty else { throw KairosFailure.invalidResponse }
            self.email = ownerEmail; signedIn = true
            let recoveredDraft = recoverHeldDraft(for: self.email)
            try await fetch()
            if recoveredDraft {
                message = withSessionWarning(unconfirmedSave ? unconfirmedSaveMessage : "Your unsent draft is recovered. Open Remember to continue it.")
            }
            return true
        } catch { handle(error); return false }
    }

    private func fetch() async throws {
        journal = try await api.journal(); loaded = true; lastFetched = Date()
        // A successful read is not a receipt for an earlier uncertain write.
        message = withSessionWarning(unconfirmedSave ? unconfirmedSaveMessage : nil)
    }

    func refresh() async {
        guard !busy else { return }
        busy = true; defer { busy = false }
        do { try await fetch() } catch { handle(error) }
    }

    func save() async -> Bool {
        guard !busy else { return false }
        let submittedDraft = draft
        let submittedProject = project
        let slug = submittedProject.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard slug.isEmpty || slug.range(of: "^[a-z0-9]+(?:-[a-z0-9]+)*$", options: .regularExpression) != nil else {
            message = "Use a short project name with letters, numbers or hyphens."; return false
        }
        busy = true; defer { busy = false }
        do {
            try await api.saveNote(text: submittedDraft, project: slug)
            unconfirmedSave = false
            // A write receipt acknowledges only the submitted snapshot. Never
            // discard text that changed while the asynchronous save was running.
            let newerDraft = draft != submittedDraft || project != submittedProject
            if !newerDraft { draft = ""; project = "" }
            // A successful write receipt remains a success if the following read fails.
            do {
                try await fetch()
                message = withSessionWarning(newerDraft ? "Your note saved. Your newer draft is kept." : "Saved to your journal.")
            }
            catch {
                handle(error)
                message = signedIn ? "Your note saved. The journal couldn't refresh; try Refresh to see it." : "Your note saved. Sign in again to refresh your journal."
                if signedIn && newerDraft {
                    message = "Your note saved. Your newer draft is kept. The journal couldn't refresh; try Refresh to see the saved note."
                }
                message = withSessionWarning(message)
            }
            return true
        } catch {
            if saveOutcomeIsUnconfirmed(error) { unconfirmedSave = true }
            handle(error)
            return false
        }
    }

    func perform(_ action: String) async {
        guard !busy else { return }
        busy = true; defer { busy = false }
        do {
            switch action {
            case "disconnect":
                try await api.disconnect()
                if let current = journal { journal = .init(deleted: current.deleted, entries: current.entries, connections: [], count: current.count) }
                message = "All AI access disconnected. Your notes remain."
            case "delete":
                try await api.deleteJournal()
                journal = .init(deleted: true, entries: [], connections: [], count: 0)
                loaded = true; lastFetched = nil; draft = ""; project = ""; unconfirmedSave = false
                message = "Active journal deleted."
            case "create":
                try await api.recreateJournal()
                journal = .init(deleted: false, entries: [], connections: [], count: 0)
                loaded = true; lastFetched = nil; unconfirmedSave = false
                message = "New empty journal. Previous AI access remains disconnected."
            case "signout": try await api.signOut(); clearDisplay(); message = "Signed out. Approved AI access remains until you disconnect it."
            case "export":
                let data = try await api.export()
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("kairos-journal-\(UUID().uuidString).json")
                try data.write(to: url, options: [.atomic, .completeFileProtection]); exportURL = url
                message = "Export prepared. Choose Share export to save or share your copy."
            default: break
            }
            message = withSessionWarning(message)
        } catch {
            if case KairosFailure.signedOutStorageCleanup = error { clearDisplay() }
            handle(error)
        }
    }

    private func clearDisplay() {
        signedIn = false; loaded = false; journal = nil; email = ""; lastFetched = nil
        draft = ""; project = ""; exportURL = nil
        unconfirmedSave = false
        heldDraft = nil
    }

    private func recoverHeldDraft(for ownerEmail: String) -> Bool {
        guard let held = heldDraft else { return false }
        heldDraft = nil
        // Both values come from successful server sign-in/session restoration,
        // rather than trusting the email typed into the sign-in form.
        guard held.ownerEmail == ownerEmail else { return false }
        draft = held.text; project = held.project; unconfirmedSave = held.unconfirmedSave
        return true
    }

    private func withSessionWarning(_ status: String?) -> String? {
        guard let warning = api.sessionStorageWarning else { return status }
        return [status, warning].compactMap { $0 }.joined(separator: " ")
    }

    private func saveOutcomeIsUnconfirmed(_ error: Error) -> Bool {
        if error is URLError || error is CancellationError { return true }
        guard let failure = error as? KairosFailure else { return false }
        switch failure {
        case .invalidResponse: return true
        case .service(let status, _): return status == 408 || (500...599).contains(status)
        default: return false
        }
    }

    private func handle(_ error: Error) {
        if let failure = error as? KairosFailure, failure.signInRequired {
            let held = !email.isEmpty && !draft.isEmpty
                ? HeldDraft(ownerEmail: email, text: draft, project: project, unconfirmedSave: unconfirmedSave)
                : heldDraft
            try? api.forgetSession(); clearDisplay()
            heldDraft = held
        }
        message = error is URLError ? "Can't reach Kairos. Check your connection and try again. Previously displayed notes haven't been refreshed." : error.localizedDescription
        if unconfirmedSave { message = unconfirmedSaveMessage + " " + (message ?? "") }
        if heldDraft != nil {
            message = (message ?? "") + " Your unsent draft is held while Kairos stays open. Sign in to the same account to recover it."
        }
        message = withSessionWarning(message)
    }

    func searchSessionExpired(_ error: Error) { handle(error) }

    var claudeURL: URL {
        var components = URLComponents(string: "https://claude.ai/customize/connectors")!
        if journal?.claudeApproved != true {
            components.queryItems = [.init(name: "modal", value: "add-custom-connector"),
                                     .init(name: "connectorName", value: "Kairos"),
                                     .init(name: "connectorUrl", value: KairosAPI.origin.absoluteString + "/mcp")]
        }
        return components.url!
    }
}
