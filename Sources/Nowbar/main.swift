import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        LoginItemRegistrar.registerIfNeeded()

        let runner = NSAppleScriptRunner()
        let provider = CompositeNowPlayingProvider(
            providers: [
                SpotifyNowPlayingProvider(runner: runner),
                MusicNowPlayingProvider(runner: runner),
                BrowserYouTubeNowPlayingProvider(runner: runner)
            ]
        )
        let navigator = AppNowPlayingNavigator(runner: runner)
        let playbackController = AppNowPlayingPlaybackController(runner: runner)

        controller = StatusBarController(
            provider: provider,
            navigator: navigator,
            playbackController: playbackController
        )
        controller?.start()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

private enum LoginItemRegistrar {
    static func registerIfNeeded() {
        guard #available(macOS 13.0, *) else {
            return
        }

        let service = SMAppService.mainApp
        guard service.status == .notRegistered else {
            return
        }

        try? service.register()
    }
}
