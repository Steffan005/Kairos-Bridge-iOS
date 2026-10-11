// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Steffan Douglas Haskins
// Local synthetic model checks. No Keychain access, HTTP calls or real journals.
import Foundation

@MainActor
private final class FixtureAPI: KairosServing {
    var email: String? = "fixture@example.test"
    var fetchFails = false
    var saveFails = false
    var saveCalls = 0
    var disconnectCalls = 0
    var deleteCalls = 0
    var createCalls = 0
    var signOutCleanupFailure = false

    let entry = JournalEntry(id: "synthetic-native-check", text: "Synthetic model fixture only.", actor: "you",
                             created_at: "2026-10-11T02:59:50.817Z", tags: ["project-kitchen"])
    func restoreSession() throws -> Bool { true }
    func forgetSession() throws { }
    func signIn(email: String, password: String) async throws { self.email = email }
    func journal() async throws -> JournalEnvelope {
        if fetchFails { throw URLError(.notConnectedToInternet) }
        return .init(deleted: false, entries: [entry], connections: [.init(clientId: "https://claude.ai/oauth/mcp-oauth-client-metadata", scopes: ["journal:read"])], count: 1)
    }
    func saveNote(text: String, project: String) async throws {
        saveCalls += 1
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

        api.saveFails = false; api.fetchFails = true
        expect(await model.save() == true, "Successful write was relabeled failed by a later refresh error")
        expect(model.draft.isEmpty, "Confirmed write left a duplicate-prone draft")
        expect(model.message?.contains("note saved") == true, "Confirmed save wasn't distinguished from refresh")

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

        print("\(passed) synthetic native-model checks passed; no iOS SDK or physical-device claim.")
    }
}
