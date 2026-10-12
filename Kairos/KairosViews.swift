// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Steffan Douglas Haskins
import SwiftUI
import UIKit
import UIKit

private struct KairosActionStyle: ButtonStyle {
    var primary = false
    @Environment(\.colorScheme) private var colorScheme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12).padding(.vertical, 10)
            .frame(minHeight: 44)
            .foregroundStyle(primary ? KairosStyle.ivory : KairosStyle.ink)
            .background(primary ? KairosStyle.aegean : KairosStyle.surface,
                        in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(primary && colorScheme == .dark ? KairosStyle.bronze : KairosStyle.outline, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// A restrained bridge mark. Decorative: the title carries the accessible name.
private struct BridgeMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.height * 0.78))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.78))
        path.move(to: CGPoint(x: rect.width * 0.12, y: rect.height * 0.78))
        path.addCurve(to: CGPoint(x: rect.width * 0.88, y: rect.height * 0.78),
                      control1: CGPoint(x: rect.width * 0.25, y: rect.height * 0.02),
                      control2: CGPoint(x: rect.width * 0.75, y: rect.height * 0.02))
        for fraction in [0.3, 0.5, 0.7] {
            path.move(to: CGPoint(x: rect.width * fraction, y: rect.height * 0.5))
            path.addLine(to: CGPoint(x: rect.width * fraction, y: rect.height * 0.78))
        }
        return path
    }
}

struct KairosRoot: View {
    @EnvironmentObject private var model: KairosModel
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        NavigationStack {
            Group { if model.signedIn { JournalView() } else { SignInView() } }
                .navigationTitle("Kairos-Bridge")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Text("Invited preview").font(.caption).foregroundStyle(.secondary) } }
        }
        // A session boundary must also discard pushed journal/control screens.
        .id(model.signedIn)
        .tint(KairosStyle.ink)
        .toolbarBackground(KairosStyle.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && model.signedIn { Task { await model.refresh() } }
        }
    }
}

struct SignInView: View {
    @EnvironmentObject private var model: KairosModel
    @State private var email = ""
    @State private var password = ""
    var body: some View {
        Form {
            Group {
                Section {
                    BridgeMark().stroke(KairosStyle.bronze, lineWidth: 2).frame(width: 48, height: 32).accessibilityHidden(true)
                    Text("The bridge to remembrance.").font(.system(.title2, design: .serif).weight(.semibold))
                    Text("Kairos keeps the notes you choose to carry into your next conversation.")
                }
                Section("Sign in to Kairos") {
                    TextField("Email", text: $email).textContentType(.username).keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField("Password", text: $password).textContentType(.password)
                    Button("Sign in") {
                        Task {
                            if await model.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password) { password = "" }
                        }
                    }.disabled(model.busy || email.isEmpty || password.isEmpty)
                }
                if model.busy { ProgressView("Signing in…") }
                if let message = model.message { Section { Text(message).accessibilityIdentifier("service-message") } }
                Section {
                    Text("This build uses invited test accounts. Customer signup and account recovery aren't ready. This app doesn't save your password or add it to journal notes.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Link("Open Kairos account page", destination: KairosAPI.origin.appendingPathComponent("sign-in"))
                    Text("Browser sign-in and app sign-in are separate. Use the same Kairos account when your AI asks you to approve access.").font(.footnote)
                }
            }.listRowBackground(KairosStyle.surface)
        }
        .foregroundStyle(KairosStyle.ink)
        .scrollContentBackground(.hidden).background(KairosStyle.background)
    }
}

struct JournalView: View {
    @EnvironmentObject private var model: KairosModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @StateObject private var browser = JournalSearchModel()
    @State private var composing = false
    @State private var searchText = ""
    @State private var mode = JournalSearchMode.words
    @State private var selectedProject = ""
    @State private var selectedAuthor = ""
    @State private var refresh = 0
    @FocusState private var searching: Bool

    private var query: JournalQuery {
        JournalQuery(text: searchText, mode: mode, project: selectedProject, author: selectedAuthor)
    }

