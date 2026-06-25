import Foundation

public enum ScriptNowPlayingParser {
    public static func spotifyItem(from scriptResult: String) -> NowPlayingItem? {
        let parts = scriptResult.lines
        guard parts.count >= 2 else {
            return nil
        }

        return NowPlayingItem(
            title: parts[1],
            artist: parts[0],
            source: .spotify,
            url: parts.dropFirst(2).first.flatMap(URL.init(string:)),
            artworkURL: parts.dropFirst(3).first.flatMap(URL.init(string:)),
            playbackState: playbackState(from: parts.dropFirst(4).first)
        )
    }

    public static func musicItem(from scriptResult: String) -> NowPlayingItem? {
        let parts = scriptResult.lines
        guard parts.count >= 2 else {
            return nil
        }

        return NowPlayingItem(
            title: parts[1],
            artist: parts[0],
            source: .appleMusic,
            url: nil,
            playbackState: playbackState(from: parts.dropFirst(2).first)
        )
    }

    public static func youtubeItem(from scriptResult: String, browserName: String) -> NowPlayingItem? {
        let parts = scriptResult.lines
        guard let title = parts.first else {
            return nil
        }

        return NowPlayingItem(
            title: BrowserTitleCleaner.cleanedTitle(from: title),
            artist: nil,
            source: .browser(name: browserName),
            url: parts.dropFirst().first.flatMap(URL.init(string:)),
            playbackState: .playing
        )
    }

    private static func playbackState(from value: String?) -> NowPlayingPlaybackState {
        switch value?.lowercased() {
        case "playing":
            return .playing
        case "paused":
            return .paused
        default:
            return .playing
        }
    }
}

private extension String {
    var lines: [String] {
        split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
