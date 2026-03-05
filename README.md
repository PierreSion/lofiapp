
<div align="center">
<img width="638" height="254" alt="Screenshot 2026-03-05 at 17 34 56" src="https://github.com/user-attachments/assets/aec511d7-27ad-4964-be30-83d73a182339" />
</div>

# LofiApp

A lightweight macOS menu bar app that plays the [Lofi Girl](https://www.youtube.com/@LofiGirl) YouTube livestream audio.

No browser tab needed — just click the menu bar icon and hit play.

## Features

- Menu bar only — no dock icon, no window
- Play/stop the Lofi Girl stream with one click
- Stream status indicator (loading, playing, buffering, error)
- Launch at Login toggle
- Lofi Girl app icon

## Installation

### Requirements

- macOS 14 (Sonoma) or later
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) installed via Homebrew

### Steps

1. Install yt-dlp:

   ```
   brew install yt-dlp
   ```

2. Install **LofiApp** from the [latest release](https://github.com/pierre-music/lofiapp/releases/latest)

---

## Development

### Build

```
./build.sh
```

This compiles the Swift source and produces `LofiApp.app` in the project directory.


### Project structure

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
