import Foundation

/// The single source of truth for Spotify integration and playback UI.
enum PlaybackState: Equatable {
    case spotifyUnavailable
    case permissionRequired
    case idle
    case paused(SpotifyTrack)
    case playing(SpotifyTrack)
    case failed(PlaybackError)

    var track: SpotifyTrack? {
        switch self {
        case .paused(let track), .playing(let track):
            return track
        case .failed(let error):
            return error.fallback.track
        case .spotifyUnavailable, .permissionRequired, .idle:
            return nil
        }
    }

    var isPlaying: Bool {
        switch self {
        case .playing:
            return true
        case .failed(let error):
            return error.fallback.isPlaying
        case .spotifyUnavailable, .permissionRequired, .idle, .paused:
            return false
        }
    }

    var isSpotifyAvailable: Bool {
        switch self {
        case .spotifyUnavailable, .permissionRequired:
            return false
        case .idle, .paused, .playing:
            return true
        case .failed(let error):
            return error.fallback.isSpotifyAvailable
        }
    }

    var canControlPlayback: Bool {
        switch self {
        case .idle, .paused, .playing:
            return true
        case .failed(let error):
            return error.fallback.isSpotifyAvailable
        case .spotifyUnavailable, .permissionRequired:
            return false
        }
    }

    var error: PlaybackError? {
        guard case .failed(let error) = self else { return nil }
        return error
    }

    var fallback: PlaybackFallback {
        switch self {
        case .spotifyUnavailable:
            return .spotifyUnavailable
        case .permissionRequired:
            return .spotifyUnavailable
        case .idle:
            return .idle
        case .paused(let track):
            return .paused(track)
        case .playing(let track):
            return .playing(track)
        case .failed(let error):
            return error.fallback
        }
    }

    func replacingCurrentTrack(with track: SpotifyTrack) -> PlaybackState {
        switch self {
        case .paused:
            return .paused(track)
        case .playing:
            return .playing(track)
        case .failed(var error):
            error.fallback = error.fallback.replacingTrack(with: track)
            return .failed(error)
        case .spotifyUnavailable, .permissionRequired, .idle:
            return self
        }
    }
}

/// A non-recursive last-known-good state retained while an error is visible.
enum PlaybackFallback: Equatable {
    case spotifyUnavailable
    case idle
    case paused(SpotifyTrack)
    case playing(SpotifyTrack)

    var state: PlaybackState {
        switch self {
        case .spotifyUnavailable: return .spotifyUnavailable
        case .idle: return .idle
        case .paused(let track): return .paused(track)
        case .playing(let track): return .playing(track)
        }
    }

    var track: SpotifyTrack? {
        switch self {
        case .paused(let track), .playing(let track): return track
        case .spotifyUnavailable, .idle: return nil
        }
    }

    var isPlaying: Bool {
        if case .playing = self { return true }
        return false
    }

    var isSpotifyAvailable: Bool {
        if case .spotifyUnavailable = self { return false }
        return true
    }

    func replacingTrack(with track: SpotifyTrack) -> PlaybackFallback {
        switch self {
        case .paused: return .paused(track)
        case .playing: return .playing(track)
        case .spotifyUnavailable, .idle: return self
        }
    }
}

struct PlaybackError: Error, Equatable {
    enum Kind: Equatable {
        case command
        case stateRefresh
        case artwork
        case unexpectedResponse
    }

    let kind: Kind
    let diagnostic: String
    var fallback: PlaybackFallback

    /// The user-facing description of this failure.
    var message: String {
        switch kind {
        case .command: return L10n.SpotifyError.command
        case .stateRefresh, .unexpectedResponse: return L10n.SpotifyError.state
        case .artwork: return L10n.SpotifyError.artwork
        }
    }
}
