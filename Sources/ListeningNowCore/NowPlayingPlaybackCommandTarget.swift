import Foundation

public enum NowPlayingPlaybackCommand: Equatable {
    case previous
    case togglePlayPause
    case next
}

public enum NowPlayingPlaybackCommandTargetResolver {
    public static func target(for item: NowPlayingItem?) -> NowPlayingNavigationTarget? {
        guard let item else {
            return nil
        }

        switch item.source {
        case .spotify, .appleMusic:
            return NowPlayingNavigationTargetResolver.target(for: item)
        case .browser:
            guard item.url != nil else {
                return nil
            }

            return NowPlayingNavigationTargetResolver.target(for: item)
        case .youtube, .unknown:
            return nil
        }
    }
}
