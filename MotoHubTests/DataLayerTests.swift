import XCTest
@testable import MotoHub

final class DataLayerTests: XCTestCase {
    // MARK: Search variables

    func testMotorbikeSearchOmitsEmptyFieldsAndSortsLists() {
        var filter = MotorbikeFilter()
        filter.brands = ["YAMAHA", "HONDA"]
        filter.text = "  r1  "
        let search = filter.search

        XCTAssertEqual(search["brandList"] as? [String], ["HONDA", "YAMAHA"])
        XCTAssertEqual(search["text"] as? String, "r1")
        XCTAssertNil(search["typeList"])
        XCTAssertNil(search["pricesRange"])
    }

    func testPriceAndYearRangesDefaultLikeTheSite() throws {
        var filter = MotorbikeFilter()
        filter.minPrice = 2000
        filter.maxYear = 2020
        let price = try XCTUnwrap(filter.search["pricesRange"] as? [String: Int])
        let year = try XCTUnwrap(filter.search["yearRange"] as? [String: Int])
        XCTAssertEqual(price, ["start": 2000, "end": 2_000_000])
        XCTAssertEqual(year, ["start": 1970, "end": 2020])
        XCTAssertEqual(filter.activeCount, 2)
    }

    func testPartSearchSendsCategoryUnlessAll() {
        XCTAssertEqual(PartFilter(category: "ACCESSORY").search["categoryList"] as? [String], ["ACCESSORY"])
        XCTAssertTrue(PartFilter(category: "ALL").search.isEmpty)
    }

    func testSortFields() {
        XCTAssertEqual(SortOption.likes.field(prefix: "property"), "propertyLikes")
        XCTAssertEqual(SortOption.views.field(prefix: "part"), "partViews")
        XCTAssertEqual(SortOption.oldest.field(prefix: "part"), "createdAt")
        XCTAssertEqual(SortOption.oldest.direction, "ASC")
        XCTAssertEqual(MotorbikeFilter().effectiveSort, .recent)
    }

    // MARK: Response mapping

    func testParsesMotorbikePage() throws {
        let body = """
        {"data":{"getProperties":{"list":[{"_id":"a1","propertyTitle":" Yamaha R1 ","propertyPrice":12500,
        "propertyYear":2019,"propertyImages":["uploads/x.jpg"],"createdAt":"2026-10-21T12:00:00.000Z",
        "meLiked":[{"myFavorite":true}],
        "memberData":{"_id":"m1","memberNick":"ali","memberPhone":"+998901234567","memberImage":""}}],
        "metaCounter":[{"total":42}]}}}
        """
        let data = try GraphQLClient.parse(Data(body.utf8), status: 200)
        let page = try XCTUnwrap(data.object("getProperties"))
        let bike = try XCTUnwrap(page.objects("list").first.map(Motorbike.init(json:)))

        XCTAssertEqual(page.counter(), 42)
        XCTAssertEqual(bike.title, "Yamaha R1")
        XCTAssertEqual(bike.year, 2019)
        XCTAssertEqual(bike.currency, "USD")
        XCTAssertTrue(bike.liked)
        XCTAssertFalse(bike.interested)
        XCTAssertEqual(bike.seller?.nick, "ali")
        XCTAssertNil(bike.seller?.imagePath, "an empty photo means no photo")
        XCTAssertNotNil(bike.createdAt)
    }

    func testParsesFollowRowsAndNotifications() {
        let follow = FollowMember(json: ["followerData": ["_id": "x", "memberNick": "vali", "memberFollowers": 3] as JSONObject,
                                         "meFollowed": [["myFollowing": true]]], key: "followerData")
        XCTAssertEqual(follow.nick, "vali")
        XCTAssertEqual(follow.followers, 3)
        XCTAssertTrue(follow.followed)

        let n = AppNotification(json: ["_id": "n1", "notificationType": "LIKE", "notificationStatus": "WAIT", "notificationTitle": "Hi"])
        XCTAssertTrue(n.unread)
    }

    func testGraphQLErrorsAreTranslated() {
        let body = #"{"errors":[{"message":"Wrong password, try again!"}],"data":null}"#
        XCTAssertThrowsError(try GraphQLClient.parse(Data(body.utf8), status: 200)) { error in
            XCTAssertEqual(error as? AppError, .server("Parol noto'g'ri."))
        }
    }

    func testValidationErrorListIsJoined() {
        let body = #"{"errors":[{"message":["a","b"]}]}"#
        XCTAssertThrowsError(try GraphQLClient.parse(Data(body.utf8), status: 400)) { error in
            XCTAssertEqual(error as? AppError, .server("a\nb"))
        }
    }

    func testHTMLErrorPageWhileRestartingIsANetworkError() {
        XCTAssertThrowsError(try GraphQLClient.parse(Data("<html>502</html>".utf8), status: 502)) { error in
            XCTAssertEqual((error as? AppError)?.isNetwork, true)
        }
    }

    func testLiveChatMessages() {
        let m = LiveChatMessage(json: ["text": "salom", "memberData": ["_id": "m1", "memberNick": "ali"]] as JSONObject)
        XCTAssertEqual(m?.member?.nick, "ali")
        XCTAssertNil(LiveChatMessage(json: ["event": "info"]))
    }

    // MARK: JWT

    func testJWTMemberAndExpiry() throws {
        let token = TestJWT.make(["_id": "m1", "memberNick": "ali", "memberType": "AGENT", "memberAddress": "Seoul",
                                  "memberImage": "", "exp": 2_000_000_000])
        let member = try XCTUnwrap(JWT.member(token))
        XCTAssertEqual(member.id, "m1")
        XCTAssertTrue(member.isAgent)
        XCTAssertEqual(member.address, "Seoul")
        XCTAssertNil(member.imagePath)
        XCTAssertEqual(JWT.expiry(token), Date(timeIntervalSince1970: 2_000_000_000))
        XCTAssertNil(JWT.member("not-a-token"))
    }

    // MARK: Config

    func testImageURL() {
        XCTAssertEqual(AppConfig.imageURL("https://cdn.example.com/a.jpg")?.absoluteString, "https://cdn.example.com/a.jpg")
        XCTAssertEqual(
            AppConfig.imageURL("uploads/property/a.jpg")?.absoluteString,
            AppConfig.apiBaseURL.absoluteString + "/uploads/property/a.jpg"
        )
        XCTAssertNil(AppConfig.imageURL(""))
    }

    func testChatSocketURLUsesWebSocketScheme() {
        XCTAssertEqual(AppConfig.chatSocketURL.scheme, AppConfig.apiBaseURL.scheme == "http" ? "ws" : "wss")
        XCTAssertEqual(AppConfig.chatSocketURL.host, AppConfig.apiBaseURL.host)
    }

    func testArticleHTMLMatchesTheSiteEditor() {
        XCTAssertEqual(WriteArticleScreen.toHTML("a <b>\nc\n\nd"), "<p>a &lt;b&gt;<br>c</p><p>d</p>")
    }
}

enum TestJWT {
    static func make(_ payload: [String: Any]) -> String {
        let data = try! JSONSerialization.data(withJSONObject: payload)
        let body = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "eyJhbGciOiJIUzI1NiJ9.\(body).signature"
    }
}
