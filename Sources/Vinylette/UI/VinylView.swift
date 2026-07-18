import SwiftUI

/// The main widget. Shows one of three designs (selectable via the hover
/// settings menu): classic printed label, album cover label, or the record
/// peeking out of its album sleeve.
struct VinylView: View {
    @EnvironmentObject var spotify: SpotifyController
    @EnvironmentObject var panelVisibility: PanelVisibility
    @AppStorage("widgetDesign") private var designRaw = WidgetDesign.classicLabel.rawValue
    @State private var angle: Double = 0
    @State private var hovering = false

    private var design: WidgetDesign { WidgetDesign(rawValue: designRaw) ?? .classicLabel }

    /// Spin only while music plays and someone can actually see the widget.
    private var isSpinning: Bool { spotify.isPlaying && panelVisibility.isVisible }

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

            if spotify.permissionDenied {
                permissionNotice
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .transition(.opacity)
            }
        }
        .frame(width: WidgetLayout.contentSize.width, height: WidgetLayout.contentSize.height)
        .padding(WidgetLayout.contentPadding)
        .task(id: isSpinning) {
            guard isSpinning else { return }

            var previousFrame = Date()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: WidgetLayout.spinFrameNanoseconds)
                let currentFrame = Date()
                let elapsed = currentFrame.timeIntervalSince(previousFrame)
                previousFrame = currentFrame

                angle = (angle + elapsed * WidgetLayout.spinDegreesPerSecond)
                    .truncatingRemainder(dividingBy: 360)
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
                .offset(x: 55, y: -14)
        }
    }

    // MARK: - Design 3: record peeking out of the album sleeve

    private var sleeve: some View {
        ZStack {
            albumSleeve
                .offset(x: -36)

            VinylDisc(artist: spotify.artistName,
                      track: spotify.trackName,
                      angle: angle)
                .frame(width: 165, height: 165)
                .offset(x: 52)

            tonearmButton
                .scaleEffect(0.82)
                // Follow the record's rightward offset: the stylus should sit
                // on the outer grooves, not across the paper label.
                .offset(x: 91, y: -11)
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
                .frame(width: 110, height: 160)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            spotify.isPlaying ? L10n.text("accessibility.pause") : L10n.text("accessibility.play")
        )
    }

    /// Shown when macOS blocks Apple Events to Spotify: a short hint with a
    /// direct route to the Automation pane in System Settings.
    private var permissionNotice: some View {
        HStack(spacing: 10) {
            Text(L10n.text("permission.missing"))
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundColor(Palette.cocoa)
            Button(L10n.text("permission.allow")) { spotify.openAutomationSettings() }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Palette.rose)
                .accessibilityLabel(L10n.text("accessibility.openAutomationSettings"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule().fill(Palette.cream.opacity(0.96))
                .overlay(Capsule().strokeBorder(Palette.rose.opacity(0.55), lineWidth: 1))
                .shadow(color: Palette.cocoa.opacity(0.25), radius: 5, y: 2)
        )
    }

    private var settingsButton: some View {
        Menu {
            Picker(L10n.text("menu.design"), selection: $designRaw) {
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
        .accessibilityLabel(L10n.text("accessibility.design"))
    }
}
