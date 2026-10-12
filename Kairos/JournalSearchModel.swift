// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Steffan Douglas Haskins
import SwiftUI

// A server-backed view of the whole private journal. It never writes queries
// or persists result text on this device. Revision guards also reject replies
// from services that finish after the Swift task has been cancelled.
@MainActor
final class JournalSearchModel: ObservableObject {
    @Published private(set) var entries: [JournalEntry] = []
    @Published private(set) var projects: [String] = []
    @Published private(set) var authors: [String] = []
    @Published private(set) var total = 0
    @Published private(set) var matchedMode = "history"
    @Published private(set) var loading = false
    @Published private(set) var loaded = false
    @Published private(set) var current = false
    @Published private(set) var message: String?
    @Published private(set) var lastFetched: Date?
    private(set) var query = JournalQuery()
    private var owner = ""
    private var revision = 0
    private var nextCursor: String?
    private var snapshot: Int?
    var hasMore: Bool { nextCursor != nil }

    func prepare(_ query: JournalQuery, owner: String) {
        guard self.query != query || self.owner != owner else { return }
        let changedOwner = self.owner != owner
        revision += 1
        self.query = query; self.owner = owner
        entries = []; total = 0; loaded = false; current = false
        nextCursor = nil; snapshot = nil; lastFetched = nil
        loading = false; message = query.validationMessage
        // Keep the full-history filter choices within the same account.
        if owner.isEmpty || changedOwner { projects = []; authors = [] }
    }

    func cancel() { revision += 1; loading = false; current = false }

    func reset() {
        cancel(); owner = ""; query = JournalQuery()
        entries = []; projects = []; authors = []; total = 0
        loaded = false; nextCursor = nil; snapshot = nil; message = nil; lastFetched = nil
    }

    func reload(_ query: JournalQuery, owner: String, api: any KairosServing,
                onExpired: (Error) -> Void) async {
        prepare(query, owner: owner)
        guard !owner.isEmpty else { reset(); return }
        if let invalid = query.validationMessage { message = invalid; return }
        revision += 1; let token = revision
        loading = true; current = false; message = nil
        defer { if revision == token { loading = false } }
        do {
            let page = try await api.search(query, cursor: nil)
            guard !Task.isCancelled, revision == token, self.owner == owner, self.query == query else { return }
            try validate(page)
            entries = page.entries; total = page.total; matchedMode = page.matched_mode
            projects = page.projects; authors = page.authors
            nextCursor = page.next_cursor; snapshot = page.snapshot_seq
            loaded = true; current = true; lastFetched = Date()
        } catch {
            guard !Task.isCancelled, revision == token else { return }
            fail(error, onExpired: onExpired)
        }
    }

    func showMore(owner: String, api: any KairosServing, onExpired: (Error) -> Void) async {
        guard !loading, current, self.owner == owner, let cursor = nextCursor else { return }
        revision += 1; let token = revision; let requested = query
        loading = true; message = nil
        defer { if revision == token { loading = false } }
        do {
            let page = try await api.search(requested, cursor: cursor)
            guard !Task.isCancelled, revision == token, self.owner == owner, query == requested else { return }
            try validate(page)
            guard page.snapshot_seq == snapshot, page.total == total, page.matched_mode == matchedMode,
                  page.next_cursor != cursor, Set(entries.map(\.id)).isDisjoint(with: page.entries.map(\.id)) else {
                throw KairosFailure.invalidResponse
            }
            entries += page.entries; nextCursor = page.next_cursor
            // Continuation keeps the original snapshot; it isn't a refresh of
            // newly arrived notes and must not relabel that snapshot as newer.
        } catch {
            guard !Task.isCancelled, revision == token else { return }
            fail(error, onExpired: onExpired)
        }
    }

    private func validate(_ page: JournalSearchPage) throws {
        guard page.total >= page.entries.count, page.total >= 0, page.snapshot_seq >= 0,
              page.entries.count <= 15, Set(page.entries.map(\.id)).count == page.entries.count,
              ["history", "all", "any", "phrase", "id"].contains(page.matched_mode),
              page.next_cursor != "", page.next_cursor == nil || !page.entries.isEmpty else {
            throw KairosFailure.invalidResponse
        }
    }

    private func fail(_ error: Error, onExpired: (Error) -> Void) {
        if let failure = error as? KairosFailure, failure.signInRequired {
            reset(); onExpired(error); return
        }
        if error is URLError {
            message = loaded ? "Can't reach Kairos. Previously shown results haven't been refreshed. Check your connection and try again."
                             : "Search needs a connection. Check your connection and try again."
        } else { message = error.localizedDescription }
    }
}
