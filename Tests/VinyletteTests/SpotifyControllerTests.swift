import AppKit
import XCTest

@testable import Vinylette

/// Launch/termination transitions, command dispatch, and deterministic
/// artwork-race coverage. Error rollback paths live in `SpotifyTrackTests`.
@MainActor
final class SpotifyControllerLifecycleTests: XCTestCase {
    private let track = SpotifyTrack(
        name: "The Other Side", artist: "Stephen Sanchez", album: "Angel Face"
    )

    // MARK: - Helpers

    private final class ScriptRecorder: @unchecked Sendable {
        private let lock = NSLock()
        private var recorded: [String] = []
        var result: Result<String, AppleScriptError> = .success("")

        var scripts: [String] {
            lock.lock()
            defer { lock.unlock() }
            return recorded
        }

        func run(_ script: String) -> Result<String, AppleScriptError> {
            lock.lock()
            recorded.append(script)
            lock.unlock()
            return result
        }
    }

    /// Suspends artwork downloads until the test resumes them, which makes
    /// out-of-order completion reproducible without timing assumptions.
    private final class ArtworkGate: @unchecked Sendable {
        private let lock = NSLock()
        private var continuations: [String: CheckedContinuation<NSImage, Error>] = [:]

        var pendingURLs: [String] {
            lock.lock()
            defer { lock.unlock() }
            return Array(continuations.keys)
        }

        func load(_ url: URL) async throws -> NSImage {
            try await withCheckedThrowingContinuation { continuation in
                lock.lock()
                continuations[url.absoluteString] = continuation
                lock.unlock()
            }
        }

        func resume(_ urlString: String, with image: NSImage) {
            lock.lock()
            let continuation = continuations.removeValue(forKey: urlString)
            lock.unlock()
            continuation?.resume(returning: image)
        }
    }

    private func makeController(
        scripts: ScriptRecorder = ScriptRecorder(),
        gate: ArtworkGate? = nil,
        spotifyIsRunning: Bool = true
    ) -> SpotifyController {
        SpotifyController(
            runScript: { scripts.run($0) },
            loadArtwork: { url in
                if let gate {
                    return try await gate.load(url)
                }
                return NSImage(size: NSSize(width: 1, height: 1))
            },
            spotifyIsRunning: { spotifyIsRunning }
        )
    }

    private func waitUntil(
        timeout: TimeInterval = 2,
        _ condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                XCTFail("Timed out waiting for condition")
                return
            }
            await Task.yield()
            try await Task.sleep(nanoseconds: 1_000_000)
        }
    }

    private func playingSnapshot(_ track: SpotifyTrack) -> SpotifyPlaybackSnapshot {
        SpotifyPlaybackSnapshot(playerState: .playing, track: track)
    }

    // MARK: - Successful commands

    func testPlayPauseTogglesOptimisticallyAndSendsCommand() {
        let scripts = ScriptRecorder()
        let controller = makeController(scripts: scripts)
        controller.receive(playingSnapshot(track))

        controller.playPause()

        XCTAssertFalse(controller.state.isPlaying)
        XCTAssertEqual(controller.state.track?.identity, track.identity)
        XCTAssertTrue(scripts.scripts.contains { $0.contains("playpause") })
    }

    func testNextAndPreviousSendTheMatchingCommands() {
        let scripts = ScriptRecorder()
        let controller = makeController(scripts: scripts)
        controller.receive(playingSnapshot(track))

        controller.nextTrack()
        controller.previousTrack()

        XCTAssertTrue(scripts.scripts.contains { $0.contains("next track") })
        XCTAssertTrue(scripts.scripts.contains { $0.contains("previous track") })
    }

    func testCommandsAreIgnoredWhileSpotifyIsUnavailable() {
        let scripts = ScriptRecorder()
        let controller = makeController(scripts: scripts, spotifyIsRunning: false)

        controller.playPause()
        controller.nextTrack()
        controller.previousTrack()

        XCTAssertEqual(controller.state, .spotifyUnavailable)
        XCTAssertTrue(scripts.scripts.isEmpty, "No AppleScript may run without Spotify")
    }

    // MARK: - Launch transitions

    func testStartBootstrapsCurrentStateFromRunningSpotify() async throws {
        let scripts = ScriptRecorder()
        let raw = [
            track.name, track.artist, track.album, "https://example.com/cover.jpg", "playing",
        ].joined(separator: SpotifyPlaybackSnapshot.separator)
        scripts.result = .success(raw)
        let controller = makeController(scripts: scripts)

        controller.start()

        XCTAssertTrue(controller.state.isPlaying)
        XCTAssertEqual(controller.state.track?.identity, track.identity)
        try await waitUntil { controller.state.track?.artwork != nil }
    }

    func testStartWithoutRunningSpotifyIsUnavailableAndRunsNoScript() {
        let scripts = ScriptRecorder()
        let controller = makeController(scripts: scripts, spotifyIsRunning: false)

        controller.start()

        XCTAssertEqual(controller.state, .spotifyUnavailable)
        XCTAssertTrue(scripts.scripts.isEmpty)
    }

    // MARK: - Stale artwork downloads

    func testStaleArtworkFromPreviousTrackIsDiscarded() async throws {
        let gate = ArtworkGate()
        let controller = makeController(gate: gate)
        let urlA = "https://example.com/a.jpg"
        let urlB = "https://example.com/b.jpg"
        let trackA = SpotifyTrack(name: "A", artist: "One", album: "First", artworkURL: urlA)
        let trackB = SpotifyTrack(name: "B", artist: "Two", album: "Second", artworkURL: urlB)
        let imageA = NSImage(size: NSSize(width: 1, height: 1))
        let imageB = NSImage(size: NSSize(width: 2, height: 2))

        controller.receive(playingSnapshot(trackA))
        try await waitUntil { gate.pendingURLs.contains(urlA) }

        controller.receive(playingSnapshot(trackB))
        try await waitUntil { gate.pendingURLs.contains(urlB) }

        // The slow response for track A arrives only after the track changed.
        gate.resume(urlA, with: imageA)
        gate.resume(urlB, with: imageB)
        try await waitUntil { controller.state.track?.artwork != nil }

        XCTAssertEqual(controller.state.track?.identity, trackB.identity)
        XCTAssertTrue(
            controller.state.track?.artwork === imageB,
            "The stale download for track A must never be shown")
    }
}
