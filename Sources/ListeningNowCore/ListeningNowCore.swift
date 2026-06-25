import Foundation

public enum NowPlayingSource: Equatable {
    case appleMusic
    case spotify
    case youtube
    case browser(name: String)
    case unknown(name: String)
}

public enum NowPlayingPlaybackState: String, Equatable {
    case playing
    case paused
    case unknown
}

public struct NowPlayingItem: Equatable {
    public let title: String
    public let artist: String?
    public let source: NowPlayingSource
    public let url: URL?
    public let artworkURL: URL?
    public let playbackState: NowPlayingPlaybackState

    public init(
        title: String,
        artist: String?,
        source: NowPlayingSource,
        url: URL?,
        artworkURL: URL? = nil,
        playbackState: NowPlayingPlaybackState = .playing
    ) {
        self.title = title
        self.artist = artist
        self.source = source
        self.url = url
        self.artworkURL = artworkURL
        self.playbackState = playbackState
    }
}

public struct MenuBarTitleFormatter {
    public let maxCharacters: Int
    public let idleTitle: String

    public init(maxCharacters: Int = 42, idleTitle: String = "Not Playing") {
        self.maxCharacters = max(1, maxCharacters)
        self.idleTitle = idleTitle
    }

    public func title(for item: NowPlayingItem?) -> String {
        guard let item else {
            return truncate(idleTitle)
        }

        let title = trimmed(item.title)
        let artist = item.artist.map(trimmed(_:)).flatMap { $0.isEmpty ? nil : $0 }
        let composedTitle = artist.map { "\(title) - \($0)" } ?? title

        return truncate(composedTitle.isEmpty ? idleTitle : composedTitle)
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func truncate(_ value: String) -> String {
        guard value.count > maxCharacters else {
            return value
        }

        guard maxCharacters > 3 else {
            return String(value.prefix(maxCharacters))
        }

        return String(value.prefix(maxCharacters - 3)) + "..."
    }
}

public enum BrowserTitleCleaner {
    public static func cleanedTitle(from tabTitle: String) -> String {
        var title = tabTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        for glyph in ["▶︎", "▶", "▷", "►"] where title.hasPrefix(glyph) {
            title.removeFirst(glyph.count)
            title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        for suffix in [" - YouTube Music", " - YouTube"] where title.hasSuffix(suffix) {
            title.removeLast(suffix.count)
            return title.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return title
    }
}
