---
title: "feat: Lofi Girl Menu Bar Player"
type: feat
status: completed
date: 2026-03-03
---

# feat: Lofi Girl Menu Bar Player

## Overview

A native macOS menu bar-only app that plays the Lofi Girl YouTube livestream audio. Click an icon in the menu bar, hit play, and chill. No dock icon, no main window — just a tiny popover with play/pause, status, and a few settings.

## Problem Statement / Motivation

Playing the Lofi Girl stream currently means keeping a browser tab open with YouTube. This wastes memory, clutters the browser, and makes it easy to accidentally close. A dedicated menu bar app provides one-click access to the stream with zero footprint.

## Proposed Solution

A SwiftUI menu bar app using `MenuBarExtra` (macOS 13+) with:
- **yt-dlp** (Homebrew) to extract the audio stream URL from the YouTube livestream
- **AVPlayer** (AVFoundation) to play the HLS audio stream
- **SMAppService** for optional launch-at-login

### Architecture

```
┌─────────────────────────────────────┐
│           LofiApp (@main)           │
│  MenuBarExtra (.window style)       │
├─────────────────────────────────────┤
│         MenuBarView (SwiftUI)       │
│  ┌─────────┐ ┌──────────────────┐  │
│  │ Play/⏸  │ │  Status label    │  │
│  └─────────┘ └──────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │  Launch at Login toggle      │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │  Quit button                 │  │
│  └──────────────────────────────┘  │
├─────────────────────────────────────┤
│        StreamPlayer (model)         │
│  - resolveURL() via yt-dlp Process  │
│  - play/stop via AVPlayer           │
│  - state: idle/loading/playing/error│
└─────────────────────────────────────┘
```

### File Structure

```
LofiApp/
├── LofiApp.swift              # @main, MenuBarExtra scene
├── StreamPlayer.swift         # yt-dlp + AVPlayer logic
├── MenuBarView.swift          # SwiftUI popover content
├── LaunchAtLoginToggle.swift  # SMAppService toggle
├── Info.plist                 # LSUIElement = YES
└── Assets.xcassets/           # Menu bar icon
```

## Technical Considerations

### yt-dlp Integration

- **Command:** `yt-dlp -g -f bestaudio -q --no-warnings <url>`
- **YouTube URL:** `https://www.youtube.com/watch?v=jfKfPfyJRdk` (Lofi Girl — beats to relax/study to)
- **Output:** Returns an m3u8 HLS manifest URL that AVPlayer handles natively
- **Path resolution:** Try `/opt/homebrew/bin/yt-dlp` (Apple Silicon), fall back to `/usr/local/bin/yt-dlp` (Intel), then show "yt-dlp not found" error with install instructions
- **Timeout:** Kill the process after 15 seconds to prevent indefinite hangs
- **URL expiry:** YouTube HLS URLs expire after a few hours. Always re-fetch when starting playback.

### AVPlayer Streaming

- Feed the m3u8 URL directly to `AVPlayer` — it handles HLS natively
- Observe `AVPlayerItem.status` via KVO: wait for `.readyToPlay` before calling `play()`
- Observe `AVPlayerItem.isPlaybackLikelyToKeepUp` for stall detection → show "Buffering..."
- Keep a strong reference to `AVPlayer` on the model to prevent deallocation

### Key Behaviors & Edge Cases

| Scenario | Behavior |
|---|---|
| App launch | Idle state, user clicks Play to start |
| Click Play | Show "Loading...", spawn yt-dlp, then start AVPlayer |
| Click Stop | `AVPlayer.pause()`, set player to nil, return to idle |
| Click Play again | Always re-fetch URL via yt-dlp (URLs expire) |
| yt-dlp not found | Error: "yt-dlp not found. Install with: brew install yt-dlp" |
| yt-dlp timeout (>15s) | Kill process, show error, allow retry |
| Stream unavailable | Show error from yt-dlp stderr |
| Network drops during playback | Detect stall, show "Connection lost", allow retry |
| System sleep/wake | AVPlayer will stall; user clicks Play to restart |
| Rapid Play clicks | Guard with `isLoading` flag, ignore while loading |
| Popover dismissed during loading | yt-dlp continues, playback starts in background |
| Another app takes audio | System handles ducking; no special handling needed |

### State Machine

```
         ┌──────┐
         │ Idle │ ← initial state on launch
         └──┬───┘
    Play    │     ▲ Stop / Error dismissed
            ▼     │
        ┌────────┐
        │Loading │ ← yt-dlp running + AVPlayer buffering
        └──┬─────┘
  Ready    │     ▲ Stall detected
           ▼     │
       ┌────────┐
       │Playing │ ← audio streaming
       └──┬─────┘
  Error   │
          ▼
       ┌───────┐
       │ Error │ ← shows message + retry button
       └───────┘
```

