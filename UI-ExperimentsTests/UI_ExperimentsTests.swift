//
//  UI_ExperimentsTests.swift
//  UI-ExperimentsTests
//
//  Created by Edwin Bosire on 25/08/2024.
//

import XCTest
@testable import UI_Experiments

final class UI_ExperimentsTests: XCTestCase {

    @MainActor
    func testTravelOnboardingNavigationKeepsPreferencesAndCompletesOnlyAtTheEnd() {
        let state = TravelOnboardingState()
        state.back()
        XCTAssertEqual(state.step, .discover)
        XCTAssertFalse(state.isComplete)
        state.style = .coast
        state.travelerName = "  Alex  "
        XCTAssertEqual(state.passName, "ALEX")
        state.next()
        state.next()
        XCTAssertEqual(state.step, .traveler)
        XCTAssertFalse(state.isComplete)
        state.back()
        XCTAssertEqual(state.step, .travelStyle)
        state.skipIntroduction()
        XCTAssertEqual(state.step, .traveler)
        state.next()
        XCTAssertTrue(state.isComplete)
        XCTAssertEqual(state.progress, 100)
        state.next()
        state.back()
        XCTAssertTrue(state.isComplete)
        state.replay()
        XCTAssertEqual(state.step, .discover)
        XCTAssertFalse(state.isComplete)
        XCTAssertEqual(state.style, .coast)
        XCTAssertEqual(state.displayName, "Alex")
        state.travelerName = " \n "
        XCTAssertEqual(state.passName, "WANDERER")
    }

    @MainActor
    func testTravelRiveBundledAssetBindsActualBoardingPassTextAndPreferences() throws {
        let controller = TravelRiveController()
        controller.load()
        XCTAssertNil(controller.errorDescription)
        let instance = try XCTUnwrap(controller.bindingInstance)
        let model = try XCTUnwrap(controller.viewModel?.riveModel)
        let state = TravelOnboardingState()
        state.travelerName = "Alex"
        for style in OnboardingTravelStyle.allCases {
            state.style = style
            controller.update(from: state, reduceMotion: true)
            // Exercise the imported .riv's bindings, rather than just the Swift setters.
            model.stateMachine?.advance(by: 0)
            model.artboard.advance(by: 0)
            XCTAssertEqual(model.artboard.textRun("Traveler value")?.text(), "ALEX")
            XCTAssertEqual(model.artboard.textRun("Destination value")?.text(), "LONDON")
            XCTAssertEqual(instance.numberProperty(fromPath: "travelStyle")?.value, style.riveValue)
            XCTAssertEqual(instance.booleanProperty(fromPath: "reduceMotion")?.value, true)
        }
        state.skipIntroduction()
        state.next()
        controller.update(from: state, reduceMotion: false)
        model.stateMachine?.advance(by: 0)
        XCTAssertEqual(instance.booleanProperty(fromPath: "isComplete")?.value, true)
        XCTAssertEqual(instance.numberProperty(fromPath: "progress")?.value, 100)
    }

    @MainActor
    func testRiveAirportDisplayCyclesEveryCityAndCodeAndLoopsAfterCompletion() throws {
        let controller = TravelRiveController()
        controller.load()
        XCTAssertNil(controller.errorDescription)
        let model = try XCTUnwrap(controller.viewModel?.riveModel)
        let machine = try XCTUnwrap(model.stateMachine)
        let state = TravelOnboardingState()
        state.skipIntroduction()
        state.next()
        controller.update(from: state, reduceMotion: false)

        func advance(_ seconds: Double) {
            for _ in 0..<Int((seconds * 60).rounded()) {
                machine.advance(by: 1.0 / 60.0)
                model.artboard.advance(by: 1.0 / 60.0)
            }
        }
        func assertDestination(_ code: String, _ city: String, line: UInt = #line) {
            XCTAssertEqual(model.artboard.textRun("Destination value")?.text(), city, line: line)
            let visibleCode = (1...3).compactMap {
                model.artboard.textRun("Airport \($0) Top turning leaf value")?.text()
            }.joined()
            XCTAssertEqual(visibleCode, code, line: line)
        }
        advance(0.1)
        assertDestination("LHR", "LONDON")
        for (code, city) in [("JFK", "NEW YORK"), ("NBO", "NAIROBI"), ("CPT", "CAPE TOWN"), ("DUB", "DUBLIN"), ("LHR", "LONDON")] {
            advance(6)
            assertDestination(code, city)
        }
        // Reduce Motion selects the settled London pose and stops cycling.
        controller.update(from: state, reduceMotion: true)
        advance(0.1)
        assertDestination("LHR", "LONDON")
        advance(14)
        assertDestination("LHR", "LONDON")
    }

