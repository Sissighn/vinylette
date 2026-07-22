import AppKit

/// Metadata and artwork for one Spotify track.
///
/// Playback is intentionally not stored here. It belongs exclusively to
/// `PlaybackState`, which prevents combinations such as a paused state with a
/// track whose own `isPlaying` flag says otherwise.
struct SpotifyTrack: Equatable {
    struct Identity: Equatable, Hashable {
        let name: String
        let artist: String
        let album: String
    }

    let name: String
    let artist: String
    let album: String
    var artworkURL: String
    var artwork: NSImage?

    init(
        name: String,
        artist: String,
        album: String,
        artworkURL: String = "",
        artwork: NSImage? = nil
    ) {
        self.name = name
        self.artist = artist
        self.album = album
        self.artworkURL = artworkURL
        self.artwork = artwork
    }

    var identity: Identity {
        Identity(name: name, artist: artist, album: album)
    }

    static func == (lhs: SpotifyTrack, rhs: SpotifyTrack) -> Bool {
        lhs.identity == rhs.identity
            && lhs.artworkURL == rhs.artworkURL
            && lhs.artwork?.tiffRepresentation == rhs.artwork?.tiffRepresentation
    }
}

/// Spotify's transport state as received from AppleScript or a distributed
/// notification.
enum SpotifyPlayerState: Equatable {
    case playing
    case paused
    case stopped

    init?(rawValue: String) {
        switch rawValue.lowercased() {
        case "playing": self = .playing
        case "paused": self = .paused
        case "stopped": self = .stopped
        default: return nil
        }
    }
}

/// A parsed boundary value. The controller immediately reduces it into the
/// app-wide `PlaybackState`.
struct SpotifyPlaybackSnapshot: Equatable {
    let playerState: SpotifyPlayerState
    let track: SpotifyTrack?

    /// Field separator used in the AppleScript response. Chosen because it
    /// cannot appear in regular track metadata.
    static let separator = "‖"

    /// Parses "name‖artist‖album‖artworkURL‖state".
    static func parse(_ raw: String) -> SpotifyPlaybackSnapshot? {
        let parts = raw.components(separatedBy: separator)
        guard parts.count == 5,
            let playerState = SpotifyPlayerState(rawValue: parts[4])
        else {
            return nil
        }

        let track =
            playerState == .stopped
            ? nil
            : SpotifyTrack(
                name: parts[0],
                artist: parts[1],
                album: parts[2],
                artworkURL: parts[3]
            )
        return SpotifyPlaybackSnapshot(playerState: playerState, track: track)
    }

    /// Builds a snapshot from Spotify's distributed-notification payload. The
    /// payload carries no artwork URL; the controller looks it up separately.
    static func from(userInfo: [AnyHashable: Any]) -> SpotifyPlaybackSnapshot? {
        guard let rawState = userInfo["Player State"] as? String,
            let playerState = SpotifyPlayerState(rawValue: rawState)
        else {
            return nil
        }

        let track =
            playerState == .stopped
            ? nil
            : SpotifyTrack(
                name: userInfo["Name"] as? String ?? "",
                artist: userInfo["Artist"] as? String ?? "",
                album: userInfo["Album"] as? String ?? ""
            )
        return SpotifyPlaybackSnapshot(playerState: playerState, track: track)
    }
}
