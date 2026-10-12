// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Steffan Douglas Haskins
// Reads a private snapshot; does not write notes or assert an actual UI tap.
import Foundation

@main
struct JournalWindowChecks {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else { fatalError("Supply a private journal snapshot") }
        let journal = try JSONDecoder().decode(JournalEnvelope.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
        let entries = journal.entries
        guard entries.count > 30 else { fatalError("Use an existing journal with more than30 records") }
        var passed = 0
        func expect(_ value: Bool, _ reason: String) {
            guard value else { fatalError(reason) }; passed += 1
        }
        var window = JournalWindow()
        let all = window.matching(entries, project: "", author: "")
        expect(all.map(\.id) == entries.map(\.id), "Default view changed stored ordering")
        expect(window.visible(all).map(\.id) == Array(entries.prefix(15)).map(\.id), "Initial window is not first15")
        let firstIDs = window.visible(all).map(\.id)
        window.showMore(matchingCount: all.count)
        expect(window.visible(all).map(\.id) == Array(entries.prefix(30)).map(\.id), "First reveal is not first30")
        expect(Array(window.visible(all).prefix(15)).map(\.id) == firstIDs, "Reveal lost the earlier group")
        while window.visibleCount < all.count {
            window.showMore(matchingCount: all.count)
        }
        expect(window.visible(all).map(\.id) == entries.map(\.id), "Final reveal lost records or reordered them")
        expect(Set(window.visible(all).map(\.id)).count == entries.count, "Reveal duplicated records")
        let completedCount = window.visibleCount
        window.showMore(matchingCount: all.count)
        expect(window.visibleCount == completedCount, "Reveal kept growing after exhaustion")
        window.reset()
        expect(window.visibleCount == 15, "Reset did not restore first15")
        for project in Set(entries.flatMap(\.tags).filter { $0.hasPrefix("project-") }) {
            let expected = entries.filter { $0.tags.contains(project) }
            let matched = window.matching(entries, project: project, author: "")
            expect(matched.map(\.id) == expected.map(\.id), "Project view dropped or changed records")
            expect(window.visible(matched).map(\.id) == Array(expected.prefix(15)).map(\.id), "Project filtering happened after pagination")
        }
        for actor in Set(entries.map(\.actor)) {
            let expected = entries.filter { $0.actor == actor }
            expect(window.matching(entries, project: "", author: actor).map(\.id) == expected.map(\.id), "Author filter changed records")
            let both = window.matching(entries, project: "project-kairos", author: actor)
            let expectedBoth = entries.filter { $0.tags.contains("project-kairos") && $0.actor == actor }
            expect(both.map(\.id) == expectedBoth.map(\.id), "Combined filter dropped or changed records")
        }
        expect(window.visible([]).isEmpty, "Empty view created a record")
        expect(window.matching(entries, project: "project-no-such-loaded-project", author: "").isEmpty, "Missing project returned unrelated memories")
        print("\(passed) display-window checks passed on \(entries.count) existing records. No new notes; no actual UI-tap claim.")
    }
}
