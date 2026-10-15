// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Steffan Douglas Haskins
// Synthetic query, pagination, cancellation and owner-boundary checks only.
import Foundation

@MainActor
private final class SearchFixture: KairosServing {
    var email: String? = "search@example.test"
    var userID: String? = "search-user"
    var calls = 0
    var response: ((JournalQuery, String?) async throws -> JournalSearchPage)!
    func restoreSession() throws -> Bool { true }
    func forgetSession() throws { email = nil }
    func signIn(email: String, password: String) async throws { self.email = email }
    func account() async throws -> AccountStatus {
        .init(id: "search-user", email: "search@example.test", emailVerified: false,
              recoveryAvailable: false, emailChangeAvailable: false)
    }
    func journal() async throws -> JournalEnvelope { .init(deleted: false, entries: [], connections: [], count: 61) }
    func search(_ query: JournalQuery, cursor: String?) async throws -> JournalSearchPage { calls += 1; return try await response(query, cursor) }
    func saveNote(text: String, project: String) async throws { fatalError("Search attempted a mutation") }
    func disconnect() async throws { fatalError("Search changed grants") }
    func deleteJournal() async throws { fatalError("Search deleted records") }
    func recreateJournal() async throws { fatalError("Search recreated records") }
    func export() async throws -> Data { Data() }
    func signOut() async throws { email = nil }
}

private func entry(_ number: Int) -> JournalEntry {
    .init(id: String(format: "%016x", number), text: "Synthetic memory \(number)", actor: "you",
          created_at: "2026-10-12T12:00:00.123Z", tags: ["project-old-only"])
}
private func page(_ numbers: [Int], total: Int = 61, cursor: String? = nil, snapshot: Int = 61, mode: String = "history") -> JournalSearchPage {
    .init(entries: numbers.map(entry), next_cursor: cursor, matched_mode: mode, total: total, snapshot_seq: snapshot,
          projects: ["project-old-only"], authors: ["you"])
}

private final class SearchVault: SessionStoring {
    func load() throws -> SessionVault.Session? {
        .init(email: "search@example.test", cookies: [.init(name: "fixture_session", value: "synthetic", domain: "kairos-journal-staging.onrender.com", path: "/", expires: nil)])
    }
    func save(_ session: SessionVault.Session) throws { }
    func clear() throws { }
}
private final class SearchHTTP: URLProtocol {
    static var lastRequest: URLRequest?
    static var status = 200
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lastRequest = request
        let body: [String: Any] = Self.status == 200 ? [
            "entries": [["id": "0123456789abcdef", "text": String(repeating: "Synthetic complete long memory. ", count: 180),
                         "actor": "claude", "created_at": "2026-10-12T12:00:00.123Z", "tags": ["project-kitchen"]]],
            "next_cursor": NSNull(), "matched_mode": "phrase", "total": 1, "snapshot_seq": 61,
            "projects": ["project-kitchen"], "authors": ["claude"]
        ] : ["error": "Sign in again."]
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: try! JSONSerialization.data(withJSONObject: body))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() { }
}

