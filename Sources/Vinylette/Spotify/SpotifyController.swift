import AppKit
import Combine

/// Talks to the local Spotify desktop app via AppleScript.
/// No OAuth, no API keys — Spotify just needs to be running.
final class SpotifyController: ObservableObject {
    @Published var isRunning = false
    @Published var isPlaying = false
    @Published var trackName = ""
    @Published var artistName = ""
    @Published var albumName = ""
    @Published var artwork: NSImage?

    private var timer: Timer?
    private var artworkURLString = ""

    func start() {
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    // MARK: - Playback controls

    func playPause() { AppleScriptRunner.run("tell application \"Spotify\" to playpause"); poll() }
    func nextTrack() { AppleScriptRunner.run("tell application \"Spotify\" to next track"); poll() }
    func previousTrack() { AppleScriptRunner.run("tell application \"Spotify\" to previous track"); poll() }

    // MARK: - Polling

    private func poll() {
        guard isSpotifyRunning() else {
            DispatchQueue.main.async {
                self.isRunning = false
                self.isPlaying = false
            }
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
            return t & "‖" & a & "‖" & al & "‖" & art & "‖" & ps
        end tell
        """
        guard let result = AppleScriptRunner.run(script) else { return }
        let parts = result.components(separatedBy: "‖")
        guard parts.count == 5 else { return }

        DispatchQueue.main.async {
            self.isRunning = true
            self.trackName = parts[0]
            self.artistName = parts[1]
            self.albumName = parts[2]
            self.isPlaying = parts[4] == "playing"
        }
        if parts[3] != artworkURLString {
            artworkURLString = parts[3]
            fetchArtwork(from: parts[3])
        }
    }

    private func isSpotifyRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.spotify.client"
        }
    }

    private func fetchArtwork(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = NSImage(data: data) else { return }
            DispatchQueue.main.async { self?.artwork = image }
        }.resume()
    }
}
