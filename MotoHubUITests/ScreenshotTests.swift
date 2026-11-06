import XCTest

/// Walks through the main screens against the live backend and attaches a
/// screenshot of each. CI exports them from the .xcresult (see screenshots.yml).
/// Steps are best-effort: a missing element is recorded, the walk goes on.
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!
    private var shot = 0

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testCaptureScreens() {
        // The free Render backend may need up to a minute to wake up.
        let card = app.buttons.matching(identifier: "listing-card").firstMatch
        let listLoaded = card.waitForExistence(timeout: 150)
        snap("mototsikllar")

        if listLoaded {
            card.tap()
            pause(4)
            snap("mototsikl-detail")
            app.swipeUp()
            pause(1)
            snap("mototsikl-detail-pasti")
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }

        let filters = app.buttons["Filtrlar"].firstMatch
        if filters.waitForExistence(timeout: 5) {
            filters.tap()
            pause(1)
            snap("filtrlar")
            app.buttons["Qo‘llash"].firstMatch.tap()
        }

        app.tabBars.buttons["Qismlar"].tap()
        _ = app.buttons.matching(identifier: "listing-card").firstMatch.waitForExistence(timeout: 60)
        pause(1)
        snap("qismlar")

        app.tabBars.buttons["AI yordamchi"].tap()
        pause(1)
        snap("ai-yordamchi")

        let input = app.descendants(matching: .any).matching(identifier: "ai-input").firstMatch
        if input.waitForExistence(timeout: 5) {
            input.tap()
            input.typeText("Toshkentda arzon sport mototsikl bormi?")
            app.descendants(matching: .any).matching(identifier: "ai-send").firstMatch.tap()
            let typing = app.staticTexts["Yordamchi javob yozmoqda…"]
            let done = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: typing)
            _ = XCTWaiter.wait(for: [done], timeout: 120)
            pause(1)
            snap("ai-javob")
        }

        app.tabBars.buttons["Kirish"].tap()
        pause(1)
        snap("kirish")

        app.segmentedControls.buttons["Ro‘yxatdan o‘tish"].tap()
        pause(1)
        snap("royxatdan-otish")
    }

    private func snap(_ name: String) {
        shot += 1
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = String(format: "%02d-%@", shot, name)
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func pause(_ seconds: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }
}
