import SwiftUI

/// Realistic gold tonearm: counterweight, pivot bearing, S-curved tube
/// and an angled headshell with stylus. Swings onto the record while playing.
struct Tonearm: View {
    let playing: Bool

    private let goldLight = Color(red: 0.96, green: 0.88, blue: 0.66)
    private let goldDeep = Color(red: 0.55, green: 0.42, blue: 0.22)

    var body: some View {
        ZStack(alignment: .top) {
            // Counterweight behind the pivot
            Capsule()
                .fill(
                    LinearGradient(colors: [goldLight, Palette.gold, goldDeep],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .frame(width: 15, height: 22)

            // S-curved arm tube with a metallic edge highlight
            ArmTube()
                .stroke(
                    LinearGradient(colors: [goldLight, Palette.gold, goldDeep],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
            ArmTube()
                .stroke(Color.white.opacity(0.45),
                        style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
                .offset(x: -1.2)

            // Pivot bearing
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [goldLight, Palette.gold, goldDeep],
                                       center: .topLeading, startRadius: 2, endRadius: 18)
                    )
                Circle().strokeBorder(goldDeep.opacity(0.8), lineWidth: 1)
                Circle()
                    .fill(
                        RadialGradient(colors: [Palette.cream, Palette.gold],
                                       center: .topLeading, startRadius: 0, endRadius: 6)
                    )
                    .frame(width: 9, height: 9)
            }
            .frame(width: 26, height: 26)
            .offset(y: 12)

            headshell
                .offset(x: 8, y: 102)
        }
        .frame(width: 44, height: 132, alignment: .top)
        .rotationEffect(.degrees(playing ? 24 : -8),
                        anchor: UnitPoint(x: 0.5, y: 0.19)) // rotate around the bearing
        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: playing)
        .shadow(color: Palette.cocoa.opacity(0.35), radius: 3, x: 2, y: 2)
    }

    /// Angled cartridge at the end of the arm.
    private var headshell: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(
                LinearGradient(colors: [goldLight, Palette.gold, goldDeep],
                               startPoint: .top, endPoint: .bottom)
            )
            .frame(width: 13, height: 26)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(goldDeep.opacity(0.6), lineWidth: 0.8)
            )
            .rotationEffect(.degrees(18))
    }
}

/// Gentle S-curve from the bearing down to the headshell.
private struct ArmTube: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: 24))
        p.addCurve(
            to: CGPoint(x: rect.midX + 8, y: 108),
            control1: CGPoint(x: rect.midX - 14, y: 55),
            control2: CGPoint(x: rect.midX + 16, y: 94)
        )
        return p
    }
}
