import XCTest
@testable import ListeningNowCore

final class ScriptNowPlayingParserTests: XCTestCase {
    func testParsesSpotifyArtistTitleAndURL() {
        let item = ScriptNowPlayingParser.spotifyItem(
            from: "Kavinsky\nNightcall\nspotify:track:0U0ldCRmgCqhVvD6ksG63j\nhttps://i.scdn.co/image/abc123\nplaying"
        )

        XCTAssertEqual(item?.title, "Nightcall")
        XCTAssertEqual(item?.artist, "Kavinsky")
        XCTAssertEqual(item?.source, .spotify)
        XCTAssertEqual(item?.url?.absoluteString, "spotify:track:0U0ldCRmgCqhVvD6ksG63j")
        XCTAssertEqual(item?.artworkURL?.absoluteString, "https://i.scdn.co/image/abc123")
        XCTAssertEqual(item?.playbackState, .playing)
    }

    func testParsesPausedSpotifyState() {
        let item = ScriptNowPlayingParser.spotifyItem(
            from: "Kavinsky\nNightcall\nspotify:track:0U0ldCRmgCqhVvD6ksG63j\nhttps://i.scdn.co/image/abc123\npaused"
        )

        XCTAssertEqual(item?.playbackState, .paused)
    }

    func testParsesMusicArtistAndTitle() {
        let item = ScriptNowPlayingParser.musicItem(from: "Kavinsky\nNightcall\npaused")

        XCTAssertEqual(item?.title, "Nightcall")
        XCTAssertEqual(item?.artist, "Kavinsky")
        XCTAssertEqual(item?.source, .appleMusic)
        XCTAssertNil(item?.url)
        XCTAssertEqual(item?.playbackState, .paused)
    }

    func testParsesYouTubeTitleAndURL() {
        let item = ScriptNowPlayingParser.youtubeItem(
            from: "Kavinsky - Nightcall - YouTube\nhttps://www.youtube.com/watch?v=MV_3Dpw-BRY",
            browserName: "Safari"
        )

        XCTAssertEqual(item?.title, "Kavinsky - Nightcall")
        XCTAssertEqual(item?.artist, nil)
        XCTAssertEqual(item?.source, .browser(name: "Safari"))
        XCTAssertEqual(item?.url?.absoluteString, "https://www.youtube.com/watch?v=MV_3Dpw-BRY")
    }
}
