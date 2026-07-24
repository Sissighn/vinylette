import SwiftUI

/// Hover controls styled and positioned for the selected widget composition.
struct PlaybackControls: View {
    @EnvironmentObject var spotify: SpotifyController
    let design: WidgetDesign

    private var metrics: WidgetLayout.ControlsPlacement {
        WidgetLayout.controls(for: design)
    }

    private var appearance: PlaybackControlAppearance {
        PlaybackControlAppearance(design: design)
    }

    var body: some View {
        HStack(spacing: metrics.spacing) {
            control(symbol: "backward.fill", help: L10n.Control.previous) {
                spotify.previousTrack()
            }
            control(
                symbol: spotify.state.isPlaying ? "pause.fill" : "play.fill",
                help: L10n.Control.playPause,
                prominent: true
            ) {
                spotify.playPause()
            }
            control(symbol: "forward.fill", help: L10n.Control.next) {
                spotify.nextTrack()
            }
            control(
                symbol: "repeat",
                help: L10n.Control.repeatPlayback,
                active: spotify.state.isRepeating
            ) {
                spotify.toggleRepeat()
            }
        }
        .padding(.horizontal, metrics.horizontalPadding)
        .padding(.vertical, metrics.verticalPadding)
        .background(
            Capsule()
                .fill(appearance.barBackground)
                .overlay(
                    Capsule().strokeBorder(appearance.barBorder, lineWidth: 1)
                )
                .shadow(color: appearance.shadow, radius: 6, y: 2)
        )
        .disabled(!spotify.state.canControlPlayback)
        .opacity(spotify.state.canControlPlayback ? 1 : 0.55)
        .animation(.easeInOut(duration: 0.18), value: spotify.state.isRepeating)
    }

    private func control(
        symbol: String,
        help: String,
        prominent: Bool = false,
        active: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        ControlButton(
            symbol: symbol,
            help: help,
            diameter: prominent ? metrics.primaryDiameter : metrics.secondaryDiameter,
            symbolSize: prominent
                ? metrics.primaryDiameter * 0.44
                : metrics.secondaryDiameter * 0.43,
            foreground: prominent ? appearance.primaryIcon : appearance.secondaryIcon,
            background: prominent
                ? appearance.primaryBackground
                : (active ? appearance.activeBackground : appearance.secondaryBackground),
            action: action
        )
    }
}

private struct PlaybackControlAppearance {
    let barBackground: Color
    let barBorder: Color
    let primaryBackground: Color
    let primaryIcon: Color
    let secondaryBackground: Color
    let secondaryIcon: Color
    let activeBackground: Color
    let shadow: Color

    init(design: WidgetDesign) {
        switch design {
        case .classicLabel:
            barBackground = Palette.cream.opacity(0.94)
            barBorder = Palette.gold.opacity(0.55)
            primaryBackground = Palette.rose
            primaryIcon = Palette.cream
            secondaryBackground = Palette.blush.opacity(0.72)
            secondaryIcon = Palette.cocoa
            activeBackground = Palette.gold.opacity(0.9)
            shadow = Palette.cocoa.opacity(0.22)
        case .albumCover:
            barBackground = Palette.vinyl.opacity(0.92)
            barBorder = Palette.gold.opacity(0.78)
            primaryBackground = Palette.gold
            primaryIcon = Palette.vinyl
            secondaryBackground = Palette.cocoa.opacity(0.82)
            secondaryIcon = Palette.cream
            activeBackground = Palette.rose
            shadow = Color.black.opacity(0.32)
        case .sleeve:
            barBackground = Palette.cream.opacity(0.96)
            barBorder = Palette.rose.opacity(0.65)
            primaryBackground = Palette.cocoa
            primaryIcon = Palette.cream
            secondaryBackground = Palette.blush.opacity(0.8)
            secondaryIcon = Palette.cocoa
            activeBackground = Palette.gold.opacity(0.92)
            shadow = Palette.cocoa.opacity(0.24)
        }
    }
}

/// Round icon button used inside the controls capsule.
private struct ControlButton: View {
    let symbol: String
    let help: String
    let diameter: CGFloat
    let symbolSize: CGFloat
    let foreground: Color
    let background: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: symbolSize, weight: .bold))
                .foregroundColor(foreground)
                .frame(width: diameter, height: diameter)
                .background(Circle().fill(background))
        }
        .buttonStyle(.plain)
        .help(help)
        .accessibilityLabel(help)
    }
}
