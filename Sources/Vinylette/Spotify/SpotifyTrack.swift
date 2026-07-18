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
}
