# LofiApp

A lightweight macOS menu bar app that plays the [Lofi Girl](https://www.youtube.com/@LofiGirl) YouTube livestream audio.

No browser tab needed — just click the menu bar icon and hit play.

## Features

- Menu bar only — no dock icon, no window
- Play/stop the Lofi Girl stream with one click
- Stream status indicator (loading, playing, buffering, error)
- Launch at Login toggle
- Lofi Girl app icon

## Requirements

- macOS 14 (Sonoma) or later
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) installed via Homebrew

## Install yt-dlp

```
brew install yt-dlp
```

## Build

```
./build.sh
```

This compiles the Swift source and produces `LofiApp.app` in the project directory.

## Run

Double-click `LofiApp.app`, or:

```
open LofiApp.app
```

To make it available in Spotlight, drag `LofiApp.app` to `/Applications`.

## How it works

1. When you click Play, the app calls `yt-dlp` to extract the audio stream URL from the Lofi Girl YouTube livestream
2. The HLS stream URL is fed to macOS's built-in `AVPlayer` for audio playback
3. Stream URLs expire after a few hours, so a fresh URL is fetched each time you start playback

## Project structure

```
LofiApp/
├── LofiApp.swift              # App entry point (MenuBarExtra)
├── MenuBarView.swift          # Popover UI
├── StreamPlayer.swift         # yt-dlp + AVPlayer integration
├── LaunchAtLoginToggle.swift  # SMAppService toggle
├── AppIcon.icns               # App icon
├── Info.plist                 # LSUIElement (hides dock icon)
└── LofiApp.entitlements       # No sandbox (needed for yt-dlp)
```
