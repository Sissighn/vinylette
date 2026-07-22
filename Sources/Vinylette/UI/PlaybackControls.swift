import SwiftUI

/// Hover controls: previous, play/pause, next.
struct PlaybackControls: View {
    @EnvironmentObject var spotify: SpotifyController

    var body: some View {
        HStack(spacing: 22) {
            ControlButton(symbol: "backward.fill") { spotify.previousTrack() }
            ControlButton(
                symbol: spotify.state.isPlaying ? "pause.fill" : "play.fill",
                prominent: true
            ) { spotify.playPause() }
            ControlButton(symbol: "forward.fill") { spotify.nextTrack() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(Palette.cream.opacity(0.92))
                .overlay(Capsule().strokeBorder(Palette.gold.opacity(0.5), lineWidth: 1))
                .shadow(color: Palette.cocoa.opacity(0.2), radius: 6, y: 2)
        )
        .disabled(!spotify.state.canControlPlayback)
        .opacity(spotify.state.canControlPlayback ? 1 : 0.55)
    }
}

/// Round icon button used inside the controls capsule.
struct ControlButton: View {
    let symbol: String
    var prominent = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: prominent ? 16 : 12, weight: .bold))
                .foregroundColor(prominent ? Palette.cream : Palette.cocoa)
                .frame(width: prominent ? 36 : 26, height: prominent ? 36 : 26)
                .background(
                    Circle().fill(prominent ? Palette.rose : Palette.blush.opacity(0.7))
                )
        }
        .buttonStyle(.plain)
    }
}
