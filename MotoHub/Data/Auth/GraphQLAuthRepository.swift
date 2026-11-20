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
        let data = try await publicClient.query(
            "mutation ($input: LoginInput!) { login(input: $input) { accessToken refreshToken } }",
            variables: ["input": ["memberNick": nick.trimmingCharacters(in: .whitespaces), "memberPassword": password]],
            authenticated: false
        )
        return try await start(with: data.object("login"))
    }

    func signup(_ form: SignupForm) async throws -> Member {
        let data = try await publicClient.query(
            "mutation ($input: MemberInput!) { signup(input: $input) { accessToken refreshToken } }",
            variables: ["input": [
                "memberNick": form.nick.trimmingCharacters(in: .whitespaces),
                "memberPassword": form.password,
                "memberPhone": form.phone.trimmingCharacters(in: .whitespaces),
                "memberType": form.isAgent ? "AGENT" : "USER",
            ]],
            authenticated: false
        )
        return try await start(with: data.object("signup"))
    }

    func logout() async {
        guard let refresh = await session.clear() else { return }
        // Best effort: the local session is already gone.
        _ = try? await publicClient.query("mutation ($t: String!) { logout(refreshToken: $t) }",
                                          variables: ["t": refresh], authenticated: false)
    }

    func updateProfile(nick: String?, phone: String?, address: String?, imagePath: String?) async throws -> Member? {
        guard let member = await session.member else { return nil }
        var input: JSONObject = ["_id": member.id]
        if let nick { input["memberNick"] = nick }
        if let phone { input["memberPhone"] = phone }
        if let address { input["memberAddress"] = address }
        if let imagePath { input["memberImage"] = imagePath }
        let data = try await client.query(
            "mutation ($input: MemberUpdate!) { updateMember(input: $input) { _id accessToken } }",
            variables: ["input": input]
        )
        if let token = data.object("updateMember")?.nonEmpty("accessToken") {
            await session.replaceAccess(token)
        }
        return await session.member
    }

    /// The backend soft-deletes the member, revokes every session and retires their listings.
    func deleteAccount() async throws {
        guard let member = await session.member else { return }
        _ = try await client.query(
            "mutation ($input: MemberUpdate!) { updateMember(input: $input) { _id memberStatus } }",
            variables: ["input": ["_id": member.id, "memberStatus": "DELETE"]]
        )
        // The server already revoked the refresh token.
        await session.clear()
    }

    func accessToken() async -> String? {
        await session.validAccessToken()
    }

    func onSessionExpired(_ handler: @escaping @Sendable () -> Void) async {
        await session.setExpiredHandler(handler)
    }

    private func start(with tokens: JSONObject?) async throws -> Member {
        guard let access = tokens?.nonEmpty("accessToken"), let member = JWT.member(access) else {
            throw AppError.server("Kirish amalga oshmadi.")
        }
        await session.save(SessionTokens(access: access, refresh: tokens?.string("refreshToken")))
        return member
    }
}
