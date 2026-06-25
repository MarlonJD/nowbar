import AppKit
import Foundation
import ListeningNowCore

protocol NowPlayingNavigating {
    func open(item: NowPlayingItem?)
}

final class AppNowPlayingNavigator: NowPlayingNavigating {
    private let runner: AppleScriptRunning
    private let workspace: NSWorkspace

    init(runner: AppleScriptRunning, workspace: NSWorkspace = .shared) {
        self.runner = runner
        self.workspace = workspace
    }

    func open(item: NowPlayingItem?) {
        guard let target = NowPlayingNavigationTargetResolver.target(for: item) else {
            return
        }

        if let browserName = target.browserName, let url = target.url {
            focusBrowserTab(browserName: browserName, url: url)
            return
        }

        if let url = target.url {
            workspace.open(url)
        }

        activate(bundleIdentifier: target.bundleIdentifier)
    }

    private func activate(bundleIdentifier: String) {
        NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
            .first?
            .activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
    }

    private func focusBrowserTab(browserName: String, url: URL) {
        switch browserName {
        case "Safari":
            _ = runner.execute(safariFocusScript(url: url.absoluteString))
        case "Google Chrome", "Brave Browser", "Microsoft Edge":
            _ = runner.execute(chromiumFocusScript(appName: browserName, url: url.absoluteString))
        default:
            break
        }
    }

    private func safariFocusScript(url: String) -> String {
        let escapedURL = url.appleScriptEscaped
        return """
        tell application "Safari"
          repeat with windowIndex from 1 to count of windows
            set browserWindow to window windowIndex
            repeat with tabIndex from 1 to count of tabs of browserWindow
              set browserTab to tab tabIndex of browserWindow
              if URL of browserTab as string is "\(escapedURL)" then
                set current tab of browserWindow to browserTab
                set index of browserWindow to 1
                activate
                return "ok"
              end if
            end repeat
          end repeat
          activate
        end tell
        return ""
        """
    }

    private func chromiumFocusScript(appName: String, url: String) -> String {
        let escapedAppName = appName.appleScriptEscaped
        let escapedURL = url.appleScriptEscaped
        return """
        tell application "\(escapedAppName)"
          repeat with windowIndex from 1 to count of windows
            set browserWindow to window windowIndex
            repeat with tabIndex from 1 to count of tabs of browserWindow
              set browserTab to tab tabIndex of browserWindow
              if URL of browserTab as string is "\(escapedURL)" then
                set active tab index of browserWindow to tabIndex
                set index of browserWindow to 1
                activate
                return "ok"
              end if
            end repeat
          end repeat
          activate
        end tell
        return ""
        """
    }
}

extension String {
    var appleScriptEscaped: String {
        replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
