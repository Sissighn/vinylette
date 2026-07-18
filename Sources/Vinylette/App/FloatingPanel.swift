import AppKit
import SwiftUI

/// Borderless, non-activating panel that floats above all windows,
/// follows every Space, and can be dragged anywhere by its background.
final class FloatingPanel: NSPanel {
    init<Content: View>(rootView: Content, size: NSSize) {
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
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