    var body: some View {
        List {
            Group {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 12) {
                            if !dynamicTypeSize.isAccessibilitySize {
                                BridgeMark().stroke(KairosStyle.bronze, lineWidth: 2).frame(width: 42, height: 28).accessibilityHidden(true)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Anamnesis").font(.system(.title, design: .serif).weight(.semibold)).foregroundStyle(KairosStyle.ink)
                                    .fixedSize(horizontal: false, vertical: true).layoutPriority(1)
                                Text("Your journal").font(.subheadline).foregroundStyle(KairosStyle.secondaryInk)
                            }
                        }
                        Text("The bridge to remembrance.").font(.subheadline)
                        if let date = browser.lastFetched {
                            Text("Last refreshed \(date.formatted(date: .abbreviated, time: .standard))")
                                .font(.caption).foregroundStyle(KairosStyle.secondaryInk)
                        }
                    }
                }
                if let message = model.message { Section { Text(message).accessibilityIdentifier("service-message") } }
                if model.busy { ProgressView("Working…") }
                if model.journal?.deleted == true {
                    Section {
                        Text("Your active journal was deleted.")
                        Button("Start a new journal") { Task { await model.perform("create") } }.disabled(model.busy)
                    }
                } else {
                    Section("View your memories") {
                        Picker("Project", selection: $selectedProject) {
                            Text("All projects").tag("")
                            ForEach(browser.projects, id: \.self) { Text(projectLabel($0)).tag($0) }
                        }.accessibilityIdentifier("project-filter")
                        Picker("Author", selection: $selectedAuthor) {
                            Text("All authors").tag("")
                            ForEach(browser.authors, id: \.self) { Text(sourceLabel($0)).tag($0) }
                        }.accessibilityIdentifier("author-filter")
                        Text(mode.hint).font(.footnote).foregroundStyle(KairosStyle.secondaryInk)
                    }
                    Section(query.isSearch ? "Search results" : "Your memories") {
                        if browser.loaded {
                            Text("\(browser.total) \(query.isSearch ? "matching " : "")\(browser.total == 1 ? "memory" : "memories") · Whole journal · Newest first")
                                .font(.footnote).foregroundStyle(KairosStyle.secondaryInk)
                                .accessibilityIdentifier("search-result-count")
                            if browser.matchedMode == "any" {
                                Text("No notes contain all of these words. Showing notes containing any of them.")
                                    .font(.footnote).foregroundStyle(KairosStyle.secondaryInk)
                            }
                            if browser.entries.isEmpty { Text(emptyMessage).foregroundStyle(KairosStyle.secondaryInk) }
                        }
                        ForEach(browser.entries) { entry in MemoryRow(entry: entry) }
                        if browser.loading {
                            ProgressView(query.isSearch ? "Searching…" : "Loading memories…")
                                .accessibilityIdentifier("search-loading")
                        }
                        if let message = browser.message {
                            Text(message).accessibilityIdentifier("search-message")
                            if query.validationMessage == nil {
                                Button("Try again") { refresh += 1 }.disabled(browser.loading)
                            }
                        }
                        if browser.hasMore {
                            Button {
                                searching = false
                                Task { await browser.showMore(owner: model.email, api: model.api, onExpired: model.searchSessionExpired) }
                            } label: {
                                Label("Show more", systemImage: "chevron.down").frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .disabled(browser.loading || !browser.current || model.busy)
                            .accessibilityLabel("Show more memories")
                            .accessibilityHint("Loads older matching notes from your journal.")
                            .accessibilityIdentifier("show-more-memories")
                        }
                        if browser.loaded {
                            Text("Showing \(browser.entries.count) of \(browser.total) memories.")
                                .font(.footnote).foregroundStyle(KairosStyle.secondaryInk)
                        }
                    }
                }
            }.listRowBackground(KairosStyle.surface)
        }
        .foregroundStyle(KairosStyle.ink)
        .scrollContentBackground(.hidden).background(KairosStyle.background)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                actions
                if model.journal?.deleted != true { searchControls }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(KairosStyle.background).overlay(alignment: .bottom) { Divider() }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { searching = false; Task { await model.refresh() } } label: { Image(systemName: "arrow.clockwise") }
                    .accessibilityLabel("Refresh journal").disabled(model.busy)
            }
        }
        .refreshable { await model.refresh() }
        .sheet(isPresented: $composing) { ComposeView() }
        .onChange(of: query) { _, value in browser.prepare(value, owner: model.email) }
        .onChange(of: model.lastFetched) { _, _ in refresh += 1 }
        .onChange(of: model.journal?.deleted) { _, deleted in
            if deleted == true { browser.reset(); searchText = ""; selectedProject = ""; selectedAuthor = "" }
        }
        .onDisappear { browser.cancel() }
        .task(id: JournalRequest(query: query, owner: model.email, refresh: refresh, deleted: model.journal?.deleted == true)) {
            let requested = query; let owner = model.email
            guard model.signedIn, model.journal?.deleted != true else { browser.reset(); return }
            if requested.isSearch {
                do { try await Task.sleep(nanoseconds: 250_000_000) } catch { return }
            }
            await browser.reload(requested, owner: owner, api: model.api, onExpired: model.searchSessionExpired)
        }
    }

    private var emptyMessage: String {
        if query.isSearch && mode == .id { return "No memory has that note ID. Check the ID or clear your filters." }
        if query.isSearch { return "No memories match. Try fewer words or clear your filters." }
        if !selectedProject.isEmpty || !selectedAuthor.isEmpty { return "No memories match these filters. Choose another view." }
        return "No notes yet. Tap Remember to begin."
    }

    private var searchControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { searchField.frame(minWidth: 180); modePicker.fixedSize(horizontal: true, vertical: false) }
            VStack(alignment: .leading, spacing: 8) { searchField; modePicker }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(KairosStyle.secondaryInk).accessibilityHidden(true)
            TextField(mode == .id ? "Paste a note ID" : "Search your journal", text: $searchText,
                      prompt: Text(mode == .id ? "Paste a note ID" : "Search your journal").foregroundColor(KairosStyle.secondaryInk))
                .focused($searching).textInputAutocapitalization(.never).autocorrectionDisabled()
                .keyboardType(mode == .id ? .asciiCapable : .default).submitLabel(.search)
                .onSubmit { searching = false; refresh += 1 }
                .accessibilityLabel("Search your journal")
                .accessibilityHint(mode.hint).accessibilityIdentifier("journal-search")
            if !searchText.isEmpty {
                Button { searchText = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .frame(minWidth: 44, minHeight: 44).buttonStyle(.borderless)
                    .accessibilityLabel("Clear search").accessibilityIdentifier("clear-search")
            }
        }
        .padding(.horizontal, 12).frame(minHeight: 44)
        .background(KairosStyle.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).stroke(KairosStyle.outline, lineWidth: 1) }
    }

    private var modePicker: some View {
        Menu {
            Picker("Search mode", selection: $mode) {
                ForEach(JournalSearchMode.allCases) { Text($0.title).tag($0) }
            }
        } label: {
            HStack(spacing: 8) { Text(mode.title); Image(systemName: "chevron.down").imageScale(.small) }
        }
        .buttonStyle(KairosActionStyle()).accessibilityLabel("Search mode, \(mode.title)")
        .accessibilityIdentifier("search-mode")
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { rememberAction; connectAction; ownerAction }.fixedSize(horizontal: true, vertical: false)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) { rememberAction; connectAction }.fixedSize(horizontal: true, vertical: false)
                ownerAction
            }
            VStack(alignment: .leading, spacing: 8) { rememberAction; connectAction; ownerAction }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private var rememberAction: some View {
        Button("Remember") { searching = false; composing = true }
            .buttonStyle(KairosActionStyle(primary: true)).disabled(model.busy || model.journal?.deleted == true)
            .accessibilityIdentifier("remember-action")
    }
    private var connectAction: some View {
        NavigationLink("Connect") { ConnectionsView() }.buttonStyle(KairosActionStyle()).accessibilityIdentifier("connections-action")
    }
    private var ownerAction: some View {
        NavigationLink("Your journal") { ControlsView() }.buttonStyle(KairosActionStyle()).accessibilityIdentifier("owner-controls-action")
    }
}

