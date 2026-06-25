import Foundation

public struct NowPlayingRetention {
    private let graceInterval: TimeInterval
    private var retainedItem: NowPlayingItem?
    private var retainedAt: Date?

    public init(graceInterval: TimeInterval) {
        self.graceInterval = graceInterval
    }

    public mutating func displayItem(for latestItem: NowPlayingItem?, now: Date = Date()) -> NowPlayingItem? {
        if let latestItem {
            retainedItem = latestItem
            retainedAt = now
            return latestItem
        }

        guard let retainedItem, let retainedAt else {
            return nil
        }

        return now.timeIntervalSince(retainedAt) <= graceInterval ? retainedItem : nil
    }
}
