import SwiftUI

struct MenuBarView: View {
    @Environment(StreamPlayer.self) var player

    var body: some View {
        VStack(spacing: 12) {
            Text("Lofi Girl")
                .font(.headline)

            statusView

            playButton

            Divider()

            LaunchAtLoginToggle()

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 240)
    }

    @ViewBuilder
    private var statusView: some View {
        switch player.state {
        case .idle:
            Text("Ready to play")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .loading:
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Loading stream...")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        case .playing:
            Text("Now playing")
                .font(.caption)
                .foregroundStyle(.green)
        case .buffering:
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Buffering...")
                    .font(.caption)
            }
            .foregroundStyle(.orange)
        case .error(let message):
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
    }

    private var playButton: some View {
        Button {
            if player.isPlaying || player.state == .loading || player.state == .buffering {
                player.stop()
            } else {
                player.startPlaying()
            }
        } label: {
            Label(
                player.isPlaying || player.state == .loading || player.state == .buffering ? "Stop" : "Play",
                systemImage: player.isPlaying || player.state == .loading || player.state == .buffering ? "stop.fill" : "play.fill"
            )
            .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
    }
}
