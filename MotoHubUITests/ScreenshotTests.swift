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
        // Home: hero video, then the carousels.
        pause(6)
        snap("bosh-sahifa")
        app.swipeUp()
        pause(2)
        snap("bosh-sahifa-karusel")
        app.swipeUp()
        app.swipeUp()
        pause(1)
        snap("bosh-sahifa-pastroq")

        openMenu("Mototsikllar")
        let card = app.buttons.matching(identifier: "listing-card").firstMatch
        let listLoaded = card.waitForExistence(timeout: 60)
        pause(2)
        snap("mototsikllar")

        if listLoaded {
            card.tap()
            pause(4)
            snap("mototsikl-detail")
            app.swipeUp()
            pause(1)
            snap("mototsikl-detail-pasti")
            tap(app.buttons["Orqaga"].firstMatch)
            pause(1)
        }

        openMenu("Ehtiyot qismlar")
        pause(4)
        snap("ehtiyot-qismlar")

        openMenu("Agentlar")
        pause(4)
        snap("agentlar")

        openMenu("Hamjamiyat")
        pause(4)
        snap("hamjamiyat")

        openMenu("Yordam")
        pause(2)
        snap("yordam")

        app.buttons["menyu-ochiq"].firstMatch.tap()
        pause(1)
        snap("menyu")
        app.buttons["Yordam"].firstMatch.tap()
        pause(1)

        let chat = app.buttons["Open chat"].firstMatch
        if chat.waitForExistence(timeout: 5) {
            chat.tap()
            pause(4)
            snap("jonli-chat")
            app.buttons["Close chat"].firstMatch.tap()
            pause(1)
        }

        openMenu("AI yordamchi")
        pause(1)
        snap("ai-yordamchi")
        let input = app.descendants(matching: .any).matching(identifier: "ai-input").firstMatch
        if input.waitForExistence(timeout: 5) {
            input.tap()
            input.typeText("Toshkentda arzon sport mototsikl bormi?")
            app.descendants(matching: .any).matching(identifier: "ai-send").firstMatch.tap()
            let typing = app.staticTexts["Qidiryapman…"]
            let done = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: typing)
            _ = XCTWaiter.wait(for: [done], timeout: 120)
            pause(1)
            snap("ai-javob")
        }

        openMenu("Kirish / Ro'yxatdan o'tish")
        pause(1)
        snap("kirish")
        tap(app.buttons["RO'YXATDAN O'TISH"].firstMatch)
        pause(1)
        snap("royxatdan-otish")
    }

    private func openMenu(_ item: String) {
        let menu = app.buttons["menyu-ochiq"].firstMatch
        guard menu.waitForExistence(timeout: 10) else { return }
        menu.tap()
        pause(1)
        tap(app.buttons[item].firstMatch)
        pause(1)
    }

    private func tap(_ element: XCUIElement) {
        if element.waitForExistence(timeout: 5) { element.tap() }
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
