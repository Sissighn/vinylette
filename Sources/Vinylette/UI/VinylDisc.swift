import SwiftUI

/// The record itself: black disc with grooves and a printed center label —
/// artist above the spindle, track title below, in warm serif type.
struct VinylDisc: View {
    let artist: String
    let track: String

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

            label
                .frame(width: 92, height: 92)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Palette.gold.opacity(0.7), lineWidth: 1.5))

            // Spindle
            Circle()
                .fill(
                    RadialGradient(colors: [Color(white: 0.85), Color(white: 0.5)],
                                   center: .topLeading, startRadius: 0, endRadius: 7)
                )
                .frame(width: 7, height: 7)
        }
    }

    private var label: some View {
        ZStack {
            Circle().fill(Palette.cream)
            if track.isEmpty {
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
