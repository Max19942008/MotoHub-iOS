import Foundation

/// Domain-facing contracts. The GraphQL implementations live in Data/; screens only see these.

protocol ListingRepository: Sendable {
    func motorbikes(filter: MotorbikeFilter, page: Int) async throws -> PagedResult<Motorbike>
    /// Home carousels: a fixed top-N by `sort` (propertyLikes | propertyViews | propertyRank).
    func topMotorbikes(sort: String, limit: Int) async throws -> [Motorbike]
    func motorbike(id: String) async throws -> Motorbike
    func parts(filter: PartFilter, page: Int) async throws -> PagedResult<Part>
    func topParts(category: String, limit: Int) async throws -> [Part]
    func part(id: String) async throws -> Part
    func likeMotorbike(id: String) async throws
    func likePart(id: String) async throws
    /// Tells the dealer "I'm interested" (one-way, like the site).
    func notifyInterest(motorbikeID: String) async throws
    func notifyInterest(partID: String) async throws
    func comments(refID: String, page: Int) async throws -> PagedResult<Comment>
    /// `group` is PROPERTY, MEMBER or ARTICLE.
    func addComment(group: String, refID: String, content: String) async throws
    /// "Related bikes": newest in the same region (site query).
    func similarMotorbikes(location: String) async throws -> [Motorbike]
    /// "Related parts": newest in the same category (site query).
    func similarParts(category: String) async throws -> [Part]
}

protocol AgentRepository: Sendable {
    func topAgents(limit: Int) async throws -> [Agent]
    /// `sort`: createdAt | memberLikes | memberViews.
    func agents(page: Int, sort: String, direction: String, text: String) async throws -> PagedResult<Agent>
    func agent(id: String) async throws -> Agent
    func agentMotorbikes(memberID: String, page: Int) async throws -> PagedResult<Motorbike>
    func likeMember(id: String) async throws
    func follow(id: String) async throws
    func unfollow(id: String) async throws
}

protocol CommunityRepository: Sendable {
    /// `category`: FREE | RECOMMEND | NEWS | HUMOR.
    func articles(category: String, page: Int) async throws -> PagedResult<Article>
    func article(id: String) async throws -> Article
    func likeArticle(id: String) async throws
    func createArticle(category: String, title: String, content: String) async throws -> String
    func memberArticles(memberID: String, page: Int) async throws -> PagedResult<Article>
}

protocol MyPageRepository: Sendable {
    /// "Sevimlilarim" (`visited` false) or "Yaqinda ko'rilganlar" (true).
    func myBikes(page: Int, visited: Bool) async throws -> PagedResult<Motorbike>
    /// `followers` true: who follows `memberID`; false: whom `memberID` follows.
    func follows(memberID: String, page: Int, followers: Bool) async throws -> PagedResult<FollowMember>
    /// My own bikes / parts with `status` ACTIVE, HOLD or SOLD.
    func myListings(status: String, page: Int) async throws -> PagedResult<Motorbike>
    func myParts(status: String, page: Int) async throws -> PagedResult<Part>
    /// New listing (`id` nil) or an edit; `fields` use the API names.
    func saveMotorbike(_ fields: [String: Any], id: String?) async throws
    func savePart(_ fields: [String: Any], id: String?) async throws
    /// Archive (SOLD), re-list (ACTIVE) or delete (DELETE) one of my listings.
    func setListingStatus(id: String, status: String, part: Bool) async throws
    /// Uploads one JPEG/PNG and returns its stored path ("uploads/member/x.jpg").
    /// `target` is the upload folder: member, property, part, article.
    func uploadImage(_ data: Data, fileName: String, target: String) async throws -> String
}

protocol NotificationRepository: Sendable {
    /// Newest first, plus the unread count for the bell badge.
    func notifications() async throws -> (items: [AppNotification], unread: Int)
    /// No ids = mark everything read (same as the site's "Mark all read").
    func markNotificationsRead(ids: [String]?) async throws
    func deleteNotification(id: String) async throws
}

protocol AuthRepository: Sendable {
    /// Member from the saved session, if any.
    func restoreSession() async -> Member?
    func login(nick: String, password: String) async throws -> Member
    func signup(_ form: SignupForm) async throws -> Member
    func logout() async
    /// "My profile" form; the server answers with a fresh token carrying the new data.
    func updateProfile(nick: String?, phone: String?, address: String?, imagePath: String?) async throws -> Member?
    /// Permanently deletes the account on the server and ends the session.
    func deleteAccount() async throws
    /// A valid access token (refreshed first if needed), for the chat socket.
    func accessToken() async -> String?
    /// Called when the server rejects the refresh token (session revoked or expired).
    func onSessionExpired(_ handler: @escaping @Sendable () -> Void) async
}

protocol AssistantRepository: Sendable {
    /// The server keeps no chat state, so earlier turns go along with every question.
    func ask(_ message: String, history: [ChatMessage]) async throws -> ChatMessage
    /// Flags an offensive or wrong answer for admin review.
    func report(reason: AIReportReason, question: String, answer: String, comment: String) async throws
}
