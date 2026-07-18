import SwiftUI

/// The golden tonearm; swings onto the record while music is playing.
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
