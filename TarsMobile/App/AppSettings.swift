import Foundation

@MainActor
final class AppSettings: ObservableObject {
    private enum Keys {
        static let serverBaseURL = "serverBaseURL"
        static let directBaseURL = "directBaseURL"
        static let relayBaseURL = "relayBaseURL"
        static let sessionID = "sessionID"
        static let connectionMode = "connectionMode"
        static let relayToken = "relayToken"
        static let relayAgentID = "relayAgentID"
        static let relayClientID = "relayClientID"
    }

    private let defaults: UserDefaults

    @Published var directBaseURLString: String {
        didSet {
            defaults.set(directBaseURLString, forKey: Keys.directBaseURL)
        }
    }

    @Published var relayBaseURLString: String {
        didSet {
            defaults.set(relayBaseURLString, forKey: Keys.relayBaseURL)
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
        let legacyBaseURL = defaults.string(forKey: Keys.serverBaseURL)
        let resolvedDirectBaseURL = defaults.string(forKey: Keys.directBaseURL)
            ?? legacyBaseURL
            ?? "http://127.0.0.1:18991"
        let resolvedRelayBaseURL = defaults.string(forKey: Keys.relayBaseURL)
            ?? Self.defaultRelayBaseURL(from: legacyBaseURL)
        let initialConnectionModeRaw = defaults.string(forKey: Keys.connectionMode)
            ?? Self.defaultConnectionModeRaw
        let resolvedConnectionModeRaw = Self.resolvedConnectionModeRaw(
            initialConnectionModeRaw,
            directBaseURLString: resolvedDirectBaseURL
        )

        self.directBaseURLString = resolvedDirectBaseURL
        self.relayBaseURLString = resolvedRelayBaseURL
        self.sessionID = defaults.string(forKey: Keys.sessionID)
            ?? "mobile-main"
        self.connectionModeRaw = resolvedConnectionModeRaw
        self.relayToken = defaults.string(forKey: Keys.relayToken) ?? ""
        self.relayAgentID = defaults.string(forKey: Keys.relayAgentID) ?? "default"
        self.relayClientID = defaults.string(forKey: Keys.relayClientID)
            ?? "ios-\(UUID().uuidString)"

        if defaults.string(forKey: Keys.relayClientID) == nil {
            defaults.set(relayClientID, forKey: Keys.relayClientID)
        }

        if defaults.string(forKey: Keys.directBaseURL) == nil {
            defaults.set(directBaseURLString, forKey: Keys.directBaseURL)
        }

        if defaults.string(forKey: Keys.relayBaseURL) == nil {
            defaults.set(relayBaseURLString, forKey: Keys.relayBaseURL)
        }

        if defaults.string(forKey: Keys.connectionMode) != connectionModeRaw {
            defaults.set(connectionModeRaw, forKey: Keys.connectionMode)
        }
    }

    var activeBaseURL: URL? {
        let trimmed = activeBaseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        return URL(string: trimmed)?.removingTrailingSlash()
    }

    var activeBaseURLString: String {
        connectionMode == .relay ? relayBaseURLString : directBaseURLString
    }

    var connectionMode: TarsConnectionMode {
        TarsConnectionMode(rawValue: connectionModeRaw) ?? .direct
    }

    var connectionFingerprint: String {
        [
            directBaseURLString,
            relayBaseURLString,
            sessionID,
            connectionModeRaw,
            relayToken,
            relayAgentID,
            relayClientID
        ].joined(separator: "\u{1f}")
    }

    private static func defaultRelayBaseURL(from legacyBaseURL: String?) -> String {
        guard
            let legacyBaseURL,
            let url = URL(string: legacyBaseURL),
            !url.isLocalhost
        else {
            return "https://tarsrelay.pqcenter.cn"
        }

        return legacyBaseURL
    }

    private static var defaultConnectionModeRaw: String {
        #if targetEnvironment(simulator)
        return TarsConnectionMode.direct.rawValue
        #else
        return TarsConnectionMode.relay.rawValue
        #endif
    }

    private static func resolvedConnectionModeRaw(
        _ rawValue: String,
        directBaseURLString: String
    ) -> String {
        #if targetEnvironment(simulator)
        return rawValue
        #else
        guard
            rawValue == TarsConnectionMode.direct.rawValue,
            URL(string: directBaseURLString)?.isLocalhost == true
        else {
            return rawValue
        }

        return TarsConnectionMode.relay.rawValue
        #endif
    }
}

private extension URL {
    func removingTrailingSlash() -> URL {
        guard absoluteString.count > 1, absoluteString.hasSuffix("/") else {
            return self
        }

        return URL(string: String(absoluteString.dropLast())) ?? self
    }

    var isLocalhost: Bool {
        guard let host = self.host?.lowercased() else {
            return false
        }

        return host == "localhost"
            || host == "127.0.0.1"
            || host == "::1"
            || host.hasSuffix(".localhost")
    }
}
