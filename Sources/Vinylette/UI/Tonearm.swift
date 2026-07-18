import SwiftUI

/// A slim, gold tonearm modelled after the reference: a long straight upper
/// section, a tighter lower bend and a small angled cartridge at the tip.
struct Tonearm: View {
    let playing: Bool

    private let goldLight = Color(red: 1.00, green: 0.89, blue: 0.55)
    private let goldMid = Color(red: 0.79, green: 0.59, blue: 0.23)
    private let goldDeep = Color(red: 0.31, green: 0.20, blue: 0.07)

    var body: some View {
        ZStack {
            armTube
            counterweight
            adjustmentCollar
            headshell
            stylus
        }
        .frame(width: 110, height: 160)
        .scaleEffect(0.90)
        .rotationEffect(
            .degrees(playing ? 0 : -16),
            anchor: UnitPoint(x: 88.0 / 110.0, y: 29.0 / 160.0)
        )
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: playing)
        .shadow(color: .black.opacity(0.27), radius: 2, x: 1.2, y: 2)
    }

    private var armTube: some View {
        ZStack {
            // Fine dark edge gives the tube separation from the record.
            ArmTube()
                .stroke(
                    goldDeep.opacity(0.88),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
                )

            ArmTube()
                .stroke(
                    LinearGradient(
                        colors: [goldDeep, goldMid, goldLight, goldMid, goldDeep],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round)
                )

            ArmTube()
                .stroke(
                    Color.white.opacity(0.54),
                    style: StrokeStyle(lineWidth: 0.85, lineCap: .round)
                )
                .offset(x: -0.9)
        }
    }

    /// Compact cylindrical weight aligned with the upper arm, rather than a
    /// large turntable base. This is the silhouette visible in the reference.
    private var counterweight: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [goldDeep, goldMid, goldLight, goldMid, goldDeep],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(goldDeep.opacity(0.9), lineWidth: 1)
                )

            VStack(spacing: 14) {
                Capsule()
                    .fill(goldLight.opacity(0.85))
                    .frame(width: 18, height: 2.5)
                Capsule()
                    .fill(goldDeep.opacity(0.65))
                    .frame(width: 17, height: 2)
            }
        }
        .frame(width: 18, height: 29)
        .rotationEffect(.degrees(18))
        .position(x: 94, y: 16)
    }

    /// Narrow calibration ring on the otherwise straight upper section.
    private var adjustmentCollar: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(
                LinearGradient(
                    colors: [goldDeep, goldLight, goldMid],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 11, height: 5)
            .overlay(RoundedRectangle(cornerRadius: 1).stroke(goldDeep, lineWidth: 0.7))
            .rotationEffect(.degrees(17))
            .position(x: 78, y: 61)
    }

    private var headshell: some View {
        ZStack {
            HeadshellBody()
                .fill(
                    LinearGradient(
                        colors: [goldDeep, goldMid, goldLight, goldMid],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(HeadshellBody().stroke(goldDeep.opacity(0.9), lineWidth: 0.9))

            HStack(spacing: 7) {
                Circle().fill(goldDeep).frame(width: 3.1, height: 3.1)
                Circle().fill(goldDeep).frame(width: 3.1, height: 3.1)
            }
            .offset(x: -1)
        }
        .frame(width: 34, height: 14)
        .rotationEffect(.degrees(-31))
        .position(x: 21, y: 137)
    }

    private var stylus: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 23, y: 140))
                path.addLine(to: CGPoint(x: 28, y: 152))
            }
            .stroke(goldDeep, style: StrokeStyle(lineWidth: 1.25, lineCap: .round))

            Circle()
                .fill(Color.black.opacity(0.9))
                .frame(width: 2.8, height: 2.8)
                .position(x: 28, y: 152)
        }
    }
}

/// Geometrically restrained curve: almost straight from the weight through
/// the upper two thirds, then bending progressively toward the headshell.
private struct ArmTube: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 110
        let sy = rect.height / 160
        var path = Path()
        path.move(to: CGPoint(x: 89 * sx, y: 28 * sy))
        path.addCurve(
            to: CGPoint(x: 66 * sx, y: 96 * sy),
            control1: CGPoint(x: 84 * sx, y: 47 * sy),
            control2: CGPoint(x: 75 * sx, y: 77 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 31 * sx, y: 130 * sy),
            control1: CGPoint(x: 58 * sx, y: 113 * sy),
            control2: CGPoint(x: 48 * sx, y: 124 * sy)
        )
        return path
    }
}

/// A tapered headshell is more faithful than a plain rounded rectangle.
private struct HeadshellBody: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 2, y: rect.minY + 2))
        path.addLine(to: CGPoint(x: rect.maxX - 1, y: rect.minY + 4))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - 1, y: rect.maxY - 4),
            control: CGPoint(x: rect.maxX + 1, y: rect.midY)
        )
        path.addLine(to: CGPoint(x: rect.minX + 2, y: rect.maxY - 1))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + 2, y: rect.minY + 2),
            control: CGPoint(x: rect.minX - 1, y: rect.midY)
        )
        path.closeSubpath()
        return path
    }
}
