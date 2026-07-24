import AppKit
import ServiceManagement

/// Menu bar entry with live playback info, widget settings and app actions.
@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let spotify: SpotifyController
    private let settings: WidgetSettings
    private let launchAtLogin: LaunchAtLogin
    private let isWidgetVisible: () -> Bool
    private let onToggle: () -> Void
    private let onQuit: () -> Void

    private let songItem = NSMenuItem()
    private let playPauseItem = NSMenuItem()
    private let previousItem = NSMenuItem()
    private let nextItem = NSMenuItem()
    private let repeatItem = NSMenuItem()
    private let toggleItem = NSMenuItem()
    private let launchAtLoginItem = NSMenuItem()
    private var designItems: [WidgetDesign: NSMenuItem] = [:]

    init(
        spotify: SpotifyController,
        settings: WidgetSettings = WidgetSettings(),
        launchAtLogin: LaunchAtLogin = LaunchAtLogin(),
        isWidgetVisible: @escaping () -> Bool,
        onToggle: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.spotify = spotify
        self.settings = settings
        self.launchAtLogin = launchAtLogin
        self.isWidgetVisible = isWidgetVisible
        self.onToggle = onToggle
        self.onQuit = onQuit
        super.init()

        statusItem.button?.image = MenuBarVinylIcon.make()
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.setAccessibilityLabel("Vinylette")
        statusItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        songItem.isEnabled = false
        menu.addItem(songItem)
        menu.addItem(.separator())

        configurePlaybackItem(
            playPauseItem,
            title: L10n.Menu.play,
            symbol: "play.fill",
            action: #selector(playPause)
        )
        configurePlaybackItem(
            previousItem,
            title: L10n.Menu.previous,
            symbol: "backward.fill",
            action: #selector(previousTrack)
        )
        configurePlaybackItem(
            nextItem,
            title: L10n.Menu.next,
            symbol: "forward.fill",
            action: #selector(nextTrack)
        )
        configurePlaybackItem(
            repeatItem,
            title: L10n.Menu.repeatPlayback,
            symbol: "repeat",
            action: #selector(toggleRepeat)
        )
        menu.addItem(playPauseItem)
        menu.addItem(previousItem)
        menu.addItem(nextItem)
        menu.addItem(repeatItem)
        menu.addItem(.separator())

        toggleItem.title = L10n.Menu.hideWidget
        toggleItem.action = #selector(toggle)
        toggleItem.keyEquivalent = "v"
        toggleItem.target = self
        menu.addItem(toggleItem)

        let designItem = NSMenuItem(title: L10n.Menu.design, action: nil, keyEquivalent: "")
        let designMenu = NSMenu(title: L10n.Menu.design)
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

        launchAtLoginItem.title = L10n.Menu.launchAtLogin
        launchAtLoginItem.action = #selector(toggleLaunchAtLogin)
        launchAtLoginItem.target = self
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: L10n.Menu.quit,
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        return menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        updateSongItem()
        updatePlaybackItems()
        updateToggleItem()
        updateDesignItems()
        updateLaunchAtLoginItem()
    }

    private func configurePlaybackItem(
        _ item: NSMenuItem,
        title: String,
        symbol: String,
        action: Selector
    ) {
        item.title = title
        item.action = action
        item.target = self
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        item.image?.isTemplate = true
    }

    private func updatePlaybackItems() {
        let canControl = spotify.state.canControlPlayback
        for item in [playPauseItem, previousItem, nextItem, repeatItem] {
            item.isEnabled = canControl
        }

        let isPlaying = spotify.state.isPlaying
        playPauseItem.title = isPlaying ? L10n.Menu.pause : L10n.Menu.play
        playPauseItem.image = NSImage(
            systemSymbolName: isPlaying ? "pause.fill" : "play.fill",
            accessibilityDescription: playPauseItem.title
        )
        playPauseItem.image?.isTemplate = true
        repeatItem.state = spotify.state.isRepeating ? .on : .off
    }

    private func updateToggleItem() {
        toggleItem.title = isWidgetVisible() ? L10n.Menu.hideWidget : L10n.Menu.showWidget
    }

    private func updateSongItem() {
        guard let track = spotify.state.track, !track.name.isEmpty else {
            songItem.title = L10n.Menu.noTrack
            return
        }

        let artist = track.artist.isEmpty ? "" : " — \(track.artist)"
        songItem.title = "♫  \(track.name)\(artist)"
    }

    private func updateDesignItems() {
        let selected = settings.design
        for (design, item) in designItems {
            item.state = design == selected ? .on : .off
        }
    }

    private func updateLaunchAtLoginItem() {
        launchAtLoginItem.state = launchAtLogin.menuState
    }

    @objc private func selectDesign(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
            let design = WidgetDesign(rawValue: rawValue)
        else { return }
        settings.design = design
        updateDesignItems()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            try launchAtLogin.toggle()
            updateLaunchAtLoginItem()
        } catch {
            showServiceError(error)
        }
    }

    @objc private func playPause() { spotify.playPause() }
    @objc private func previousTrack() { spotify.previousTrack() }
    @objc private func nextTrack() { spotify.nextTrack() }
    @objc private func toggleRepeat() { spotify.toggleRepeat() }

    private func showServiceError(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.ServiceError.title
        alert.informativeText =
            "\(L10n.ServiceError.message)\n\n\(error.localizedDescription)"
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc private func toggle() { onToggle() }
    @objc private func quit() { onQuit() }
}
