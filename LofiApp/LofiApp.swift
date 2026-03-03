import SwiftUI

@main
struct LofiApp: App {
    @State private var streamPlayer = StreamPlayer()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(streamPlayer)
        } label: {
            Image(systemName: streamPlayer.isPlaying ? "waveform" : "music.note")
        }
        .menuBarExtraStyle(.window)
    }
}
