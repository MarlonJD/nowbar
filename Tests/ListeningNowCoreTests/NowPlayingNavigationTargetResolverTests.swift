import XCTest
@testable import ListeningNowCore

final class NowPlayingNavigationTargetResolverTests: XCTestCase {
    func testResolvesSpotifyTarget() {
        let item = NowPlayingItem(
            title: "Nightcall",
            artist: "Kavinsky",
            source: .spotify,
            url: URL(string: "spotify:track:0U0ldCRmgCqhVvD6ksG63j")
        )

        let target = NowPlayingNavigationTargetResolver.target(for: item)

        XCTAssertEqual(target?.bundleIdentifier, "com.spotify.client")
        XCTAssertEqual(target?.browserName, nil)
        XCTAssertEqual(target?.url?.absoluteString, "spotify:track:0U0ldCRmgCqhVvD6ksG63j")
    }

    func testResolvesMusicTarget() {
        let item = NowPlayingItem(title: "Nightcall", artist: "Kavinsky", source: .appleMusic, url: nil)

        let target = NowPlayingNavigationTargetResolver.target(for: item)

        XCTAssertEqual(target?.bundleIdentifier, "com.apple.Music")
        XCTAssertEqual(target?.browserName, nil)
        XCTAssertNil(target?.url)
    }

    func testResolvesSupportedBrowserTarget() {
        let item = NowPlayingItem(
            title: "Nightcall",
            artist: nil,
            source: .browser(name: "Safari"),
            url: URL(string: "https://www.youtube.com/watch?v=MV_3Dpw-BRY")
        )

        let target = NowPlayingNavigationTargetResolver.target(for: item)

        XCTAssertEqual(target?.bundleIdentifier, "com.apple.Safari")
        XCTAssertEqual(target?.browserName, "Safari")
        XCTAssertEqual(target?.url?.absoluteString, "https://www.youtube.com/watch?v=MV_3Dpw-BRY")
    }

    func testReturnsNilForUnsupportedSources() {
        let item = NowPlayingItem(title: "Unknown", artist: nil, source: .unknown(name: "Other"), url: nil)

        XCTAssertNil(NowPlayingNavigationTargetResolver.target(for: item))
    }
}
