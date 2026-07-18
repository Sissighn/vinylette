# Vinylette

A small vintage vinyl player widget for macOS, connected to the local Spotify
desktop app. It floats above all windows and shows the currently playing track
as a spinning record.

## Features

- Spinning vinyl with the current album cover as the record label
- Tonearm that lowers onto the record while music is playing
- Play/pause and skip controls on hover
- Freely movable, stays on top of all windows and on all Spaces
- Menu bar icon to show, hide, and quit the widget
- No login and no API keys; communicates with the local Spotify app via AppleScript

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

## How It Works

The app is a SwiftUI view inside a borderless, floating NSPanel. A
SpotifyController polls the Spotify desktop app once per second via AppleScript
for the track title, artist, cover URL, and playback state. This avoids both
OAuth and any Spotify Premium requirement.
