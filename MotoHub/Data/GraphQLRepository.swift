import Foundation

/// Every listing / agent / community / my-page / notification call, with the
/// same queries the website and the Android app send.
struct GraphQLRepository: ListingRepository, AgentRepository, CommunityRepository, MyPageRepository, NotificationRepository {
    let client: GraphQLClient

    // MARK: - Fields

    private static let sellerFields = "memberData { _id memberNick memberPhone memberImage memberType }"

    private static let motorbikeFields = """
    _id propertyType propertyLocation propertyBrand propertyCondition propertyAddress
    propertyTitle propertyPrice propertyCurrency propertyYear propertyEngineCc
    propertyMileAge propertyViews propertyLikes propertyRank propertyImages propertyDesc
    propertyBarter propertyRent propertyStatus createdAt
    \(sellerFields)
    """

    private static let meFields = "meLiked { myFavorite } meInterested { myInterest }"

    private static let agentFields = """
    _id memberNick memberFullName memberPhone memberImage memberRank memberType memberAddress
    memberProperties memberViews memberLikes meLiked { myFavorite }
    """

    private static let partFields = """
    _id partCategory partType partLocation partBrand partCondition partTitle
    partPrice partCurrency partStockCount partCompatibleBrands partViews partLikes partRank
    partImages partDesc partBarter partStatus createdAt
    \(sellerFields)
    """

    private static let articleFields = """
    _id articleCategory articleTitle articleContent articleImage articleViews
    articleLikes articleComments createdAt meLiked { myFavorite }
    memberData { _id memberNick memberImage }
    """

    // MARK: - Helpers

    private func inquiry(page: Int, limit: Int, sort: String? = nil, direction: String? = nil, search: JSONObject) -> JSONObject {
        var input: JSONObject = ["page": page, "limit": limit, "search": search]
        if let sort { input["sort"] = sort }
        if let direction { input["direction"] = direction }
        return ["input": input]
    }

    private func list<T>(_ data: JSONObject, _ field: String, _ map: (JSONObject) -> T) -> PagedResult<T> {
        let result = data.object(field) ?? [:]
        return PagedResult(items: result.objects("list").map(map), total: result.counter())
    }

    private func mutate(_ document: String, _ variables: JSONObject) async throws {
        _ = try await client.query(document, variables: variables)
    }

    // MARK: - Listings

    func motorbikes(filter: MotorbikeFilter, page: Int) async throws -> PagedResult<Motorbike> {
        let data = try await client.query(
            "query ($input: PropertiesInquiry!) { getProperties(input: $input) { list { \(Self.motorbikeFields) } metaCounter { total } } }",
            variables: inquiry(page: page, limit: AppConfig.pageSize, sort: filter.effectiveSort.field(prefix: "property"),
                               direction: filter.effectiveSort.direction, search: filter.search)
        )
        return list(data, "getProperties", Motorbike.init(json:))
    }

    func topMotorbikes(sort: String, limit: Int) async throws -> [Motorbike] {
        let data = try await client.query(
            "query ($input: PropertiesInquiry!) { getProperties(input: $input) { list { \(Self.motorbikeFields) } } }",
            variables: inquiry(page: 1, limit: limit, sort: sort, direction: "DESC", search: [:])
        )
        return list(data, "getProperties", Motorbike.init(json:)).items
    }

    func motorbike(id: String) async throws -> Motorbike {
        let data = try await client.query(
            "query ($id: String!) { getProperty(propertyId: $id) { \(Self.motorbikeFields) \(Self.meFields) } }",
            variables: ["id": id]
        )
        return Motorbike(json: data.object("getProperty") ?? [:])
    }

    func parts(filter: PartFilter, page: Int) async throws -> PagedResult<Part> {
        let data = try await client.query(
            "query ($input: PartsInquiry!) { getParts(input: $input) { list { \(Self.partFields) } metaCounter { total } } }",
            variables: inquiry(page: page, limit: AppConfig.pageSize, sort: filter.effectiveSort.field(prefix: "part"),
                               direction: filter.effectiveSort.direction, search: filter.search)
        )
        return list(data, "getParts", Part.init(json:))
    }

