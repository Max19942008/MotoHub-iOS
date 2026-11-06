import XCTest
@testable import MotoHub

final class DataLayerTests: XCTestCase {
    // MARK: Search variables

    func testMotorbikeSearchOmitsEmptyFieldsAndSortsLists() throws {
        var filter = MotorbikeFilter()
        filter.brands = ["YAMAHA", "HONDA"]
        filter.text = "  r1  "
        let json = try jsonObject(MotorbikeSearchDTO(filter))

        XCTAssertEqual(json["brandList"] as? [String], ["HONDA", "YAMAHA"])
        XCTAssertEqual(json["text"] as? String, "r1")
        XCTAssertNil(json["typeList"])
        XCTAssertNil(json["pricesRange"])
    }

    func testPriceRangeDefaultsOpenEnd() throws {
        var filter = MotorbikeFilter()
        filter.minPrice = 2000
        let range = try XCTUnwrap(jsonObject(MotorbikeSearchDTO(filter))["pricesRange"] as? [String: Int])
        XCTAssertEqual(range, ["start": 2000, "end": 100_000_000])
    }

    func testPartSearchAlwaysSendsCategory() throws {
        let json = try jsonObject(PartSearchDTO(PartFilter(category: .accessory)))
        XCTAssertEqual(json["categoryList"] as? [String], ["ACCESSORY"])
        XCTAssertEqual(json.count, 1)
    }

    func testSortFields() {
        XCTAssertEqual(SortOption.cheapest.field(prefix: "property"), "propertyPrice")
        XCTAssertEqual(SortOption.cheapest.direction, "ASC")
        XCTAssertEqual(SortOption.popular.field(prefix: "part"), "partViews")
        XCTAssertEqual(SortOption.newest.field(prefix: "part"), "createdAt")
    }

    // MARK: Response decoding

    func testDecodesMotorbikePage() throws {
        let body = """
        {"data":{"getProperties":{"list":[{"_id":"a1","propertyTitle":" Yamaha R1 ","propertyPrice":12500,
        "propertyYear":2019,"propertyImages":["uploads/x.jpg"],"createdAt":"2026-10-21T12:00:00.000Z",
        "memberData":{"_id":"m1","memberNick":"ali","memberPhone":"+998901234567"}}],"metaCounter":[{"total":42}]}}}
        """
        struct Response: Decodable { let getProperties: ListDTO<MotorbikeDTO> }
        let page = try GraphQLClient.decode(Response.self, from: Data(body.utf8), status: 200).getProperties
        let bike = try XCTUnwrap(page.list.first?.toDomain())

        XCTAssertEqual(page.total, 42)
        XCTAssertEqual(bike.title, "Yamaha R1")
        XCTAssertEqual(bike.year, 2019)
        XCTAssertEqual(bike.currency, "USD")
        XCTAssertEqual(bike.seller?.nick, "ali")
        XCTAssertNotNil(bike.createdAt)
    }

    func testGraphQLErrorsAreTranslated() {
        let body = #"{"errors":[{"message":"Wrong password, try again!"}],"data":null}"#
        XCTAssertThrowsError(try GraphQLClient.decode(TokensDTO.self, from: Data(body.utf8), status: 200)) { error in
            XCTAssertEqual(error as? AppError, .server("Parol noto‘g‘ri."))
        }
    }

    func testValidationErrorListIsJoined() {
        let body = #"{"errors":[{"message":["a","b"]}]}"#
        XCTAssertThrowsError(try GraphQLClient.decode(TokensDTO.self, from: Data(body.utf8), status: 400)) { error in
            XCTAssertEqual(error as? AppError, .server("a\nb"))
        }
    }

    func testHTMLErrorPageWhileBootingIsANetworkError() {
        XCTAssertThrowsError(try GraphQLClient.decode(TokensDTO.self, from: Data("<html>502</html>".utf8), status: 502)) { error in
            XCTAssertEqual((error as? AppError)?.isNetwork, true)
        }
    }

    // MARK: JWT

    func testJWTMemberAndExpiry() throws {
        let token = TestJWT.make(["_id": "m1", "memberNick": "ali", "memberType": "AGENT", "exp": 2_000_000_000])
        let member = try XCTUnwrap(JWT.member(token))
        XCTAssertEqual(member.id, "m1")
        XCTAssertTrue(member.isAgent)
        XCTAssertEqual(JWT.expiry(token), Date(timeIntervalSince1970: 2_000_000_000))
        XCTAssertNil(JWT.member("not-a-token"))
    }

    // MARK: Image URLs

    func testImageURL() {
        XCTAssertEqual(AppConfig.imageURL("https://cdn.example.com/a.jpg")?.absoluteString, "https://cdn.example.com/a.jpg")
        XCTAssertEqual(
            AppConfig.imageURL("uploads/property/a.jpg")?.absoluteString,
            AppConfig.apiBaseURL.absoluteString + "/uploads/property/a.jpg"
        )
        XCTAssertNil(AppConfig.imageURL(""))
    }

    private func jsonObject(_ value: some Encodable) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as? [String: Any])
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
