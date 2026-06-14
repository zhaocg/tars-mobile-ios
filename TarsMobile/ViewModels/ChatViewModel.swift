import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isConnected = false
    @Published private(set) var isSending = false
    @Published private(set) var activityText = "Disconnected"
    @Published var draft = ""
    @Published var errorMessage: String?

    private var apiClient: TarsAPIClient?
    private var baseURL: URL?
    private var connectionMode: TarsConnectionMode = .direct
    private var relayToken = ""
    private var relayAgentID = "default"
    private var relayClientID = ""
    private var sessionID = ""
    private var eventsTask: Task<Void, Never>?
    private var transcriptMessages: [ChatMessage] = []
    private var streamingMessagesByRunID: [String: ChatMessage] = [:]

    deinit {
        eventsTask?.cancel()
    }

    func configure(
        baseURL: URL?,
        sessionID: String,
        connectionMode: TarsConnectionMode,
        relayToken: String,
        relayAgentID: String,
        relayClientID: String
    ) {
        guard let baseURL else {
            self.apiClient = nil
            self.sessionID = sessionID
            self.isConnected = false
            self.activityText = "Invalid server URL"
            self.errorMessage = "Set a valid Tars server URL in Settings."
            return
        }

        if self.sessionID == sessionID,
           self.baseURL == baseURL,
           self.connectionMode == connectionMode,
           self.relayToken == relayToken,
           self.relayAgentID == relayAgentID,
           self.relayClientID == relayClientID,
           self.apiClient != nil {
            return
        }

        self.apiClient = TarsAPIClient(
            baseURL: baseURL,
            mode: connectionMode,
            relayToken: relayToken,
            relayAgentID: relayAgentID,
            relayClientID: relayClientID
        )
        self.baseURL = baseURL
        self.connectionMode = connectionMode
        self.relayToken = relayToken
        self.relayAgentID = relayAgentID
        self.relayClientID = relayClientID
        self.sessionID = sessionID
        reconnect()
    }

    func reconnect() {
        eventsTask?.cancel()
        eventsTask = nil
        isConnected = false
        activityText = "Connecting"
        errorMessage = nil

        guard let apiClient else {
            activityText = "Invalid server URL"
            return
        }

        eventsTask = Task { [weak self] in
            await self?.loadInitialTranscript(apiClient: apiClient)
            await self?.consumeEvents(apiClient: apiClient)
        }
    }

    func sendDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let apiClient else {
            return
        }

        draft = ""
        isSending = true
        activityText = "Sending message"

        let optimistic = ChatMessage(
            id: "local:\(UUID().uuidString)",
            runId: nil,
            role: "user",
            content: text,
            status: "created"
        )
        transcriptMessages.append(optimistic)
        renderMessages()

        Task {
            do {
                _ = try await apiClient.submitMessage(text, sessionID: sessionID)
                activityText = "Waiting for response"
            } catch {
                errorMessage = error.localizedDescription
                activityText = "Send failed"
            }
            isSending = false
        }
    }

    private func loadInitialTranscript(apiClient: TarsAPIClient) async {
        do {
            let transcript = try await apiClient.transcript(sessionID: sessionID)
            applyTranscript(transcript)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func consumeEvents(apiClient: TarsAPIClient) async {
        do {
            for try await event in apiClient.sessionEvents(sessionID: sessionID) {
                handle(event)
            }
        } catch {
            isConnected = false
            activityText = "Disconnected"
            errorMessage = error.localizedDescription
        }
    }

    private func handle(_ event: TarsSessionEvent) {
        switch event.type {
        case "session.connected":
            isConnected = true
            activityText = connectionMode == .relay ? "Connected via Relay" : "Connected"

        case "session.snapshot", "transcript.updated":
            if let transcript = event.payload?.transcript {
                applyTranscript(transcript)
            }

        case "message.delta":
            applyDelta(event.payload)

        case "message.completed":
            if let runID = event.payload?.run?.id {
                streamingMessagesByRunID[runID] = nil
                renderMessages()
            }
            activityText = connectionMode == .relay ? "Connected via Relay" : "Connected"

        case "message.error":
            errorMessage = event.payload?.message ?? "The model response failed."
            activityText = "Response failed"

        case "tool.started":
            activityText = toolActivityText(event.payload)

        case "run.updated":
            if let status = event.payload?.run?.status {
                activityText = "Run \(status)"
            }

        default:
            break
        }
    }

    private func applyTranscript(_ transcript: [TarsTranscriptEntry]) {
        transcriptMessages = transcript.map(ChatMessage.init)
        let completedRunIDs = Set(transcriptMessages.compactMap { message -> String? in
            guard message.isAssistant else {
                return nil
            }
            return message.runId
        })

        for runID in completedRunIDs {
            streamingMessagesByRunID[runID] = nil
        }

        renderMessages()
    }

    private func applyDelta(_ payload: TarsSessionEventPayload?) {
        guard let runID = payload?.runId else {
            return
        }

        let content = payload?.content ?? payload?.delta ?? ""
        guard !content.isEmpty else {
            return
        }

        var message = streamingMessagesByRunID[runID] ?? ChatMessage(
            id: "stream:\(runID)",
            runId: runID,
            role: "assistant",
            content: "",
            status: "created",
            isStreaming: true
        )
        message.content = content
        message.isStreaming = true
        streamingMessagesByRunID[runID] = message
        activityText = "Receiving response"
        renderMessages()
    }

    private func renderMessages() {
        let streaming = streamingMessagesByRunID.values.sorted { left, right in
            left.createdAt < right.createdAt
        }
        messages = (transcriptMessages + streaming).sorted { left, right in
            left.createdAt < right.createdAt
        }
    }

    private func toolActivityText(_ payload: TarsSessionEventPayload?) -> String {
        guard let first = payload?.requests?.first else {
            return "Running tool"
        }

        if let toolName = first.toolName {
            return "Running \(toolName)"
        }

        if let capability = first.capability {
            return "Running \(capability)"
        }

        return "Running tool"
    }
}
