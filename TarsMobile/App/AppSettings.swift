import Foundation

@MainActor
final class AppSettings: ObservableObject {
    private enum Keys {
        static let relayBaseURL = "relayBaseURL"
        static let sessionID = "sessionID"
        static let relayToken = "relayToken"
        static let relayAgentID = "relayAgentID"
        static let relayClientID = "relayClientID"
    }

    private let defaults: UserDefaults

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
        let resolvedRelayBaseURL = defaults.string(forKey: Keys.relayBaseURL)
            ?? "https://tarsrelay.pqcenter.cn"

        self.relayBaseURLString = resolvedRelayBaseURL
        self.sessionID = defaults.string(forKey: Keys.sessionID)
            ?? "mobile-main"
        self.relayToken = defaults.string(forKey: Keys.relayToken) ?? ""
        self.relayAgentID = defaults.string(forKey: Keys.relayAgentID) ?? "default"
        self.relayClientID = defaults.string(forKey: Keys.relayClientID)
            ?? "ios-\(UUID().uuidString)"

        if defaults.string(forKey: Keys.relayClientID) == nil {
            defaults.set(relayClientID, forKey: Keys.relayClientID)
        }

        if defaults.string(forKey: Keys.relayBaseURL) == nil {
            defaults.set(relayBaseURLString, forKey: Keys.relayBaseURL)
        }
    }

    var relayBaseURL: URL? {
        let trimmed = relayBaseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        return URL(string: trimmed)?.removingTrailingSlash()
    }

    var connectionFingerprint: String {
        [
            relayBaseURLString,
            sessionID,
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
