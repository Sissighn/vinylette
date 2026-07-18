import CoreGraphics

/// Single source of truth for the widget's fixed dimensions and motion.
enum WidgetLayout {
    /// Size of the widget content (deck or sleeve arrangement).
    static let contentSize = CGSize(width: 276, height: 240)

    /// Breathing room around the content, inside the window.
    static let contentPadding: CGFloat = 12

    /// Window size: content plus padding on every side.
    static var panelSize: CGSize {
        CGSize(width: contentSize.width + 2 * contentPadding,
               height: contentSize.height + 2 * contentPadding)
    }

    /// Record spin speed in degrees per second.
    static let spinDegreesPerSecond: Double = 50

    /// Frame duration of the spin loop (~60 fps).
    static let spinFrameNanoseconds: UInt64 = 16_666_667
}
