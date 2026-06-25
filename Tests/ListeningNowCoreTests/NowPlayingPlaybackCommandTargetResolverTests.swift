import XCTest
@testable import ListeningNowCore

final class NowPlayingPlaybackCommandTargetResolverTests: XCTestCase {
    func testResolvesSpotifyPlaybackTarget() {
        let item = NowPlayingItem(title: "Nightcall", artist: "Kavinsky", source: .spotify, url: nil)

        let target = NowPlayingPlaybackCommandTargetResolver.target(for: item)

        XCTAssertEqual(target?.bundleIdentifier, "com.spotify.client")
        XCTAssertEqual(target?.browserName, nil)
    }

    func testResolvesMusicPlaybackTarget() {
        let item = NowPlayingItem(title: "Nightcall", artist: "Kavinsky", source: .appleMusic, url: nil)

        let target = NowPlayingPlaybackCommandTargetResolver.target(for: item)

        XCTAssertEqual(target?.bundleIdentifier, "com.apple.Music")
        XCTAssertEqual(target?.browserName, nil)
    }

    func testResolvesBrowserPlaybackTargetWhenURLExists() {
        let item = NowPlayingItem(
            title: "Nightcall",
            artist: nil,
            source: .browser(name: "Google Chrome"),
            url: URL(string: "https://www.youtube.com/watch?v=MV_3Dpw-BRY")
        )

        let target = NowPlayingPlaybackCommandTargetResolver.target(for: item)

        XCTAssertEqual(target?.bundleIdentifier, "com.google.Chrome")
        XCTAssertEqual(target?.browserName, "Google Chrome")
        XCTAssertEqual(target?.url?.absoluteString, "https://www.youtube.com/watch?v=MV_3Dpw-BRY")
    }

    func testReturnsNilForBrowserPlaybackTargetWithoutURL() {
        let item = NowPlayingItem(title: "Nightcall", artist: nil, source: .browser(name: "Safari"), url: nil)

        XCTAssertNil(NowPlayingPlaybackCommandTargetResolver.target(for: item))
    }
}
