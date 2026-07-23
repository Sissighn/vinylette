import CoreGraphics

/// Single source of truth for the widget's fixed dimensions and motion.
enum WidgetLayout {
    /// Size of the widget content (deck or sleeve arrangement).
    static let contentSize = CGSize(width: 276, height: 240)

    /// Breathing room around the content, inside the window.
    static let contentPadding: CGFloat = 12

    /// Window size: content plus padding on every side.
    static var panelSize: CGSize {
        CGSize(
            width: contentSize.width + 2 * contentPadding,
            height: contentSize.height + 2 * contentPadding)
    }

    /// Record spin speed in degrees per second.
    static let spinDegreesPerSecond: Double = 50

    /// Frame duration of the spin loop (~60 fps).
    static let spinFrameNanoseconds: UInt64 = 16_666_667

    /// Duration of the cover cross-fade when a new track's artwork arrives.
    static let artworkCrossfadeSeconds: Double = 0.6

    // MARK: - Shared disc and tonearm anchors

    /// Where a design places its record inside the widget content.
    struct DiscPlacement {
        let center: CGPoint
        let diameter: CGFloat
    }

    static let deckDisc = DiscPlacement(center: CGPoint(x: -18, y: 0), diameter: 190)
    static let sleeveDisc = DiscPlacement(center: CGPoint(x: 38, y: 0), diameter: 165)
    static let sleeveCoverCenter = CGPoint(x: -50, y: 0)

    /// The deck is the reference composition: every other design derives its
    /// tonearm placement from the arm's position relative to this disc, so the
    /// stylus always lands on the same groove regardless of record size.
    private static let referenceDisc = deckDisc
    private static let referenceTonearmOffset = CGPoint(x: 55, y: -14)

    static func tonearmScale(on disc: DiscPlacement) -> CGFloat {
        disc.diameter / referenceDisc.diameter
    }

    static func tonearmOffset(on disc: DiscPlacement) -> CGPoint {
        let scale = tonearmScale(on: disc)
        return CGPoint(
            x: disc.center.x + scale * (referenceTonearmOffset.x - referenceDisc.center.x),
            y: disc.center.y + scale * (referenceTonearmOffset.y - referenceDisc.center.y)
        )
    }
}