private func projectLabel(_ tag: String) -> String {
    let slug = tag.hasPrefix("project-") ? String(tag.dropFirst(8)) : tag
    return slug.replacingOccurrences(of: "-", with: " ").capitalized
}

private func sourceLabel(_ actor: String) -> String {
    ["you": "You", "claude": "Claude", "chatgpt": "ChatGPT", "grok": "Grok", "gemini": "Gemini"][actor] ?? actor
}

private struct MemoryRow: View {
    let entry: JournalEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(entry.sourceName).font(.subheadline.weight(.semibold)).foregroundStyle(KairosStyle.authorInk)
            Text(entry.text).font(.body).lineSpacing(3).textSelection(.enabled)
            Text(entry.date.map { $0.formatted(date: .abbreviated, time: .standard) } ?? entry.created_at)
                .font(.caption).foregroundStyle(KairosStyle.secondaryInk)
            let projects = entry.tags.filter { $0.hasPrefix("project-") }
            if !projects.isEmpty {
                Text(projects.map(projectLabel).joined(separator: ", "))
                    .font(.caption.weight(.medium)).foregroundStyle(KairosStyle.secondaryInk)
            }
        }
        .padding(.vertical, 10)
        .contextMenu {
            Button("Copy note ID") { UIPasteboard.general.string = entry.id }
        }
        .accessibilityElement(children: .contain)
    }
}

