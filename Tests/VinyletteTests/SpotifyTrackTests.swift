import AppKit
import XCTest

@testable import Vinylette

final class SpotifySnapshotTests: XCTestCase {
    func testParsesPlayingTrack() {
        let raw = [
            "The Other Side", "Stephen Sanchez", "Angel Face",
            "https://i.scdn.co/image/abc", "playing",
        ].joined(separator: SpotifyPlaybackSnapshot.separator)

        let snapshot = SpotifyPlaybackSnapshot.parse(raw)

        XCTAssertEqual(snapshot?.playerState, .playing)
        XCTAssertEqual(
            snapshot?.track,
            SpotifyTrack(
                name: "The Other Side",
                artist: "Stephen Sanchez",
                album: "Angel Face",
                artworkURL: "https://i.scdn.co/image/abc"
            ))
    }

    func testParsesPausedTrackWithoutDuplicatingPlaybackStateOnTrack() {
        let raw = ["Beautiful", "Lana Del Rey", "Blue Banisters", "", "paused"]
            .joined(separator: SpotifyPlaybackSnapshot.separator)

        let snapshot = SpotifyPlaybackSnapshot.parse(raw)

        XCTAssertEqual(snapshot?.playerState, .paused)
        XCTAssertEqual(snapshot?.track?.name, "Beautiful")
    }

    func testKeepsMetadataWithSpecialCharactersIntact() {
        let raw = [
            "Don't Stop | Live & Loud", "AC/DC; Friends", "Album \"X\"",
            "https://example.com/a?b=c&d=e", "playing",
        ].joined(separator: SpotifyPlaybackSnapshot.separator)

        let track = SpotifyPlaybackSnapshot.parse(raw)?.track

        XCTAssertEqual(track?.name, "Don't Stop | Live & Loud")
        XCTAssertEqual(track?.artist, "AC/DC; Friends")
        XCTAssertEqual(track?.album, "Album \"X\"")
        XCTAssertEqual(track?.artworkURL, "https://example.com/a?b=c&d=e")
    }

    func testStoppedResponseHasNoTrack() {
        let raw = ["", "", "", "", "stopped"]
            .joined(separator: SpotifyPlaybackSnapshot.separator)

        let snapshot = SpotifyPlaybackSnapshot.parse(raw)

        XCTAssertEqual(snapshot?.playerState, .stopped)
        XCTAssertNil(snapshot?.track)
    }

    func testRejectsMalformedOrUnknownResponses() {
        XCTAssertNil(SpotifyPlaybackSnapshot.parse("only‖four‖fields‖here"))
        XCTAssertNil(SpotifyPlaybackSnapshot.parse(""))

        let tooMany = ["a", "b", "c", "d", "playing", "extra"]
            .joined(separator: SpotifyPlaybackSnapshot.separator)
        XCTAssertNil(SpotifyPlaybackSnapshot.parse(tooMany))

        let unknownState = ["a", "b", "c", "d", "buffering"]
            .joined(separator: SpotifyPlaybackSnapshot.separator)
        XCTAssertNil(SpotifyPlaybackSnapshot.parse(unknownState))
    }

    func testBuildsSnapshotFromPlaybackNotification() {
        let userInfo: [AnyHashable: Any] = [
            "Name": "The Other Side",
            "Artist": "Stephen Sanchez",
            "Album": "Angel Face",
            "Player State": "Playing",
        ]

        let snapshot = SpotifyPlaybackSnapshot.from(userInfo: userInfo)

        XCTAssertEqual(snapshot?.playerState, .playing)
        XCTAssertEqual(snapshot?.track?.name, "The Other Side")
        XCTAssertEqual(snapshot?.track?.artist, "Stephen Sanchez")
        XCTAssertEqual(snapshot?.track?.album, "Angel Face")
        XCTAssertEqual(
            snapshot?.track?.artworkURL,
            "",
            "The notification payload carries no artwork URL"
        )
    }

    func testNotificationMetadataFallsBackToEmptyStrings() {
        let snapshot = SpotifyPlaybackSnapshot.from(
            userInfo: ["Player State": "Paused"]
        )

        XCTAssertEqual(snapshot?.playerState, .paused)
        XCTAssertEqual(snapshot?.track?.name, "")
        XCTAssertEqual(snapshot?.track?.artist, "")
        XCTAssertEqual(snapshot?.track?.album, "")
    }

    func testStoppedNotificationProducesIdleBoundaryValue() {
        let snapshot = SpotifyPlaybackSnapshot.from(
            userInfo: ["Player State": "Stopped", "Name": "Old Song"]
        )

        XCTAssertEqual(snapshot?.playerState, .stopped)
        XCTAssertNil(snapshot?.track)
    }

    func testNotificationWithoutValidPlayerStateIsRejected() {
        XCTAssertNil(SpotifyPlaybackSnapshot.from(userInfo: ["Name": "Song"]))
        XCTAssertNil(SpotifyPlaybackSnapshot.from(userInfo: [:]))
        XCTAssertNil(SpotifyPlaybackSnapshot.from(userInfo: ["Player State": "Buffering"]))
    }
}

final class SpotifyControllerTests: XCTestCase {
    @MainActor
    func testFailedPlayPauseRollsBackOptimisticStateAndSurfacesError() {
        let track = SpotifyTrack(name: "Song", artist: "Artist", album: "Album")
        let controller = makeController(runScript: { _ in
            .failure(AppleScriptError(code: -1, message: "Command failed"))
        })
        controller.receive(SpotifyPlaybackSnapshot(playerState: .paused, track: track))

        controller.playPause()

        guard case .failed(let error) = controller.state else {
            return XCTFail("Expected a visible failure state")
        }
        XCTAssertEqual(error.kind, .command)
        XCTAssertFalse(controller.state.isPlaying, "The optimistic play state must be rolled back")
        XCTAssertEqual(controller.state.track, track)
    }

