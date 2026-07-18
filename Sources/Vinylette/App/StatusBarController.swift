import AppKit
import ServiceManagement

/// Menu bar entry with live playback info, widget settings and app actions.
@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let spotify: SpotifyController
    private let onToggle: () -> Void
    private let onQuit: () -> Void

    private let songItem = NSMenuItem()
    private let launchAtLoginItem = NSMenuItem()
    private var designItems: [WidgetDesign: NSMenuItem] = [:]

    init(spotify: SpotifyController,
         onToggle: @escaping () -> Void,
         onQuit: @escaping () -> Void) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.spotify = spotify
        self.onToggle = onToggle
        self.onQuit = onQuit
        super.init()

        statusItem.button?.title = "♫"
        statusItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        songItem.isEnabled = false
        menu.addItem(songItem)
        menu.addItem(.separator())

        let toggleItem = NSMenuItem(
            title: L10n.text("menu.toggleWidget"),
            action: #selector(toggle),
            keyEquivalent: "v"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        let designItem = NSMenuItem(title: L10n.text("menu.design"), action: nil, keyEquivalent: "")
        let designMenu = NSMenu(title: L10n.text("menu.design"))
        for design in WidgetDesign.allCases {
            let item = NSMenuItem(
                title: design.displayName,
                action: #selector(selectDesign(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = design.rawValue
            designMenu.addItem(item)
            designItems[design] = item
        }
        designItem.submenu = designMenu
        menu.addItem(designItem)

        launchAtLoginItem.title = L10n.text("menu.launchAtLogin")
        launchAtLoginItem.action = #selector(toggleLaunchAtLogin)
        launchAtLoginItem.target = self
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: L10n.text("menu.quit"),
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        return menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        updateSongItem()
        updateDesignItems()
        updateLaunchAtLoginItem()
    }

    private func updateSongItem() {
        guard spotify.isRunning, !spotify.trackName.isEmpty else {
            songItem.title = L10n.text("menu.noTrack")
            return
        }

        let artist = spotify.artistName.isEmpty ? "" : " — \(spotify.artistName)"
        songItem.title = "♫  \(spotify.trackName)\(artist)"
    }

    private func updateDesignItems() {
        let selectedRaw = UserDefaults.standard.string(forKey: "widgetDesign")
            ?? WidgetDesign.classicLabel.rawValue
        for (design, item) in designItems {
            item.state = design.rawValue == selectedRaw ? .on : .off
        }
    }

    private func updateLaunchAtLoginItem() {
        switch SMAppService.mainApp.status {
        case .enabled:
            launchAtLoginItem.state = .on
        case .requiresApproval:
            launchAtLoginItem.state = .mixed
        case .notRegistered, .notFound:
            launchAtLoginItem.state = .off
        @unknown default:
            launchAtLoginItem.state = .off
        }
    }

    @objc private func selectDesign(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              WidgetDesign(rawValue: rawValue) != nil else { return }
        UserDefaults.standard.set(rawValue, forKey: "widgetDesign")
        updateDesignItems()
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            switch service.status {
            case .enabled:
                try service.unregister()
            case .requiresApproval:
                SMAppService.openSystemSettingsLoginItems()
            case .notRegistered, .notFound:
                try service.register()
            @unknown default:
                try service.register()
            }
            updateLaunchAtLoginItem()
        } catch {
            showServiceError(error)
        }
    }

    private func showServiceError(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.text("service.error.title")
        alert.informativeText = "\(L10n.text("service.error.message"))\n\n\(error.localizedDescription)"
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc private func toggle() { onToggle() }
    @objc private func quit() { onQuit() }
}
