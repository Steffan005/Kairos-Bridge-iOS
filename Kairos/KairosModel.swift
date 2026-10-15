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
    @Published private(set) var userID = ""
    @Published private(set) var account: AccountStatus?
    @Published var lastFetched: Date?
    @Published var draft = ""
    @Published var project = ""
    @Published var exportURL: URL?
    private struct HeldDraft {
        let ownerID: String
        let text: String
        let project: String
        let unconfirmedSave: Bool
    }
    // In-memory only. Never expose an expired owner's draft to another account.
    // Build 6 also held drafts only in memory: updating/relaunching cannot migrate
    // one. Save or copy an unsent draft before updating the installed app.
    private var heldDraft: HeldDraft?
    private var sessionGeneration = 0
    private struct SupersededSession: Error { }
    private var unconfirmedSave = false
    private let unconfirmedSaveMessage = "We couldn't confirm whether an earlier note saved. Your draft is kept. Check your journal before saving again to avoid a duplicate."
    let api: any KairosServing

    init(api: (any KairosServing)? = nil) { self.api = api ?? KairosAPI() }

    func restore() async {
        guard !busy else { return }
        clearDisplay()
        let generation = sessionGeneration
        busy = true; defer { busy = false }
        do {
            signedIn = try api.restoreSession()
            email = api.email ?? ""
            userID = api.userID ?? ""
            if signedIn { try await fetch() }
        } catch { if generation == sessionGeneration { handle(error) } }
    }

    func signIn(email: String, password: String) async -> Bool {
        guard !busy else { return false }
        let previousDraft = heldCurrentDraft() ?? heldDraft
        // Clear every previous owner's visible value before publishing a new login,
        // including when its first account/journal request subsequently fails.
        clearDisplay(); heldDraft = previousDraft
        let generation = sessionGeneration
        busy = true; defer { busy = false }
        do {
            try await api.signIn(email: email, password: password)
            guard generation == sessionGeneration else { return false }
            guard let ownerEmail = api.email, !ownerEmail.isEmpty,
                  let ownerID = api.userID, !ownerID.isEmpty else { throw KairosFailure.invalidResponse }
            self.email = ownerEmail; userID = ownerID; signedIn = true
            let recoveredDraft = recoverHeldDraft(for: ownerID)
            try await fetch()
            try requireSession(generation, owner: ownerID)
            if recoveredDraft {
                message = withSessionWarning(unconfirmedSave ? unconfirmedSaveMessage : "Your unsent draft is recovered. Open Remember to continue it.")
            }
            return true
        } catch { if generation == sessionGeneration { handle(error) }; return false }
    }

    private func fetch() async throws {
        let generation = sessionGeneration, expectedOwner = userID
        try requireSession(generation, owner: expectedOwner)
        let current = try await api.account()
        try requireSession(generation, owner: expectedOwner)
        guard !current.id.isEmpty, !current.email.isEmpty else { throw KairosFailure.invalidResponse }
        guard userID.isEmpty || userID == current.id else {
            throw KairosFailure.service(401, "Your account changed. Please sign in again.")
        }
        // This also migrates an older cookie-only session. A live authenticated
        // response establishes ownership; cached email is only a display value.
        userID = current.id; email = current.email; account = current
        let fetched = try await api.journal()
        try requireSession(generation, owner: current.id)
        journal = fetched; loaded = true; lastFetched = Date()
        // A successful read is not a receipt for an earlier uncertain write.
        message = withSessionWarning(unconfirmedSave ? unconfirmedSaveMessage : nil)
    }

    func refresh() async {
        guard !busy else { return }
        let generation = sessionGeneration
        busy = true; defer { busy = false }
        do { try await fetch() } catch { if generation == sessionGeneration { handle(error) } }
    }

    func save() async -> Bool {
        guard !busy else { return false }
        guard signedIn, !userID.isEmpty else {
            message = "Refresh your account or sign in before saving a note."; return false
        }
        let submittedDraft = draft
        let submittedProject = project
        let generation = sessionGeneration, owner = userID
        let slug = submittedProject.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard slug.isEmpty || slug.range(of: "^[a-z0-9]+(?:-[a-z0-9]+)*$", options: .regularExpression) != nil else {
            message = "Use a short project name with letters, numbers or hyphens."; return false
        }
        busy = true; defer { busy = false }
        let previouslyUnconfirmed = unconfirmedSave
        // An independently expired session may hold this draft while the write
        // is still in flight, before this task receives any receipt.
        unconfirmedSave = true
        do {
            try await api.saveNote(text: submittedDraft, project: slug)
            try requireSession(generation, owner: owner)
            unconfirmedSave = false
            // A write receipt acknowledges only the submitted snapshot. Never
            // discard text that changed while the asynchronous save was running.
            let newerDraft = draft != submittedDraft || project != submittedProject
            if !newerDraft { draft = ""; project = "" }
            // A successful write receipt remains a success if the following read fails.
            do {
                try await fetch()
                try requireSession(generation, owner: owner)
                message = withSessionWarning(newerDraft ? "Your note saved. Your newer draft is kept." : "Saved to your journal.")
            }
            catch {
                guard generation == sessionGeneration else { return true }
                handle(error)
                message = signedIn ? "Your note saved. The journal couldn't refresh; try Refresh to see it." : "Your note saved. Sign in again to refresh your journal."
                if signedIn && newerDraft {
                    message = "Your note saved. Your newer draft is kept. The journal couldn't refresh; try Refresh to see the saved note."
                }
                message = withSessionWarning(message)
            }
            return true
        } catch {
            guard generation == sessionGeneration else { return false }
            unconfirmedSave = previouslyUnconfirmed || saveOutcomeIsUnconfirmed(error)
            handle(error)
            return false
        }
    }

    func perform(_ action: String) async {
        guard !busy else { return }
        let generation = sessionGeneration, owner = userID
        busy = true; defer { busy = false }
        do {
            switch action {
            case "disconnect":
                try await api.disconnect()
                try requireSession(generation, owner: owner)
                if let current = journal { journal = .init(deleted: current.deleted, entries: current.entries, connections: [], count: current.count) }
                message = "All AI access disconnected. Your notes remain."
            case "delete":
                try await api.deleteJournal()
                try requireSession(generation, owner: owner)
                journal = .init(deleted: true, entries: [], connections: [], count: 0)
                loaded = true; lastFetched = nil; draft = ""; project = ""; unconfirmedSave = false
                message = "Active journal deleted."
            case "create":
                try await api.recreateJournal()
                try requireSession(generation, owner: owner)
                journal = .init(deleted: false, entries: [], connections: [], count: 0)
                loaded = true; lastFetched = nil; unconfirmedSave = false
                message = "New empty journal. Previous AI access remains disconnected."
            case "signout":
                try await api.signOut()
                try requireSession(generation, owner: owner)
                clearDisplay(); message = "Signed out. Approved AI access remains until you disconnect it."
            case "export":
                let data = try await api.export()
                try requireSession(generation, owner: owner)
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("kairos-journal-\(UUID().uuidString).json")
                try data.write(to: url, options: [.atomic, .completeFileProtection]); exportURL = url
                message = "Export prepared. Choose Share export to save or share your copy."
            default: break
            }
            message = withSessionWarning(message)
        } catch {
            guard generation == sessionGeneration else { return }
            if case KairosFailure.signedOutStorageCleanup = error { clearDisplay() }
            handle(error)
        }
    }

    private func clearDisplay() {
        sessionGeneration += 1
        signedIn = false; loaded = false; journal = nil; email = ""; userID = ""; account = nil; lastFetched = nil
        draft = ""; project = ""; exportURL = nil
        unconfirmedSave = false
        heldDraft = nil
    }

    private func requireSession(_ generation: Int, owner: String) throws {
        guard generation == sessionGeneration, signedIn, userID == owner else { throw SupersededSession() }
    }

    private func heldCurrentDraft() -> HeldDraft? {
        guard !userID.isEmpty, !draft.isEmpty else { return nil }
        return HeldDraft(ownerID: userID, text: draft, project: project, unconfirmedSave: unconfirmedSave)
    }

    private func recoverHeldDraft(for ownerID: String) -> Bool {
        guard let held = heldDraft else { return false }
        heldDraft = nil
        // Email can change or be reassigned. Only the immutable ID from the
        // authenticated session can recover a previous owner's held draft.
        guard held.ownerID == ownerID else { return false }
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
        if error is SupersededSession { return }
        if let failure = error as? KairosFailure, failure.signInRequired {
            let held = heldCurrentDraft() ?? heldDraft
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
