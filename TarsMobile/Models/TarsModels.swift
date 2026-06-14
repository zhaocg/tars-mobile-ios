import Foundation

struct TarsHealthResponse: Decodable {
    let status: String
}

struct TarsSessionsResponse: Decodable {
    let sessions: [TarsSessionSummary]
}

struct TarsTranscriptResponse: Decodable {
    let transcript: [TarsTranscriptEntry]
}

struct TarsSessionSummary: Decodable, Identifiable, Equatable {
    let sessionId: String
    let runCount: Int
    let createdAt: String
    let updatedAt: String
    let status: String
    let lastRun: TarsRunRecord?

    var id: String {
        sessionId
    }
}

struct TarsRunRecord: Decodable, Equatable {
    let id: String
    let sessionId: String?
    let message: String?
    let status: String?
    let createdAt: String?
    let updatedAt: String?
}

struct TarsTranscriptEntry: Decodable, Identifiable, Equatable {
    let id: String
    let runId: String
    let sessionId: String
    let role: String
    let content: String
    let createdAt: String
    let status: String
}

struct TarsSubmitMessageResponse: Decodable {
    let run: TarsRunRecord
}

struct TarsRelayAcceptedResponse: Decodable {
    let eventId: String
    let accepted: Bool
}

struct TarsSessionEvent: Decodable, Identifiable {
    let id: String
    let sessionId: String
    let type: String
    let payload: TarsSessionEventPayload?
}

struct TarsSessionEventPayload: Decodable {
    let runId: String?
    let delta: String?
    let content: String?
    let model: String?
    let message: String?
    let transcript: [TarsTranscriptEntry]?
    let run: TarsRunRecord?
    let requests: [TarsToolRequest]?
}

struct TarsToolRequest: Decodable, Equatable {
    let id: String?
    let toolName: String?
    let capability: String?
    let resource: String?
}

struct ChatMessage: Identifiable, Equatable {
    let id: String
    let runId: String?
    let role: String
    var content: String
    var status: String
    let createdAt: Date
    var isStreaming: Bool

    var isFromUser: Bool {
        role == "user"
    }

    var isAssistant: Bool {
        role == "assistant"
    }

    init(entry: TarsTranscriptEntry) {
        self.id = entry.id
        self.runId = entry.runId
        self.role = entry.role
        self.content = entry.content
        self.status = entry.status
        self.createdAt = ISO8601DateFormatter.tarsShared.date(from: entry.createdAt) ?? .now
        self.isStreaming = false
    }

    init(
        id: String,
        runId: String?,
        role: String,
        content: String,
        status: String,
        createdAt: Date = .now,
        isStreaming: Bool = false
    ) {
        self.id = id
        self.runId = runId
        self.role = role
        self.content = content
        self.status = status
        self.createdAt = createdAt
        self.isStreaming = isStreaming
    }
}

extension ISO8601DateFormatter {
    static let tarsShared: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