struct ComposeView: View {
    @EnvironmentObject private var model: KairosModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var editingNote: Bool
    var body: some View {
        NavigationStack {
            Form {
                Group {
                    Section("A note for next time") {
                        TextField("Write something to remember", text: $model.draft, axis: .vertical)
                            .lineLimit(6...12)
                            .focused($editingNote)
                            .disabled(model.busy)
                            .accessibilityLabel("A note for next time")
                            .accessibilityIdentifier("note-draft")
                    }
                    Section("Project (optional)") {
                        TextField("For example: kitchen", text: $model.project)
                            .textInputAutocapitalization(.never).autocorrectionDisabled().disabled(model.busy)
                        let projects = Array(Set((model.journal?.entries ?? []).flatMap {
                            $0.tags.filter { $0.hasPrefix("project-") }
                        })).sorted()
                        if !projects.isEmpty {
                            Menu("Choose a recent project") {
                                Button("No project") { model.project = "" }
                                ForEach(projects, id: \.self) { tag in
                                    Button(projectLabel(tag)) { model.project = String(tag.dropFirst(8)) }
                                }
                            }.disabled(model.busy)
                        }
                        Text("Choose a recent project, or use a short name such as kitchen or summer-trip.")
                            .font(.footnote).foregroundStyle(KairosStyle.secondaryInk)
                    }
                    if let message = model.message { Section { Text(message) } }
                    Section {
                        Button("Save note") { Task { if await model.save() { dismiss() } } }
                            .disabled(model.busy || model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if model.busy { ProgressView("Saving…") }
                        Text("If a save can't be confirmed, check your journal before trying again. Kairos doesn't automatically retry a note.").font(.footnote).foregroundStyle(.secondary)
                    }
                }.listRowBackground(KairosStyle.surface)
            }.navigationTitle("Remember")
                .foregroundStyle(KairosStyle.ink)
                .scrollContentBackground(.hidden).background(KairosStyle.background)
                .tint(KairosStyle.ink)
                .toolbarBackground(KairosStyle.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .interactiveDismissDisabled(model.busy)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Keep draft") { dismiss() }.disabled(model.busy) }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { editingNote = false }
                    }
                }
        }
    }
}

