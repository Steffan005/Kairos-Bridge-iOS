// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Steffan Douglas Haskins
import Foundation

private final class RefuseRedirects: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        // Owner credentials must never follow a redirect to another destination.
        completionHandler(nil)
    }
}

@MainActor
protocol KairosServing {
    var email: String? { get }
    var sessionStorageWarning: String? { get }
    func restoreSession() throws -> Bool
    func forgetSession() throws
    func signIn(email: String, password: String) async throws
    func journal() async throws -> JournalEnvelope
    func search(_ query: JournalQuery, cursor: String?) async throws -> JournalSearchPage
    func saveNote(text: String, project: String) async throws
    func disconnect() async throws
    func deleteJournal() async throws
    func recreateJournal() async throws
    func export() async throws -> Data
    func signOut() async throws
}

extension KairosServing {
    var sessionStorageWarning: String? { nil }
    func search(_ query: JournalQuery, cursor: String?) async throws -> JournalSearchPage {
        throw KairosFailure.service(503, "Journal search is unavailable. Please try again.")
    }
}

@MainActor
final class KairosAPI: KairosServing {
    static let origin = URL(string: "https://kairos-journal-staging.onrender.com")!
    private let vault: any SessionStoring
    private let providedTransport: URLSession?
    private var saved = SessionVault.Session(email: nil, cookies: [])
    private(set) var sessionStorageWarning: String?
    private let redirects = RefuseRedirects()
    private lazy var transport: URLSession = {
        if let providedTransport { return providedTransport }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 20
        return URLSession(configuration: configuration, delegate: redirects, delegateQueue: nil)
    }()

    init(vault: any SessionStoring = SessionVault(), transport: URLSession? = nil) {
        self.vault = vault
        self.providedTransport = transport
    }

    var email: String? { saved.email }

    func restoreSession() throws -> Bool {
        saved = try vault.load() ?? .init(email: nil, cookies: [])
        sessionStorageWarning = nil
        saved.cookies.removeAll { $0.expires.map { $0 <= Date() } ?? false }
        return !saved.cookies.isEmpty
    }

    func forgetSession() throws {
        try vault.clear()
        saved = .init(email: nil, cookies: [])
        sessionStorageWarning = nil
    }

    func signIn(email: String, password: String) async throws {
        let data = try await request("/api/auth/sign-in/email", method: "POST", body: ["email": email, "password": password])
        let reply = try JSONDecoder().decode(SignInReply.self, from: data)
        guard !saved.cookies.isEmpty else { throw KairosFailure.invalidResponse }
        saved.email = reply.user.email
        try vault.save(saved)
        sessionStorageWarning = nil
    }

    func journal() async throws -> JournalEnvelope {
        try JSONDecoder().decode(JournalEnvelope.self, from: await request("/api/journal"))
    }

    func search(_ query: JournalQuery, cursor: String? = nil) async throws -> JournalSearchPage {
        var components = URLComponents()
        components.path = "/api/journal/search"
        components.queryItems = [
            .init(name: "q", value: query.normalizedText),
            .init(name: "mode", value: query.mode.rawValue),
            .init(name: "limit", value: "15")
        ]
        if !query.project.isEmpty { components.queryItems?.append(.init(name: "project", value: query.project)) }
        if !query.author.isEmpty { components.queryItems?.append(.init(name: "author", value: query.author)) }
        if let cursor { components.queryItems?.append(.init(name: "cursor", value: cursor)) }
        // URLComponents permits literal '+', but the server's URLSearchParams
        // decodes it as a space. Preserve literal plus signs in every value.
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        guard let path = components.string else { throw KairosFailure.invalidResponse }
        return try JSONDecoder().decode(JournalSearchPage.self, from: await request(path))
    }

    func saveNote(text: String, project: String) async throws {
        _ = try await request("/api/journal/notes", method: "POST",
                              body: ["text": text, "tags": project.isEmpty ? [] : ["project-" + project]])
    }

    func disconnect() async throws { _ = try await request("/api/journal/disconnect", method: "POST", body: [:]) }
    func deleteJournal() async throws { _ = try await request("/api/journal", method: "DELETE", body: [:]) }
    func recreateJournal() async throws { _ = try await request("/api/journal/create", method: "POST", body: [:]) }
    func export() async throws -> Data { try await request("/api/journal/export") }

    func signOut() async throws {
        _ = try await request("/api/auth/sign-out", method: "POST", body: [:])
        do { try forgetSession() }
        catch {
            saved = .init(email: nil, cookies: [])
            sessionStorageWarning = nil
            throw KairosFailure.signedOutStorageCleanup
        }
    }

    private func request(_ path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> Data {
        guard path.hasPrefix("/api/"), let url = URL(string: path, relativeTo: Self.origin)?.absoluteURL,
              url.host == Self.origin.host, url.scheme == "https" else { throw KairosFailure.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Self.origin.absoluteString, forHTTPHeaderField: "Origin")
        request.httpShouldHandleCookies = false
        let cookies = saved.cookies.filter { cookie in
            cookie.domain.trimmingCharacters(in: CharacterSet(charactersIn: ".")) == url.host &&
            url.path.hasPrefix(cookie.path) && (cookie.expires.map { $0 > Date() } ?? true)
        }
        if !cookies.isEmpty { request.setValue(cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; "), forHTTPHeaderField: "Cookie") }
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        // No automatic application retry: a timed-out mutation may already have committed.
        let (data, response) = try await transport.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw KairosFailure.invalidResponse }
        if (200..<300).contains(response.statusCode) {
            let previousSession = saved
            let headers = response.allHeaderFields.reduce(into: [String: String]()) { result, pair in
                if let key = pair.key as? String { result[key] = String(describing: pair.value) }
            }
            for cookie in HTTPCookie.cookies(withResponseHeaderFields: headers, for: url) {
                guard cookie.isSecure,
                      cookie.domain.trimmingCharacters(in: CharacterSet(charactersIn: ".")) == Self.origin.host else { continue }
                saved.cookies.removeAll { $0.name == cookie.name && $0.path == cookie.path }
                if cookie.expiresDate.map({ $0 <= Date() }) != true {
                    saved.cookies.append(.init(name: cookie.name, value: cookie.value, domain: cookie.domain,
                                               path: cookie.path, expires: cookie.expiresDate))
                }
            }
            // Sign-in persists after validating the account reply; sign-out clears
            // the vault itself. A later storage error must not turn an acknowledged
            // journal write or control action into a reported server failure.
            if saved != previousSession && path != "/api/auth/sign-in/email" && path != "/api/auth/sign-out" {
                do { try vault.save(saved); sessionStorageWarning = nil }
                catch {
                    sessionStorageWarning = "This device couldn't save updated sign-in details. You may need to sign in again when you reopen Kairos."
                }
            }
            return data
        }
        let failure = try? JSONDecoder().decode(ServiceFailure.self, from: data)
        throw KairosFailure.service(response.statusCode, failure?.error ?? failure?.message ?? "Kairos couldn't finish that request. Please try again.")
    }
}
