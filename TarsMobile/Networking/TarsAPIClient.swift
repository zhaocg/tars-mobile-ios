import Foundation

enum TarsAPIError: Error, LocalizedError, Equatable {
    case invalidBaseURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "The Tars server URL is invalid."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .httpStatus(let status):
            return "The server returned HTTP \(status)."
        case .decodingFailed:
            return "The server event could not be decoded."
        }
    }
}

final class TarsAPIClient {
    private let baseURL: URL
    private let urlSession: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let sseClient: ServerSentEventsClient

    init(baseURL: URL, urlSession: URLSession = .shared) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self.sseClient = ServerSentEventsClient(urlSession: urlSession)
    }

    func health() async throws -> TarsHealthResponse {
        try await get(path: "/health")
    }

    func sessions() async throws -> [TarsSessionSummary] {
        let response: TarsSessionsResponse = try await get(path: "/sessions")
        return response.sessions
    }

    func transcript(sessionID: String) async throws -> [TarsTranscriptEntry] {
        let response: TarsTranscriptResponse = try await get(
            path: "/sessions/\(Self.pathEscape(sessionID))/transcript"
        )
        return response.transcript
    }

    func submitMessage(_ message: String, sessionID: String) async throws -> TarsRunRecord {
        struct Body: Encodable {
            let message: String
            let stream: Bool
            let background: Bool
        }

        let body = Body(message: message, stream: true, background: true)
        let response: TarsSubmitMessageResponse = try await post(
            path: "/sessions/\(Self.pathEscape(sessionID))/messages",
            body: body
        )
        return response.run
    }

    func sessionEvents(sessionID: String) -> AsyncThrowingStream<TarsSessionEvent, Error> {
        var request = URLRequest(url: url(
            path: "/sessions/\(Self.pathEscape(sessionID))/events"
        ))
        request.httpMethod = "GET"
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await event in sseClient.stream(request: request) {
                        guard event.event != nil else {
                            continue
                        }

                        guard let data = event.data.data(using: .utf8) else {
                            throw TarsAPIError.decodingFailed
                        }

                        let decoded = try decoder.decode(TarsSessionEvent.self, from: data)
                        continuation.yield(decoded)
                    }

                    continuation.finish()
                } catch {
                    if Task.isCancelled {
                        continuation.finish()
                    } else {
                        continuation.finish(throwing: error)
                    }
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func get<T: Decodable>(path: String) async throws -> T {
        var request = URLRequest(url: url(path: path))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await send(request)
    }

    private func post<Body: Encodable, Response: Decodable>(path: String, body: Body) async throws -> Response {
        var request = URLRequest(url: url(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        return try await send(request)
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TarsAPIError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw TarsAPIError.httpStatus(httpResponse.statusCode)
        }

        return try decoder.decode(T.self, from: data)
    }

    private func url(path: String) -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return baseURL
        }

        let basePath = components.percentEncodedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let suffix = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let combined = [basePath, suffix]
            .filter { !$0.isEmpty }
            .joined(separator: "/")
        components.percentEncodedPath = "/" + combined

        return components.url ?? baseURL
    }

    private static func pathEscape(_ value: String) -> String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}
