import SwiftUI

/// The record: near-black disc with fine grooves, track-separator bands,
/// a stationary light sheen, and a printed center label. Only the label
/// rotates — the sheen stays put like a real light reflection.
struct VinylDisc: View {
    enum LabelStyle { case text, cover }

    let artist: String
    let track: String
    var artwork: NSImage? = nil
    var style: LabelStyle = .text
    var angle: Double = 0

    var body: some View {
        ZStack {
            // Vinyl base with a soft edge bevel
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(white: 0.10), location: 0.0),
                            .init(color: Palette.vinyl, location: 0.55),
                            .init(color: Color(white: 0.03), location: 0.96),
                            .init(color: Color(white: 0.20), location: 1.0),
                        ]),
                        center: .center, startRadius: 0, endRadius: 95
                    )
                )
                .shadow(color: .black.opacity(0.4), radius: 9, y: 5)

            // Fine grooves from the edge down to the run-out area
            ForEach(0..<16) { i in
                Circle()
                    .strokeBorder(Color.white.opacity(0.045), lineWidth: 0.6)
                    .padding(5 + CGFloat(i) * 2.6)
            }

            // Track-separator bands (slightly shinier rings)
            ForEach([9, 22, 34], id: \.self) { inset in
                Circle()
                    .strokeBorder(Color.white.opacity(0.09), lineWidth: 1.3)
                    .padding(CGFloat(inset))
            }

            // Stationary sheen — two soft light bands sweeping the surface
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0.00),
                            .init(color: .white.opacity(0.10), location: 0.07),
                            .init(color: .clear, location: 0.16),
                            .init(color: .clear, location: 0.48),
                            .init(color: .white.opacity(0.06), location: 0.56),
                            .init(color: .clear, location: 0.66),
                            .init(color: .clear, location: 1.00),
                        ]),
                        center: .center,
                        angle: .degrees(-50)
                    )
                )

            label
                .frame(width: 92, height: 92)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Palette.gold.opacity(0.7), lineWidth: 1.5))
                .rotationEffect(.degrees(angle))

            // Spindle
            Circle()
                .fill(
                    RadialGradient(colors: [Color(white: 0.85), Color(white: 0.5)],
                                   center: .topLeading, startRadius: 0, endRadius: 7)
                )
                .frame(width: 7, height: 7)
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
                        .font(.system(size: 10, weight: .semibold, design: .serif))
                        .foregroundColor(Palette.vinyl)
                    Spacer(minLength: 16)
                    Text(track)
                        .font(.system(size: 8.5, design: .serif))
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
