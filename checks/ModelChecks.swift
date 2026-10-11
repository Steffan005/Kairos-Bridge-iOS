// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Steffan Douglas Haskins
// Local synthetic model checks. No Keychain access, HTTP calls or real journals.
import Foundation

@MainActor
private final class FixtureAPI: KairosServing {
    var email: String? = "fixture@example.test"
    var fetchFails = false
    var saveFails = false
    var saveError: Error?
    var fetchError: Error?
    var reportedOwnerEmail: String?
    var saveCalls = 0
    var disconnectCalls = 0
    var deleteCalls = 0
    var createCalls = 0
    var signOutCleanupFailure = false
    var duringSave: (() -> Void)?
    var lastSavedText: String?
    var lastSavedProject: String?

    let entry = JournalEntry(id: "synthetic-native-check", text: "Synthetic model fixture only.", actor: "you",
                             created_at: "2026-10-11T02:59:50.817Z", tags: ["project-kitchen"])
    func restoreSession() throws -> Bool { true }
    func forgetSession() throws { }
    func signIn(email: String, password: String) async throws { self.email = reportedOwnerEmail ?? email }
    func journal() async throws -> JournalEnvelope {
        if let fetchError { throw fetchError }
        if fetchFails { throw URLError(.notConnectedToInternet) }
        return .init(deleted: false, entries: [entry], connections: [.init(clientId: "https://claude.ai/oauth/mcp-oauth-client-metadata", scopes: ["journal:read"])], count: 1)
    }
    func saveNote(text: String, project: String) async throws {
        saveCalls += 1
        lastSavedText = text; lastSavedProject = project
        duringSave?()
        if let saveError { throw saveError }
        if saveFails { throw URLError(.timedOut) }
    }
    func disconnect() async throws { disconnectCalls += 1 }
    func deleteJournal() async throws { deleteCalls += 1 }
    func recreateJournal() async throws { createCalls += 1 }
    func export() async throws -> Data { Data("[]".utf8) }
    func signOut() async throws {
        if signOutCleanupFailure { throw KairosFailure.signedOutStorageCleanup }
    }
}

