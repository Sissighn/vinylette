import AppKit
import SwiftUI

/// Wires the pieces together: floating panel, menu bar item, Spotify polling.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: FloatingPanel!
    private var statusBar: StatusBarController!
    private let spotify = SpotifyController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        panel = FloatingPanel(
            rootView: VinylView().environmentObject(spotify),
            size: NSSize(width: 300, height: 340)
        )
        panel.orderFrontRegardless()

        statusBar = StatusBarController(
            onToggle: { [weak self] in self?.togglePanel() },
            onQuit: { NSApp.terminate(nil) }
        )

        spotify.start()
    }

    private func togglePanel() {
        if panel.isVisible { panel.orderOut(nil) } else { panel.orderFrontRegardless() }
    }
}
