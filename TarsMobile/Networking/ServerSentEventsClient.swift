import Foundation

struct ServerSentEvent: Equatable {
    let id: String?
    let event: String?
    let data: String
}

final class ServerSentEventsClient {
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func stream(request: URLRequest) -> AsyncThrowingStream<ServerSentEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, response) = try await urlSession.bytes(for: request)
                    try Self.validate(response: response)

                    var accumulator = EventAccumulator()

                    for try await line in bytes.lines {
                        if Task.isCancelled {
                            break
                        }

                        if line.isEmpty {
                            if let event = accumulator.makeEvent() {
                                continuation.yield(event)
                            }
                            accumulator = EventAccumulator()
                            continue
                        }

                        accumulator.append(line: line)
                    }

                    if let event = accumulator.makeEvent() {
                        continuation.yield(event)
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

    private static func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TarsAPIError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw TarsAPIError.httpStatus(httpResponse.statusCode)
        }
    }
}

private struct EventAccumulator {
    private var id: String?
    private var event: String?
    private var dataLines: [String] = []

    mutating func append(line: String) {
        guard !line.hasPrefix(":") else {
            return
        }

        if line.hasPrefix("id:") {
            id = Self.value(afterFieldPrefix: "id:", in: line)
            return
        }

        if line.hasPrefix("event:") {
            event = Self.value(afterFieldPrefix: "event:", in: line)
            return
        }

        if line.hasPrefix("data:") {
            dataLines.append(Self.value(afterFieldPrefix: "data:", in: line))
        }
    }

    func makeEvent() -> ServerSentEvent? {
        guard !dataLines.isEmpty else {
            return nil
        }

        return ServerSentEvent(id: id, event: event, data: dataLines.joined(separator: "\n"))
    }

    private static func value(afterFieldPrefix prefix: String, in line: String) -> String {
        let start = line.index(line.startIndex, offsetBy: prefix.count)
        let value = String(line[start...])
        if value.first == " " {
            return String(value.dropFirst())
        }
        return value
    }
}