    func testStockSessionPathsKeepTheirIdentitiesAndJoinThroughoutRangeTransitions() throws {
        let ranges = XStockRange.allCases.map { XStockReference.series(for: $0) }
        let ids = try XCTUnwrap(ranges.first).samples.map(\.id)
        for series in ranges {
            XCTAssertEqual(series.regularLineSamples.map(\.id), ids)
            XCTAssertEqual(series.afterHoursLineSamples.map(\.id), ids)
        }

        for source in ranges {
            for destination in ranges {
                let sourceClose = try XCTUnwrap(source.regularLineSamples.last)
                let destinationClose = try XCTUnwrap(destination.regularLineSamples.last)
                let sourceAfterHoursStart = try XCTUnwrap(source.afterHoursLineSamples.first)
                let destinationAfterHoursStart = try XCTUnwrap(destination.afterHoursLineSamples.first)
                for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
                    func interpolate(_ start: Double, _ end: Double) -> Double {
                        start + (end - start) * progress
                    }
                    let boundary = interpolate(sourceClose.fraction, destinationClose.fraction)
                    XCTAssertEqual(boundary, interpolate(sourceAfterHoursStart.fraction, destinationAfterHoursStart.fraction), accuracy: 0.000001)
                    XCTAssertEqual(interpolate(sourceClose.price, destinationClose.price), interpolate(sourceAfterHoursStart.price, destinationAfterHoursStart.price), accuracy: 0.000001)
                    for (start, end) in zip(source.regularLineSamples, destination.regularLineSamples) {
                        XCTAssertLessThanOrEqual(interpolate(start.fraction, end.fraction), boundary + 0.000001)
                    }
                    for (start, end) in zip(source.afterHoursLineSamples, destination.afterHoursLineSamples) {
                        XCTAssertGreaterThanOrEqual(interpolate(start.fraction, end.fraction), boundary - 0.000001)
                    }
                }
            }
        }
    }

    func testStockScrubbingClampsToEndpointsAndPreservesSessionBoundary() throws {
        for range in XStockRange.allCases {
            let series = XStockReference.series(for: range)
            XCTAssertEqual(series.sample(at: -1).id, series.samples.first?.id)
            XCTAssertEqual(series.sample(at: 2).id, series.samples.last?.id)
            XCTAssertEqual(try XCTUnwrap(series.regularSamples.last).price, 198.87, accuracy: 0.0001)
            if let afterHoursStart = series.afterHoursSamples.first {
                XCTAssertEqual(afterHoursStart.id, series.regularSamples.last?.id)
                XCTAssertEqual(afterHoursStart.price, 198.87, accuracy: 0.0001)
            }
            for sample in series.samples {
                XCTAssertTrue(sample.price.isFinite)
                XCTAssertTrue(series.domain.contains(sample.price))
            }
        }
        XCTAssertEqual(XStockReference.priceLabel(198.87), "$198.87")
    }

    func testStockCandlesContainTheirBodiesAndHaveDistinctIntervals() {
        for range in XStockRange.allCases {
            let series = XStockReference.series(for: range)
            for (style, count) in [(XStockChartStyle.thirtyMinutes, 104), (.hour, 52), (.fourHours, 13)] {
                let candles = series.candles(for: style)
                XCTAssertEqual(candles.count, count)
                XCTAssertEqual(Set(candles.map(\.id)).count, count)
                for candle in candles {
                    XCTAssertGreaterThanOrEqual(candle.high, max(candle.open, candle.close))
                    XCTAssertLessThanOrEqual(candle.low, min(candle.open, candle.close))
                    XCTAssertTrue(candle.close.isFinite)
                }
            }
        }
    }

    func testGrokRandomReactionsAreStableAcrossRedrawsAndIndependentBetweenBots() {
        let tracks = GrokBot.allCases.map { GrokAutonomousReactions(seed: UInt64($0.rawValue + 1) * 1_234_567) }
        var expressions: [[Double]] = []
        var blinks: [[Double]] = []
        for track in tracks {
            var expressionSamples: [Double] = []
            var blinkSamples: [Double] = []
            for time in stride(from: 0.0, through: 60, by: 0.1) {
                let pose = grokPoseValues(track.pose(at: time))
                XCTAssertEqual(pose, grokPoseValues(track.pose(at: time)), "A redraw must preserve the pose")
                expressionSamples.append(contentsOf: pose)
                blinkSamples.append(track.blinkAmount(at: time))
            }
            expressions.append(expressionSamples)
            blinks.append(blinkSamples)
        }
        XCTAssertEqual(Set(expressions).count, 9, "Each mascot needs its own expression sequence")
        XCTAssertEqual(Set(blinks).count, 9, "Blinks must also have independent timing")
    }

    func testGrokRandomExpressionsAndBlinksTransitionSmoothly() {
        for bot in GrokBot.allCases {
            let track = GrokAutonomousReactions(seed: UInt64(bot.rawValue + 1) * 1_234_567)
            var previous = grokPoseValues(GrokEyePose.pose(for: bot, reaction: .automatic, time: 0, autonomousReactions: track))
            for time in stride(from: 1.0 / 120, through: 30, by: 1.0 / 120) {
                let pose = GrokEyePose.pose(for: bot, reaction: .automatic, time: time, autonomousReactions: track)
                let values = grokPoseValues(pose)
                for (before, after) in zip(previous, values) {
                    XCTAssertTrue(after.isFinite)
                    XCTAssertLessThan(abs(after - before), 0.12, "\(bot.name) jumped at \(time)")
                }
                XCTAssertGreaterThan(pose.height, 0)
                previous = values
            }
        }
    }

    private func grokPoseValues(_ pose: GrokEyePose) -> [Double] {
        [pose.x, pose.y, pose.width, pose.height, pose.separation, pose.leftTilt, pose.rightTilt]
    }

    func testGrokDriftRemainsContinuousAcrossReturnAndLoopBoundaries() {
        let size = CGSize(width: 390, height: 844)
        let duration = 9.617
        let step = 0.001

        for bot in GrokBot.allCases {
            for boundary in [duration, 3 * duration, 4 * duration] {
                let before = bot.position(at: boundary - step, in: size)
                let center = bot.position(at: boundary, in: size)
                let after = bot.position(at: boundary + step, in: size)
                XCTAssertLessThan(hypot(after.x - before.x, after.y - before.y), 0.03, "\(bot.name) must not jump at \(boundary)")
                let velocityBefore = CGPoint(x: (center.x - before.x) / step, y: (center.y - before.y) / step)
                let velocityAfter = CGPoint(x: (after.x - center.x) / step, y: (after.y - center.y) / step)
                XCTAssertEqual(velocityBefore.x, velocityAfter.x, accuracy: 0.01)
                XCTAssertEqual(velocityBefore.y, velocityAfter.y, accuracy: 0.01)
            }
        }
    }

    func testFlexibleItemsShareRemainingSpaceWithoutResizingFixedItems() {
        let result = FlowArrangement(sizes: [
            CGSize(width: 100, height: 80),
            CGSize(width: 80, height: 100),
            CGSize(width: 120, height: 60)
        ], width: 400, spacing: 10, flexibleIndices: [1, 2])
        XCTAssertEqual(result.frames.map(\.width), [100, 120, 160])
        XCTAssertEqual(result.frames[2].maxX, 400)
        XCTAssertEqual(result.size.height, 100)
    }

    func testFlexibleItemsWrapAtMinimumAndFillTheirOwnRows() {
        let result = FlowArrangement(sizes: [
            CGSize(width: 180, height: 100),
            CGSize(width: 120, height: 150)
        ], width: 300, spacing: 12, flexibleIndices: [0, 1])
        XCTAssertEqual(result.frames.map(\.width), [300, 300])
        XCTAssertEqual(result.frames[1].minY, 112)
        XCTAssertEqual(result.size.height, 262)
    }

    func testFlexibleMinimumSurvivesNarrowAndUnspecifiedProposals() {
        let sizes = [CGSize(width: 180, height: 100)]
        let narrow = FlowArrangement(sizes: sizes, width: 100, spacing: 12, flexibleIndices: [0])
        let unspecified = FlowArrangement(sizes: sizes, width: nil, spacing: 12, flexibleIndices: [0])
        XCTAssertEqual(narrow.size.width, 180)
        XCTAssertEqual(narrow.frames[0].width, 180)
        XCTAssertEqual(unspecified.frames[0].width, 180)
    }

    func testFlowWrapsBelowTallestItemAndAllowsExactFit() {
        let result = FlowArrangement(sizes: [
            CGSize(width: 100, height: 40),
            CGSize(width: 90, height: 120),
            CGSize(width: 60, height: 30)
        ], width: 200, spacing: 10)
        XCTAssertEqual(result.frames[1].origin, CGPoint(x: 110, y: 0))
        XCTAssertEqual(result.frames[2].origin, CGPoint(x: 0, y: 130))
        XCTAssertEqual(result.size, CGSize(width: 200, height: 160))
    }

    func testFlowEmptyAndUnconstrainedSizes() {
        XCTAssertEqual(FlowArrangement(sizes: [], width: 200, spacing: 10).size.height, 0)
        let result = FlowArrangement(sizes: [CGSize(width: 80, height: 40), CGSize(width: 90, height: 60)], width: nil, spacing: 10)
        XCTAssertEqual(result.size, CGSize(width: 180, height: 60))
    }

    func testInsertionUsesRowsIncludingSpaceBelowShortItems() {
        let frames = FlowArrangement(sizes: [
            CGSize(width: 100, height: 40),
            CGSize(width: 90, height: 120),
            CGSize(width: 60, height: 30)
        ], width: 200, spacing: 10).frames
        XCTAssertEqual(FlowArrangement.insertionIndex(at: CGPoint(x: 20, y: 100), frames: frames), 0)
        XCTAssertEqual(FlowArrangement.insertionIndex(at: CGPoint(x: 130, y: 100), frames: frames), 1)
        XCTAssertEqual(FlowArrangement.insertionIndex(at: CGPoint(x: 10, y: 140), frames: frames), 2)
        XCTAssertEqual(FlowArrangement.insertionIndex(at: CGPoint(x: 190, y: 140), frames: frames), 3)
        XCTAssertEqual(FlowArrangement.insertionIndex(at: CGPoint(x: 0, y: 200), frames: frames), 3)
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
