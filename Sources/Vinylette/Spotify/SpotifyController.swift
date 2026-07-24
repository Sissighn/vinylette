import AppKit
import Combine
import os

private let spotifyBundleIdentifier = "com.spotify.client"
private let spotifyPlaybackChanged = Notification.Name("com.spotify.client.PlaybackStateChanged")

/// Publishes one coherent Spotify playback state to the UI.
///
/// Distributed notifications trigger immediate updates. AppleScript is used
/// only to bootstrap the state, obtain the artwork URL, and send commands.
@MainActor
final class SpotifyController: ObservableObject {
    typealias ScriptRunner = (String) -> Result<String, AppleScriptError>
    typealias ArtworkLoader = (URL) async throws -> NSImage

    @Published private(set) var state: PlaybackState = .spotifyUnavailable

    private let runScript: ScriptRunner
    private let loadArtwork: ArtworkLoader
    private let spotifyIsRunning: () -> Bool
    private let logger = Logger(subsystem: "com.setayesh.vinylette", category: "spotify")

    private var distributedObserver: NSObjectProtocol?
    private var terminationObserver: NSObjectProtocol?
    private var launchObserver: NSObjectProtocol?
    private var artworkTask: Task<Void, Never>?
    private var artworkRequestID: UUID?
    private var artworkRequestURLString: String?
    private var artworkRequestIdentity: SpotifyTrack.Identity?

    init(
        runScript: @escaping ScriptRunner = AppleScriptRunner.run,
        loadArtwork: @escaping ArtworkLoader = { url in
            let (data, response) = try await URLSession.shared.data(from: url)
            if let response = response as? HTTPURLResponse,
                !(200 ... 299).contains(response.statusCode)
            {
                throw URLError(.badServerResponse)
            }
            guard let image = NSImage(data: data) else {
                throw URLError(.cannotDecodeContentData)
            }
            return image
        },
        spotifyIsRunning: @escaping () -> Bool = {
            NSWorkspace.shared.runningApplications.contains {
                $0.bundleIdentifier == spotifyBundleIdentifier
            }
        }
    ) {
        self.runScript = runScript
        self.loadArtwork = loadArtwork
        self.spotifyIsRunning = spotifyIsRunning
    }

    func start() {
        guard distributedObserver == nil else { return }

        distributedObserver = DistributedNotificationCenter.default().addObserver(
            forName: spotifyPlaybackChanged,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            let userInfo = notification.userInfo
            Task { @MainActor [weak self] in
                self?.receivePlaybackNotification(userInfo: userInfo)
            }
        }

        terminationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            let application =
                notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication
            let bundleIdentifier = application?.bundleIdentifier
            Task { @MainActor [weak self] in
                guard bundleIdentifier == spotifyBundleIdentifier else { return }
                self?.spotifyDidTerminate()
            }
        }

        launchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            let application =
                notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication
            let bundleIdentifier = application?.bundleIdentifier
            Task { @MainActor [weak self] in
                guard bundleIdentifier == spotifyBundleIdentifier else { return }
                self?.fetchCurrentState()
            }
        }

        fetchCurrentState()
    }

    deinit {
        if let distributedObserver {
            DistributedNotificationCenter.default().removeObserver(distributedObserver)
        }
        if let terminationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(terminationObserver)
        }
        if let launchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(launchObserver)
        }
        artworkTask?.cancel()
    }

    // MARK: - Playback controls

    func playPause() {
        guard state.canControlPlayback else { return }

        let fallback = state.fallback
        state = fallback.state
        if let track = state.track {
            state = state.isPlaying ? .paused(track) : .playing(track)
        }
        execute(command: "playpause", rollback: fallback)
    }

    func nextTrack() {
        executeNonOptimistic(command: "next track")
    }

    func previousTrack() {
        executeNonOptimistic(command: "previous track")
    }

    func toggleRepeat() {
        guard state.canControlPlayback, var track = state.track else { return }

        let fallback = state.fallback
        track.isRepeating.toggle()
        state = state.replacingCurrentTrack(with: track)
        execute(
            command: "set repeating to \(track.isRepeating)",
            rollback: fallback
        )
    }

    func dismissError() {
        guard case .failed(let error) = state else { return }
        state = error.fallback.state
    }

    private func executeNonOptimistic(command: String) {
        guard state.canControlPlayback else { return }
        let fallback = state.fallback
        state = fallback.state
        execute(command: command, rollback: fallback)
    }

    private func execute(command: String, rollback: PlaybackFallback) {
        if case .failure(let error) = runScript("tell application \"Spotify\" to \(command)") {
            handle(error, kind: .command, fallback: rollback)
        }
    }

    /// Opens System Settings on the Automation pane so the user can grant the
    /// missing permission.
    func openAutomationSettings() {
        guard
            let url = URL(
                string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
            )
        else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Event handling

    /// This method is always entered from an explicit `Task { @MainActor in }`
    /// boundary, regardless of the thread used by Distributed Notifications.
    func receivePlaybackNotification(userInfo: [AnyHashable: Any]?) {
        guard let userInfo,
            let snapshot = SpotifyPlaybackSnapshot.from(userInfo: userInfo)
        else {
            fail(
                kind: .unexpectedResponse,
                diagnostic: "Playback notification contained no readable state",
                fallback: state.fallback
            )
            return
        }

        receive(snapshot, fetchArtworkWhenMissing: true)
    }

    func spotifyDidTerminate() {
        cancelArtworkRequest()
        state = .spotifyUnavailable
    }

    // MARK: - State reduction

    /// Reduces a boundary snapshot into the single public state. Internal
    /// visibility keeps the reducer directly testable without posting global
    /// process notifications.
    func receive(
        _ snapshot: SpotifyPlaybackSnapshot,
        fetchArtworkWhenMissing: Bool = false
    ) {
        guard snapshot.playerState != .stopped else {
            cancelArtworkRequest()
            state = .idle
            return
        }

        guard var incomingTrack = snapshot.track else {
            fail(
                kind: .unexpectedResponse,
                diagnostic: "Spotify returned playback without a track",
                fallback: state.fallback
            )
            return
        }

        let previousTrack = state.track
        let isSameTrack = previousTrack?.identity == incomingTrack.identity
        incomingTrack.isRepeating =
            snapshot.isRepeating ?? previousTrack?.isRepeating ?? false
        if let previousTrack, isSameTrack {
            if incomingTrack.artworkURL.isEmpty {
                incomingTrack.artworkURL = previousTrack.artworkURL
                incomingTrack.artwork = previousTrack.artwork
            } else if incomingTrack.artworkURL == previousTrack.artworkURL {
                incomingTrack.artwork = previousTrack.artwork
            }
        } else {
            cancelArtworkRequest()
        }

        switch snapshot.playerState {
        case .playing:
            state = .playing(incomingTrack)
        case .paused:
            state = .paused(incomingTrack)
        case .stopped:
            assertionFailure("Stopped snapshots are handled before track reduction")
        }

        if !incomingTrack.artworkURL.isEmpty {
            loadArtworkIfChanged(
                incomingTrack.artworkURL,
                for: incomingTrack.identity
            )
        } else if incomingTrack.artwork == nil && fetchArtworkWhenMissing {
            fetchCurrentState(fallback: state.fallback)
        }
    }

    /// Spotify only emits notifications for changes, so bootstrap once at
    /// launch and repeat the same full lookup when a new track needs artwork.
    private func fetchCurrentState(fallback: PlaybackFallback? = nil) {
        guard spotifyIsRunning() else {
            spotifyDidTerminate()
            return
        }

        let script = """
            tell application "Spotify"
                set t to name of current track
                set a to artist of current track
                set al to album of current track
                set art to artwork url of current track
                set ps to player state as string
                set rp to repeating as string
                return t & "\(SpotifyPlaybackSnapshot.separator)" & a & "\(SpotifyPlaybackSnapshot.separator)" & al & "\(SpotifyPlaybackSnapshot.separator)" & art & "\(SpotifyPlaybackSnapshot.separator)" & ps & "\(SpotifyPlaybackSnapshot.separator)" & rp
            end tell
            """

        switch runScript(script) {
        case .success(let result):
            guard let snapshot = SpotifyPlaybackSnapshot.parse(result) else {
                fail(
                    kind: .unexpectedResponse,
                    diagnostic: "Unexpected bootstrap response from Spotify",
                    fallback: fallback ?? state.fallback
                )
                return
            }
            receive(snapshot)
        case .failure(let error):
            handle(error, kind: .stateRefresh, fallback: fallback ?? state.fallback)
        }
    }

    private func handle(
        _ error: AppleScriptError,
        kind: PlaybackError.Kind,
        fallback: PlaybackFallback
    ) {
        if error.isPermissionDenied {
            cancelArtworkRequest()
            state = .permissionRequired
        } else if error.isSpotifyUnavailable {
            spotifyDidTerminate()
        } else if error.isNoCurrentTrack, kind == .stateRefresh {
            cancelArtworkRequest()
            state = .idle
        } else {
            fail(kind: kind, diagnostic: error.message, fallback: fallback)
        }
    }

    private func fail(
        kind: PlaybackError.Kind,
        diagnostic: String,
        fallback: PlaybackFallback
    ) {
        logger.error("Spotify integration failed: \(diagnostic, privacy: .public)")
        state = .failed(
            PlaybackError(
                kind: kind,
                diagnostic: diagnostic,
                fallback: fallback
            ))
    }

    // MARK: - Artwork

    private func loadArtworkIfChanged(
        _ urlString: String,
        for identity: SpotifyTrack.Identity
    ) {
        guard state.track?.identity == identity else { return }
        guard let url = URL(string: urlString), !urlString.isEmpty else {
            fail(
                kind: .artwork,
                diagnostic: "Spotify returned an invalid artwork URL",
                fallback: state.fallback
            )
            return
        }
        if state.track?.artworkURL == urlString, state.track?.artwork != nil {
            return
        }
        if artworkRequestID != nil,
            artworkRequestURLString == urlString,
            artworkRequestIdentity == identity
        {
            return
        }

        cancelArtworkRequest()

        if var track = state.track {
            track.artworkURL = urlString
            track.artwork = nil
            state = state.replacingCurrentTrack(with: track)
        }

        let requestID = UUID()
        artworkRequestID = requestID
        artworkRequestURLString = urlString
        artworkRequestIdentity = identity
        let artworkLoader = loadArtwork
        artworkTask = Task { [weak self] in
            do {
                let image = try await artworkLoader(url)
                guard !Task.isCancelled else { return }
                self?.finishArtwork(
                    image,
                    urlString: urlString,
                    identity: identity,
                    requestID: requestID
                )
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self?.finishArtworkFailure(
                    error,
                    identity: identity,
                    requestID: requestID
                )
            }
        }
    }

    private func finishArtwork(
        _ image: NSImage,
        urlString: String,
        identity: SpotifyTrack.Identity,
        requestID: UUID
    ) {
        guard artworkRequestID == requestID,
            state.track?.identity == identity,
            var track = state.track
        else { return }

        track.artworkURL = urlString
        track.artwork = image
        state = state.replacingCurrentTrack(with: track)
        artworkTask = nil
        artworkRequestID = nil
        artworkRequestURLString = nil
        artworkRequestIdentity = nil
    }

    private func finishArtworkFailure(
        _ error: Error,
        identity: SpotifyTrack.Identity,
        requestID: UUID
    ) {
        guard artworkRequestID == requestID,
            state.track?.identity == identity
        else { return }

        artworkTask = nil
        artworkRequestID = nil
        artworkRequestURLString = nil
        artworkRequestIdentity = nil
        fail(
            kind: .artwork,
            diagnostic: error.localizedDescription,
            fallback: state.fallback
        )
    }

    private func cancelArtworkRequest() {
        artworkTask?.cancel()
        artworkTask = nil
        artworkRequestID = nil
        artworkRequestURLString = nil
        artworkRequestIdentity = nil
    }
}
