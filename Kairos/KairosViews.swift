// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Steffan Douglas Haskins
import SwiftUI

struct KairosRoot: View {
    @EnvironmentObject private var model: KairosModel
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        NavigationStack {
            Group { if model.signedIn { JournalView() } else { SignInView() } }
                .navigationTitle("Kairos")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Text("Invited preview").font(.caption).foregroundStyle(.secondary) } }
        }
        .tint(Color(red: 0.22, green: 0.40, blue: 0.33))
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
            Section {
                Text("Your AI conversations, with a place to remember.").font(.title2.bold())
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
                Text("Browser sign-in and app sign-in are separate. Use the same Kairos account when Claude asks you to approve access.").font(.footnote)
            }
        }
    }
}

struct JournalView: View {
    @EnvironmentObject private var model: KairosModel
    @State private var composing = false
    var body: some View {
        List {
            Section {
                Text("A place to pick up where you left off.").font(.title2.bold())
                if !model.email.isEmpty { Text(model.email).font(.caption).foregroundStyle(.secondary) }
                Text("Your private journal, shared with the AI connections you approve.").font(.subheadline)
                if let date = model.lastFetched { Text("Last refreshed \(date.formatted(date: .abbreviated, time: .standard))").font(.caption).foregroundStyle(.secondary) }
            }
            if let message = model.message { Section { Text(message).accessibilityIdentifier("service-message") } }
            if model.busy { ProgressView("Working…") }
            if model.journal?.deleted == true {
                Section {
                    Text("Your active journal was deleted.")
                    Button("Start a new journal") { Task { await model.perform("create") } }.disabled(model.busy)
                }
            } else {
                Section {
                    Button { composing = true } label: { Label("Remember something", systemImage: "square.and.pencil") }.disabled(model.busy)
                }
                Section("Saved notes") {
                    if model.loaded && model.journal?.entries.isEmpty == true { Text("No notes yet. Save something you'd like your AI to remember.").foregroundStyle(.secondary) }
                    ForEach(model.journal?.entries ?? []) { entry in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(entry.text).textSelection(.enabled)
                            Text(entry.sourceName).font(.caption.bold())
                            if let date = entry.date { Text(date.formatted(date: .abbreviated, time: .standard)).font(.caption).foregroundStyle(.secondary) }
                            else { Text(entry.created_at).font(.caption).foregroundStyle(.secondary) }
                            if !entry.tags.isEmpty { Text(entry.tags.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary) }
                        }.padding(.vertical, 6)
                    }
                    if let journal = model.journal, let count = journal.count, count > journal.entries.count {
                        Text("Showing \(journal.entries.count) of \(count) notes. Your export includes the full journal.").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Section {
                NavigationLink("AI connections") { ConnectionsView() }
                NavigationLink("Your journal, your choice") { ControlsView() }
                Button("Refresh") { Task { await model.refresh() } }.disabled(model.busy)
            }
        }
        .refreshable { await model.refresh() }
        .sheet(isPresented: $composing) { ComposeView() }
    }
}

struct ComposeView: View {
    @EnvironmentObject private var model: KairosModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("A note for next time") { TextEditor(text: $model.draft).frame(minHeight: 160).accessibilityLabel("A note for next time") }
                Section("Project (optional)") { TextField("For example: kitchen", text: $model.project).textInputAutocapitalization(.never).autocorrectionDisabled() }
                if let message = model.message { Section { Text(message) } }
                Section {
                    Button("Save note") { Task { if await model.save() { dismiss() } } }
                        .disabled(model.busy || model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if model.busy { ProgressView("Saving…") }
                    Text("If a save can't be confirmed, check your journal before trying again. Kairos doesn't automatically retry a note.").font(.footnote).foregroundStyle(.secondary)
                }
            }.navigationTitle("Remember something")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Keep draft") { dismiss() }.disabled(model.busy) } }
        }
    }
}

struct ConnectionsView: View {
    @EnvironmentObject private var model: KairosModel
    var body: some View {
        Form {
            Section("Claude") {
                Text(model.journal?.claudeApproved == true ? "Claude access is approved for this journal." : "Connect Claude to use your saved notes in a new conversation.")
                Link(model.journal?.claudeApproved == true ? "Open Claude connections" : "Connect Claude", destination: model.claudeURL)
                Text("1. Confirm the Kairos connection address. Choose Sign in now and Use Claude's published identity.")
                Text("2. Sign in to Kairos in your browser if asked. Check the account email before allowing access.")
                Text("3. Start a new conversation in the Claude app. Enable Kairos in the connectors menu.")
                Text("Your browser and this app have separate sign-ins. Check that Claude is connected to the same Kairos account shown in your journal.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("Already added?") {
                Text("Use the existing connector with this address. Its name may still include test. Reconnect when Claude asks, then enable it in your new chat.")
                Text(KairosAPI.origin.absoluteString + "/mcp").font(.footnote).textSelection(.enabled)
            }
            Section {
                Text("Approval doesn't mean the connector is enabled in the current chat. Claude receives the notes you ask it to retrieve.").font(.footnote)
                Button("Refresh approval") { Task { await model.refresh() } }.disabled(model.busy)
            }
        }.navigationTitle("AI connections")
    }
}

struct ControlsView: View {
    @EnvironmentObject private var model: KairosModel
    @State private var deleting = false
    @State private var disconnecting = false
    var body: some View {
        Form {
            if let message = model.message { Section { Text(message) } }
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
        }.navigationTitle("Your choice")
            .confirmationDialog("Disconnect all AI access? Your notes will remain.", isPresented: $disconnecting, titleVisibility: .visible) {
                Button("Disconnect all AI access", role: .destructive) { Task { await model.perform("disconnect") } }
            }
            .confirmationDialog("Delete every active note? This cannot be undone here.", isPresented: $deleting, titleVisibility: .visible) {
                Button("Delete all my notes", role: .destructive) { Task { await model.perform("delete") } }
            }
    }
}
