import XCTest
@testable import ListeningNowCore

final class NowPlayingDisplayInfoFormatterTests: XCTestCase {
    func testFormatsTitleAndArtistWithSource() {
        let item = NowPlayingItem(title: "Sleepwalker", artist: "The Killers", source: .spotify, url: nil)

        let info = NowPlayingDisplayInfoFormatter.displayInfo(for: item)

        XCTAssertEqual(info.title, "Sleepwalker")
        XCTAssertEqual(info.subtitle, "The Killers - Spotify")
    }

    func testUsesSourceWhenArtistIsMissing() {
        let item = NowPlayingItem(title: "Sleepwalker", artist: nil, source: .browser(name: "Safari"), url: nil)

        let info = NowPlayingDisplayInfoFormatter.displayInfo(for: item)

        XCTAssertEqual(info.title, "Sleepwalker")
        XCTAssertEqual(info.subtitle, "Safari")
    }

    func testFormatsIdleState() {
        let info = NowPlayingDisplayInfoFormatter.displayInfo(for: nil)

        XCTAssertEqual(info.title, "Not Playing")
        XCTAssertEqual(info.subtitle, "No active media")
    }
}
