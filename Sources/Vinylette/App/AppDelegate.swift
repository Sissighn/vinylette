import AppKit
import SwiftUI

/// Wires the pieces together: floating panel, menu bar item, Spotify updates.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: FloatingPanel!
    private var statusBar: StatusBarController!
    private let spotify = SpotifyController()
    private let panelVisibility = PanelVisibility()

    func applicationDidFinishLaunching(_ notification: Notification) {
        panel = FloatingPanel(
            rootView: VinylView()
                .environmentObject(spotify)
                .environmentObject(panelVisibility),
            size: WidgetLayout.panelSize,
            visibility: panelVisibility
        )
        panel.orderFrontRegardless()

        statusBar = StatusBarController(
            spotify: spotify,
            onToggle: { [weak self] in self?.togglePanel() },
            onQuit: { NSApp.terminate(nil) }
        )

        spotify.start()
    }

    private func togglePanel() {
        if panel.isVisible { panel.orderOut(nil) } else { panel.orderFrontRegardless() }
    }
}
