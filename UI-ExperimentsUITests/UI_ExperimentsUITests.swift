//
//  UI_ExperimentsUITests.swift
//  UI-ExperimentsUITests
//
//  Created by Edwin Bosire on 25/08/2024.
//

import XCTest

final class UI_ExperimentsUITests: XCTestCase {

    func testRiveOnboardingSelectionNameBackCompletionReplayAndSkip() {
        let app = XCUIApplication()
        app.launch()
        app.openCatalogueExperiment("rive-onboarding-demo")
        let next = app.buttons["rive-onboarding-next"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        XCTAssertEqual(next.label, "Find my adventure")
        next.tap()
        let coast = app.buttons["rive-onboarding-style-coast"]
        XCTAssertTrue(coast.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["rive-onboarding-style-city"].isHittable)
        coast.tap()
        XCTAssertEqual(coast.value as? String, "Selected")
        next.tap()
        let name = app.textFields["rive-onboarding-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        name.tap()
        if let value = name.value as? String, value != name.placeholderValue {
            name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count))
        }
        name.typeText("Alex")
        app.keyboards.buttons["Done"].tap()
        app.buttons["rive-onboarding-back"].tap()
        XCTAssertEqual(coast.value as? String, "Selected")
        next.tap()
        XCTAssertEqual(name.value as? String, "Alex")
        next.tap()
        XCTAssertTrue(app.staticTexts["Your travel style is saved."].waitForExistence(timeout: 3))
        XCTAssertEqual(next.label, "Start exploring")
        app.buttons["rive-onboarding-back"].tap()
        XCTAssertEqual(next.label, "Find my adventure")
        app.buttons["rive-onboarding-skip"].tap()
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        XCTAssertEqual(name.value as? String, "Alex")
        app.buttons["close-rive-onboarding"].tap()
        XCTAssertTrue(app.buttons["rive-onboarding-demo"].waitForExistence(timeout: 3))
        app.openCatalogueExperiment("rive-onboarding-demo")
        app.buttons["rive-onboarding-skip"].tap()
        XCTAssertEqual(name.value as? String, "Alex")
        next.tap()
        next.tap()
        XCTAssertTrue(app.buttons["rive-onboarding-demo"].waitForExistence(timeout: 3))
    }

    func testRiveOnboardingKeepsNavigationReachableAtAccessibilityTextSize() {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        app.openCatalogueExperiment("rive-onboarding-demo")
        let next = app.buttons["rive-onboarding-next"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        XCTAssertTrue(next.isHittable)
        next.tap()
        XCTAssertTrue(app.buttons["rive-onboarding-back"].isHittable)
        app.buttons["rive-onboarding-skip"].tap()
        next.tap()
        XCTAssertEqual(next.label, "Start exploring")
        XCTAssertTrue(next.isHittable)
        app.buttons["close-rive-onboarding"].tap()
    }

    func testStockRangesScrubReleaseAndCandleStyles() {
        let app = XCUIApplication()
        app.launch()
        app.openCatalogueExperiment("x-stock-demo")
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
        app.openCatalogueExperiment("grok-bot-demo")
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
        app.openCatalogueExperiment("grok-bot-demo")
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
        app.openCatalogueExperiment("ultracode-demo")

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
        app.openCatalogueExperiment("ultracode-demo")
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
        app.openCatalogueExperiment("dynamic-layout-demo")

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
        app.openCatalogueExperiment("dynamic-layout-demo")

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


final class CatalogueUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCategoryFiltersPreserveNavigationAndRestoreAllStudies() {
        let app = XCUIApplication()
        app.launch()
        let count = app.staticTexts["catalogue-count"]
        XCTAssertTrue(count.waitForExistence(timeout: 5))
        let total = count.label
        app.selectCatalogueCategory("controls")
        XCTAssertEqual(count.label, "4 STUDIES")
        XCTAssertTrue(app.buttons["catalogue-filter-controls"].isSelected)
        XCTAssertFalse(app.buttons["grok-bot-demo"].exists)
        app.openCatalogueExperiment("animated-checkbox-demo")
        XCTAssertTrue(app.navigationBars["Animated checkbox"].waitForExistence(timeout: 3))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["catalogue-filter-controls"].isSelected)
        app.selectCatalogueCategory("motion")
        XCTAssertFalse(app.buttons["x-stock-demo"].exists)
        XCTAssertTrue(app.buttons["grok-bot-demo"].exists)
        app.selectCatalogueCategory("all")
        XCTAssertEqual(count.label, total)
        app.selectCatalogueCategory("layouts")
        XCTAssertEqual(count.label, "3 STUDIES")
        app.openCatalogueExperiment("cover-flow-demo")
        XCTAssertTrue(app.staticTexts["Bright Objects"].waitForExistence(timeout: 5))
    }

    func testCatalogueScrollsToEveryEntry() {
        let app = XCUIApplication()
        app.launch()
        for id in ["x-stock-demo", "grok-bot-demo", "duo-owl-demo", "ultracode-demo",
                   "dynamic-layout-demo", "animated-checkbox-demo", "quiz-demo", "highlighter-demo",
                   "intensity-picker-demo", "cover-flow-demo"] {
            let link = app.buttons[id]
            app.revealCatalogueElement(link)
            XCTAssertTrue(link.isHittable, "Missing catalogue entry: \(id)")
        }
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Catalogue collection"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCatalogueSupportsAccessibilityTextAndCompactWidth() {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        app.selectCatalogueCategory("controls")
        let link = app.buttons["animated-checkbox-demo"]
        app.revealCatalogueElement(link)
        XCTAssertTrue(link.isHittable)
        XCTAssertGreaterThanOrEqual(link.frame.minX, app.frame.minX)
        XCTAssertLessThanOrEqual(link.frame.maxX, app.frame.maxX)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Catalogue accessibility text"
        attachment.lifetime = .keepAlways
        add(attachment)
        link.tap()
        XCTAssertTrue(app.navigationBars["Animated checkbox"].waitForExistence(timeout: 3))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["catalogue-filter-controls"].isSelected)
    }
}