@main
struct SearchChecks {
    @MainActor
    static func main() async throws {
        var checks = 0
        func expect(_ value: Bool, _ message: String) { guard value else { fatalError(message) }; checks += 1 }
        let api = SearchFixture(); let browser = JournalSearchModel(); let q = JournalQuery()
        expect(JournalRequest(query: q, owner: "owner-a", refresh: 0, deleted: true)
               != JournalRequest(query: q, owner: "owner-a", refresh: 0, deleted: false),
               "Journal recreation failed to change the actual view's search task identity")
        api.response = { _, cursor in
            let offset = Int(cursor ?? "0")!
            let numbers = Array((1...61).reversed().dropFirst(offset).prefix(15))
            return page(numbers, cursor: offset + numbers.count < 61 ? String(offset + numbers.count) : nil)
        }
        await browser.reload(q, owner: "owner-a", api: api, onExpired: { _ in fatalError("Unexpected expiry") })
        expect(browser.entries.count == 15 && browser.total == 61 && browser.hasMore, "Initial whole-history page missing")
        expect(browser.projects == ["project-old-only"], "Full-history project choices missing")
        let snapshotFetched = browser.lastFetched
        for _ in 0..<4 { await browser.showMore(owner: "owner-a", api: api, onExpired: { _ in }) }
        expect(browser.entries.count == 61 && !browser.hasMore, "Show more didn't pass the old 50-record boundary")
        expect(Set(browser.entries.map(\.id)).count == 61 && browser.entries.last?.id == entry(1).id, "Paging duplicated or lost oldest memory")
        expect(browser.lastFetched == snapshotFetched, "Continuation mislabeled the old snapshot as freshly refreshed")
        let calls = api.calls
        await browser.showMore(owner: "owner-b", api: api, onExpired: { _ in })
        expect(api.calls == calls, "A different owner reused a cursor")

        api.response = { _, _ in throw URLError(.notConnectedToInternet) }
        await browser.reload(q, owner: "owner-a", api: api, onExpired: { _ in })
        expect(browser.entries.count == 61 && !browser.current && browser.message?.contains("haven't been refreshed") == true,
               "Offline refresh erased results or mislabeled them fresh")
        let newQuery = JournalQuery(text: "copper")
        browser.prepare(newQuery, owner: "owner-a")
        expect(browser.entries.isEmpty && !browser.loaded, "New query showed results from the old query")
        await browser.reload(newQuery, owner: "owner-a", api: api, onExpired: { _ in })
        expect(browser.message?.contains("needs a connection") == true, "Initial offline search lacks direction")

        var malformed = JournalQuery(text: "wrong", mode: .id)
        let beforeInvalid = api.calls
        await browser.reload(malformed, owner: "owner-a", api: api, onExpired: { _ in })
        expect(api.calls == beforeInvalid && browser.message?.contains("16-character") == true, "Malformed ID was sent to service")
        malformed.text = "0123456789ABCDEF"
        expect(malformed.validationMessage == nil, "Complete uppercase note ID rejected")
        expect(JournalQuery(text: String(repeating: "a", count: 501)).validationMessage != nil, "Long query wasn't bounded")

        api.response = { _, _ in page([61], total: 1, mode: "all") }
        await browser.reload(newQuery, owner: "owner-a", api: api, onExpired: { _ in })
        expect(browser.entries.count == 1 && browser.current, "Recovery failed after offline search")
        browser.prepare(newQuery, owner: "owner-b")
        expect(browser.entries.isEmpty && browser.projects.isEmpty && browser.authors.isEmpty, "Owner switch exposed prior data or filter labels")

        var oldReply: CheckedContinuation<JournalSearchPage, Error>?
        api.response = { request, _ in
            if request.text == "old" { return try await withCheckedThrowingContinuation { oldReply = $0 } }
            return page([60], total: 1, mode: "all")
        }
        let oldTask = Task { await browser.reload(.init(text: "old"), owner: "owner-b", api: api, onExpired: { _ in }) }
        while oldReply == nil { await Task.yield() }
        await browser.reload(.init(text: "new"), owner: "owner-b", api: api, onExpired: { _ in })
        oldReply?.resume(returning: page([61], total: 1, mode: "all")); await oldTask.value
        expect(browser.entries.first?.id == entry(60).id && browser.query.text == "new", "Late old response overwrote new results")

        api.response = { _, _ in page([61,61], total: 2) }
        await browser.reload(q, owner: "owner-b", api: api, onExpired: { _ in })
        expect(!browser.current && browser.message != nil, "Duplicate server IDs were accepted")
        api.response = { _, cursor in cursor == nil ? page([61], cursor: "next") : page([61], cursor: "next") }
        await browser.reload(q, owner: "owner-b", api: api, onExpired: { _ in })
        await browser.showMore(owner: "owner-b", api: api, onExpired: { _ in })
        expect(browser.entries.count == 1 && browser.message != nil, "Repeated page/cursor appended a duplicate")

        var expired = false
        api.response = { _, _ in throw KairosFailure.service(401, "Sign in again.") }
        await browser.reload(q, owner: "owner-b", api: api, onExpired: { _ in expired = true })
        expect(expired && browser.entries.isEmpty && browser.projects.isEmpty && !browser.loaded, "Expired owner search retained private display")
        browser.reset()
        expect(!browser.hasMore && browser.entries.isEmpty && browser.message == nil, "Reset retained search state")
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SearchHTTP.self]
        let transport = URLSession(configuration: config)
        defer { transport.invalidateAndCancel() }
        let actual = KairosAPI(vault: SearchVault(), transport: transport)
        _ = try actual.restoreSession()
        let literal = "café & + \"blue\" # ?"
        let reply = try await actual.search(.init(text: literal, mode: .exact, project: "project-kitchen", author: "claude"), cursor: "cursor.with+symbols")
        let request = SearchHTTP.lastRequest!
        let pairs = Dictionary(uniqueKeysWithValues: URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!.map { ($0.name, $0.value!) })
        expect(request.httpMethod == "GET" && request.url?.host == KairosAPI.origin.host && request.url?.path == "/api/journal/search", "Search request changed destination or method")
        expect(pairs["q"] == literal && pairs["mode"] == "exact" && pairs["cursor"] == "cursor.with+symbols", "Query URL encoding changed literal input or cursor")
        let wireQuery = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.percentEncodedQuery!
        let formPairs = Dictionary(uniqueKeysWithValues: wireQuery.split(separator: "&").map { item -> (String, String) in
            let pair = item.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            func decoded(_ value: Substring) -> String { String(value).replacingOccurrences(of: "+", with: " ").removingPercentEncoding! }
            return (decoded(pair[0]), decoded(pair[1]))
        })
        expect(formPairs["q"] == literal && formPairs["cursor"] == "cursor.with+symbols" && !wireQuery.contains("+"),
               "Server form-query decoding lost literal plus signs")
        expect(pairs["project"] == "project-kitchen" && pairs["author"] == "claude" && pairs["limit"] == "15", "Search omitted exact filters or page bound")
        expect(request.value(forHTTPHeaderField: "Cookie") == "fixture_session=synthetic", "Search omitted existing owner session")
        expect(reply.entries[0].text.count > 5000 && reply.entries[0].created_at.hasSuffix(".123Z"), "Owner search response truncated full text or timestamp")
        SearchHTTP.status = 401
        var signInRequired = false
        do { _ = try await actual.search(q, cursor: nil) } catch let failure as KairosFailure { signInRequired = failure.signInRequired }
        expect(signInRequired, "Search transport failed to identify expired owner session")
        print("Passed \(checks) synthetic native search checks; no live network or owner data.")
    }
}
