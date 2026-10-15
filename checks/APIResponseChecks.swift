// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Steffan Douglas Haskins
// Synthetic HTTP callbacks and storage only; no live network or actual Keychain.
import Foundation

private final class FixtureVault: SessionStoring {
    var failSave = true
    var failClear = false
    var saves = 0
    var session: SessionVault.Session? = .init(email: "fixture@example.test", cookies: [
        .init(name: "fixture_session", value: "synthetic", domain: "kairos-journal-staging.onrender.com", path: "/", expires: nil)
    ])
    func load() throws -> SessionVault.Session? { session }
    func save(_ session: SessionVault.Session) throws {
        saves += 1
        if failSave { throw KairosFailure.secureStorage }
        self.session = session
    }
    func clear() throws {
        if failClear { throw KairosFailure.secureStorage }
        session = nil
    }
}

private final class FixtureHTTP: URLProtocol {
    private static let responseLock = NSLock()
    private static var pausedPath: String?
    private static var pausedReply: (() -> Void)?
    static func pause(_ path: String) {
        responseLock.lock(); defer { responseLock.unlock() }
        pausedPath = path
    }
    static var waiting: Bool {
        responseLock.lock(); defer { responseLock.unlock() }
        return pausedReply != nil
    }
    static func release() {
        responseLock.lock()
        let reply = pausedReply; pausedReply = nil; pausedPath = nil
        responseLock.unlock(); reply?()
    }
    static func waitUntilPaused() async {
        for _ in 0..<10_000 {
            if waiting { return }
            await Task.yield()
        }
        fatalError("Synthetic HTTP request did not reach suspension")
    }
    static var mutations = 0
    static var rotateCookie = true
    static var approved = true
    static var saveStatus = 201
    static var dropSaveResponse = false
    static var accountID = "fixture-user"
    static var accountEmail = "fixture@example.test"
    static var accountStatus = 200
    static var sessionMissing = false
    static var sessionReads = 0
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL)); return
        }
        let body: String
        var status = 200
        switch url.path {
        case "/api/journal/notes":
            Self.mutations += 1; status = Self.saveStatus
            if Self.dropSaveResponse {
                client?.urlProtocol(self, didFailWithError: URLError(.timedOut)); return
            }
            body = "{\"id\":\"synthetic-ack\",\"text\":\"Synthetic response check\"}"
        case "/api/auth/sign-in/email":
            body = "{\"user\":{\"id\":\"\(Self.accountID)\",\"email\":\"\(Self.accountEmail)\"}}"
        case "/api/account":
            status = Self.accountStatus
            body = status == 200
                ? "{\"id\":\"\(Self.accountID)\",\"email\":\"\(Self.accountEmail)\",\"emailVerified\":true,\"recoveryAvailable\":true,\"emailChangeAvailable\":true}"
                : "{\"error\":\"Account controls unavailable\"}"
        case "/api/auth/get-session":
            Self.sessionReads += 1
            body = Self.sessionMissing ? "null" : "{\"user\":{\"id\":\"\(Self.accountID)\",\"email\":\"\(Self.accountEmail)\",\"emailVerified\":true}}"
        case "/api/auth/sign-out":
            body = "{\"success\":true}"
        case "/api/journal/disconnect":
            Self.mutations += 1; Self.approved = false
            body = "{\"disconnected\":true}"
        case "/api/journal":
            let connections = Self.approved ? "[{\"clientId\":\"https://claude.ai/oauth/mcp-oauth-client-metadata\",\"scopes\":[\"journal:read\"]}]" : "[]"
            body = "{\"deleted\":false,\"count\":1,\"entries\":[{\"id\":\"synthetic\",\"text\":\"Synthetic API fixture\",\"actor\":\"you\",\"created_at\":\"2026-10-11T12:00:00.000Z\",\"tags\":[\"project-kitchen\"]}],\"connections\":\(connections)}"
        default:
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL)); return
        }
        var headers = ["Content-Type": "application/json"]
        if Self.rotateCookie && url.path != "/api/journal" {
            headers["Set-Cookie"] = "fixture_session=rotated-synthetic; Path=/; Secure; HttpOnly"
        }
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
        let reply = {
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: Data(body.utf8))
            self.client?.urlProtocolDidFinishLoading(self)
        }
        Self.responseLock.lock()
        if Self.pausedPath == url.path {
            Self.pausedReply = reply; Self.responseLock.unlock(); return
        }
        Self.responseLock.unlock(); reply()
    }
    override func stopLoading() { }
}

