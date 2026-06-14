import Foundation

@MainActor
final class AppSettings: ObservableObject {
    private enum Keys {
        static let serverBaseURL = "serverBaseURL"
        static let sessionID = "sessionID"
        static let connectionMode = "connectionMode"
        static let relayToken = "relayToken"
        static let relayAgentID = "relayAgentID"
        static let relayClientID = "relayClientID"
    }

    private let defaults: UserDefaults

    @Published var serverBaseURLString: String {
        didSet {
            defaults.set(serverBaseURLString, forKey: Keys.serverBaseURL)
        }
    }

    @Published var sessionID: String {
        didSet {
            defaults.set(sessionID, forKey: Keys.sessionID)
        }
    }

    @Published var connectionModeRaw: String {
        didSet {
            defaults.set(connectionModeRaw, forKey: Keys.connectionMode)
        }
    }

    @Published var relayToken: String {
        didSet {
            defaults.set(relayToken, forKey: Keys.relayToken)
        }
    }

    @Published var relayAgentID: String {
        didSet {
            defaults.set(relayAgentID, forKey: Keys.relayAgentID)
        }
    }

    @Published var relayClientID: String {
        didSet {
            defaults.set(relayClientID, forKey: Keys.relayClientID)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.serverBaseURLString = defaults.string(forKey: Keys.serverBaseURL)
            ?? "http://127.0.0.1:18991"
        self.sessionID = defaults.string(forKey: Keys.sessionID)
            ?? "mobile-main"
        self.connectionModeRaw = defaults.string(forKey: Keys.connectionMode)
            ?? TarsConnectionMode.direct.rawValue
        self.relayToken = defaults.string(forKey: Keys.relayToken) ?? ""
        self.relayAgentID = defaults.string(forKey: Keys.relayAgentID) ?? "default"
        self.relayClientID = defaults.string(forKey: Keys.relayClientID)
            ?? "ios-\(UUID().uuidString)"

        if defaults.string(forKey: Keys.relayClientID) == nil {
            defaults.set(relayClientID, forKey: Keys.relayClientID)
        }
    }

    var serverBaseURL: URL? {
        let trimmed = serverBaseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        return URL(string: trimmed)?.removingTrailingSlash()
    }

    var connectionMode: TarsConnectionMode {
        TarsConnectionMode(rawValue: connectionModeRaw) ?? .direct
    }

    var connectionFingerprint: String {
        [
            serverBaseURLString,
            sessionID,
            connectionModeRaw,
            relayToken,
            relayAgentID,
            relayClientID
        ].joined(separator: "\u{1f}")
    }
}

private extension URL {
    func removingTrailingSlash() -> URL {
        guard absoluteString.count > 1, absoluteString.hasSuffix("/") else {
            return self
        }

        return URL(string: String(absoluteString.dropLast())) ?? self
    }
}
