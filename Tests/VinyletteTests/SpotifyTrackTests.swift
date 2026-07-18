import XCTest
@testable import Vinylette

final class SpotifyTrackTests: XCTestCase {
    func testParsesPlayingTrack() {
        let raw = ["The Other Side", "Stephen Sanchez", "Angel Face",
                   "https://i.scdn.co/image/abc", "playing"]
            .joined(separator: SpotifyTrack.separator)

        let track = SpotifyTrack.parse(raw)

        XCTAssertEqual(track, SpotifyTrack(
            name: "The Other Side",
            artist: "Stephen Sanchez",
            album: "Angel Face",
            artworkURL: "https://i.scdn.co/image/abc",
            isPlaying: true
        ))
    }

    func testParsesPausedTrack() {
        let raw = ["Beautiful", "Lana Del Rey", "Blue Banisters", "", "paused"]
            .joined(separator: SpotifyTrack.separator)

        XCTAssertEqual(SpotifyTrack.parse(raw)?.isPlaying, false)
    }

    func testKeepsMetadataWithSpecialCharactersIntact() {
        let raw = ["Don't Stop | Live & Loud", "AC/DC; Friends", "Album \"X\"",
                   "https://example.com/a?b=c&d=e", "playing"]
            .joined(separator: SpotifyTrack.separator)

        let track = SpotifyTrack.parse(raw)

        XCTAssertEqual(track?.name, "Don't Stop | Live & Loud")
        XCTAssertEqual(track?.artist, "AC/DC; Friends")
        XCTAssertEqual(track?.album, "Album \"X\"")
        XCTAssertEqual(track?.artworkURL, "https://example.com/a?b=c&d=e")
    }

    func testRejectsResponseWithTooFewFields() {
        XCTAssertNil(SpotifyTrack.parse("only‖four‖fields‖here"))
    }

    func testRejectsResponseWithTooManyFields() {
        let raw = ["a", "b", "c", "d", "playing", "extra"]
            .joined(separator: SpotifyTrack.separator)

        XCTAssertNil(SpotifyTrack.parse(raw))
    }

    func testRejectsEmptyResponse() {
        XCTAssertNil(SpotifyTrack.parse(""))
    }

    func testTreatsUnknownPlayerStateAsNotPlaying() {
        let raw = ["a", "b", "c", "d", "stopped"]
            .joined(separator: SpotifyTrack.separator)

        XCTAssertEqual(SpotifyTrack.parse(raw)?.isPlaying, false)
    }
}

final class SpotifyNotificationTests: XCTestCase {
    func testBuildsTrackFromPlaybackNotification() {
        let userInfo: [AnyHashable: Any] = [
            "Name": "The Other Side",
            "Artist": "Stephen Sanchez",
            "Album": "Angel Face",
            "Player State": "Playing",
        ]

        let track = SpotifyTrack.from(userInfo: userInfo)

        XCTAssertEqual(track?.name, "The Other Side")
        XCTAssertEqual(track?.artist, "Stephen Sanchez")
        XCTAssertEqual(track?.album, "Angel Face")
        XCTAssertEqual(track?.isPlaying, true)
        XCTAssertEqual(track?.artworkURL, "", "The notification payload carries no artwork URL")
    }

    func testPausedNotificationIsNotPlaying() {
        let userInfo: [AnyHashable: Any] = ["Player State": "Paused"]

        XCTAssertEqual(SpotifyTrack.from(userInfo: userInfo)?.isPlaying, false)
    }

    func testMissingMetadataFallsBackToEmptyStrings() {
        let userInfo: [AnyHashable: Any] = ["Player State": "Playing"]

        let track = SpotifyTrack.from(userInfo: userInfo)

        XCTAssertEqual(track?.name, "")
        XCTAssertEqual(track?.artist, "")
        XCTAssertEqual(track?.album, "")
    }

    func testPayloadWithoutPlayerStateIsRejected() {
        XCTAssertNil(SpotifyTrack.from(userInfo: ["Name": "Song"]))
        XCTAssertNil(SpotifyTrack.from(userInfo: [:]))
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
