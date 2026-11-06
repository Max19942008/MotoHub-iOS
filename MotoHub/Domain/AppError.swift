import Foundation

/// Errors surfaced to the UI, already in Uzbek.
enum AppError: LocalizedError, Equatable {
    /// The server was never reached (offline, timeout, Render instance waking up).
    case network(String)
    /// The server answered with an error.
    case server(String)

    var errorDescription: String? {
        switch self {
        case .network(let message), .server(let message): message
        }
    }

    var isNetwork: Bool {
        if case .network = self { return true }
        return false
    }
}
