import SwiftUI

/// A black LP with dense grooves, run-out rings and a stationary reflection.
/// Only the paper label rotates; the light stays fixed like it would in a room.
struct VinylDisc: View {
    enum LabelStyle { case text, cover }

    let artist: String
    let track: String
    var artwork: NSImage? = nil
    var style: LabelStyle = .text
    var angle: Double = 0

    var body: some View {
        ZStack {
            // Deep black PVC with a raised, polished outer edge.
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(white: 0.13), location: 0.00),
                            .init(color: Color(white: 0.035), location: 0.46),
                            .init(color: Color(white: 0.075), location: 0.78),
                            .init(color: Color(white: 0.018), location: 0.975),
                            .init(color: Color(white: 0.24), location: 1.00),
                        ]),
                        center: .center, startRadius: 0, endRadius: 95
                    )
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.24), .black, .white.opacity(0.07)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.2
                        )
                )
                .shadow(color: .black.opacity(0.5), radius: 9, y: 5)

            // Closely spaced grooves with slightly irregular highlights.
            ForEach(0..<28) { i in
                Circle()
                    .strokeBorder(
                        i.isMultiple(of: 5)
                            ? Color.white.opacity(0.105)
                            : Color.white.opacity(0.042),
                        lineWidth: i.isMultiple(of: 7) ? 0.9 : 0.45
                    )
                    .padding(5 + CGFloat(i) * 2.55)
            }

            // Wider lead-in and track-separator bands.
            ForEach([10, 23, 37, 50], id: \.self) { inset in
                Circle()
                    .strokeBorder(Color.white.opacity(0.115), lineWidth: 1.05)
                    .padding(CGFloat(inset))
            }

            // Two broad reflections across the grooves, matching the reference.
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0.00),
                            .init(color: .white.opacity(0.025), location: 0.045),
                            .init(color: .white.opacity(0.22), location: 0.095),
                            .init(color: .white.opacity(0.035), location: 0.17),
                            .init(color: .clear, location: 0.27),
                            .init(color: .clear, location: 0.51),
                            .init(color: .white.opacity(0.11), location: 0.58),
                            .init(color: .clear, location: 0.69),
                            .init(color: .clear, location: 1.00),
                        ]),
                        center: .center,
                        angle: .degrees(-58)
                    )
                )
                .padding(2.5)
                .blendMode(.screen)

            Circle()
                .trim(from: 0.08, to: 0.30)
                .stroke(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.27), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 1.1, lineCap: .round)
                )
                .padding(15)
                .rotationEffect(.degrees(-20))

            // Recess around the center paper label.
            Circle()
                .fill(Color.black.opacity(0.68))
                .frame(width: 84, height: 84)
                .overlay(Circle().stroke(Color.white.opacity(0.11), lineWidth: 1))

            label
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .overlay(Circle().fill(Color.white.opacity(0.055)))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.68), lineWidth: 1))
                .shadow(color: .black.opacity(0.55), radius: 2, y: 1)
                .rotationEffect(.degrees(angle))

            // Domed metal spindle.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, Color(white: 0.61), Color(white: 0.15)],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 5
                    )
                )
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(.black.opacity(0.48), lineWidth: 0.6))
                .shadow(color: .black.opacity(0.55), radius: 1, y: 1)
        }
    }

    // Printed like a real record label — artist above the spindle,
    // track title below, in warm serif type.
    private var label: some View {
        ZStack {
            Circle().fill(Palette.cream)
            if style == .cover, let artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .scaledToFill()
            } else if track.isEmpty {
                Text("♡")
                    .font(.system(size: 26, design: .serif))
                    .foregroundColor(Palette.blush)
            } else {
                VStack(spacing: 0) {
                    Text(artist)
                        .font(.system(size: 8.5, weight: .semibold, design: .serif))
                        .foregroundColor(Palette.vinyl)
                    Spacer(minLength: 16)
                    Text(track)
                        .font(.system(size: 7, design: .serif))
                        .italic()
                        .foregroundColor(Palette.cocoa)
                }
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.55)
                .padding(.horizontal, 9)
                .padding(.vertical, 14)
            }
        }
    }
}
