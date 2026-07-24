import AppKit

/// Metadata and artwork for one Spotify track.
///
/// Playing versus paused is intentionally not stored here. It belongs
/// exclusively to `PlaybackState`, which prevents contradictory states. The
/// repeat flag is retained with the current playback context because Spotify's
/// distributed notifications do not include it.
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
    var isRepeating: Bool

    init(
        name: String,
        artist: String,
        album: String,
        artworkURL: String = "",
        artwork: NSImage? = nil,
        isRepeating: Bool = false
    ) {
        self.name = name
        self.artist = artist
        self.album = album
        self.artworkURL = artworkURL
        self.artwork = artwork
        self.isRepeating = isRepeating
    }

    var identity: Identity {
        Identity(name: name, artist: artist, album: album)
    }

    static func == (lhs: SpotifyTrack, rhs: SpotifyTrack) -> Bool {
        lhs.identity == rhs.identity
            && lhs.artworkURL == rhs.artworkURL
            && lhs.artwork?.tiffRepresentation == rhs.artwork?.tiffRepresentation
            && lhs.isRepeating == rhs.isRepeating
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
    /// `nil` for distributed notifications, which do not carry repeat state.
    let isRepeating: Bool?

    init(
        playerState: SpotifyPlayerState,
        track: SpotifyTrack?,
        isRepeating: Bool? = nil
    ) {
        self.playerState = playerState
        self.track = track
        self.isRepeating = isRepeating
    }

    /// Field separator used in the AppleScript response. Chosen because it
    /// cannot appear in regular track metadata.
    static let separator = "‖"

    /// Parses "name‖artist‖album‖artworkURL‖state[‖repeat]". Five-field
    /// responses remain supported for deterministic tests and older builds.
    static func parse(_ raw: String) -> SpotifyPlaybackSnapshot? {
        let parts = raw.components(separatedBy: separator)
        guard (5 ... 6).contains(parts.count),
            let playerState = SpotifyPlayerState(rawValue: parts[4])
        else {
            return nil
        }

        let isRepeating: Bool?
        if parts.count == 6 {
            switch parts[5].lowercased() {
            case "true": isRepeating = true
            case "false": isRepeating = false
            default: return nil
            }
        } else {
            isRepeating = nil
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
        return SpotifyPlaybackSnapshot(
            playerState: playerState,
            track: track,
            isRepeating: isRepeating
        )
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