    func topParts(category: String, limit: Int) async throws -> [Part] {
        let data = try await client.query(
            "query ($input: PartsInquiry!) { getParts(input: $input) { list { \(Self.partFields) } } }",
            variables: inquiry(page: 1, limit: limit, sort: "partRank", direction: "DESC", search: ["categoryList": [category]])
        )
        return list(data, "getParts", Part.init(json:)).items
    }

    func part(id: String) async throws -> Part {
        let data = try await client.query(
            "query ($id: String!) { getPart(partId: $id) { \(Self.partFields) \(Self.meFields) } }",
            variables: ["id": id]
        )
        return Part(json: data.object("getPart") ?? [:])
    }

    func likeMotorbike(id: String) async throws {
        try await mutate("mutation ($id: String!) { likeTargetProperty(propertyId: $id) { _id } }", ["id": id])
    }

    func likePart(id: String) async throws {
        try await mutate("mutation ($id: String!) { likeTargetPart(partId: $id) { _id } }", ["id": id])
    }

    func notifyInterest(motorbikeID: String) async throws {
        try await mutate("mutation ($id: String!) { notifyInterest(propertyId: $id) }", ["id": motorbikeID])
    }

    func notifyInterest(partID: String) async throws {
        try await mutate("mutation ($id: String!) { notifyPartInterest(partId: $id) }", ["id": partID])
    }

    func comments(refID: String, page: Int) async throws -> PagedResult<Comment> {
        let data = try await client.query(
            """
            query ($input: CommentsInquiry!) {
              getComments(input: $input) {
                list { _id commentContent createdAt memberData { memberNick memberImage } }
                metaCounter { total }
              }
            }
            """,
            variables: inquiry(page: page, limit: 5, sort: "createdAt", direction: "DESC", search: ["commentRefId": refID])
        )
        return list(data, "getComments", Comment.init(json:))
    }

    func addComment(group: String, refID: String, content: String) async throws {
        try await mutate(
            "mutation ($input: CommentInput!) { createComment(input: $input) { _id } }",
            ["input": ["commentGroup": group, "commentRefId": refID, "commentContent": content]]
        )
    }

    func similarMotorbikes(location: String) async throws -> [Motorbike] {
        let data = try await client.query(
            "query ($input: PropertiesInquiry!) { getProperties(input: $input) { list { \(Self.motorbikeFields) } } }",
            variables: inquiry(page: 1, limit: 9, sort: "createdAt", direction: "DESC", search: ["locationList": [location]])
        )
        return list(data, "getProperties", Motorbike.init(json:)).items
    }

    func similarParts(category: String) async throws -> [Part] {
        let data = try await client.query(
            "query ($input: PartsInquiry!) { getParts(input: $input) { list { \(Self.partFields) } } }",
            variables: inquiry(page: 1, limit: 9, sort: "createdAt", direction: "DESC", search: ["categoryList": [category]])
        )
        return list(data, "getParts", Part.init(json:)).items
    }

    // MARK: - Agents

    func topAgents(limit: Int) async throws -> [Agent] {
        let data = try await client.query(
            "query ($input: AgentsInquiry!) { getAgents(input: $input) { list { \(Self.agentFields) } } }",
            variables: inquiry(page: 1, limit: limit, sort: "memberRank", direction: "DESC", search: [:])
        )
        return list(data, "getAgents", Agent.init(json:)).items
    }

