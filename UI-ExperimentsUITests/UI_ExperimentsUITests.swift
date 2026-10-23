//
//  UI_ExperimentsUITests.swift
//  UI-ExperimentsUITests
//
//  Created by Edwin Bosire on 25/08/2024.
//

import XCTest

final class UI_ExperimentsUITests: XCTestCase {

    func testStockRangesScrubReleaseAndCandleStyles() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["x-stock-demo"].tap()
        let price = app.staticTexts["x-stock-price"]
        XCTAssertTrue(price.waitForExistence(timeout: 5))
        XCTAssertEqual(price.label, "$198.87")

        let expectedChanges = [
            ("1W", "↑ $17.39 (+9.58%)"),
            ("1M", "↑ $15.85 (+8.66%)"),
            ("1Y", "↑ $198.38 (+40,736%)"),
            ("ALL", "↑ $198.38 (+40,736%)"),
            ("1D", "↑ $0.82 (+0.42%)")
        ]
        for (range, change) in expectedChanges {
            app.buttons["x-stock-range-\(range)"].tap()
            XCTAssertEqual(app.staticTexts["x-stock-change"].label, change)
            XCTAssertEqual(price.label, "$198.87")
        }

        app.buttons["x-stock-range-1W"].tap()
        let plot = app.descendants(matching: .any)["x-stock-plot"].firstMatch
        plot.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5)).press(
            forDuration: 0.1,
            thenDragTo: plot.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5)),
            withVelocity: .slow,
            thenHoldForDuration: 0.3
        )
        XCTAssertEqual(price.label, "$198.87", "Releasing the chart restores the current quote")
        XCTAssertFalse(app.staticTexts["x-stock-timestamp"].exists)
        XCTAssertTrue(app.buttons["x-stock-range-1W"].isHittable)

        let styleButton = app.buttons["x-stock-chart-style"]
        for style in ["30m", "1h", "4h", "Line"] {
            styleButton.tap()
            let option = app.buttons["x-stock-style-\(style)"]
            XCTAssertTrue(option.waitForExistence(timeout: 3))
            option.tap()
            XCTAssertEqual(styleButton.value as? String, style == "Line" ? "Line" : "\(style) candles")
            XCTAssertFalse(option.exists)
        }

        app.buttons["close-x-stock-demo"].tap()
        XCTAssertTrue(app.buttons["x-stock-demo"].waitForExistence(timeout: 3))
    }

    func testGrokReactionsApplyToAllNineAndReplayWelcome() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["grok-bot-demo"].tap()
        let showReactions = app.buttons["grok-reactions"]
        XCTAssertTrue(showReactions.waitForExistence(timeout: 5))
        showReactions.tap()

        let cloud = app.buttons["grok-card-0"]
        XCTAssertTrue(cloud.waitForExistence(timeout: 5))
        XCTAssertEqual(cloud.value as? String, "Auto")
        cloud.tap()
        XCTAssertEqual(cloud.value as? String, "Curious")

        // Selecting the already-selected group reaction must clear overrides.
        app.buttons["grok-reaction-Auto"].tap()
        XCTAssertEqual(cloud.value as? String, "Auto")
        app.buttons["grok-reaction-Happy"].tap()
        for id in 0..<6 {
            XCTAssertEqual(app.buttons["grok-card-\(id)"].value as? String, "Happy")
        }
        app.swipeUp()
        for id in 6..<9 {
            let card = app.buttons["grok-card-\(id)"]
            XCTAssertTrue(card.exists)
            XCTAssertEqual(card.value as? String, "Happy")
        }
        app.buttons["grok-replay-welcome"].tap()
        XCTAssertTrue(showReactions.waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["grok-bot-0"].value as? String, "Auto")
        app.buttons["close-grok-demo"].tap()
        XCTAssertTrue(app.buttons["grok-bot-demo"].waitForExistence(timeout: 5))
    }

    func testGrokReactionsAtAccessibilityTextSize() {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        app.buttons["grok-bot-demo"].tap()
        app.buttons["grok-reactions"].tap()
        let cloud = app.buttons["grok-card-0"]
        XCTAssertTrue(cloud.waitForExistence(timeout: 5))
        XCTAssertTrue(cloud.isHittable)
        cloud.tap()
        XCTAssertEqual(cloud.value as? String, "Curious")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["grok-reactions"].isHittable)
    }

    func testUltracodeSelectionReplayAndReopening() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["ultracode-demo"].tap()

        let row = app.buttons["ultracode-row"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertEqual(row.value as? String, "Selected")

        app.buttons["replay-ultracode"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        XCTAssertEqual(row.value as? String, "Selected", "Replay must preserve the chosen effort")

        app.buttons["close-ultracode-picker"].tap()
        let present = app.buttons["show-ultracode-picker"]
        XCTAssertTrue(present.waitForExistence(timeout: 3))
        XCTAssertTrue(present.label.contains("Ultracode"))
        present.tap()
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        XCTAssertEqual(row.value as? String, "Selected")

        app.buttons["Medium"].tap()
        XCTAssertNotEqual(row.value as? String, "Selected")
        app.buttons["close-ultracode-picker"].tap()
        XCTAssertTrue(present.label.contains("Medium"))
    }

    func testUltracodeAtAccessibilityTextSize() {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        app.buttons["ultracode-demo"].tap()
        let row = app.buttons["ultracode-row"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        app.scrollViews.firstMatch.swipeUp()
        XCTAssertTrue(row.isHittable)
        row.tap()
        XCTAssertEqual(row.value as? String, "Selected")
    }

    func testDynamicLayoutAddsDeletesAndRecoversFromEmpty() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["dynamic-layout-demo"].tap()

        let a = app.descendants(matching: .any)["flow-item-A"].firstMatch
        XCTAssertTrue(a.waitForExistence(timeout: 5))
        app.buttons["delete-item-A"].tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: a)
        waitForExpectations(timeout: 3)

        app.buttons["add-layout-component"].tap()
        let added = app.descendants(matching: .any)["flow-item-9"].firstMatch
        XCTAssertTrue(added.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["delete-item-9"].isHittable, "Scroll to reveal the newly added rectangle")
        app.buttons["delete-item-9"].tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: added)
        waitForExpectations(timeout: 3)

        for id in ["B", "C", "D", "E", "F", "G", "H"] {
            app.buttons["delete-item-\(id)"].tap()
        }
        XCTAssertTrue(app.descendants(matching: .any)["empty-layout"].firstMatch.waitForExistence(timeout: 3))

        app.buttons["add-layout-component"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["flow-item-10"].firstMatch.waitForExistence(timeout: 3))
        app.buttons["reset-layout"].tap()
        XCTAssertTrue(a.waitForExistence(timeout: 3))
        XCTAssertEqual(a.value as? String, "Position 1 of 8")
    }

    func testDynamicLayoutReordersBothDirectionsAndResets() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["dynamic-layout-demo"].tap()

        let a = app.descendants(matching: .any)["flow-item-A"].firstMatch
        let b = app.descendants(matching: .any)["flow-item-B"].firstMatch
        let c = app.descendants(matching: .any)["flow-item-C"].firstMatch
        XCTAssertTrue(a.waitForExistence(timeout: 5))
        XCTAssertEqual(a.frame.width, 150, accuracy: 1)
        XCTAssertGreaterThan(b.frame.width, 110)
        XCTAssertTrue(b.label.contains("flexible"))
        let initialFlexibleWidth = c.frame.width

        b.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.4, thenDragTo: a.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5)), withVelocity: .slow, thenHoldForDuration: 1)
        expectation(for: NSPredicate(format: "value == %@", "Position 1 of 8"), evaluatedWith: b)
        waitForExpectations(timeout: 3)

        b.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.4, thenDragTo: a.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)), withVelocity: .slow, thenHoldForDuration: 1)
        expectation(for: NSPredicate(format: "value == %@", "Position 2 of 8"), evaluatedWith: b)
        waitForExpectations(timeout: 3)

        // Moving across rows must repack the differently sized rectangles.
        c.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(
            forDuration: 0.4,
            thenDragTo: a.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)),
            withVelocity: .slow,
            thenHoldForDuration: 1
        )
        expectation(for: NSPredicate(format: "value == %@", "Position 1 of 8"), evaluatedWith: c)
        waitForExpectations(timeout: 3)
        XCTAssertGreaterThanOrEqual(c.frame.width, 170)
        XCTAssertNotEqual(c.frame.width, initialFlexibleWidth, "Flexible width should adapt to its new row")
        XCTAssertEqual(a.frame.width, 150, accuracy: 1)

        app.buttons["reset-layout"].tap()
        expectation(for: NSPredicate(format: "value == %@", "Position 2 of 8"), evaluatedWith: b)
        waitForExpectations(timeout: 3)

        // A stationary long press must not change the order or leave a lifted tile.
        a.press(forDuration: 0.4)
        XCTAssertEqual(a.value as? String, "Position 1 of 8")
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
