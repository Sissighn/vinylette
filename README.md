<p align="center">
  <img src="docs/logo.png" width="140" alt="Vinylette logo">
</p>

<h1 align="center">Vinylette</h1>

<p align="center">
  A vintage vinyl record player widget for macOS, connected to the Spotify desktop app.
</p>

<p align="center">
  <a href="https://github.com/Sissighn/vinylette/actions/workflows/ci.yml"><img src="https://github.com/Sissighn/vinylette/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
  <img src="https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-000000?logo=apple&logoColor=white" alt="macOS 13+">
  <img src="https://img.shields.io/badge/UI-SwiftUI-blue" alt="SwiftUI">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="MIT license"></a>
</p>

Vinylette lives on your desktop like a native widget: above the wallpaper and
icons, beneath every application window. While music plays, the record spins,
the gold tonearm rests on the vinyl, and the current track is printed on the
record label.

## Designs

Three looks, selectable from the settings menu that appears when hovering over
the widget. The choice is remembered across launches.

| Classic Label | Album Cover | Sleeve |
| :---: | :---: | :---: |
| ![Classic label design](docs/screenshots/classic-label.png) | ![Album cover design](docs/screenshots/album-cover.png) | ![Sleeve design](docs/screenshots/sleeve.png) |
| Artist and track printed on the record label | The album artwork as the record label | The record peeking out of its album sleeve |

## Features

- Spinning record with a stationary light reflection; only the label rotates,
  as it would on a real turntable
- Clickable gold tonearm to toggle playback, with previous/next controls on hover
- Three selectable designs, persisted across launches
- Desktop-widget window behavior: always on the desktop, never above your apps,
  present on every Space
- Remembers its dragged position and moves back onscreen when the display setup
  changes
- Pauses its animation while fully covered by other windows, so it consumes
  no energy it cannot show
- Menu bar item with the current track, design picker, launch-at-login toggle,
  show/hide, and quit actions
- Localized interface and accessibility labels in English and German
- No login and no API keys; playback state arrives instantly via Spotify's
  distributed notifications, commands go through AppleScript

## Requirements

- macOS 13 or later
- Xcode (Command Line Tools alone are not sufficient for SwiftUI apps)
- Spotify desktop app

## Build and Run

```sh
./build.sh
open Vinylette.app
```

On first launch, macOS asks whether Vinylette may control Spotify. Confirm with
"Allow". If you decline by accident, re-enable it under System Settings >
Privacy & Security > Automation.

## Architecture

The app is a SwiftUI view hosted in a borderless, non-activating `NSPanel`
pinned one window level below normal application windows.

Playback state is event-driven rather than polled: the controller subscribes
to Spotify's `com.spotify.client.PlaybackStateChanged` distributed
notification, so track changes reach the UI instantly and the app does no
periodic work. AppleScript is only used in three places — reading the initial
state at launch, looking up cover art URLs, and sending playback commands.
Script failures are logged via `os.Logger` and surfaced in the UI: when the
Automation permission is missing, the widget shows a hint with a direct
shortcut to the relevant System Settings pane. This design avoids OAuth, API
keys, and any network dependency beyond fetching cover art.

The spin animation runs in a frame loop that pauses automatically while the
panel is fully covered by other windows, tracked through the window's
occlusion state.

```
Sources/Vinylette
├── App
│   ├── VinyletteApp.swift      Entry point
│   ├── AppDelegate.swift       Wires panel, menu bar, and Spotify controller
│   ├── FloatingPanel.swift     Desktop-level, borderless, draggable panel
│   ├── Localization.swift      String Catalog access for AppKit and SwiftUI
│   ├── PanelVisibility.swift   Occlusion state observed by the UI
│   └── StatusBarController.swift
├── Spotify
│   ├── SpotifyController.swift Playback state and commands (event-driven)
│   ├── SpotifyTrack.swift      Playback-state model and payload parsing
│   └── AppleScriptRunner.swift
└── UI
    ├── VinylView.swift         Main view and the three design layouts
    ├── VinylDisc.swift         Record, grooves, label
    ├── Tonearm.swift
    ├── PlaybackControls.swift
    ├── WidgetDesign.swift
    ├── WidgetLayout.swift      Shared dimensions and motion constants
    └── Palette.swift
```

## Testing

```sh
swift test
```

Unit tests cover the AppleScript response parsing and the design persistence
model. Tests also run in CI on every push.

## License

Released under the [MIT License](LICENSE).
