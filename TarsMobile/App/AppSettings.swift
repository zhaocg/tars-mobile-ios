import Foundation

@MainActor
final class AppSettings: ObservableObject {
    private enum Keys {
        static let serverBaseURL = "serverBaseURL"
        static let sessionID = "sessionID"
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

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.serverBaseURLString = defaults.string(forKey: Keys.serverBaseURL)
            ?? "http://127.0.0.1:18991"
        self.sessionID = defaults.string(forKey: Keys.sessionID)
            ?? "mobile-main"
    }

    var serverBaseURL: URL? {
        let trimmed = serverBaseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        return URL(string: trimmed)?.removingTrailingSlash()
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