@main
struct APIResponseChecks {
    @MainActor
    static func main() async throws {
        var passed = 0
        func expect(_ value: Bool, _ message: String) {
            guard value else { fatalError(message) }; passed += 1
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureHTTP.self]
        let transport = URLSession(configuration: configuration)
        defer { transport.invalidateAndCancel() }
        let vault = FixtureVault()
        let api = KairosAPI(vault: vault, transport: transport)
        let restored = try api.restoreSession()
        expect(restored, "Fixture session was not restored")
        do {
            try await api.saveNote(text: "Synthetic response check", project: "kitchen")
        } catch {
            expect(FixtureHTTP.mutations == 1, "Fixture did not acknowledge exactly one write")
            fatalError("A server-confirmed write was reported as failed after secure storage failed")
        }
        expect(FixtureHTTP.mutations == 1, "Write was retried")
        expect(vault.saves == 1, "Fixture did not inject the storage failure")
        expect(api.sessionStorageWarning?.contains("couldn't save") == true,
               "Acknowledged write hid the local storage failure")

        FixtureHTTP.rotateCookie = false; FixtureHTTP.mutations = 0
        let unchangedVault = FixtureVault()
        let unchangedAPI = KairosAPI(vault: unchangedVault, transport: transport)
        _ = try unchangedAPI.restoreSession()
        try await unchangedAPI.saveNote(text: "Synthetic response check", project: "kitchen")
        expect(unchangedVault.saves == 0, "Unchanged session triggered a redundant storage write")
        expect(unchangedAPI.sessionStorageWarning == nil, "Unchanged session invented a storage warning")
        expect(FixtureHTTP.mutations == 1, "Unchanged-session write was retried")

        FixtureHTTP.rotateCookie = true
        let loginVault = FixtureVault()
        let loginAPI = KairosAPI(vault: loginVault, transport: transport)
        var loginFailed = false
        do { try await loginAPI.signIn(email: "fixture@example.test", password: "Synthetic fixture only") }
        catch KairosFailure.secureStorage { loginFailed = true }
        expect(loginFailed, "Sign-in succeeded without mandatory secure session storage")
        expect(loginVault.saves == 1, "Sign-in persisted before validating the account reply")

        let logoutVault = FixtureVault(); logoutVault.failClear = true
        let logoutAPI = KairosAPI(vault: logoutVault, transport: transport)
        _ = try logoutAPI.restoreSession()
        var knownSignOut = false
        do { try await logoutAPI.signOut() }
        catch KairosFailure.signedOutStorageCleanup { knownSignOut = true }
        expect(knownSignOut, "Acknowledged sign-out cleanup failure was not distinguished")
        expect(logoutAPI.email == nil, "Acknowledged sign-out retained an in-memory owner")
        expect(logoutVault.saves == 0, "Sign-out unnecessarily saved a session before clearing it")

        FixtureHTTP.mutations = 0; FixtureHTTP.approved = true
        let controlVault = FixtureVault()
        let controlAPI = KairosAPI(vault: controlVault, transport: transport)
        let model = KairosModel(api: controlAPI)
        await model.restore()
        expect(model.journal?.claudeApproved == true, "Initial control fixture wasn't approved")
        await model.perform("disconnect")
        expect(FixtureHTTP.mutations == 1 && !FixtureHTTP.approved, "Disconnect fixture did not run once")
        expect(model.journal?.connections.isEmpty == true && model.journal?.entries.count == 1,
               "Acknowledged Disconnect did not preserve notes and clear approval")
        expect(model.message?.contains("disconnected") == true && model.message?.contains("couldn't save") == true,
               "Disconnect hid either acknowledgement or storage warning")
        for (status, dropResponse) in [(503, false), (201, true)] {
            FixtureHTTP.mutations = 0; FixtureHTTP.saveStatus = status; FixtureHTTP.dropSaveResponse = dropResponse
            let ambiguousVault = FixtureVault(); ambiguousVault.failSave = false
            let ambiguousAPI = KairosAPI(vault: ambiguousVault, transport: transport)
            let ambiguousModel = KairosModel(api: ambiguousAPI)
            await ambiguousModel.restore()
            ambiguousModel.draft = "Synthetic possibly committed note"
            expect(await ambiguousModel.save() == false, "Unknown mutation was reported confirmed")
            expect(FixtureHTTP.mutations == 1, "Failed-response mutation was retried")
            expect(ambiguousModel.draft == "Synthetic possibly committed note", "Unknown commit discarded draft")
            expect(ambiguousModel.message?.contains("couldn't confirm") == true,
                   "Committed fixture with failed response didn't explain uncertainty")
            await ambiguousModel.refresh()
            expect(ambiguousModel.message?.contains("couldn't confirm") == true && FixtureHTTP.mutations == 1,
                   "Read certified the earlier unknown commit or repeated its mutation")
        }

        let legacyData = Data("{\"email\":\"old@example.test\",\"cookies\":[]}".utf8)
        let legacySession = try JSONDecoder().decode(SessionVault.Session.self, from: legacyData)
        expect(legacySession.userID == nil && legacySession.email == "old@example.test",
               "Older Keychain session format no longer decodes safely")

        FixtureHTTP.rotateCookie = false
        let identityVault = FixtureVault(); identityVault.failSave = false
        let identityAPI = KairosAPI(vault: identityVault, transport: transport)
        _ = try identityAPI.restoreSession()
        expect(identityAPI.userID == nil, "Legacy email was guessed into an account ID")
        let account = try await identityAPI.account()
        expect(account.id == "fixture-user" && identityVault.session?.userID == "fixture-user",
               "Authenticated account ID was not backfilled into secure storage")
        FixtureHTTP.accountEmail = "verified@example.com"
        _ = try await identityAPI.account()
        expect(identityAPI.email == "verified@example.com" && identityVault.session?.email == "verified@example.com",
               "Authoritative email change did not refresh both memory and secure storage")
        expect(identityAPI.userID == "fixture-user", "Email change replaced the immutable user ID")
        FixtureHTTP.accountID = "replacement-user"
        var identityRejected = false
        do { _ = try await identityAPI.account() }
        catch let error as KairosFailure { identityRejected = error.signInRequired }
        expect(identityRejected && identityAPI.userID == "fixture-user",
               "Unexpected account ID was accepted into an existing saved session")

        FixtureHTTP.accountID = "fixture-user"; FixtureHTTP.accountStatus = 404
        let fallbackVault = FixtureVault(); fallbackVault.failSave = false
        let fallbackAPI = KairosAPI(vault: fallbackVault, transport: transport)
        _ = try fallbackAPI.restoreSession()
        let fallback = try await fallbackAPI.account()
        expect(fallback.id == "fixture-user" && fallback.email == "verified@example.com"
               && !fallback.emailChangeAvailable && !fallback.recoveryAvailable,
               "Older service fallback did not establish identity with unavailable account controls")
        expect(fallbackVault.session?.userID == "fixture-user",
               "Older service's authoritative ID was not persisted")
        FixtureHTTP.sessionMissing = true
        var missingSessionRejected = false
        do { _ = try await fallbackAPI.account() }
        catch let error as KairosFailure { missingSessionRejected = error.signInRequired }
        expect(missingSessionRejected, "Null legacy session response did not require sign-in")

        FixtureHTTP.accountStatus = 503; FixtureHTTP.sessionMissing = false
        let previousSessionReads = FixtureHTTP.sessionReads
        do { _ = try await fallbackAPI.account(); fatalError("Account error was hidden") }
        catch KairosFailure.service(503, _) { }
        expect(FixtureHTTP.sessionReads == previousSessionReads,
               "Account-service failure silently fell back to a different response contract")

        FixtureHTTP.accountStatus = 200; FixtureHTTP.rotateCookie = true
        FixtureHTTP.accountID = "alice-user"; FixtureHTTP.accountEmail = "alice@example.test"
        let raceVault = FixtureVault(); raceVault.failSave = false
        let raceAPI = KairosAPI(vault: raceVault, transport: transport)
        _ = try raceAPI.restoreSession()
        FixtureHTTP.pause("/api/account")
        let expiredRead = Task { () -> Bool in
            do { _ = try await raceAPI.account(); return false }
            catch is CancellationError { return true }
            catch { return false }
        }
        await FixtureHTTP.waitUntilPaused()
        try raceAPI.forgetSession()
        FixtureHTTP.release()
        expect(await expiredRead.value && raceAPI.userID == nil && raceAPI.email == nil && raceVault.session == nil,
               "Delayed account/cookie response resurrected an expired device session")

        for oldStatus in [200, 401] {
            FixtureHTTP.accountStatus = oldStatus
            FixtureHTTP.accountID = "alice-user"; FixtureHTTP.accountEmail = "alice@example.test"
            FixtureHTTP.pause("/api/account")
            let replacedRead = Task { () -> Bool in
                do { _ = try await raceAPI.account(); return false }
                catch is CancellationError { return true }
                catch { return false }
            }
            await FixtureHTTP.waitUntilPaused()
            FixtureHTTP.accountID = "bob-user"; FixtureHTTP.accountEmail = "bob@example.test"
            try await raceAPI.signIn(email: "bob@example.test", password: "synthetic fixture only")
            let savedBob = raceVault.session
            FixtureHTTP.release()
            expect(await replacedRead.value && raceAPI.userID == "bob-user" && raceAPI.email == "bob@example.test"
                   && raceVault.session == savedBob,
                   "Old \(oldStatus) response modified the replacement owner's identity or secure session")
        }

        expect(KairosAPI.passwordRecoveryURL.scheme == "https" && KairosAPI.passwordRecoveryURL.path == "/forgot-password",
               "Forgot-password link requires an authenticated account page")
        expect(KairosAPI.accountURL.scheme == "https" && KairosAPI.accountURL.path == "/account",
               "Account management did not use the HTTPS account page")
        print("\(passed) synthetic API-response checks passed; no live network or Keychain.")
    }
}
