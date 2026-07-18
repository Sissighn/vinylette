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
        setFrameOrigin(NSPoint(x: visible.maxX - frame.width - margin,
                               y: visible.maxY - frame.height - margin))
    }

    /// Keeps the complete widget reachable after a display is unplugged or
    /// its resolution/arrangement changes.
    private func clampToVisibleScreen() {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }

        let currentFrame = frame
        let intersections = screens.map {
            ($0, Self.area(of: currentFrame.intersection($0.visibleFrame)))
        }

        let targetScreen: NSScreen
        if let bestVisible = intersections.max(by: { $0.1 < $1.1 }), bestVisible.1 > 0 {
            targetScreen = bestVisible.0
        } else {
            let center = NSPoint(x: currentFrame.midX, y: currentFrame.midY)
            targetScreen = screens.min {
                Self.squaredDistance(from: center, to: $0.visibleFrame)
                    < Self.squaredDistance(from: center, to: $1.visibleFrame)
            } ?? screens[0]
        }

        let visible = targetScreen.visibleFrame
        let maxX = max(visible.minX, visible.maxX - currentFrame.width)
        let maxY = max(visible.minY, visible.maxY - currentFrame.height)
        let clampedOrigin = NSPoint(
            x: min(max(currentFrame.minX, visible.minX), maxX),
            y: min(max(currentFrame.minY, visible.minY), maxY)
        )

        guard clampedOrigin != currentFrame.origin else { return }
        setFrameOrigin(clampedOrigin)
    }

    private static func area(of rect: NSRect) -> CGFloat {
        guard !rect.isNull, !rect.isEmpty else { return 0 }
        return rect.width * rect.height
    }

    private static func squaredDistance(from point: NSPoint, to rect: NSRect) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return dx * dx + dy * dy
    }
}
