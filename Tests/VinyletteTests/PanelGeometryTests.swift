import XCTest

@testable import Vinylette

final class PanelGeometryTests: XCTestCase {
    private let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)

    func testFullyVisibleFrameKeepsItsOrigin() {
        let frame = CGRect(x: 100, y: 200, width: 300, height: 264)

        let origin = PanelGeometry.clampedOrigin(of: frame, within: [screen])

        XCTAssertEqual(origin, CGPoint(x: 100, y: 200))
    }

    func testFramePastTheTopRightCornerIsClampedInside() {
        let frame = CGRect(x: 1800, y: 1000, width: 300, height: 264)

        let origin = PanelGeometry.clampedOrigin(of: frame, within: [screen])

        XCTAssertEqual(origin, CGPoint(x: 1620, y: 816))
    }

    func testFullyOffscreenFrameMovesOntoTheNearestScreen() {
        let frame = CGRect(x: 5000, y: -900, width: 300, height: 264)

        let origin = PanelGeometry.clampedOrigin(of: frame, within: [screen])

        XCTAssertEqual(origin, CGPoint(x: 1620, y: 0))
    }

    func testPrefersTheScreenWithTheLargerOverlap() {
        let left = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let right = CGRect(x: 1000, y: 0, width: 1000, height: 800)
        // 40 points overlap the left screen, 260 points the right one.
        let frame = CGRect(x: 960, y: 100, width: 300, height: 264)

        let origin = PanelGeometry.clampedOrigin(of: frame, within: [left, right])

        XCTAssertEqual(origin, CGPoint(x: 1000, y: 100), "Panel belongs to the right screen")
    }

    func testChoosesNearestScreenWhenOffscreenBetweenTwoDisplays() {
        let left = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let farRight = CGRect(x: 5000, y: 0, width: 1000, height: 800)
        let frame = CGRect(x: 1200, y: 900, width: 300, height: 264)

        let origin = PanelGeometry.clampedOrigin(of: frame, within: [left, farRight])

        XCTAssertEqual(origin, CGPoint(x: 700, y: 536))
    }

    func testFrameLargerThanTheScreenPinsToTheScreenOrigin() {
        let small = CGRect(x: 0, y: 0, width: 200, height: 200)
        let frame = CGRect(x: 500, y: 500, width: 300, height: 264)

        let origin = PanelGeometry.clampedOrigin(of: frame, within: [small])

        XCTAssertEqual(origin, CGPoint(x: 0, y: 0))
    }

    func testNoScreensYieldsNoOrigin() {
        let frame = CGRect(x: 0, y: 0, width: 300, height: 264)

        XCTAssertNil(PanelGeometry.clampedOrigin(of: frame, within: []))
    }
}

/// The shared tonearm anchors: every design must place the stylus on the same
/// groove of its record, regardless of the record's size and position.
final class WidgetLayoutAnchorTests: XCTestCase {
    func testDeckIsTheUnscaledReference() {
        XCTAssertEqual(WidgetLayout.tonearmScale(on: WidgetLayout.deckDisc), 1)
    }

    func testTonearmScaleFollowsDiscDiameter() {
        let scale = WidgetLayout.tonearmScale(on: WidgetLayout.sleeveDisc)

        XCTAssertEqual(
            scale,
            WidgetLayout.sleeveDisc.diameter / WidgetLayout.deckDisc.diameter,
            accuracy: 0.0001
        )
    }

    func testStylusLandsOnTheSameGrooveInEveryDesign() {
        func relativeAnchor(on disc: WidgetLayout.DiscPlacement) -> CGPoint {
            let offset = WidgetLayout.tonearmOffset(on: disc)
            // The arm position relative to the disc center, normalized by the
            // disc radius: identical values mean the same groove.
            return CGPoint(
                x: (offset.x - disc.center.x) / (disc.diameter / 2),
                y: (offset.y - disc.center.y) / (disc.diameter / 2)
            )
        }

        let deck = relativeAnchor(on: WidgetLayout.deckDisc)
        let sleeve = relativeAnchor(on: WidgetLayout.sleeveDisc)

        XCTAssertEqual(deck.x, sleeve.x, accuracy: 0.0001)
        XCTAssertEqual(deck.y, sleeve.y, accuracy: 0.0001)
    }

    func testSleeveCompositionStaysInsideTheContentBounds() {
        let disc = WidgetLayout.sleeveDisc
        let armOffset = WidgetLayout.tonearmOffset(on: disc)
        let armScale = WidgetLayout.tonearmScale(on: disc)
        // The tonearm view is 110 points wide around its center.
        let rightmostPoint = armOffset.x + armScale * 55

        XCTAssertLessThanOrEqual(
            rightmostPoint,
            WidgetLayout.panelSize.width / 2,
            "The tonearm must not be clipped by the window edge"
        )
    }
}
