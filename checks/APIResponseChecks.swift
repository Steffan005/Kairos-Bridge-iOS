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
    static var mutations = 0
    static var rotateCookie = true
    static var approved = true
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
            Self.mutations += 1; status = 201
            body = "{\"id\":\"synthetic-ack\",\"text\":\"Synthetic response check\"}"
        case "/api/auth/sign-in/email":
            body = "{\"user\":{\"email\":\"fixture@example.test\"}}"
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
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
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
        print("\(passed) synthetic API-response checks passed; no live network or Keychain.")
    }
}
