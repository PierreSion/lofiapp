# Lofi Girl Menu Bar App — Brainstorm

**Date:** 2026-03-03
**Status:** Complete

## What We're Building

A native macOS menu bar app that plays the Lofi Girl YouTube livestream audio. The app lives entirely in the menu bar (no dock icon) and provides a small dropdown popover with:

- Play/pause toggle (click the menu bar icon to toggle)
- Stream status info (playing, loading, error)
- "Launch at Login" toggle

## Why This Approach

**Architecture:** Swift + SwiftUI menu bar app using `yt-dlp` for YouTube stream URL extraction and `AVPlayer` for audio playback.

**Rationale:**
- SwiftUI is the modern, lightweight choice for macOS menu bar utilities
- `yt-dlp` is the most reliable way to extract playable audio URLs from YouTube livestreams
- `AVPlayer` (AVFoundation) handles HTTP audio streams natively with minimal code
- Requiring Homebrew-installed yt-dlp keeps the app simple and avoids bundling/update complexity

**Rejected alternative:** Hidden WKWebView approach — too heavy, fragile against YouTube page changes, and harder to isolate just the audio stream.

## Key Decisions

1. **Tech stack:** Swift + SwiftUI, Xcode project
2. **Audio source:** Lofi Girl YouTube livestream, URL extracted via `yt-dlp --get-url`
3. **Audio playback:** AVFoundation `AVPlayer` with the extracted stream URL
4. **yt-dlp dependency:** User installs via Homebrew (`brew install yt-dlp`). App calls it from PATH
5. **UI:** Menu bar icon with dropdown menu (play/pause, status info, launch at login toggle). No volume slider — keep it minimal
6. **No dock icon:** App runs as `LSUIElement` (agent app), menu bar only
7. **Launch at Login:** Supported via `SMAppService`, with a toggle in the dropdown
8. **App name:** LofiApp (working title)

## Open Questions

_None — all key decisions resolved._
