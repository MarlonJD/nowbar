import XCTest
@testable import ListeningNowCore

final class MenuBarTitleFormatterTests: XCTestCase {
    func testFormatsTrackAndArtistWhenAvailable() {
        let item = NowPlayingItem(
            title: "Nightcall",
            artist: "Kavinsky",
            source: .spotify,
            url: nil
        )

        let title = MenuBarTitleFormatter(maxCharacters: 48).title(for: item)

        XCTAssertEqual(title, "Nightcall - Kavinsky")
    }

    func testFallsBackToTitleWhenArtistIsMissing() {
        let item = NowPlayingItem(
            title: "WWDC session on macOS menu bar apps",
            artist: nil,
            source: .youtube,
            url: nil
        )

        let title = MenuBarTitleFormatter(maxCharacters: 48).title(for: item)

        XCTAssertEqual(title, "WWDC session on macOS menu bar apps")
    }

    func testTruncatesLongTitlesWithoutExceedingLimit() {
        let item = NowPlayingItem(
            title: "An extremely long ambient live performance from a browser tab",
            artist: "Someone With A Very Long Artist Name",
            source: .browser(name: "Safari"),
            url: nil
        )

        let title = MenuBarTitleFormatter(maxCharacters: 24).title(for: item)

        XCTAssertEqual(title, "An extremely long amb...")
        XCTAssertLessThanOrEqual(title.count, 24)
    }

    func testUsesIdleTitleWhenNothingIsPlaying() {
        let title = MenuBarTitleFormatter(maxCharacters: 48).title(for: nil)

        XCTAssertEqual(title, "Not Playing")
    }
}
