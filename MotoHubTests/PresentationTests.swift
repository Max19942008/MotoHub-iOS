import XCTest
@testable import MotoHub

@MainActor
final class PresentationTests: XCTestCase {
    private struct Item: Identifiable, Sendable { let id: Int }

    func testPagingLoadsNextPageAtTheEnd() async {
        let model = PagedListViewModel<Item, String>(query: "") { _, page in
            PagedResult(items: (1...10).map { Item(id: (page - 1) * 10 + $0) }, total: 25)
        }
        await model.loadIfNeeded()
        XCTAssertEqual(model.items.count, 10)
        XCTAssertTrue(model.canLoadMore)

        await model.loadMoreIfNeeded(after: model.items[3]) // not the last row: no request
        XCTAssertEqual(model.items.count, 10)

        await model.loadMoreIfNeeded(after: model.items[9])
        XCTAssertEqual(model.items.map(\.id).last, 20)
    }

    func testQueryChangeReloadsFromFirstPage() async {
        let model = PagedListViewModel<Item, String>(query: "a") { query, _ in
            PagedResult(items: [Item(id: query == "a" ? 1 : 2)], total: 1)
        }
        await model.loadIfNeeded()
        await model.update("b")
        XCTAssertEqual(model.items.map(\.id), [2])
        XCTAssertEqual(model.query, "b")
    }

    func testFailureShowsMessage() async {
        let model = PagedListViewModel<Item, String>(query: "") { _, _ in
            throw AppError.network("Internet aloqasi yo‘q.")
        }
        await model.loadIfNeeded()
        XCTAssertEqual(model.errorMessage, "Internet aloqasi yo‘q.")
        XCTAssertFalse(model.isLoading)
    }

    func testAssistantKeepsHistoryAndReportsErrors() async {
        let repository = FakeAssistant()
        let model = AssistantViewModel(repository: repository)

        model.draft = "Honda bormi?"
        await model.send()
        XCTAssertEqual(model.messages.map(\.role), [.user, .assistant])
        XCTAssertEqual(model.draft, "")

        repository.fail = true
        await model.send("Yana?")
        XCTAssertEqual(model.messages.last?.role, .error)
        XCTAssertEqual(repository.lastHistoryCount, 2)
    }

    func testReportingAnAnswerSendsItsQuestionAndMarksIt() async throws {
        let repository = FakeAssistant()
        let model = AssistantViewModel(repository: repository)
        await model.send("Honda bormi?")
        let answer = try XCTUnwrap(model.messages.last)

        try await model.report(answer, reason: .wrong, comment: "")
        XCTAssertEqual(repository.lastReport?.reason, .wrong)
        XCTAssertEqual(repository.lastReport?.question, "Honda bormi?")
        XCTAssertEqual(repository.lastReport?.answer, "Ha, bor [1]")
        XCTAssertTrue(model.reported.contains(answer.id))

        model.clear()
        XCTAssertTrue(model.reported.isEmpty)
    }

    func testSessionLoginAndDelete() async throws {
        let auth = FakeAuth()
        let session = SessionStore(repository: auth)
        await session.restore()
        XCTAssertFalse(session.isLoggedIn)

        try await session.login(nick: "ali", password: "12345")
        XCTAssertEqual(session.member?.nick, "ali")

        try await session.deleteAccount()
        XCTAssertNil(session.member)
        XCTAssertTrue(auth.deleted)
    }

    func testExpiredAccessTokenWithoutRefreshTokenSignsOut() async {
        let expired = TestJWT.make(["_id": "m1", "memberNick": "ali", "exp": 1])
        let store = InMemoryTokenStore(SessionTokens(access: expired, refresh: nil))
        let session = AuthSession(client: GraphQLClient(endpoint: URL(string: "https://invalid.example")!), store: store)
        let signedOut = expectation(description: "expired handler")
        await session.setExpiredHandler { signedOut.fulfill() }

        let token = await session.validAccessToken()

        XCTAssertNil(token)
        XCTAssertNil(store.load())
        await fulfillment(of: [signedOut], timeout: 1)
    }

    func testFreshAccessTokenIsUsedAsIs() async {
        let fresh = TestJWT.make(["_id": "m1", "exp": Date().timeIntervalSince1970 + 3600])
        let session = AuthSession(
            client: GraphQLClient(endpoint: URL(string: "https://invalid.example")!),
            store: InMemoryTokenStore(SessionTokens(access: fresh, refresh: "r"))
        )
        let token = await session.validAccessToken()
        XCTAssertEqual(token, fresh)
    }
}

// MARK: - Fakes

private final class FakeAssistant: AssistantRepository, @unchecked Sendable {
    var fail = false
    var lastHistoryCount = 0

    func ask(_ message: String, history: [ChatMessage]) async throws -> ChatMessage {
        lastHistoryCount = history.count
        if fail { throw AppError.server("Yordamchi hozir ishlamayapti.") }
        return ChatMessage(role: .assistant, text: "Ha, bor [1]")
    }

    var lastReport: (reason: AIReportReason, question: String, answer: String)?

    func report(reason: AIReportReason, question: String, answer: String, comment: String) async throws {
        if fail { throw AppError.server("Yuborib bo‘lmadi.") }
        lastReport = (reason, question, answer)
    }
}

private final class FakeAuth: AuthRepository, @unchecked Sendable {
    var member: Member?
    var deleted = false

    func restoreSession() async -> Member? { member }

    func login(nick: String, password: String) async throws -> Member {
        let member = Member(id: "m1", nick: nick, phone: nil, imagePath: nil, type: "USER", fullName: nil)
        self.member = member
        return member
    }

    func signup(_ form: SignupForm) async throws -> Member {
        try await login(nick: form.nick, password: form.password)
    }

    func logout() async { member = nil }

    func deleteAccount() async throws {
        deleted = true
        member = nil
    }

    func onSessionExpired(_ handler: @escaping @Sendable () -> Void) async {}
}
