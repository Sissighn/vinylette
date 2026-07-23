import SwiftUI

/// The main widget. Shows one of three designs (selectable via the hover
/// settings menu): classic printed label, album cover label, or the record
/// peeking out of its album sleeve.
struct VinylView: View {
    @EnvironmentObject var spotify: SpotifyController
    @EnvironmentObject var panelVisibility: PanelVisibility
    @AppStorage(WidgetSettings.designKey) private var designRaw = WidgetDesign.classicLabel.rawValue
    @State private var angle: Double = 0
    @State private var hovering = false

    private var design: WidgetDesign { WidgetDesign(rawValue: designRaw) ?? .classicLabel }

    /// Spin only while music plays and someone can actually see the widget.
    private var isSpinning: Bool {
        spotify.state.isPlaying && panelVisibility.isVisible
    }

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

            playbackNotice
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .transition(.opacity)
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

            VinylDisc(
                artist: spotify.state.track?.artist ?? "",
                track: spotify.state.track?.name ?? "",
                artwork: spotify.state.track?.artwork,
                style: design == .albumCover ? .cover : .text,
                angle: angle
            )
            .frame(
                width: WidgetLayout.deckDisc.diameter,
                height: WidgetLayout.deckDisc.diameter
            )
            .offset(x: WidgetLayout.deckDisc.center.x, y: WidgetLayout.deckDisc.center.y)

            tonearm(on: WidgetLayout.deckDisc)
        }
    }

    // MARK: - Design 3: record peeking out of the album sleeve

    private var sleeve: some View {
        ZStack {
            albumSleeve
                .offset(
                    x: WidgetLayout.sleeveCoverCenter.x,
                    y: WidgetLayout.sleeveCoverCenter.y
                )

            VinylDisc(
                artist: spotify.state.track?.artist ?? "",
                track: spotify.state.track?.name ?? "",
                angle: angle
            )
            .frame(
                width: WidgetLayout.sleeveDisc.diameter,
                height: WidgetLayout.sleeveDisc.diameter
            )
            .offset(x: WidgetLayout.sleeveDisc.center.x, y: WidgetLayout.sleeveDisc.center.y)

            tonearm(on: WidgetLayout.sleeveDisc)
        }
    }

    private var albumSleeve: some View {
        ZStack {
            if let artwork = spotify.state.track?.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .scaledToFill()
                    .id(ObjectIdentifier(artwork))
                    .transition(.opacity)
            } else {
                ZStack {
                    Palette.blush
                    Text("♡")
                        .font(.system(size: 40, design: .serif))
                        .foregroundColor(Palette.cream)
                }
                .transition(.opacity)
            }
        }
        // Cross-fade when a new cover arrives instead of swapping abruptly.
        .animation(
            .easeInOut(duration: WidgetLayout.artworkCrossfadeSeconds),
            value: spotify.state.track?.artwork.map(ObjectIdentifier.init)
        )
        .frame(width: 175, height: 175)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Palette.cocoa.opacity(0.35), radius: 10, y: 6)
    }

    // MARK: - Shared pieces

    /// Places the tonearm from the shared anchors in `WidgetLayout`, so every
    /// design puts the stylus on the same groove of its record.
    private func tonearm(on disc: WidgetLayout.DiscPlacement) -> some View {
        let offset = WidgetLayout.tonearmOffset(on: disc)
        return
            tonearmButton
            .scaleEffect(WidgetLayout.tonearmScale(on: disc))
            .offset(x: offset.x, y: offset.y)
    }

    private var tonearmButton: some View {
        Button(action: spotify.playPause) {
            Tonearm(playing: spotify.state.isPlaying)
                .frame(width: 110, height: 160)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!spotify.state.canControlPlayback)
        .accessibilityLabel(
            spotify.state.isPlaying
                ? L10n.Accessibility.pause
                : L10n.Accessibility.play
        )
    }

    @ViewBuilder
    private var playbackNotice: some View {
        switch spotify.state {
        case .spotifyUnavailable:
            unavailableNotice
        case .permissionRequired:
            permissionNotice
        case .failed(let error):
            errorNotice(error)
        case .idle, .paused, .playing:
            EmptyView()
        }
    }

    private var unavailableNotice: some View {
        Text(L10n.Spotify.unavailable)
            .font(.system(size: 11, weight: .semibold, design: .serif))
            .foregroundColor(Palette.cocoa)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(noticeBackground)
    }

    /// Shown when macOS blocks Apple Events to Spotify: a short hint with a
    /// direct route to the Automation pane in System Settings.
    private var permissionNotice: some View {
        HStack(spacing: 10) {
            Text(L10n.Permission.missing)
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundColor(Palette.cocoa)
            Button(L10n.Permission.allow) { spotify.openAutomationSettings() }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Palette.rose)
                .accessibilityLabel(L10n.Accessibility.openAutomationSettings)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(noticeBackground)
    }

    private func errorNotice(_ error: PlaybackError) -> some View {
        HStack(spacing: 10) {
            Text(error.message)
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundColor(Palette.cocoa)
            Button(L10n.SpotifyError.dismiss) { spotify.dismissError() }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Palette.rose)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(noticeBackground)
    }

    private var noticeBackground: some View {
        Capsule().fill(Palette.cream.opacity(0.96))
            .overlay(Capsule().strokeBorder(Palette.rose.opacity(0.55), lineWidth: 1))
            .shadow(color: Palette.cocoa.opacity(0.25), radius: 5, y: 2)
    }

    private var settingsButton: some View {
        Menu {
            Picker(L10n.Menu.design, selection: $designRaw) {
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
        .accessibilityLabel(L10n.Accessibility.design)
    }
}