### Menu Bar Icon

- Use SF Symbol `music.note` for the menu bar icon
- Optionally: `music.note` (idle) vs `waveform` (playing) to indicate state at a glance

### No Sandboxing

The app uses `Process` to call yt-dlp, which requires the app to be **not sandboxed**. This means:
- Cannot distribute via Mac App Store (fine for a personal utility)
- Disable "App Sandbox" capability in Xcode

### Minimum macOS Version

**macOS 13 (Ventura)** — required for `MenuBarExtra` and `SMAppService`.

## Acceptance Criteria

- [x] Menu bar icon appears, no dock icon
- [x] Clicking the icon opens a popover with play/stop button, status text, launch-at-login toggle, quit button
- [x] Clicking Play extracts audio URL via yt-dlp and starts AVPlayer streaming
- [x] Clicking Stop halts playback and returns to idle
- [x] Status shows: idle, loading, playing, buffering, or error with message
- [x] "yt-dlp not found" shown with install instructions if yt-dlp is missing
- [x] Launch at Login toggle works via SMAppService
- [x] Quit button terminates the app
- [x] yt-dlp process is killed after 15s timeout
- [x] Rapid play clicks don't spawn multiple yt-dlp processes

## Implementation Phases

### Phase 1: Project Setup & Menu Bar Shell

- Create Xcode project (macOS App, SwiftUI, Swift)
- Configure `LSUIElement = YES` in Info.plist
- Disable App Sandbox
- Set deployment target to macOS 13
- Create `LofiApp.swift` with `MenuBarExtra` scene (`.window` style, `music.note` icon)
- Create `MenuBarView.swift` with placeholder UI (static play button, status text, quit button)
- Verify: app appears in menu bar only, popover opens/closes

**Files:** `LofiApp.swift`, `MenuBarView.swift`, `Info.plist`

### Phase 2: yt-dlp Stream URL Resolution

- Create `StreamPlayer.swift` with `@Observable` class
- Implement `resolveStreamURL()` — calls yt-dlp via `Process`, captures stdout
- Path probing: try `/opt/homebrew/bin/yt-dlp`, then `/usr/local/bin/yt-dlp`
- 15-second timeout via `DispatchQueue.asyncAfter` + `process.terminate()`
- Error handling: not found, timeout, non-zero exit, invalid output
- Run on background thread via `Task` + `withCheckedThrowingContinuation`

**Files:** `StreamPlayer.swift`

### Phase 3: AVPlayer Audio Playback

- Add `play(url:)` and `stop()` to `StreamPlayer`
- Create `AVPlayer` with the resolved HLS URL
- KVO observe `AVPlayerItem.status` → transition to playing on `.readyToPlay`
- KVO observe `isPlaybackLikelyToKeepUp` → detect stalls/buffering
- Wire up the full flow: Play button → resolve URL → start AVPlayer
- State enum: `idle`, `loading`, `playing`, `buffering`, `error(String)`

**Files:** `StreamPlayer.swift`, `MenuBarView.swift`

### Phase 4: Launch at Login + Polish

- Create `LaunchAtLoginToggle.swift` using `SMAppService`
- Read `SMAppService.mainApp.status` on appear and when popover becomes active
- Add toggle to `MenuBarView`
- Add Quit button with `NSApp.terminate(nil)`
- Polish: icon state change (optional), error messages with install instructions

**Files:** `LaunchAtLoginToggle.swift`, `MenuBarView.swift`

## Dependencies & Risks

| Risk | Mitigation |
|---|---|
| YouTube changes stream format | yt-dlp is actively maintained; `brew upgrade yt-dlp` |
| yt-dlp not installed | Clear error message with install command |
| Lofi Girl stream goes down | Error state with retry — rare, stream is 24/7 |
| HLS URL expires mid-session | User clicks Play again; URL is always re-fetched |
| Apple removes Process support | Extremely unlikely; foundation API |

## References & Research

### Internal
- Brainstorm: `docs/brainstorms/2026-03-03-lofi-menubar-app-brainstorm.md`

### External
- [Apple MenuBarExtra docs](https://developer.apple.com/documentation/SwiftUI/MenuBarExtra)
- [Apple SMAppService docs](https://developer.apple.com/documentation/servicemanagement/smappservice)
- [Apple AVPlayer docs](https://developer.apple.com/documentation/avfoundation/avplayer)
- [yt-dlp GitHub](https://github.com/yt-dlp/yt-dlp)
- [Nil Coalescing — Menu bar app in SwiftUI](https://nilcoalescing.com/blog/BuildAMacOSMenuBarUtilityInSwiftUI/)
- [Nil Coalescing — Launch at login](https://nilcoalescing.com/blog/LaunchAtLoginSetting/)
