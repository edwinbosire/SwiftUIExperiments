//
//  UI_ExperimentsUITests.swift
//  UI-ExperimentsUITests
//
//  Created by Edwin Bosire on 25/08/2024.
//

import XCTest

final class UI_ExperimentsUITests: XCTestCase {

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
