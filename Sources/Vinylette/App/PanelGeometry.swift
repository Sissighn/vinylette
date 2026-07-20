import CoreGraphics

/// Pure screen-placement math for the floating panel. Free of AppKit types so
/// every rule is directly unit-testable.
enum PanelGeometry {
    /// Returns the origin that keeps `frame` fully inside the most suitable of
    /// `visibleFrames`: the screen with the largest current overlap, or the
    /// nearest screen when the panel is completely off screen. Returns `nil`
    /// when no screen information is available.
    static func clampedOrigin(of frame: CGRect, within visibleFrames: [CGRect]) -> CGPoint? {
        guard let target = targetFrame(for: frame, in: visibleFrames) else { return nil }

        let maxX = max(target.minX, target.maxX - frame.width)
        let maxY = max(target.minY, target.maxY - frame.height)
        return CGPoint(
            x: min(max(frame.minX, target.minX), maxX),
            y: min(max(frame.minY, target.minY), maxY)
        )
    }

    /// The screen the panel should live on: largest visible overlap first,
    /// shortest distance as the tie-breaker for fully off-screen frames.
    private static func targetFrame(for frame: CGRect, in visibleFrames: [CGRect]) -> CGRect? {
        guard !visibleFrames.isEmpty else { return nil }

        let overlaps = visibleFrames.map { ($0, area(of: frame.intersection($0))) }
        if let bestVisible = overlaps.max(by: { $0.1 < $1.1 }), bestVisible.1 > 0 {
            return bestVisible.0
        }

        let center = CGPoint(x: frame.midX, y: frame.midY)
        return visibleFrames.min {
            squaredDistance(from: center, to: $0) < squaredDistance(from: center, to: $1)
        }
    }

    private static func area(of rect: CGRect) -> CGFloat {
        guard !rect.isNull, !rect.isEmpty else { return 0 }
        return rect.width * rect.height
    }

    private static func squaredDistance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return dx * dx + dy * dy
    }
}
