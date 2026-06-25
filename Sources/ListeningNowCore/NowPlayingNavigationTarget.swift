import Foundation

public struct NowPlayingNavigationTarget: Equatable {
    public let bundleIdentifier: String
    public let browserName: String?
    public let url: URL?

    public init(bundleIdentifier: String, browserName: String?, url: URL?) {
        self.bundleIdentifier = bundleIdentifier
        self.browserName = browserName
        self.url = url
    }
}

public enum NowPlayingNavigationTargetResolver {
    public static func target(for item: NowPlayingItem?) -> NowPlayingNavigationTarget? {
        guard let item else {
            return nil
        }

        switch item.source {
        case .spotify:
            return NowPlayingNavigationTarget(
                bundleIdentifier: "com.spotify.client",
                browserName: nil,
                url: item.url
            )
        case .appleMusic:
            return NowPlayingNavigationTarget(
                bundleIdentifier: "com.apple.Music",
                browserName: nil,
                url: item.url
            )
        case .browser(let name):
            guard let bundleIdentifier = browserBundleIdentifier(for: name) else {
                return nil
            }

            return NowPlayingNavigationTarget(
                bundleIdentifier: bundleIdentifier,
                browserName: name,
                url: item.url
            )
        case .youtube, .unknown:
            return nil
        }
    }

    private static func browserBundleIdentifier(for browserName: String) -> String? {
        switch browserName {
        case "Safari":
            return "com.apple.Safari"
        case "Google Chrome":
            return "com.google.Chrome"
        case "Brave Browser":
            return "com.brave.Browser"
        case "Microsoft Edge":
            return "com.microsoft.edgemac"
        default:
            return nil
        }
    }
}