private extension XCUIApplication {
    func revealCatalogueElement(_ element: XCUIElement) {
        let scroll = scrollViews["experiment-catalogue"]
        for _ in 0..<16 {
            if element.exists && element.isHittable { return }
            if element.exists && element.frame.maxY < scroll.frame.minY + 44 {
                scroll.swipeDown()
            } else {
                scroll.swipeUp()
            }
        }
    }

    func openCatalogueExperiment(_ identifier: String) {
        let link = buttons[identifier]
        revealCatalogueElement(link)
        XCTAssertTrue(link.isHittable, "Could not reach \(identifier)")
        link.tap()
    }

    func selectCatalogueCategory(_ category: String) {
        let filter = buttons["catalogue-filter-\(category)"]
        let filters = scrollViews["catalogue-filters"]
        revealCatalogueElement(filters)
        if !filter.isHittable {
            if category == "all" || category == "motion" { filters.swipeRight() }
            else { filters.swipeLeft() }
        }
        XCTAssertTrue(filter.isHittable)
        filter.tap()
    }
}


final class ResponsiveFeatureUITests: XCTestCase {
    private let features = ["x-stock-demo", "grok-bot-demo", "duo-owl-demo", "ultracode-demo",
                            "dynamic-layout-demo", "animated-checkbox-demo", "quiz-demo",
                            "highlighter-demo", "intensity-picker-demo", "cover-flow-demo",
                            "rive-onboarding-demo", "travel-character-demo"]

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testQuizAnswersInShortWindow() {
        let app = launch("quiz-demo", width: 640, height: 300)
        let scroll = app.scrollViews.firstMatch
        let answer = app.buttons["quiz-answer-St Helena"]
        reveal(answer, in: scroll)
        capture(app, name: "Quiz in a short window")
        XCTAssertTrue(answer.isHittable)
        answer.tap()
        XCTAssertEqual(answer.value as? String, "Selected")
    }

    func testStockControlsInShortWindow() {
        let app = launch("x-stock-demo", width: 640, height: 300)
        let scroll = app.scrollViews["x-stock-scroll"]
        let style = app.buttons["x-stock-chart-style"]
        for _ in 0..<4 { scroll.swipeUp() }
        capture(app, name: "Stock short window after scrolling")
        XCTAssertTrue(style.isHittable)
    }

