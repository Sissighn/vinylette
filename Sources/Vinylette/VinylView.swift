import SwiftUI

// MARK: - Palette (vintage · soft · feminine)

enum Palette {
    static let cream = Color(red: 0.97, green: 0.94, blue: 0.89)      // warm ivory
    static let blush = Color(red: 0.89, green: 0.76, blue: 0.74)      // dusty rose
    static let rose = Color(red: 0.80, green: 0.58, blue: 0.56)       // deeper rose
    static let gold = Color(red: 0.78, green: 0.66, blue: 0.43)       // antique gold
    static let cocoa = Color(red: 0.36, green: 0.27, blue: 0.23)      // soft brown
    static let vinyl = Color(red: 0.13, green: 0.11, blue: 0.11)      // warm black
}

// MARK: - Main view

struct VinylView: View {
    @EnvironmentObject var spotify: SpotifyController
    @State private var angle: Double = 0
    @State private var hovering = false

    private let spin = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 10) {
            deck
            if spotify.isRunning && !spotify.trackName.isEmpty {
                trackInfo
            }
        }
        .padding(12)
        .onReceive(spin) { _ in
            if spotify.isPlaying { angle += 0.9 } // gentle ~27°/s spin
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

            VinylDisc(artwork: spotify.artwork)
                .frame(width: 190, height: 190)
                .rotationEffect(.degrees(angle))
                .offset(x: -18)

            Tonearm(playing: spotify.isPlaying)
                .offset(x: 96, y: -50)
                .contentShape(Rectangle())
                .onTapGesture { spotify.playPause() }

            if hovering {
                controls
                    .transition(.opacity)
                    .offset(y: 96)
            }
        }
        .frame(width: 276, height: 240)
        .animation(.easeInOut(duration: 0.25), value: hovering)
    }

    private var controls: some View {
        HStack(spacing: 22) {
            ControlButton(symbol: "backward.fill") { spotify.previousTrack() }
            ControlButton(symbol: spotify.isPlaying ? "pause.fill" : "play.fill",
                          prominent: true) { spotify.playPause() }
            ControlButton(symbol: "forward.fill") { spotify.nextTrack() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(Palette.cream.opacity(0.92))
                .overlay(Capsule().strokeBorder(Palette.gold.opacity(0.5), lineWidth: 1))
                .shadow(color: Palette.cocoa.opacity(0.2), radius: 6, y: 2)
        )
    }

    private var trackInfo: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .italic()
                .foregroundColor(Palette.cocoa)
                .lineLimit(1)
            Text(subtitle)
                .font(.system(size: 12, design: .serif))
                .foregroundColor(Palette.rose)
                .lineLimit(1)
        }
        .frame(maxWidth: 260)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule().fill(Palette.cream.opacity(0.95))
                .overlay(Capsule().strokeBorder(Palette.blush, lineWidth: 1))
                .shadow(color: Palette.cocoa.opacity(0.15), radius: 5, y: 2)
        )
    }

    private var title: String { spotify.trackName }

    private var subtitle: String {
        spotify.artistName.isEmpty ? "♡" : spotify.artistName
    }
}

// MARK: - Vinyl disc

struct VinylDisc: View {
    let artwork: NSImage?

    var body: some View {
        ZStack {
            // Record with subtle sheen
            Circle()
                .fill(
                    AngularGradient(
                        colors: [Palette.vinyl, .black, Palette.vinyl,
                                 Color(white: 0.22), Palette.vinyl],
                        center: .center
                    )
                )
                .shadow(color: .black.opacity(0.35), radius: 8, y: 4)

            // Grooves
            ForEach(0..<7) { i in
                Circle()
                    .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                    .padding(CGFloat(8 + i * 9))
            }

            // Center label: album art, or a rose-colored label as fallback
            Group {
                if let artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Palette.blush
                        Text("♡")
                            .font(.system(size: 26, design: .serif))
                            .foregroundColor(Palette.cream)
                    }
                }
            }
            .frame(width: 76, height: 76)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Palette.gold.opacity(0.7), lineWidth: 1.5))

            // Spindle
            Circle()
                .fill(Palette.cream)
                .frame(width: 7, height: 7)
        }
    }
}

// MARK: - Tonearm

struct Tonearm: View {
    let playing: Bool

    var body: some View {
        ZStack(alignment: .top) {
            // Arm
            RoundedRectangle(cornerRadius: 2)
                .fill(Palette.gold)
                .frame(width: 4, height: 92)
                .offset(y: 12)
            // Pivot base
            Circle()
                .fill(
                    RadialGradient(colors: [Palette.gold, Palette.cocoa],
                                   center: .center, startRadius: 1, endRadius: 12)
                )
                .frame(width: 22, height: 22)
            // Needle head
            Capsule()
                .fill(Palette.cocoa)
                .frame(width: 10, height: 22)
                .offset(y: 96)
        }
        .rotationEffect(.degrees(playing ? 24 : -8), anchor: .top)
        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: playing)
        .shadow(color: Palette.cocoa.opacity(0.3), radius: 3, x: 2, y: 2)
    }
}

// MARK: - Control button

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
