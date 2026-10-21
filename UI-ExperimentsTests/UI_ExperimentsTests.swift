//
//  UI_ExperimentsTests.swift
//  UI-ExperimentsTests
//
//  Created by Edwin Bosire on 25/08/2024.
//

import XCTest
@testable import UI_Experiments

final class UI_ExperimentsTests: XCTestCase {

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
