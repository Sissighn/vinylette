import SwiftUI

/// The main widget. Shows one of three designs (selectable via the hover
/// settings menu): classic printed label, album cover label, or the record
/// peeking out of its album sleeve.
struct VinylView: View {
    @EnvironmentObject var spotify: SpotifyController
    @AppStorage("widgetDesign") private var designRaw = WidgetDesign.classicLabel.rawValue
    @State private var angle: Double = 0
    @State private var hovering = false

    private var design: WidgetDesign { WidgetDesign(rawValue: designRaw) ?? .classicLabel }

    var body: some View {
        ZStack {
            switch design {
            case .classicLabel, .albumCover:
                deck
            case .sleeve:
                sleeve
            }

            if hovering {
                settingsButton
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(10)
                    .transition(.opacity)

                PlaybackControls()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 6)
                    .transition(.opacity)
            }
        }
        .frame(width: 276, height: 240)
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
        .animation(.easeInOut(duration: 0.25), value: hovering)
    }

    // MARK: - Design 1 & 2: the player deck

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

            VinylDisc(artist: spotify.artistName,
                      track: spotify.trackName,
                      artwork: spotify.artwork,
                      style: design == .albumCover ? .cover : .text,
                      angle: angle)
                .frame(width: 190, height: 190)
                .offset(x: -18)

            tonearmButton
                .offset(x: 96, y: -50)
        }
    }

    // MARK: - Design 3: record peeking out of the album sleeve

    private var sleeve: some View {
        ZStack {
            VinylDisc(artist: spotify.artistName,
                      track: spotify.trackName,
                      angle: angle)
                .frame(width: 165, height: 165)
                .offset(x: 52)

            albumSleeve
                .offset(x: -36)

            tonearmButton
                .scaleEffect(0.85)
                .offset(x: 102, y: -28)
        }
    }

    private var albumSleeve: some View {
        Group {
            if let artwork = spotify.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Palette.blush
                    Text("♡")
                        .font(.system(size: 40, design: .serif))
                        .foregroundColor(Palette.cream)
                }
            }
        }
        .frame(width: 175, height: 175)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Palette.cocoa.opacity(0.35), radius: 10, y: 6)
    }

    // MARK: - Shared pieces

    private var tonearmButton: some View {
        Button(action: spotify.playPause) {
            Tonearm(playing: spotify.isPlaying)
                .frame(width: 64, height: 132)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(spotify.isPlaying ? "Musik pausieren" : "Musik abspielen")
    }

    private var settingsButton: some View {
        Menu {
            Picker("Design", selection: $designRaw) {
                ForEach(WidgetDesign.allCases) { design in
                    Text(design.displayName).tag(design.rawValue)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Palette.cocoa)
                .frame(width: 26, height: 26)
                .background(
                    Circle().fill(Palette.cream.opacity(0.92))
                        .overlay(Circle().strokeBorder(Palette.gold.opacity(0.5), lineWidth: 1))
                        .shadow(color: Palette.cocoa.opacity(0.2), radius: 4, y: 2)
                )
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel("Design auswählen")
    }
}
