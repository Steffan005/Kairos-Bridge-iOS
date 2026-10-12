// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Steffan Douglas Haskins
import Foundation

struct JournalEntry: Decodable, Identifiable {
    let id: String
    let text: String
    let actor: String
    let created_at: String
    let tags: [String]

    var sourceName: String {
        ["you": "You", "claude": "Claude", "chatgpt": "ChatGPT", "grok": "Grok", "gemini": "Gemini"][actor] ?? actor
    }

    var date: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: created_at) ?? ISO8601DateFormatter().date(from: created_at)
    }
}

struct ApprovedConnection: Decodable {
    let clientId: String
    let scopes: [String]
}

enum JournalProvider: String, CaseIterable, Identifiable {
    case claude, chatgpt, grok
    var id: String { rawValue }
    var name: String { ["claude": "Claude", "chatgpt": "ChatGPT", "grok": "Grok"][rawValue]! }
    var clientID: String {
        switch self {
        case .claude: return "https://claude.ai/oauth/mcp-oauth-client-metadata"
        case .chatgpt: return "https://chatgpt.com/oauth/client.json"
        case .grok: return "https://grok.com/oauth/mcp-client.json"
        }
    }
    var settingsURL: URL {
        switch self {
        case .claude: return URL(string: "https://claude.ai/customize/connectors")!
        case .chatgpt: return URL(string: "https://chatgpt.com/plugins")!
        case .grok: return URL(string: "https://grok.com/connectors")!
        }
    }
}

struct JournalEnvelope: Decodable {
    let deleted: Bool
    let entries: [JournalEntry]
    let connections: [ApprovedConnection]
    let count: Int?

    var claudeApproved: Bool {
        approval(for: .claude) != nil
    }

    func approval(for provider: JournalProvider) -> ApprovedConnection? {
        connections.first { $0.clientId == provider.clientID && $0.scopes.contains("journal:read") }
    }
}

struct SignInReply: Decodable {
    struct Owner: Decodable { let email: String }
    let user: Owner
}

struct ServiceFailure: Decodable {
    let error: String?
    let message: String?
}

enum KairosFailure: LocalizedError {
    case service(Int, String)
    case secureStorage
    case signedOutStorageCleanup
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .service(_, let message): return message
        case .secureStorage: return "Kairos couldn't safely store your sign-in on this device. Please try again."
        case .signedOutStorageCleanup: return "Signed out of Kairos. This device couldn't remove its old session record; that server session has ended."
        case .invalidResponse: return "Kairos couldn't read the service response. Please try again."
        }
    }

    var signInRequired: Bool {
        if case .service(401, _) = self { return true }
        return false
    }
}
