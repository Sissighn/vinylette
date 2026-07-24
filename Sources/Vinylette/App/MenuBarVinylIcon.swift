import AppKit

/// A code-native monochrome record icon for the menu bar. As an AppKit
/// template image it automatically follows macOS appearance and contrast.
enum MenuBarVinylIcon {
    static func make() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.black.setStroke()
            NSColor.black.setFill()

            let outer = NSBezierPath(ovalIn: rect.insetBy(dx: 1.25, dy: 1.25))
            outer.lineWidth = 1.5
            outer.stroke()

            for inset: CGFloat in [4.1, 6.1] {
                let groove = NSBezierPath(ovalIn: rect.insetBy(dx: inset, dy: inset))
                groove.lineWidth = 0.75
                groove.stroke()
            }

            NSBezierPath(
                ovalIn: NSRect(x: 7.1, y: 7.1, width: 3.8, height: 3.8)
            ).fill()

            let glint = NSBezierPath()
            glint.appendArc(
                withCenter: NSPoint(x: 9, y: 9),
                radius: 6.2,
                startAngle: 112,
                endAngle: 158
            )
            glint.lineWidth = 1.4
            glint.lineCapStyle = .round
            glint.stroke()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Vinylette"
        return image
    }
}
