// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Steffan Douglas Haskins
// Local synthetic model checks. No Keychain access, HTTP calls or real journals.
import Foundation

@MainActor
private final class Suspension {
    private var continuation: CheckedContinuation<Void, Never>?
    var waiting: Bool { continuation != nil }
    func pause() async { await withCheckedContinuation { continuation = $0 } }
    func release() { continuation?.resume(); continuation = nil }
    func waitUntilPaused() async {
        for _ in 0..<1_000 {
            if waiting { return }
            await Task.yield()
        }
        fatalError("Synthetic request did not reach its suspension")
    }
}

@MainActor
private final class FixtureAPI: KairosServing {
    var email: String? = "fixture@example.test"
    var userID: String? = "fixture-user"
    var accountError: Error?
    var authoritativeID = "fixture-user"
    var authoritativeEmail: String?
    var fetchFails = false
    var saveFails = false
    var saveError: Error?
    var fetchError: Error?
    var reportedOwnerEmail: String?
    var reportedOwnerID: String?
    var saveCalls = 0
    var disconnectCalls = 0
    var deleteCalls = 0
    var createCalls = 0
    var signOutCleanupFailure = false
    var duringSave: (() -> Void)?
    var pauseAccount: Suspension?
    var pauseJournal: Suspension?
    var pauseSave: Suspension?
    var pauseControl: Suspension?
    var lastSavedText: String?
    var lastSavedProject: String?

    let entry = JournalEntry(id: "synthetic-native-check", text: "Synthetic model fixture only.", actor: "you",
                             created_at: "2026-10-11T02:59:50.817Z", tags: ["project-kitchen"])
    func restoreSession() throws -> Bool { true }
    func forgetSession() throws { }
    func signIn(email: String, password: String) async throws {
        self.email = reportedOwnerEmail ?? email
        userID = reportedOwnerID ?? authoritativeID
        authoritativeID = userID!
    }
    func account() async throws -> AccountStatus {
        if let accountError { throw accountError }
        let result = AccountStatus(id: authoritativeID, email: authoritativeEmail ?? email ?? "fixture@example.test",
                     emailVerified: true, recoveryAvailable: true, emailChangeAvailable: true)
        if let pauseAccount { await pauseAccount.pause() }
        return result
    }
    func journal() async throws -> JournalEnvelope {
        if let pauseJournal { await pauseJournal.pause() }
        if let fetchError { throw fetchError }
        if fetchFails { throw URLError(.notConnectedToInternet) }
        return .init(deleted: false, entries: [entry], connections: [.init(clientId: "https://claude.ai/oauth/mcp-oauth-client-metadata", scopes: ["journal:read"])], count: 1)
    }
    func saveNote(text: String, project: String) async throws {
        saveCalls += 1
        lastSavedText = text; lastSavedProject = project
        duringSave?()
        if let pauseSave { await pauseSave.pause() }
        if let saveError { throw saveError }
        if saveFails { throw URLError(.timedOut) }
    }
    func disconnect() async throws { disconnectCalls += 1; if let pauseControl { await pauseControl.pause() } }
    func deleteJournal() async throws { deleteCalls += 1; if let pauseControl { await pauseControl.pause() } }
    func recreateJournal() async throws { createCalls += 1; if let pauseControl { await pauseControl.pause() } }
    func export() async throws -> Data {
        if let pauseControl { await pauseControl.pause() }
        return Data("[]".utf8)
    }
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
        expiryAPI.reportedOwnerID = "different-user"
        _ = await expiryModel.signIn(email: "fixture@example.test", password: "synthetic")
        expect(expiryModel.draft.isEmpty && expiryModel.project.isEmpty,
               "Different owner inherited a held draft")

        let renameAPI = FixtureAPI()
        let renameModel = KairosModel(api: renameAPI)
        await renameModel.restore()
        renameModel.draft = "Keep this through email change"; renameModel.project = "bridge"
        renameAPI.authoritativeEmail = "verified@example.com"
        await renameModel.refresh()
        expect(renameModel.email == "verified@example.com" && renameModel.userID == "fixture-user",
               "Refresh did not replace cached email with authoritative same-account identity")
        expect(renameModel.draft == "Keep this through email change" && renameModel.journal?.claudeApproved == true,
               "An email refresh discarded a draft or changed approved access")
        renameAPI.accountError = KairosFailure.service(401, "Please sign in again.")
        await renameModel.refresh()
        expect(renameModel.draft.isEmpty && !renameModel.signedIn,
               "Session expiry left the draft visible")
        renameAPI.accountError = nil
        renameAPI.reportedOwnerEmail = "verified@example.com"
        expect(await renameModel.signIn(email: "verified@example.com", password: "synthetic"),
               "Renamed account could not sign in")
        expect(renameModel.draft == "Keep this through email change" && renameModel.project == "bridge",
               "Same immutable account ID did not recover its held draft after email change")
        renameAPI.accountError = KairosFailure.service(401, "Please sign in again.")
        await renameModel.refresh()
        renameAPI.accountError = nil; renameAPI.reportedOwnerID = "replacement-user"
        _ = await renameModel.signIn(email: "verified@example.com", password: "synthetic")
        expect(renameModel.draft.isEmpty && renameModel.project.isEmpty,
               "A different account reusing the same email inherited the held draft")