    @MainActor
    func testPermissionFailureBecomesPermissionRequired() {
        let track = SpotifyTrack(name: "Song", artist: "Artist", album: "Album")
        let controller = makeController(runScript: { _ in
            .failure(AppleScriptError(code: -1743, message: "Not authorized"))
        })
        controller.receive(SpotifyPlaybackSnapshot(playerState: .playing, track: track))

        controller.playPause()

        XCTAssertEqual(controller.state, .permissionRequired)
    }

    @MainActor
    func testSpotifyTerminationClearsTrackAndArtwork() {
        let artwork = NSImage(size: NSSize(width: 20, height: 20))
        let track = SpotifyTrack(
            name: "Song",
            artist: "Artist",
            album: "Album",
            artworkURL: "https://example.com/art.png",
            artwork: artwork
        )
        let controller = makeController()
        controller.receive(SpotifyPlaybackSnapshot(playerState: .playing, track: track))

        controller.spotifyDidTerminate()

        XCTAssertEqual(controller.state, .spotifyUnavailable)
        XCTAssertNil(controller.state.track)
    }

    @MainActor
    func testStoppedPlaybackClearsTrackAndBecomesIdle() {
        let controller = makeController()
        let track = SpotifyTrack(name: "Song", artist: "Artist", album: "Album")
        controller.receive(SpotifyPlaybackSnapshot(playerState: .playing, track: track))

        controller.receive(SpotifyPlaybackSnapshot(playerState: .stopped, track: nil))

        XCTAssertEqual(controller.state, .idle)
        XCTAssertNil(controller.state.track)
    }

    @MainActor
    func testOlderArtworkRequestCannotOverwriteNewTrack() async throws {
        let oldURL = "https://example.com/old.png"
        let newURL = "https://example.com/new.png"
        let controller = makeController(loadArtwork: { url in
            if url.absoluteString == oldURL {
                try? await Task.sleep(nanoseconds: 150_000_000)
                return NSImage(size: NSSize(width: 10, height: 10))
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
            return NSImage(size: NSSize(width: 20, height: 20))
        })

        controller.receive(
            SpotifyPlaybackSnapshot(
                playerState: .playing,
                track: SpotifyTrack(
                    name: "Old Song",
                    artist: "Artist",
                    album: "Old Album",
                    artworkURL: oldURL
                )
            ))
        await Task.yield()
        controller.receive(
            SpotifyPlaybackSnapshot(
                playerState: .playing,
                track: SpotifyTrack(
                    name: "New Song",
                    artist: "Artist",
                    album: "New Album",
                    artworkURL: newURL
                )
            ))

        try await Task.sleep(nanoseconds: 250_000_000)

        XCTAssertEqual(controller.state.track?.name, "New Song")
        XCTAssertEqual(controller.state.track?.artworkURL, newURL)
        XCTAssertEqual(controller.state.track?.artwork?.size.width, 20)
    }

    @MainActor
    func testArtworkFailureIsVisibleAndRetainsPlayback() async throws {
        let controller = makeController(loadArtwork: { _ in
            throw URLError(.notConnectedToInternet)
        })
        let track = SpotifyTrack(
            name: "Song",
            artist: "Artist",
            album: "Album",
            artworkURL: "https://example.com/art.png"
        )

        controller.receive(SpotifyPlaybackSnapshot(playerState: .playing, track: track))
        try await Task.sleep(nanoseconds: 20_000_000)

        guard case .failed(let error) = controller.state else {
            return XCTFail("Expected a visible artwork failure")
        }
        XCTAssertEqual(error.kind, .artwork)
        XCTAssertTrue(controller.state.isPlaying)
        XCTAssertEqual(controller.state.track?.name, "Song")
    }

    @MainActor
    func testMalformedNotificationIsVisibleAndDismissible() {
        let controller = makeController()
        let track = SpotifyTrack(name: "Song", artist: "Artist", album: "Album")
        controller.receive(SpotifyPlaybackSnapshot(playerState: .paused, track: track))

        controller.receivePlaybackNotification(userInfo: ["Name": "Missing state"])

        XCTAssertEqual(controller.state.error?.kind, .unexpectedResponse)
        controller.dismissError()
        XCTAssertEqual(controller.state, .paused(track))
    }

    @MainActor
    private func makeController(
        runScript: @escaping SpotifyController.ScriptRunner = { _ in .success("") },
        loadArtwork: @escaping SpotifyController.ArtworkLoader = { _ in
            NSImage(size: NSSize(width: 1, height: 1))
        }
    ) -> SpotifyController {
        SpotifyController(
            runScript: runScript,
            loadArtwork: loadArtwork,
            spotifyIsRunning: { true }
        )
    }
}

final class WidgetDesignTests: XCTestCase {
    func testEveryCaseHasADisplayName() {
        for design in WidgetDesign.allCases {
            XCTAssertFalse(design.displayName.isEmpty)
        }
    }

    func testRawValuesAreStableForPersistence() {
        XCTAssertEqual(WidgetDesign(rawValue: "classicLabel"), .classicLabel)
        XCTAssertEqual(WidgetDesign(rawValue: "albumCover"), .albumCover)
        XCTAssertEqual(WidgetDesign(rawValue: "sleeve"), .sleeve)
    }
}
