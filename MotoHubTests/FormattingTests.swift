import XCTest
@testable import MotoHub

final class FormattingTests: XCTestCase {
    func testLabels() {
        XCTAssertEqual(Formatting.label("HARLEY_DAVIDSON"), "Harley-Davidson")
        XCTAssertEqual(Formatting.label("TASHKENT"), "Toshkent")
        XCTAssertEqual(Formatting.label("SOME_NEW_VALUE"), "Some New Value")
    }

    func testPrice() {
        XCTAssertEqual(Formatting.price(12_500, currency: "USD"), "$12 500")
        XCTAssertEqual(Formatting.price(1_250_000, currency: "UZS"), "1 250 000 so‘m")
        XCTAssertEqual(Formatting.price(999, currency: "EUR"), "999 EUR")
        XCTAssertEqual(Formatting.price(100, currency: nil), "$100")
    }

    func testPlainText() {
        XCTAssertEqual(Formatting.plainText("<p>Zo&amp;r</p><p>holat<br/>a’lo</p>"), "Zo&r\nholat\na’lo")
        XCTAssertEqual(Formatting.plainText(nil), "")
    }

    func testTimeAgo() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertEqual(Formatting.timeAgo(now.addingTimeInterval(-30), now: now), "1 daqiqa oldin")
        XCTAssertEqual(Formatting.timeAgo(now.addingTimeInterval(-3 * 3600), now: now), "3 soat oldin")
        XCTAssertEqual(Formatting.timeAgo(now.addingTimeInterval(-2 * 86400), now: now), "2 kun oldin")
    }
}