struct ConnectionsView: View {
    @EnvironmentObject private var model: KairosModel
    @State private var copiedAddress = false
    var body: some View {
        Form {
            Group {
                Section {
                    Text("One journal. Your choice of AI.").font(.system(.title2, design: .serif).weight(.semibold))
                    Text("Approval lets an AI use this journal. Enable Kairos in each new chat where you want to use it.")
                    if !model.email.isEmpty { Text(model.email).font(.caption).foregroundStyle(.secondary) }
                }
                ForEach(JournalProvider.allCases) { provider in
                    Section(provider.name) {
                        if let approval = model.journal?.approval(for: provider) {
                            Label("Approved for this journal", systemImage: "checkmark.circle")
                            Text(approval.scopes.contains("journal:write") ? "Can read and save notes." : "Can read notes. Saving is not approved.")
                                .font(.footnote).foregroundStyle(.secondary)
                            Text("Enable Kairos in a new \(provider.name) chat.")
                        } else {
                            Text(model.loaded ? "Not approved for this journal." : "Refresh to check approval.")
                        }
                        Link("Open \(provider.name) connections",
                             destination: provider == .claude ? model.claudeURL : provider.settingsURL)
                        if provider == .claude && model.journal?.claudeApproved != true {
                            Text("Choose Sign in now and Use Claude's published identity in the custom connector form. Sign in to Kairos, check the account email, then approve access.")
                                .font(.footnote)
                        } else if model.journal?.approval(for: provider) == nil {
                            Text("Add a custom connection using the address below. Follow \(provider.name)'s setup, check the Kairos account email, and approve access.")
                                .font(.footnote)
                        }
                    }
                }
                Section("Connection address") {
                    Text("Use your existing Kairos connection if already added. Its name may still include test.")
                    Text(KairosAPI.origin.absoluteString + "/mcp").font(.footnote).textSelection(.enabled)
                    Button("Copy connection address") {
                        UIPasteboard.general.string = KairosAPI.origin.absoluteString + "/mcp"
                        copiedAddress = true
                    }.accessibilityIdentifier("copy-connection-address")
                    if copiedAddress { Text("Address copied. Paste it into your AI's custom connection form.") }
                }
                Section {
                    Text("This app and your browser have separate sign-ins. Approve the same Kairos account shown here. Your AI receives notes you ask it to retrieve.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("Use Your journal → Disconnect all AI access to stop every approved connection. Your notes remain.")
                        .font(.footnote)
                    Button("Refresh approval") { Task { await model.refresh() } }.disabled(model.busy)
                    if let message = model.message { Text(message) }
                }
            }.listRowBackground(KairosStyle.surface)
        }.navigationTitle("AI connections")
            .foregroundStyle(KairosStyle.ink)
            .scrollContentBackground(.hidden).background(KairosStyle.background)
    }
}

struct ControlsView: View {
    @EnvironmentObject private var model: KairosModel
    @State private var deleting = false
    @State private var disconnecting = false
    var body: some View {
        Form {
            Group {
                if let message = model.message { Section { Text(message) } }
                Section("Your account") {
                    if !model.email.isEmpty { Text(model.email).font(.subheadline).textSelection(.enabled) }
                    Text("Your private journal, shared with the AI connections you approve.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Keep a copy") {
                    Button("Prepare journal export") { Task { await model.perform("export") } }.disabled(model.busy || model.journal?.deleted == true)
                    if let url = model.exportURL { ShareLink("Share export", item: url) }
                    Text("An export contains your journal notes. Copies you save or share are yours to manage.").font(.footnote).foregroundStyle(.secondary)
                }
                Section("Control AI access") {
                    Button("Disconnect all AI access") { disconnecting = true }.disabled(model.busy)
                    Text("Disconnect stops new AI access and keeps your notes. Text already copied into an AI conversation can remain there.").font(.footnote).foregroundStyle(.secondary)
                    Button("Sign out") { Task { await model.perform("signout") } }.disabled(model.busy)
                    Text("Signing out preserves approved AI connections. Use Disconnect to stop their access.").font(.footnote).foregroundStyle(.secondary)
                }
                Section("Remove active notes") {
                    Button("Delete journal", role: .destructive) { deleting = true }.disabled(model.busy || model.journal?.deleted == true)
                    Text("Deletion removes active notes and disconnects every AI. It cannot be undone here. The sign-in account remains. Host disk snapshots may retain deleted data; customer recovery and backup removal aren't ready.").font(.footnote).foregroundStyle(.secondary)
                }
            }.listRowBackground(KairosStyle.surface)
        }.navigationTitle("Your choice")
            .foregroundStyle(KairosStyle.ink)
            .scrollContentBackground(.hidden).background(KairosStyle.background)
            .confirmationDialog("Disconnect all AI access? Your notes will remain.", isPresented: $disconnecting, titleVisibility: .visible) {
                Button("Disconnect all AI access", role: .destructive) { Task { await model.perform("disconnect") } }
            }
            .confirmationDialog("Delete every active note? This cannot be undone here.", isPresented: $deleting, titleVisibility: .visible) {
                Button("Delete all my notes", role: .destructive) { Task { await model.perform("delete") } }
            }
    }
}
