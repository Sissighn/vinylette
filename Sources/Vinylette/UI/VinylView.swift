import SwiftUI

/// The main widget: player deck with spinning record and tonearm,
/// plus the track-info capsule while Spotify is playing something.
struct VinylView: View {
    @EnvironmentObject var spotify: SpotifyController
    @State private var angle: Double = 0
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 10) {
            deck
            if spotify.isRunning && !spotify.trackName.isEmpty {
                TrackInfoView(
                    title: spotify.trackName,
                    subtitle: spotify.artistName.isEmpty ? "♡" : spotify.artistName
                )
            }
        }
        .padding(12)
        .task(id: spotify.isPlaying) {
            guard spotify.isPlaying else { return }

            var previousFrame = Date()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 16_666_667)
                let currentFrame = Date()
                let elapsed = currentFrame.timeIntervalSince(previousFrame)
                previousFrame = currentFrame

                // Gentle widget spin: 50°/s, one turn every ~7 s.
                angle = (angle + elapsed * 50).truncatingRemainder(dividingBy: 360)
            }
        }
        .onHover { hovering = $0 }
    }

    // The player deck: cream base, vinyl, tonearm
    private var deck: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Palette.cream, Palette.blush.opacity(0.55)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Palette.gold.opacity(0.6), lineWidth: 1.5)
                )
                .shadow(color: Palette.cocoa.opacity(0.25), radius: 12, y: 6)

            VinylDisc(artist: spotify.artistName, track: spotify.trackName, angle: angle)
                .frame(width: 190, height: 190)
                .offset(x: -18)

            Button(action: spotify.playPause) {
                Tonearm(playing: spotify.isPlaying)
                    .frame(width: 64, height: 132)
                    .contentShape(Rectangle())
            }
                .buttonStyle(.plain)
                .accessibilityLabel(spotify.isPlaying ? "Musik pausieren" : "Musik abspielen")
                .offset(x: 96, y: -50)

            if hovering {
                PlaybackControls()
                    .transition(.opacity)
                    .offset(y: 96)
            }
        }
        .frame(width: 276, height: 240)
        .animation(.easeInOut(duration: 0.25), value: hovering)
    }
}
