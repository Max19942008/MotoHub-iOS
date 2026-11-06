import Foundation

/// Owns the token pair. Access tokens are short-lived; refresh tokens rotate
/// (each one is single-use), so concurrent callers must share one refresh.
actor AuthSession: AccessTokenProviding {
    /// Refresh this long before the access token actually expires.
    static let refreshLeeway: TimeInterval = 60

    private let client: GraphQLClient
    private let store: any TokenStore
    private var tokens: SessionTokens?
    private var refreshTask: Task<String?, Never>?
    private var expiredHandler: (@Sendable () -> Void)?

    /// - Parameter client: an unauthenticated client (the refresh call must not ask this actor for a token).
    init(client: GraphQLClient, store: any TokenStore) {
        self.client = client
        self.store = store
        self.tokens = store.load()
    }

    var member: Member? { tokens.flatMap { JWT.member($0.access) } }

    func setExpiredHandler(_ handler: @escaping @Sendable () -> Void) {
        expiredHandler = handler
    }

    func save(_ newTokens: SessionTokens) {
        tokens = newTokens
        store.save(newTokens)
    }

    /// Drops the local session and returns the refresh token so the caller can revoke it.
    @discardableResult
    func clear() -> String? {
        let refresh = tokens?.refresh
        tokens = nil
        store.clear()
        return refresh
    }

    func validAccessToken() async -> String? {
        guard let current = tokens else { return nil }
        if let expiry = JWT.expiry(current.access), expiry.timeIntervalSinceNow <= Self.refreshLeeway {
            if let running = refreshTask { return await running.value }
            let task = Task { await refresh() }
            refreshTask = task
            let token = await task.value
            refreshTask = nil
            return token
        }
        return current.access
    }

    private func refresh() async -> String? {
        guard let refresh = tokens?.refresh else {
            expire()
            return nil
        }
        do {
            let result = try await client.execute(AuthOperations.refresh(refresh))
            guard let access = result.refreshToken.accessToken, !access.isEmpty else {
                expire()
                return nil
            }
            save(SessionTokens(access: access, refresh: result.refreshToken.refreshToken ?? refresh))
            return access
        } catch let error as AppError where error.isNetwork {
            // Offline or the server is waking up: keep the session, send the old token.
            return tokens?.access
        } catch {
            expire() // revoked, expired or reused
            return nil
        }
    }

    private func expire() {
        clear()
        expiredHandler?()
    }
}
