import AppKit
import Combine
import os

/// Publishes Spotify's playback state to the UI.
///
/// Primary source: Spotify's `com.spotify.client.PlaybackStateChanged`
/// distributed notification — instant updates, no polling. AppleScript is
/// only used for the initial state at launch, artwork lookups, and playback
/// commands. No OAuth, no API keys — Spotify just needs to be running.
@MainActor
final class SpotifyController: ObservableObject {
    @Published var isRunning = false
    @Published var isPlaying = false
    @Published var trackName = ""
    @Published var artistName = ""
    @Published var artwork: NSImage?
    /// True when macOS blocks Apple Events to Spotify because the
    /// Automation permission is missing.
    @Published var permissionDenied = false

    private var artworkURLString = ""
    private let logger = Logger(subsystem: "com.setayesh.vinylette", category: "spotify")

    private static let spotifyBundleID = "com.spotify.client"
    private static let playbackChanged = Notification.Name("com.spotify.client.PlaybackStateChanged")

    func start() {
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(playbackStateChanged(_:)),
            name: Self.playbackChanged, object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(applicationTerminated(_:)),
            name: NSWorkspace.didTerminateApplicationNotification, object: nil
        )
        fetchCurrentState() // one-time bootstrap; afterwards fully event-driven
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // MARK: - Event handling

    @objc private func playbackStateChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let track = SpotifyTrack.from(userInfo: userInfo) else {
            logger.warning("Playback notification without a readable payload")
            return
        }
        isRunning = true
        apply(track)
        refreshArtwork()
    }

    @objc private func applicationTerminated(_ notification: Notification) {
        let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        guard app?.bundleIdentifier == Self.spotifyBundleID else { return }
        isRunning = false
        isPlaying = false
    }

    // MARK: - Playback controls

    func playPause() {
        // Move the UI immediately; the PlaybackStateChanged notification
        // reconciles the real state right after.
        isPlaying.toggle()
        command("playpause")
    }

    func nextTrack() { command("next track") }
    func previousTrack() { command("previous track") }

    private func command(_ verb: String) {
        if case .failure(let error) = AppleScriptRunner.run("tell application \"Spotify\" to \(verb)") {
            handle(error)
        }
    }

    /// Opens System Settings on the Automation pane so the user can grant
    /// the missing permission.
    func openAutomationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - State

    private func apply(_ track: SpotifyTrack) {
        trackName = track.name
        artistName = track.artist
        isPlaying = track.isPlaying
    }

    /// Spotify only notifies on changes, so ask once for the current state
    /// at launch.
    private func fetchCurrentState() {
        guard isSpotifyRunning() else {
            isRunning = false
            isPlaying = false
            return
        }
        // Note: variable names like `st` collide with reserved AppleScript terms.
        let script = """
        tell application "Spotify"
            set t to name of current track
            set a to artist of current track
            set al to album of current track
            set art to artwork url of current track
            set ps to player state as string
            return t & "\(SpotifyTrack.separator)" & a & "\(SpotifyTrack.separator)" & al & "\(SpotifyTrack.separator)" & art & "\(SpotifyTrack.separator)" & ps
        end tell
        """
        switch AppleScriptRunner.run(script) {
        case .success(let result):
            guard let track = SpotifyTrack.parse(result) else {
                logger.warning("Unexpected bootstrap response from Spotify")
                return
            }
            permissionDenied = false
            isRunning = true
            apply(track)
            loadArtworkIfChanged(track.artworkURL)
        case .failure(let error):
            handle(error)
        }
    }

    private func refreshArtwork() {
        switch AppleScriptRunner.run("tell application \"Spotify\" to artwork url of current track") {
        case .success(let url):
            permissionDenied = false
            loadArtworkIfChanged(url)
        case .failure(let error):
            handle(error)
        }
    }

    private func handle(_ error: AppleScriptError) {
        if error.isPermissionDenied {
            permissionDenied = true
        }
    }

    private func isSpotifyRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == Self.spotifyBundleID
        }
    }

    // MARK: - Artwork

    private func loadArtworkIfChanged(_ urlString: String) {
        guard !urlString.isEmpty, urlString != artworkURLString,
              let url = URL(string: urlString) else { return }
        artworkURLString = urlString
        Task {
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = NSImage(data: data) else { return }
            artwork = image
        }
    }
}
