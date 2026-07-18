import AppKit
import SwiftUI

/// Borderless, non-activating panel that lives on the desktop like a widget:
/// above the wallpaper and icons, but beneath every app window.
final class FloatingPanel: NSPanel {
    init<Content: View>(rootView: Content, size: NSSize) {
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        // One step below normal app windows: apps cover the widget, but it
        // stays above the desktop, its icons, and the system widget layer.
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.normalWindow)) - 1)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        hidesOnDeactivate = false
        contentView = NSHostingView(rootView: rootView)
        positionTopTrailing(margin: 24)
    }

    /// Top-right corner of the main screen with a little margin.
    private func positionTopTrailing(margin: CGFloat) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        setFrameOrigin(NSPoint(x: visible.maxX - frame.width - margin,
                               y: visible.maxY - frame.height - margin))
    }
}
