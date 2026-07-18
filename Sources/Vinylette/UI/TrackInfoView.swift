import SwiftUI

/// Capsule below the deck showing the current track title and artist.
struct TrackInfoView: View {
    let title: String
    let subtitle: String

    var body: some View {
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
}
