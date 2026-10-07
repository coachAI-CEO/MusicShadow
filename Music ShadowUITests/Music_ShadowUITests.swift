//
//  Music_ShadowUITests.swift
//  Music ShadowUITests
//
//  Created by macbook on 11/16/25.
//

import XCTest

final class Music_ShadowUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    // MARK: - Send sheet (Phase 0)

    @MainActor
    private func launchSendSheet() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestSendSheet", "-sendSongExplainerSeen", "NO"]
        app.launch()
        return app
    }

    @MainActor
    func testSendSheetExplainerThenEmptyNoteBlocksSend() throws {
        let app = launchSendSheet()
        let gotIt = app.buttons["Got it"]
        XCTAssertTrue(gotIt.waitForExistence(timeout: 5), "first-run explainer should appear")
        gotIt.tap()

        let send = app.buttons["Review"]
        XCTAssertTrue(send.waitForExistence(timeout: 5))
        XCTAssertFalse(send.isEnabled, "an empty note must block Review")
    }

    @MainActor
    func testStarterPromptInsertsTextAndEnablesSend() throws {
        let app = launchSendSheet()
        if app.buttons["Got it"].waitForExistence(timeout: 5) { app.buttons["Got it"].tap() }

        let prompt = app.buttons["What do I wish you knew?"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 5))
        prompt.tap()

        let note = app.textViews["Your note"]
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        XCTAssertTrue((note.value as? String ?? "").contains("What do I wish you knew?"))
        XCTAssertTrue(app.buttons["Review"].isEnabled)
    }

    @MainActor
    func testReviewScreenShowsWhatWhenAndHowLongBeforeAnythingIsSent() throws {
        let app = launchSendSheet()
        if app.buttons["Got it"].waitForExistence(timeout: 5) { app.buttons["Got it"].tap() }

        let prompt = app.buttons["What do I wish you knew?"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 5))
        prompt.tap()
        app.buttons["Review"].tap()

        // The iTunes lookup times out after 3 seconds and falls back to a search link, so this works offline too.
        XCTAssertTrue(app.staticTexts["What you're sharing"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["What stays private"].exists)
        XCTAssertTrue(app.staticTexts["When it goes"].exists)
        XCTAssertTrue(app.staticTexts["How long"].exists)
        XCTAssertTrue(app.buttons["Choose who to send to"].exists)
        XCTAssertTrue(app.buttons["Edit"].exists)

        app.buttons["Edit"].tap()
        XCTAssertTrue(app.buttons["Review"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testExplainerShowsOnlyOnce() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestSendSheet", "-sendSongExplainerSeen", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["Review"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Got it"].exists)
    }
}
