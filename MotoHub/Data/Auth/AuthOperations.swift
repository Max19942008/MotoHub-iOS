import Foundation

struct TokensDTO: Decodable {
    let accessToken: String?
    let refreshToken: String?
}

/// GraphQL operations for login, signup, refresh, logout and self-deletion.
enum AuthOperations {
    struct LoginInput: Encodable {
        let memberNick: String
        let memberPassword: String
    }

    struct SignupInput: Encodable {
        let memberNick: String
        let memberPassword: String
        let memberPhone: String
        let memberType: String
    }

    struct DeleteInput: Encodable {
        let _id: String
        let memberStatus = "DELETE"
    }

    struct Input<T: Encodable>: Encodable { let input: T }
    struct TokenVariable: Encodable { let t: String }

    struct LoginResponse: Decodable { let login: TokensDTO }
    struct SignupResponse: Decodable { let signup: TokensDTO }
    struct RefreshResponse: Decodable { let refreshToken: TokensDTO }
    struct LogoutResponse: Decodable { let logout: Bool? }
    struct DeleteResponse: Decodable {
        struct Result: Decodable { let memberStatus: String? }
        let updateMember: Result
    }

    static func login(nick: String, password: String) -> GraphQLOperation<Input<LoginInput>, LoginResponse> {
        GraphQLOperation(
            document: "mutation ($input: LoginInput!) { login(input: $input) { accessToken refreshToken } }",
            variables: Input(input: LoginInput(memberNick: nick, memberPassword: password))
        )
    }

    static func signup(_ form: SignupForm) -> GraphQLOperation<Input<SignupInput>, SignupResponse> {
        GraphQLOperation(
            document: "mutation ($input: MemberInput!) { signup(input: $input) { accessToken refreshToken } }",
            variables: Input(input: SignupInput(
                memberNick: form.nick,
                memberPassword: form.password,
                memberPhone: form.phone,
                memberType: form.isAgent ? "AGENT" : "USER"
            ))
        )
    }

    static func refresh(_ token: String) -> GraphQLOperation<TokenVariable, RefreshResponse> {
        GraphQLOperation(
            document: "mutation ($t: String!) { refreshToken(refreshToken: $t) { accessToken refreshToken } }",
            variables: TokenVariable(t: token)
        )
    }

    static func logout(_ token: String) -> GraphQLOperation<TokenVariable, LogoutResponse> {
        GraphQLOperation(document: "mutation ($t: String!) { logout(refreshToken: $t) }", variables: TokenVariable(t: token))
    }

    /// The backend soft-deletes the member, revokes every session and retires their listings.
    static func deleteAccount(memberID: String) -> GraphQLOperation<Input<DeleteInput>, DeleteResponse> {
        GraphQLOperation(
            document: "mutation ($input: MemberUpdate!) { updateMember(input: $input) { _id memberStatus } }",
            variables: Input(input: DeleteInput(_id: memberID))
        )
    }
}
