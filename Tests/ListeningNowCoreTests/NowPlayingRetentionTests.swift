import XCTest
@testable import ListeningNowCore

final class NowPlayingRetentionTests: XCTestCase {
    func testKeepsLastItemDuringShortMetadataGap() {
        var retention = NowPlayingRetention(graceInterval: 8)
        let start = Date(timeIntervalSince1970: 100)
        let item = NowPlayingItem(title: "Desperate Things", artist: "The Killers", source: .spotify, url: nil)

        _ = retention.displayItem(for: item, now: start)
        let displayed = retention.displayItem(for: nil, now: start.addingTimeInterval(3))

        XCTAssertEqual(displayed, item)
    }

    func testClearsLastItemAfterGraceInterval() {
        var retention = NowPlayingRetention(graceInterval: 8)
        let start = Date(timeIntervalSince1970: 100)
        let item = NowPlayingItem(title: "Desperate Things", artist: "The Killers", source: .spotify, url: nil)

        _ = retention.displayItem(for: item, now: start)
        let displayed = retention.displayItem(for: nil, now: start.addingTimeInterval(9))

        XCTAssertNil(displayed)
    }
}
