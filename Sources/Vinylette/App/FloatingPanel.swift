import AppKit
import SwiftUI

/// Borderless, non-activating panel that lives on the desktop like a widget:
/// above the wallpaper and icons, but beneath every app window.
final class FloatingPanel: NSPanel {
    private static let frameAutosaveName = NSWindow.FrameAutosaveName("VinyletteWidget")

    private var occlusionObserver: NSObjectProtocol?
    private var screenObserver: NSObjectProtocol?

    init<Content: View>(rootView: Content, size: NSSize, visibility: PanelVisibility) {
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

        // Restore the last dragged position. `force` also restores borderless,
        // non-resizable panels; first launch still uses the top-right default.
        let restoredFrame = setFrameUsingName(Self.frameAutosaveName, force: true)
        setFrameAutosaveName(Self.frameAutosaveName)
        if !restoredFrame {
            positionTopTrailing(margin: 24)
        }
        clampToVisibleScreen()

        occlusionObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification,
            object: self, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            visibility.isVisible = self.occlusionState.contains(.visible)
        }

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.clampToVisibleScreen()
        }
    }

    deinit {
        if let occlusionObserver {
            NotificationCenter.default.removeObserver(occlusionObserver)
        }
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }

    /// Top-right corner of the main screen with a little margin.
    private func positionTopTrailing(margin: CGFloat) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        setFrameOrigin(
            NSPoint(
                x: visible.maxX - frame.width - margin,
                y: visible.maxY - frame.height - margin))
    }

    /// Keeps the complete widget reachable after a display is unplugged or
    /// its resolution/arrangement changes. The math lives in `PanelGeometry`.
    private func clampToVisibleScreen() {
        let visibleFrames = NSScreen.screens.map(\.visibleFrame)
        guard let clampedOrigin = PanelGeometry.clampedOrigin(of: frame, within: visibleFrames),
            clampedOrigin != frame.origin
        else { return }
        setFrameOrigin(clampedOrigin)
    }
}
