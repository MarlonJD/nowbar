import AppKit
import Foundation
import ListeningNowCore

protocol NowPlayingPlaybackControlling {
    func send(_ command: NowPlayingPlaybackCommand, to item: NowPlayingItem?)
}

final class AppNowPlayingPlaybackController: NowPlayingPlaybackControlling {
    private let runner: AppleScriptRunning

    init(runner: AppleScriptRunning) {
        self.runner = runner
    }

    func send(_ command: NowPlayingPlaybackCommand, to item: NowPlayingItem?) {
        guard let target = NowPlayingPlaybackCommandTargetResolver.target(for: item) else {
            return
        }

        if let browserName = target.browserName, let url = target.url {
            sendBrowserCommand(command, browserName: browserName, url: url)
            return
        }

        switch target.bundleIdentifier {
        case "com.spotify.client":
            _ = runner.execute(spotifyScript(for: command))
        case "com.apple.Music":
            _ = runner.execute(musicScript(for: command))
        default:
            break
        }
    }

    private func spotifyScript(for command: NowPlayingPlaybackCommand) -> String {
        switch command {
        case .previous:
            return """
            tell application "Spotify"
              previous track
            end tell
            """
        case .togglePlayPause:
            return """
            tell application "Spotify"
              playpause
            end tell
            """
        case .next:
            return """
            tell application "Spotify"
              next track
            end tell
            """
        }
    }

    private func musicScript(for command: NowPlayingPlaybackCommand) -> String {
        switch command {
        case .previous:
            return """
            tell application "Music"
              previous track
            end tell
            """
        case .togglePlayPause:
            return """
            tell application "Music"
              playpause
            end tell
            """
        case .next:
            return """
            tell application "Music"
              next track
            end tell
            """
        }
    }

    private func sendBrowserCommand(_ command: NowPlayingPlaybackCommand, browserName: String, url: URL) {
        switch browserName {
        case "Safari":
            _ = runner.execute(safariPlaybackScript(command: command, url: url.absoluteString))
        case "Google Chrome", "Brave Browser", "Microsoft Edge":
            _ = runner.execute(chromiumPlaybackScript(command: command, appName: browserName, url: url.absoluteString))
        default:
            break
        }
    }

    private func safariPlaybackScript(command: NowPlayingPlaybackCommand, url: String) -> String {
        let escapedURL = url.appleScriptEscaped
        let javascript = youtubeJavaScript(for: command).appleScriptEscaped
        return """
        tell application "Safari"
          repeat with windowIndex from 1 to count of windows
            set browserWindow to window windowIndex
            repeat with tabIndex from 1 to count of tabs of browserWindow
              set browserTab to tab tabIndex of browserWindow
              if URL of browserTab as string is "\(escapedURL)" then
                do JavaScript "\(javascript)" in browserTab
                return "ok"
              end if
            end repeat
          end repeat
        end tell
        return ""
        """
    }

    private func chromiumPlaybackScript(command: NowPlayingPlaybackCommand, appName: String, url: String) -> String {
        let escapedAppName = appName.appleScriptEscaped
        let escapedURL = url.appleScriptEscaped
        let javascript = youtubeJavaScript(for: command).appleScriptEscaped
        return """
        tell application "\(escapedAppName)"
          repeat with windowIndex from 1 to count of windows
            set browserWindow to window windowIndex
            repeat with tabIndex from 1 to count of tabs of browserWindow
              set browserTab to tab tabIndex of browserWindow
              if URL of browserTab as string is "\(escapedURL)" then
                execute browserTab javascript "\(javascript)"
                return "ok"
              end if
            end repeat
          end repeat
        end tell
        return ""
        """
    }

    private func youtubeJavaScript(for command: NowPlayingPlaybackCommand) -> String {
        switch command {
        case .previous:
            return "document.querySelector('.ytp-prev-button')?.click();"
        case .togglePlayPause:
            return "document.querySelector('.ytp-play-button')?.click();"
        case .next:
            return "document.querySelector('.ytp-next-button')?.click();"
        }
    }
}
