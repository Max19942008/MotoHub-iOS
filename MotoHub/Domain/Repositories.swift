import Foundation

/// Domain-facing contracts. Implementations live in Data/; screens only see these.

protocol ListingRepository: Sendable {
    func motorbikes(filter: MotorbikeFilter, page: Int) async throws -> PagedResult<Motorbike>
    func motorbike(id: String) async throws -> Motorbike
    func parts(filter: PartFilter, page: Int) async throws -> PagedResult<Part>
    func part(id: String) async throws -> Part
}

protocol AuthRepository: Sendable {
    /// Member from the saved session, if any.
    func restoreSession() async -> Member?
    func login(nick: String, password: String) async throws -> Member
    func signup(_ form: SignupForm) async throws -> Member
    func logout() async
    /// Permanently deletes the account on the server and ends the session.
    func deleteAccount() async throws
    /// Called when the server rejects the refresh token (session revoked or expired).
    func onSessionExpired(_ handler: @escaping @Sendable () -> Void) async
}

protocol AssistantRepository: Sendable {
    /// The server keeps no chat state, so earlier turns go along with every question.
    func ask(_ message: String, history: [ChatMessage]) async throws -> ChatMessage
    /// Flags an offensive or wrong answer for admin review.
    func report(reason: AIReportReason, question: String, answer: String, comment: String) async throws
}