    func testIntensityPanelCanReopenInSmallWindow() {
        let app = launch("intensity-picker-demo", width: 320, height: 568)
        let show = app.buttons["show-intensity-picker"]
        XCTAssertTrue(show.waitForExistence(timeout: 5))
        XCTAssertTrue(show.isHittable)
        show.tap()
        app.buttons["close-intensity-picker"].tap()
        capture(app, name: "Intensity after closing")
        expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: show)
        waitForExpectations(timeout: 3)
        show.tap()
        XCTAssertTrue(app.buttons["close-intensity-picker"].isHittable)
    }

    func testLayoutLabelsWithAccessibilityText() {
        checkFeatures(width: 320, height: 568, accessibility: true, only: ["dynamic-layout-demo"])
    }

    func testBookDetailsWithAccessibilityText() {
        checkFeatures(width: 320, height: 568, accessibility: true, only: ["cover-flow-demo"])
    }

    func testEveryFeatureInNarrowWindow() { checkFeatures(width: 320, height: 568) }
    func testEveryFeatureInShortWindow() { checkFeatures(width: 640, height: 300) }
    func testEveryFeatureOnTablet() { checkFeatures(width: 834, height: 1100) }
    func testEveryFeatureWithAccessibilityText() { checkFeatures(width: 320, height: 568, accessibility: true) }

    func testStockChartUsesLandscapeTabletWidthAndKeepsItsSelectionOnRotation() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = launch("x-stock-demo")
        let plot = app.descendants(matching: .any)["x-stock-plot"].firstMatch
        XCTAssertTrue(plot.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(plot.frame.width, min(1100, app.frame.width) * 0.9)
        reveal(app.buttons["x-stock-range-1W"], in: app.scrollViews["x-stock-scroll"])
        app.buttons["x-stock-range-1W"].tap()
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.buttons["x-stock-range-1W"].isSelected)
        XCTAssertEqual(app.staticTexts["x-stock-price"].label, "$198.87")
        capture(app, name: "Stock chart on iPad")
    }

    private func checkFeatures(width: Double, height: Double, accessibility: Bool = false, only: [String]? = nil) {
        for id in only ?? features {
            XCTContext.runActivity(named: "\(id) at \(Int(width)) × \(Int(height))") { _ in
                let app = launch(id, width: width, height: height, accessibility: accessibility)
                // The two travel demos may still be local, uncommitted additions.
                if ["rive-onboarding-demo", "travel-character-demo"].contains(id),
                   app.scrollViews["experiment-catalogue"].exists {
                    app.terminate()
                    return
                }
                let scroll = app.scrollViews.firstMatch
                switch id {
                case "x-stock-demo":
                    let plot = app.descendants(matching: .any)["x-stock-plot"].firstMatch
                    XCTAssertTrue(plot.waitForExistence(timeout: 5))
                    fits(plot, width: width, app: app)
                    if width >= 800 { XCTAssertGreaterThan(plot.frame.width, 700) }
                    let style = app.buttons["x-stock-chart-style"]
                    let controls = app.scrollViews["x-stock-controls"]
                    revealVertically(style, in: app.scrollViews["x-stock-scroll"])
                    for _ in 0..<3 where !style.isHittable { controls.swipeLeft(velocity: .slow) }
                    XCTAssertTrue(style.isHittable)
                    fits(app.buttons["close-x-stock-demo"], width: width, app: app)
                case "grok-bot-demo":
                    let signIn = app.buttons["grok-reactions"]
                    XCTAssertTrue(signIn.waitForExistence(timeout: 5))
                    fits(signIn, width: width, app: app)
                    XCTAssertTrue(signIn.isHittable)
                    signIn.tap()
                    XCTAssertTrue(app.buttons["grok-card-0"].waitForExistence(timeout: 5))
                case "duo-owl-demo":
                    let love = app.buttons["duo-reaction-love"]
                    reveal(love, in: app.scrollViews["duo-owl-scroll"])
                    fits(love, width: width, app: app)
                    love.tap()
                    XCTAssertTrue(love.isSelected)
                case "ultracode-demo":
                    let row = app.buttons["ultracode-row"]
                    XCTAssertTrue(row.waitForExistence(timeout: 5))
                    reveal(row, in: scroll)
                    fits(row, width: app.frame.width, app: app)
                    row.tap()
                    XCTAssertEqual(row.value as? String, "Selected")
                    app.buttons["close-ultracode-picker"].tap()
                    let reopen = app.buttons["show-ultracode-picker"]
                    reveal(reopen, in: scroll)
                    fits(reopen, width: width, app: app)
                case "dynamic-layout-demo":
                    let rectangle = app.descendants(matching: .any)["flow-item-A"].firstMatch
                    reveal(rectangle, in: scroll)
                    fits(rectangle, width: width, app: app)
                    XCTAssertTrue(app.buttons["add-layout-component"].isHittable)
                case "animated-checkbox-demo":
                    let text = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Write code everyday")).firstMatch
                    XCTAssertTrue(text.waitForExistence(timeout: 5))
                    fits(text, width: width, app: app)
                case "quiz-demo":
                    let answer = app.buttons["quiz-answer-St Helena"]
                    reveal(answer, in: scroll)
                    fits(answer, width: width, app: app)
                    answer.tap()
                    XCTAssertEqual(answer.value as? String, "Selected")
                case "highlighter-demo":
                    let web = app.webViews.firstMatch
                    XCTAssertTrue(web.waitForExistence(timeout: 5))
                    fits(web, width: width, app: app)
                    XCTAssertTrue(web.staticTexts["Life in the UK"].waitForExistence(timeout: 5))
                case "intensity-picker-demo":
                    let show = app.buttons["show-intensity-picker"]
                    XCTAssertTrue(show.waitForExistence(timeout: 5))
                    fits(show, width: width, app: app)
                    show.tap()
                    let close = app.buttons["close-intensity-picker"]
                    XCTAssertTrue(close.waitForExistence(timeout: 3))
                    XCTAssertTrue(close.isHittable)
                    let control = app.descendants(matching: .any)["intensity-control"].firstMatch
                    XCTAssertTrue(control.exists)
                    fits(control, width: width, app: app)
                    close.tap()
                    let available = NSPredicate(format: "hittable == true")
                    expectation(for: available, evaluatedWith: show)
                    waitForExpectations(timeout: 3)
                case "cover-flow-demo":
                    let book = app.buttons["cover-flow-book-the-deep-blue"]
                    reveal(book, in: app.scrollViews["cover-flow-scroll"])
                    fits(app.scrollViews["cover-flow-carousel"], width: width, app: app)
                    book.tap()
                    let close = app.buttons["Close details"]
                    XCTAssertTrue(close.waitForExistence(timeout: 5))
                    fits(close, width: width, app: app)
                    XCTAssertTrue(close.isHittable)
                    let details = app.scrollViews.matching(NSPredicate(format: "identifier == %@ OR identifier == %@", "book-detail-scroll", "coverFlow.detail")).firstMatch
                    details.swipeUp()
                    XCTAssertTrue(close.isHittable)
                    close.tap()
                    let back = app.buttons["close-cover-flow-demo"]
                    expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: back)
                    waitForExpectations(timeout: 3)
                case "rive-onboarding-demo":
                    let next = app.buttons["rive-onboarding-next"]
                    XCTAssertTrue(next.waitForExistence(timeout: 5))
                    fits(next, width: width, app: app)
                    XCTAssertTrue(next.isHittable)
                    next.tap()
                    XCTAssertTrue(app.buttons["rive-onboarding-skip"].isHittable)
                case "travel-character-demo":
                    let city = app.buttons["travel-city"]
                    reveal(city, in: scroll)
                    fits(city, width: width, app: app)
                    city.tap()
                    XCTAssertTrue(city.isSelected)
                default: XCTFail("Unverified feature \(id)")
                }
                capture(app, name: "\(id)-\(Int(width))x\(Int(height))\(accessibility ? "-large-text" : "")")
                app.terminate()
            }
        }
    }

    private func launch(_ id: String, width: Double? = nil, height: Double? = nil, accessibility: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo-test-feature", id]
        if let width, let height {
            app.launchArguments += ["-demo-test-width", String(width), "-demo-test-height", String(height)]
        }
        if accessibility {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        return app
    }

    private func revealVertically(_ element: XCUIElement, in scroll: XCUIElement) {
        for _ in 0..<20 {
            let center = element.frame.midY
            let bounds = scroll.frame.insetBy(dx: 0, dy: 24)
            if element.exists && element.frame.height > 0 && center >= bounds.minY && center <= bounds.maxY { return }
            let movingDown = element.exists && center < bounds.minY
            let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: movingDown ? 0.4 : 0.75))
            let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: movingDown ? 0.75 : 0.4))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
        }
        XCTFail("Could not scroll to \(element)")
    }

    private func reveal(_ element: XCUIElement, in scroll: XCUIElement) {
        for _ in 0..<20 {
            if element.exists && element.isHittable { return }
            let movingDown = element.exists && element.frame.width > 0 && element.frame.maxY < scroll.frame.minY + 20
            let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: movingDown ? 0.4 : 0.75))
            let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: movingDown ? 0.75 : 0.4))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
        }
        capture(XCUIApplication(), name: "Unreachable \(element.identifier)")
        XCTAssertTrue(element.isHittable, "Cannot reach \(element) at \(element.frame) within \(scroll.frame)")
    }

    private func fits(_ element: XCUIElement, width: Double, app: XCUIApplication) {
        let frame = element.frame
        XCTAssertGreaterThan(frame.width, 0)
        XCTAssertLessThanOrEqual(frame.width, min(width, app.frame.width) + 1)
        XCTAssertGreaterThanOrEqual(frame.minX, app.frame.minX - 1)
        XCTAssertLessThanOrEqual(frame.maxX, app.frame.minX + min(width, app.frame.width) + 1)
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
