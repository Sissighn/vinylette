<p align="center">
  <img src="docs/logo.png" width="140" alt="Vinylette logo">
</p>

<h1 align="center">Vinylette</h1>

<p align="center">
  A vintage vinyl record player widget for macOS, connected to the Spotify desktop app.
</p>

<p align="center">
  <a href="https://github.com/Sissighn/vinylette/actions/workflows/ci.yml"><img src="https://github.com/Sissighn/vinylette/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
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
- Menu bar item to show, hide, and quit the widget
- No login and no API keys; playback state is read from the local Spotify app
  via AppleScript

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
pinned one window level below normal application windows. A controller polls
the Spotify desktop app once per second via AppleScript and publishes the
playback state to the UI; playback commands go the same route. This avoids
OAuth, API keys, and any network dependency beyond fetching cover art.

```
Sources/Vinylette
├── main.swift                  Entry point
├── App
│   ├── AppDelegate.swift       Wires panel, menu bar, and Spotify controller
│   ├── FloatingPanel.swift     Desktop-level, borderless, draggable panel
│   └── StatusBarController.swift
├── Spotify
│   ├── SpotifyController.swift Polling and playback commands
│   ├── SpotifyTrack.swift      Playback-state model and response parsing
│   └── AppleScriptRunner.swift
└── UI
    ├── VinylView.swift         Main view and the three design layouts
    ├── VinylDisc.swift         Record, grooves, label
    ├── Tonearm.swift
    ├── PlaybackControls.swift
    ├── WidgetDesign.swift
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
