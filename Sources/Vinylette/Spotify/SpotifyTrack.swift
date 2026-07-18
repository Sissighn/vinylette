import Foundation

/// One snapshot of Spotify's playback state.
struct SpotifyTrack: Equatable {
    let name: String
    let artist: String
    let album: String
    let artworkURL: String
    let isPlaying: Bool

    /// Field separator used in the AppleScript response. Chosen because it
    /// cannot appear in regular track metadata.
    static let separator = "‖"

    /// Parses the delimiter-joined AppleScript response:
    /// "name‖artist‖album‖artworkURL‖state".
    static func parse(_ raw: String) -> SpotifyTrack? {
        let parts = raw.components(separatedBy: separator)
        guard parts.count == 5 else { return nil }
        return SpotifyTrack(
            name: parts[0],
            artist: parts[1],
            album: parts[2],
            artworkURL: parts[3],
            isPlaying: parts[4] == "playing"
        )
    }

    /// Builds a track from Spotify's `com.spotify.client.PlaybackStateChanged`
    /// distributed-notification payload. The payload carries no artwork URL;
    /// that is looked up separately via AppleScript.
    static func from(userInfo: [AnyHashable: Any]) -> SpotifyTrack? {
        guard let state = userInfo["Player State"] as? String else { return nil }
        return SpotifyTrack(
            name: userInfo["Name"] as? String ?? "",
            artist: userInfo["Artist"] as? String ?? "",
            album: userInfo["Album"] as? String ?? "",
            artworkURL: "",
            isPlaying: state == "Playing"
        )
    }
}
