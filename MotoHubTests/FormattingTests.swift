import XCTest
@testable import MotoHub

final class FormattingTests: XCTestCase {
    func testLabels() {
        XCTAssertEqual(Formatting.label("HARLEY_DAVIDSON"), "Harley-Davidson")
        XCTAssertEqual(Formatting.label("TASHKENT"), "Toshkent")
        XCTAssertEqual(Formatting.label("SOME_NEW_VALUE"), "Some New Value")
        XCTAssertEqual(Formatting.label(""), "")
    }

    func testPriceLikeTheSite() {
        XCTAssertEqual(Formatting.price(12_500, currency: "USD"), "$12,500")
        XCTAssertEqual(Formatting.price(1_250_000, currency: "UZS"), "1 250 000 so'm")
        XCTAssertEqual(Formatting.price(999, currency: "EUR"), "999 EUR")
        XCTAssertEqual(Formatting.price(100, currency: nil), "$100")
    }

    func testRating() {
        XCTAssertEqual(Formatting.siteRating(0), "4.6")
        XCTAssertEqual(Formatting.siteRating(12), "1.2")
        XCTAssertEqual(Formatting.siteRating(20, home: true), "20.00")
    }

    func testPlainText() {
        XCTAssertEqual(Formatting.plainText("<p>Zo&amp;r</p><p>holat<br/>a'lo</p>"), "Zo&r\nholat\na'lo")
        XCTAssertEqual(Formatting.plainText(nil), "")
    }

    func testTimeAgo() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertEqual(Formatting.timeAgo(now.addingTimeInterval(-30), now: now), "1 daqiqa oldin")
        XCTAssertEqual(Formatting.timeAgo(now.addingTimeInterval(-3 * 3600), now: now), "3 soat oldin")
        XCTAssertEqual(Formatting.timeAgo(now.addingTimeInterval(-2 * 86400), now: now), "2 kun oldin")
    }

    func testTranslationTablesAndNumberTemplates() {
        let i18n = I18n(lang: .ru)
        XCTAssertEqual(i18n.tr("Mototsikllar"), "Мотоциклы")
        XCTAssertNotEqual(i18n.tr("12 mavjud"), "12 mavjud", "numbers are templated as {0}")
        XCTAssertTrue(i18n.tr("12 mavjud").contains("12"))
        XCTAssertEqual(i18n.tr("Yamaha R1"), "Yamaha R1", "unknown text stays as is")
        XCTAssertEqual(I18n(lang: .uz).tr("Mototsikllar"), "Mototsikllar")
    }
}
