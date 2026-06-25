import AppKit
import Foundation
import ListeningNowCore

protocol NowPlayingProviding {
    func currentItem() -> NowPlayingItem?
}

final class CompositeNowPlayingProvider: NowPlayingProviding {
    private let providers: [NowPlayingProviding]

    init(providers: [NowPlayingProviding]) {
        self.providers = providers
    }

    func currentItem() -> NowPlayingItem? {
        for provider in providers {
            if let item = provider.currentItem() {
                return item
            }
        }

        return nil
    }
}

final class SpotifyNowPlayingProvider: NowPlayingProviding {
    private let runner: AppleScriptRunning

    init(runner: AppleScriptRunning) {
        self.runner = runner
    }

    func currentItem() -> NowPlayingItem? {
        guard ApplicationState.isRunning(bundleIdentifier: "com.spotify.client") else {
            return nil
        }

        let script = """
        tell application "Spotify"
          if player state is playing or player state is paused then
            set trackState to player state as string
            set trackArtist to artist of current track as string
            set trackName to name of current track as string
            set trackURL to spotify url of current track as string
            set coverURL to artwork url of current track as string
            return trackArtist & linefeed & trackName & linefeed & trackURL & linefeed & coverURL & linefeed & trackState
          end if
        end tell
        return ""
        """

        guard let result = runner.execute(script),
              let item = ScriptNowPlayingParser.spotifyItem(from: result) else {
            return nil
        }

        return item
    }
}

final class MusicNowPlayingProvider: NowPlayingProviding {
    private let runner: AppleScriptRunning

    init(runner: AppleScriptRunning) {
        self.runner = runner
    }

    func currentItem() -> NowPlayingItem? {
        guard ApplicationState.isRunning(bundleIdentifier: "com.apple.Music") else {
            return nil
        }

        let script = """
        tell application "Music"
          if player state is playing or player state is paused then
            set trackState to player state as string
            set trackArtist to artist of current track as string
            set trackName to name of current track as string
            return trackArtist & linefeed & trackName & linefeed & trackState
          end if
        end tell
        return ""
        """

        guard let result = runner.execute(script),
              let item = ScriptNowPlayingParser.musicItem(from: result) else {
            return nil
        }

        return item
    }
}

final class BrowserYouTubeNowPlayingProvider: NowPlayingProviding {
    private struct Browser {
        let appName: String
        let bundleIdentifier: String
        let titleProperty: String
    }

    private let browsers: [Browser] = [
        Browser(appName: "Safari", bundleIdentifier: "com.apple.Safari", titleProperty: "name"),
        Browser(appName: "Google Chrome", bundleIdentifier: "com.google.Chrome", titleProperty: "title"),
        Browser(appName: "Brave Browser", bundleIdentifier: "com.brave.Browser", titleProperty: "title"),
        Browser(appName: "Microsoft Edge", bundleIdentifier: "com.microsoft.edgemac", titleProperty: "title")
    ]

    private let runner: AppleScriptRunning

    init(runner: AppleScriptRunning) {
        self.runner = runner
    }

    func currentItem() -> NowPlayingItem? {
        for browser in browsers where ApplicationState.isRunning(bundleIdentifier: browser.bundleIdentifier) {
            guard let result = runner.execute(script(for: browser)),
                  let item = ScriptNowPlayingParser.youtubeItem(from: result, browserName: browser.appName) else {
                continue
            }

            return item
        }

        return nil
    }

    private func script(for browser: Browser) -> String {
        """
        tell application "\(browser.appName)"
          repeat with browserWindow in windows
            repeat with browserTab in tabs of browserWindow
              set tabURL to URL of browserTab as string
              if tabURL contains "youtube.com/watch" or tabURL contains "music.youtube.com/watch" or tabURL contains "youtu.be/" then
                set tabTitle to \(browser.titleProperty) of browserTab as string
                return tabTitle & linefeed & tabURL
              end if
            end repeat
          end repeat
        end tell
        return ""
        """
    }
}

enum ApplicationState {
    static func isRunning(bundleIdentifier: String) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty
    }
}
