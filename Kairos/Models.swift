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

struct JournalEnvelope: Decodable {
    let deleted: Bool
    let entries: [JournalEntry]
    let connections: [ApprovedConnection]
    let count: Int?

    var claudeApproved: Bool {
        connections.contains { $0.clientId == "https://claude.ai/oauth/mcp-oauth-client-metadata" }
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
