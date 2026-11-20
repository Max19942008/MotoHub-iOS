import Foundation
import Observation

/// The website's live chat socket (ignition libs/chatSocket.ts), one per app.
///
/// Same server and protocol as the site and the Android app, so everyone shares
/// one room: the token goes in the query string, the server answers with `info`
/// (online count), `getMessages` (last 20) and `message` events, and we send
/// `{event: "message", data: text}`. Reconnects with backoff when the line
/// drops, reconnects with the new token when the user logs in or out, and
/// closes while the app is in the background.
@MainActor
@Observable
final class ChatService {
    static let maxTextLength = 500

    private(set) var messages: [LiveChatMessage] = []
    private(set) var onlineUsers = 0
    private(set) var connected = false

    @ObservationIgnored private let url: URL
    @ObservationIgnored private let auth: any AuthRepository
    @ObservationIgnored private var socket: URLSessionWebSocketTask?
    /// Bumps on every (re)open; callbacks of older sockets are ignored.
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var memberID: String?
    @ObservationIgnored private var retries = 0
    @ObservationIgnored private var retryTask: Task<Void, Never>?
    @ObservationIgnored private var started = false
    @ObservationIgnored private var paused = false

    init(url: URL, auth: any AuthRepository) {
        self.url = url
        self.auth = auth
    }

    /// Opens the socket once; safe to call again.
    func start(memberID: String?) {
        guard !started else { return }
        started = true
        self.memberID = memberID
        open()
    }

    /// The server reads who we are only at connect time.
    func memberChanged(_ id: String?) {
        guard started, id != memberID else { return }
        memberID = id
        if !paused { open() }
    }

    func pause() {
        guard started, !paused else { return }
        paused = true
        close()
    }

    func resume() {
        guard started, paused else { return }
        paused = false
        open()
    }

    /// Sends `text`; false when the socket is not open (the UI says so).
    func send(_ text: String) -> Bool {
        guard let socket, connected else { return false }
        let trimmed = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxTextLength))
        guard
            let data = try? JSONSerialization.data(withJSONObject: ["event": "message", "data": trimmed]),
            let json = String(data: data, encoding: .utf8)
        else { return false }
        socket.send(.string(json)) { _ in }
        return true
    }

    // MARK: - Connection

    private func open() {
        retryTask?.cancel()
        generation += 1
        let gen = generation
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
        connected = false

        Task {
            // Chat as a guest rather than not at all.
            let token = await auth.accessToken()
            guard gen == generation else { return }
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            if let token, !token.isEmpty {
                components.queryItems = [URLQueryItem(name: "token", value: token)]
            }
            guard let target = components.url else { return }
            let ws = URLSession.shared.webSocketTask(with: target)
            socket = ws
            ws.resume()
            receive(ws, gen)
            ws.sendPing { [weak self] error in
                Task { @MainActor in
                    guard let self, gen == self.generation else { return }
                    if error == nil { self.markConnected() } else { self.lost(gen) }
                }
            }
            keepAlive(ws, gen)
            // Give up on a connect that hangs.
            try? await Task.sleep(for: .seconds(15))
            if gen == generation, !connected {
                generation += 1
                socket?.cancel()
                lost(generation)
            }
        }
    }

    private func markConnected() {
        connected = true
        retries = 0
    }

    private func receive(_ ws: URLSessionWebSocketTask, _ gen: Int) {
        ws.receive { [weak self] result in
            Task { @MainActor in
                guard let self, gen == self.generation else { return }
                switch result {
                case .success(let message):
                    self.markConnected()
                    if case .string(let text) = message { self.handle(text) }
                    self.receive(ws, gen)
                case .failure:
                    self.lost(gen)
                }
            }
        }
    }

    private func keepAlive(_ ws: URLSessionWebSocketTask, _ gen: Int) {
        Task { [weak self] in
            while true {
                try? await Task.sleep(for: .seconds(30))
                guard let self, gen == self.generation else { return }
                ws.sendPing { _ in }
            }
        }
    }

    private func handle(_ text: String) {
        guard
            let data = text.data(using: .utf8),
            let json = (try? JSONSerialization.jsonObject(with: data)) as? JSONObject
        else { return }
        switch json["event"] as? String {
        case "info":
            onlineUsers = json.int("totalClients")
        case "getMessages":
            messages = ((json["list"] as? [Any]) ?? []).compactMap { LiveChatMessage(json: $0) }
        case "message":
            if let message = LiveChatMessage(json: json) { messages.append(message) }
        default:
            break
        }
    }

    private func lost(_ gen: Int) {
        guard gen == generation else { return } // replaced on purpose
        socket = nil
        connected = false
        guard !paused else { return }
        let delay = min(30, 1 << min(retries, 5))
        retries += 1
        retryTask?.cancel()
        retryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.open()
        }
    }

    private func close() {
        retryTask?.cancel()
        generation += 1
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
        connected = false
    }
}
