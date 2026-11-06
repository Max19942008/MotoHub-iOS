import Foundation

struct GraphQLAuthRepository: AuthRepository {
    /// For login/signup/refresh/logout — calls that must not carry (or wait for) a token.
    let publicClient: GraphQLClient
    /// Sends the member's access token.
    let client: GraphQLClient
    let session: AuthSession

    func restoreSession() async -> Member? {
        await session.member
    }

    func login(nick: String, password: String) async throws -> Member {
        let result = try await publicClient.execute(AuthOperations.login(
            nick: nick.trimmingCharacters(in: .whitespaces),
            password: password
        ))
        return try await start(with: result.login)
    }

    func signup(_ form: SignupForm) async throws -> Member {
        var form = form
        form.nick = form.nick.trimmingCharacters(in: .whitespaces)
        form.phone = form.phone.trimmingCharacters(in: .whitespaces)
        let result = try await publicClient.execute(AuthOperations.signup(form))
        return try await start(with: result.signup)
    }

    func logout() async {
        guard let refresh = await session.clear() else { return }
        // Best effort: the local session is already gone.
        _ = try? await publicClient.execute(AuthOperations.logout(refresh))
    }

    func deleteAccount() async throws {
        guard let member = await session.member else { return }
        _ = try await client.execute(AuthOperations.deleteAccount(memberID: member.id))
        // The server already revoked the refresh token.
        await session.clear()
    }

    func onSessionExpired(_ handler: @escaping @Sendable () -> Void) async {
        await session.setExpiredHandler(handler)
    }

    private func start(with tokens: TokensDTO) async throws -> Member {
        guard let access = tokens.accessToken, !access.isEmpty, let member = JWT.member(access) else {
            throw AppError.server("Kirish amalga oshmadi.")
        }
        await session.save(SessionTokens(access: access, refresh: tokens.refreshToken))
        return member
    }
}
