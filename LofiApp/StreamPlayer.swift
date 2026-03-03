import AVFoundation
import Foundation

enum PlayerState: Equatable {
    case idle
    case loading
    case playing
    case buffering
    case error(String)
}

@Observable
class StreamPlayer {
    private(set) var state: PlayerState = .idle

    var isPlaying: Bool {
        state == .playing
    }

    private var player: AVPlayer?
    private var statusObservation: NSKeyValueObservation?
    private var stallObservation: NSKeyValueObservation?
    private var runningProcess: Process?

    private let lofiGirlURL = "https://www.youtube.com/watch?v=jfKfPfyJRdk"

    func startPlaying() {
        guard state == .idle || state.isError else { return }
        state = .loading

        Task {
            do {
                let streamURL = try await resolveStreamURL()
                await MainActor.run {
                    beginPlayback(url: streamURL)
                }
            } catch {
                await MainActor.run {
                    state = .error(error.localizedDescription)
                }
            }
        }
    }

    func stop() {
        runningProcess?.terminate()
        runningProcess = nil
        player?.pause()
        player = nil
        statusObservation?.invalidate()
        statusObservation = nil
        stallObservation?.invalidate()
        stallObservation = nil
        state = .idle
    }

    // MARK: - yt-dlp

    private func resolveStreamURL() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    let url = try runYtDlp()
                    continuation.resume(returning: url)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func findYtDlp() -> String? {
        let paths = [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
        ]
        return paths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private func runYtDlp() throws -> URL {
        guard let ytDlpPath = findYtDlp() else {
            throw PlayerError.ytDlpNotFound
        }

        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()

        process.executableURL = URL(fileURLWithPath: ytDlpPath)
        // Use 91 (lowest quality 144p+audio) since livestreams have no audio-only formats.
        // This minimizes bandwidth — we only need the audio track.
        process.arguments = ["-g", "-f", "91/bestaudio/worst", "-q", "--no-warnings", lofiGirlURL]
        process.standardOutput = stdout
        process.standardError = stderr

        DispatchQueue.main.sync {
            self.runningProcess = process
        }

        try process.run()

        // 15-second timeout
        let timeoutItem = DispatchWorkItem {
            if process.isRunning {
                process.terminate()
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 15, execute: timeoutItem)

        process.waitUntilExit()
        timeoutItem.cancel()

        DispatchQueue.main.sync {
            self.runningProcess = nil
        }

        guard process.terminationStatus == 0 else {
            if process.terminationReason == .uncaughtSignal {
                throw PlayerError.timeout
            }
            let errorOutput = String(
                decoding: stderr.fileHandleForReading.readDataToEndOfFile(),
                as: UTF8.self
            ).trimmingCharacters(in: .whitespacesAndNewlines)
            throw PlayerError.ytDlpFailed(errorOutput.isEmpty ? "Stream unavailable" : errorOutput)
        }

        let urlString = String(
            decoding: stdout.fileHandleForReading.readDataToEndOfFile(),
            as: UTF8.self
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        // yt-dlp may return multiple URLs (video + audio); take the first line
        let firstLine = urlString.components(separatedBy: .newlines).first ?? urlString

        guard let url = URL(string: firstLine), !firstLine.isEmpty else {
            throw PlayerError.invalidURL
        }

        return url
    }

    // MARK: - AVPlayer

    private func beginPlayback(url: URL) {
        let item = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: item)
        self.player = avPlayer

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    avPlayer.play()
                    self.state = .playing
                case .failed:
                    let message = item.error?.localizedDescription ?? "Playback failed"
                    self.state = .error(message)
                default:
                    break
                }
            }
        }

        stallObservation = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if self.state == .playing && !item.isPlaybackLikelyToKeepUp {
                    self.state = .buffering
                } else if self.state == .buffering && item.isPlaybackLikelyToKeepUp {
                    self.state = .playing
                }
            }
        }
    }
}

// MARK: - Errors

enum PlayerError: LocalizedError {
    case ytDlpNotFound
    case ytDlpFailed(String)
    case timeout
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .ytDlpNotFound:
            return "yt-dlp not found.\nInstall with: brew install yt-dlp"
        case .ytDlpFailed(let message):
            return message
        case .timeout:
            return "Connection timed out. Try again."
        case .invalidURL:
            return "Failed to extract stream URL."
        }
    }
}

// MARK: - Helpers

extension PlayerState {
    var isError: Bool {
        if case .error = self { return true }
        return false
    }
}
