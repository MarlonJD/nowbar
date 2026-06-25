import XCTest
@testable import ListeningNowCore

final class BrowserTitleCleanerTests: XCTestCase {
    func testRemovesYouTubeSuffixFromTabTitle() {
        XCTAssertEqual(
            BrowserTitleCleaner.cleanedTitle(from: "Kavinsky - Nightcall - YouTube"),
            "Kavinsky - Nightcall"
        )
    }

    func testRemovesYouTubeMusicSuffixFromTabTitle() {
        XCTAssertEqual(
            BrowserTitleCleaner.cleanedTitle(from: "Kavinsky - Nightcall - YouTube Music"),
            "Kavinsky - Nightcall"
        )
    }

    func testRemovesCommonPlaybackGlyphsFromTabTitle() {
        XCTAssertEqual(
            BrowserTitleCleaner.cleanedTitle(from: "▶ Kavinsky - Nightcall - YouTube"),
            "Kavinsky - Nightcall"
        )
    }
}