@main
struct ModelChecks {
    @MainActor
    static func main() async throws {
        var passed = 0
        func expect(_ value: Bool, _ message: String) {
            guard value else { fatalError(message) }; passed += 1
        }
        let api = FixtureAPI()
        let model = KairosModel(api: api)
        await model.restore()
        expect(model.journal?.entries.count == 1 && model.journal?.claudeApproved == true, "Fixture read didn't populate journal")
        expect(model.journal?.entries[0].date != nil, "Full stored timestamp didn't decode")

        model.draft = "Draft to keep"
        api.saveFails = true
        expect(await model.save() == false, "Timed-out save reported success")
        expect(model.draft == "Draft to keep", "Unconfirmed save discarded draft")
        expect(model.message?.contains("couldn't confirm") == true, "Uncertain save didn't explain ambiguity")

        api.fetchFails = true
        await model.refresh()
        expect(model.message?.contains("couldn't confirm") == true,
               "Failed refresh hid the unconfirmed-save warning")
        api.fetchFails = false
        await model.refresh()
        expect(model.message?.contains("couldn't confirm") == true,
               "Successful refresh silently certified an unconfirmed write")

        api.saveFails = false; api.fetchFails = true
        expect(await model.save() == true, "Successful write was relabeled failed by a later refresh error")
        expect(model.draft.isEmpty, "Confirmed write left a duplicate-prone draft")
        expect(model.message?.contains("note saved") == true, "Confirmed save wasn't distinguished from refresh")

        api.fetchFails = false
        model.draft = "Original note in flight"; model.project = "kitchen"
        api.duringSave = {
            model.draft = "Newer unsent draft"; model.project = "garden"
        }
        expect(await model.save() == true, "Confirmed write failed when a newer draft appeared")
        expect(api.lastSavedText == "Original note in flight" && api.lastSavedProject == "kitchen",
               "Save did not use the submitted note and project")
        expect(model.draft == "Newer unsent draft" && model.project == "garden",
               "Successful save erased a newer unsent draft")
        expect(model.message?.contains("newer draft is kept") == true,
               "Successful save did not explain retained newer draft")
        api.duringSave = nil

        model.busy = true
        let count = api.saveCalls
        expect(await model.save() == false && api.saveCalls == count, "Queued double-tap created another write")
        model.busy = false

        await model.perform("disconnect")
        expect(api.disconnectCalls == 1 && model.journal?.connections.isEmpty == true && model.journal?.entries.count == 1,
               "Known Disconnect didn't clear approval while preserving notes")

        model.draft = "Draft before deletion"
        await model.perform("delete")
        expect(api.deleteCalls == 1 && model.journal?.deleted == true && model.journal?.entries.isEmpty == true && model.draft.isEmpty,
               "Known deletion retained active displayed notes")

        await model.perform("create")
        expect(api.createCalls == 1 && model.journal?.deleted == false && model.journal?.connections.isEmpty == true,
               "Recreation reused stale grants")

        await model.perform("signout")
        expect(model.signedIn == false && model.journal == nil, "Sign-out didn't clear native display")

        api.fetchFails = false
        await model.restore()
        api.signOutCleanupFailure = true
        await model.perform("signout")
        expect(model.signedIn == false && model.journal == nil && model.message?.contains("server session has ended") == true,
               "Successful server sign-out with a local cleanup error retained the journal screen")

        let expiryAPI = FixtureAPI()
        let expiryModel = KairosModel(api: expiryAPI)
        await expiryModel.restore()
        expiryModel.draft = "Unsent owner's draft"; expiryModel.project = "kitchen"
        expiryAPI.saveError = KairosFailure.service(401, "Please sign in again.")
        expect(await expiryModel.save() == false && !expiryModel.signedIn && expiryModel.journal == nil,
               "Expired owner session did not hide the journal")
        expect(expiryModel.draft.isEmpty && expiryModel.message?.contains("same account") == true,
               "Expired sign-in silently discarded the unsent draft")
        expiryAPI.saveError = nil
        expect(await expiryModel.signIn(email: "fixture@example.test", password: "synthetic") == true,
               "Same-owner reauthentication fixture failed")
        expect(expiryModel.draft == "Unsent owner's draft" && expiryModel.project == "kitchen",
               "Same-owner reauthentication lost the held draft")
        expect(expiryModel.message?.contains("draft") == true,
               "Recovered draft was not explained")
        expiryAPI.fetchError = KairosFailure.service(401, "Please sign in again.")
        await expiryModel.refresh()
        expiryAPI.fetchError = nil
        expiryAPI.reportedOwnerEmail = "different@example.test"
        _ = await expiryModel.signIn(email: "fixture@example.test", password: "synthetic")
        expect(expiryModel.draft.isEmpty && expiryModel.project.isEmpty,
               "Different owner inherited a held draft")

        let uncertainAPI = FixtureAPI()
        let uncertainModel = KairosModel(api: uncertainAPI)
        await uncertainModel.restore()
        uncertainModel.draft = "Possibly committed note"
        uncertainAPI.saveError = KairosFailure.service(503, "Service temporarily unavailable")
        expect(await uncertainModel.save() == false && uncertainModel.draft == "Possibly committed note",
               "Unknown server outcome discarded the draft")
        expect(uncertainModel.message?.contains("couldn't confirm") == true && uncertainAPI.saveCalls == 1,
               "Ambiguous server response encouraged a duplicate or retried")
        await uncertainModel.refresh()
        expect(uncertainModel.message?.contains("couldn't confirm") == true,
               "Later read erased uncertainty from a server failure")

        let rejectedAPI = FixtureAPI()
        let rejectedModel = KairosModel(api: rejectedAPI)
        await rejectedModel.restore()
        rejectedModel.draft = "Rejected note"
        rejectedAPI.saveError = KairosFailure.service(400, "Synthetic validation rejection")
        _ = await rejectedModel.save()
        expect(rejectedModel.draft == "Rejected note" && rejectedModel.message == "Synthetic validation rejection",
               "Known validation rejection was labeled an uncertain commit")

        for ambiguous in [KairosFailure.service(408, "Timeout"), .service(502, "Proxy failure"), .invalidResponse] {
            let failedAPI = FixtureAPI()
            let failedModel = KairosModel(api: failedAPI)
            await failedModel.restore(); failedModel.draft = "Held synthetic draft"
            failedAPI.saveError = ambiguous
            _ = await failedModel.save()
            expect(failedModel.message?.contains("couldn't confirm") == true && failedAPI.saveCalls == 1,
                   "Ambiguous response lost uncertainty or retried")
        }

        print("\(passed) synthetic native-model checks passed; no iOS SDK or physical-device claim.")
    }
}