    func agents(page: Int, sort: String, direction: String, text: String) async throws -> PagedResult<Agent> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let data = try await client.query(
            "query ($input: AgentsInquiry!) { getAgents(input: $input) { list { \(Self.agentFields) } metaCounter { total } } }",
            variables: inquiry(page: page, limit: 10, sort: sort, direction: direction, search: trimmed.isEmpty ? [:] : ["text": trimmed])
        )
        return list(data, "getAgents", Agent.init(json:))
    }

    func agent(id: String) async throws -> Agent {
        let data = try await client.query(
            "query ($id: String!) { getMember(memberId: $id) { \(Self.agentFields) meFollowed { myFollowing } } }",
            variables: ["id": id]
        )
        return Agent(json: data.object("getMember") ?? [:])
    }

    func agentMotorbikes(memberID: String, page: Int) async throws -> PagedResult<Motorbike> {
        let data = try await client.query(
            "query ($input: PropertiesInquiry!) { getProperties(input: $input) { list { \(Self.motorbikeFields) } metaCounter { total } } }",
            variables: inquiry(page: page, limit: 9, sort: "createdAt", direction: "DESC", search: ["memberId": memberID])
        )
        return list(data, "getProperties", Motorbike.init(json:))
    }

    func likeMember(id: String) async throws {
        try await mutate("mutation ($id: String!) { likeTargetMember(memberId: $id) { _id } }", ["id": id])
    }

    func follow(id: String) async throws {
        try await mutate("mutation ($id: String!) { subscribe(input: $id) { _id } }", ["id": id])
    }

    func unfollow(id: String) async throws {
        try await mutate("mutation ($id: String!) { unsubscribe(input: $id) { _id } }", ["id": id])
    }

    // MARK: - Community

    func articles(category: String, page: Int) async throws -> PagedResult<Article> {
        let data = try await client.query(
            "query ($input: BoardArticlesInquiry!) { getBoardArticles(input: $input) { list { \(Self.articleFields) } metaCounter { total } } }",
            variables: inquiry(page: page, limit: 6, sort: "createdAt", direction: "DESC", search: ["articleCategory": category])
        )
        return list(data, "getBoardArticles", Article.init(json:))
    }

    func article(id: String) async throws -> Article {
        let data = try await client.query(
            "query ($id: String!) { getBoardArticle(articleId: $id) { \(Self.articleFields) } }",
            variables: ["id": id]
        )
        return Article(json: data.object("getBoardArticle") ?? [:])
    }

    func likeArticle(id: String) async throws {
        try await mutate("mutation ($id: String!) { likeTargetArticle(articleId: $id) { _id } }", ["id": id])
    }

    func createArticle(category: String, title: String, content: String) async throws -> String {
        let data = try await client.query(
            "mutation ($input: BoardArticleInput!) { createBoardArticle(input: $input) { _id } }",
            variables: ["input": ["articleCategory": category, "articleTitle": title, "articleContent": content]]
        )
        return data.object("createBoardArticle")?.text("_id") ?? ""
    }

    func memberArticles(memberID: String, page: Int) async throws -> PagedResult<Article> {
        let data = try await client.query(
            "query ($input: BoardArticlesInquiry!) { getBoardArticles(input: $input) { list { \(Self.articleFields) } metaCounter { total } } }",
            variables: inquiry(page: page, limit: 6, sort: "createdAt", direction: "DESC", search: ["memberId": memberID])
        )
        return list(data, "getBoardArticles", Article.init(json:))
    }

    // MARK: - My page

    func myBikes(page: Int, visited: Bool) async throws -> PagedResult<Motorbike> {
        let field = visited ? "getVisited" : "getFavorites"
        let data = try await client.query(
            "query ($input: OrdinaryInquiry!) { \(field)(input: $input) { list { \(Self.motorbikeFields) } metaCounter { total } } }",
            variables: ["input": ["page": page, "limit": 6]]
        )
        return list(data, field, Motorbike.init(json:))
    }

    func follows(memberID: String, page: Int, followers: Bool) async throws -> PagedResult<FollowMember> {
        let field = followers ? "getMemberFollowers" : "getMemberFollowings"
        let key = followers ? "followerData" : "followingData"
        let searchKey = followers ? "followingId" : "followerId"
        let data = try await client.query(
            """
            query ($input: FollowInquiry!) {
              \(field)(input: $input) {
                list {
                  meLiked { myFavorite } meFollowed { myFollowing }
                  \(key) { _id memberNick memberImage memberFollowers memberFollowings memberLikes }
                }
                metaCounter { total }
              }
            }
            """,
            variables: ["input": ["page": page, "limit": 5, "search": [searchKey: memberID]] as JSONObject]
        )
        let result = list(data, field) { FollowMember(json: $0, key: key) }
        // Deleted accounts keep their follow rows as "nick#del#id".
        return PagedResult(items: result.items.filter { !$0.nick.contains("#del#") }, total: result.total)
    }

    func myListings(status: String, page: Int) async throws -> PagedResult<Motorbike> {
        let data = try await client.query(
            "query ($input: AgentPropertiesInquiry!) { getAgentProperties(input: $input) { list { \(Self.motorbikeFields) } metaCounter { total } } }",
            variables: inquiry(page: page, limit: 5, sort: "createdAt", direction: "DESC", search: ["propertyStatus": status])
        )
        return list(data, "getAgentProperties", Motorbike.init(json:))
    }

    func myParts(status: String, page: Int) async throws -> PagedResult<Part> {
        let data = try await client.query(
            "query ($input: AgentPartsInquiry!) { getAgentParts(input: $input) { list { \(Self.partFields) } metaCounter { total } } }",
            variables: inquiry(page: page, limit: 5, sort: "createdAt", direction: "DESC", search: ["partStatus": status])
        )
        return list(data, "getAgentParts", Part.init(json:))
    }

    func saveMotorbike(_ fields: JSONObject, id: String?) async throws {
        if let id {
            try await mutate("mutation ($input: PropertyUpdate!) { updateProperty(input: $input) { _id } }",
                             ["input": fields.merging(["_id": id]) { $1 }])
        } else {
            try await mutate("mutation ($input: PropertyInput!) { createProperty(input: $input) { _id } }", ["input": fields])
        }
    }

    func savePart(_ fields: JSONObject, id: String?) async throws {
        if let id {
            try await mutate("mutation ($input: PartUpdate!) { updatePart(input: $input) { _id } }",
                             ["input": fields.merging(["_id": id]) { $1 }])
        } else {
            try await mutate("mutation ($input: PartInput!) { createPart(input: $input) { _id } }", ["input": fields])
        }
    }

    func setListingStatus(id: String, status: String, part: Bool) async throws {
        if part {
            try await savePart(["partStatus": status], id: id)
        } else {
            try await saveMotorbike(["propertyStatus": status], id: id)
        }
    }

    func uploadImage(_ data: Data, fileName: String, target: String) async throws -> String {
        try await client.uploadImage(data, fileName: fileName, target: target)
    }

    // MARK: - Notifications

    func notifications() async throws -> (items: [AppNotification], unread: Int) {
        let data = try await client.query(
            """
            query ($input: NotificationInquiry!) {
              getNotifications(input: $input) {
                list { _id notificationType notificationStatus notificationTitle notificationDesc createdAt }
                unreadCounter { total }
              }
            }
            """,
            variables: inquiry(page: 1, limit: 50, sort: "createdAt", direction: "DESC", search: [:])
        )
        let result = data.object("getNotifications") ?? [:]
        return (result.objects("list").map(AppNotification.init(json:)), result.counter("unreadCounter"))
    }

    func markNotificationsRead(ids: [String]?) async throws {
        var input: JSONObject = [:]
        if let ids { input["_id"] = ids }
        try await mutate("mutation ($input: NotificationReadInput) { markNotificationsRead(input: $input) }", ["input": input])
    }

    func deleteNotification(id: String) async throws {
        try await mutate("mutation ($input: NotificationDeleteInput) { deleteNotification(input: $input) }", ["input": ["_id": [id]]])
    }
}
