import Foundation

public struct NowPlayingDisplayInfo: Equatable {
    public let title: String
    public let subtitle: String

    public init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }
}

public enum NowPlayingDisplayInfoFormatter {
    public static func displayInfo(for item: NowPlayingItem?) -> NowPlayingDisplayInfo {
        guard let item else {
            return NowPlayingDisplayInfo(title: "Not Playing", subtitle: "No active media")
        }

        let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = item.artist?.trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceName = sourceDisplayName(for: item.source)

        return NowPlayingDisplayInfo(
            title: title.isEmpty ? "Untitled" : title,
            subtitle: artist?.isEmpty == false ? "\(artist!) - \(sourceName)" : sourceName
        )
    }

    private static func sourceDisplayName(for source: NowPlayingSource) -> String {
        switch source {
        case .appleMusic:
            return "Music"
        case .spotify:
            return "Spotify"
        case .youtube:
            return "YouTube"
        case .browser(let name):
            return name
        case .unknown(let name):
            return name
        }
    }
}