        let legacyAPI = FixtureAPI(); legacyAPI.userID = nil
        let legacyModel = KairosModel(api: legacyAPI)
        await legacyModel.restore()
        expect(legacyModel.userID == "fixture-user" && legacyModel.loaded,
               "Legacy session did not acquire its immutable owner from the server")
        let unidentifiedAPI = FixtureAPI(); unidentifiedAPI.userID = nil
        unidentifiedAPI.accountError = URLError(.notConnectedToInternet)
        let unidentifiedModel = KairosModel(api: unidentifiedAPI)
        await unidentifiedModel.restore()
        unidentifiedModel.draft = "Unattributed fixture draft"
        expect(await unidentifiedModel.save() == false && unidentifiedAPI.saveCalls == 0,
               "An unverified legacy owner could save a draft without establishing identity")

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

        // Alice's read finishes after independent search expiry. Bob's login then
        // succeeds but its account fetch fails: no Alice values may reappear.
        let raceAPI = FixtureAPI(); let raceModel = KairosModel(api: raceAPI)
        await raceModel.restore(); raceModel.draft = "Alice's private draft"
        let journalPause = Suspension(); raceAPI.pauseJournal = journalPause
        let delayedRead = Task { await raceModel.refresh() }
        await journalPause.waitUntilPaused()
        raceModel.searchSessionExpired(KairosFailure.service(401, "Expired"))
        journalPause.release(); await delayedRead.value
        expect(!raceModel.signedIn && raceModel.journal == nil && !raceModel.loaded && raceModel.lastFetched == nil,
               "Delayed journal response restored an expired owner's notes")
        raceAPI.pauseJournal = nil; raceAPI.reportedOwnerID = "bob-user"
        raceAPI.accountError = KairosFailure.service(503, "Unavailable")
        _ = await raceModel.signIn(email: "bob@example.test", password: "synthetic")
        expect(raceModel.signedIn && raceModel.userID == "bob-user" && raceModel.journal == nil
               && !raceModel.loaded && raceModel.draft.isEmpty && raceModel.account == nil,
               "Failed first refresh exposed Alice's journal or draft under Bob's login")

        let accountRaceAPI = FixtureAPI(); let accountRaceModel = KairosModel(api: accountRaceAPI)
        await accountRaceModel.restore()
        let accountPause = Suspension(); accountRaceAPI.pauseAccount = accountPause
        let delayedAccount = Task { await accountRaceModel.refresh() }
        await accountPause.waitUntilPaused()
        accountRaceModel.searchSessionExpired(KairosFailure.service(401, "Expired"))
        accountPause.release(); await delayedAccount.value
        expect(accountRaceModel.userID.isEmpty && accountRaceModel.email.isEmpty && accountRaceModel.account == nil
               && accountRaceModel.journal == nil, "Delayed account response restored expired identity")

        let saveRaceAPI = FixtureAPI(); let saveRaceModel = KairosModel(api: saveRaceAPI)
        await saveRaceModel.restore(); saveRaceModel.draft = "Pending Alice write"
        let savePause = Suspension(); saveRaceAPI.pauseSave = savePause
        let delayedSave = Task { await saveRaceModel.save() }
        await savePause.waitUntilPaused()
        saveRaceModel.searchSessionExpired(KairosFailure.service(401, "Expired"))
        savePause.release(); _ = await delayedSave.value
        expect(!saveRaceModel.signedIn && saveRaceModel.journal == nil && saveRaceModel.draft.isEmpty,
               "Delayed save receipt restored expired display or visible draft")
        saveRaceAPI.pauseSave = nil
        _ = await saveRaceModel.signIn(email: "renamed@example.com", password: "synthetic")
        expect(saveRaceModel.draft == "Pending Alice write" && saveRaceModel.message?.contains("couldn't confirm") == true,
               "Held in-flight write lost its draft or duplicate-prevention warning")

        for action in ["disconnect", "delete", "create", "export"] {
            let controlAPI = FixtureAPI(); let controlModel = KairosModel(api: controlAPI)
            await controlModel.restore()
            let pause = Suspension(); controlAPI.pauseControl = pause
            let delayedControl = Task { await controlModel.perform(action) }
            await pause.waitUntilPaused()
            controlModel.searchSessionExpired(KairosFailure.service(401, "Expired"))
            pause.release(); await delayedControl.value
            expect(!controlModel.signedIn && controlModel.journal == nil && controlModel.exportURL == nil && !controlModel.loaded,
                   "Delayed \(action) response repopulated expired owner state")
        }

        print("\(passed) synthetic native-model checks passed; no iOS SDK or physical-device claim.")
    }
}
