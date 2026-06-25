import AppKit
import ListeningNowCore
import QuartzCore

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let formatter: MenuBarTitleFormatter
    private let provider: NowPlayingProviding
    private let navigator: NowPlayingNavigating
    private let playbackController: NowPlayingPlaybackControlling
    private let pollingQueue = DispatchQueue(label: "com.marlonjd.Nowbar.polling", qos: .utility)
    private let popover = NSPopover()
    private let popoverViewController = PlayerPopoverViewController()
    private let quitMenu = NSMenu()
    private var refreshTimer: Timer?
    private var currentItem: NowPlayingItem?
    private var retention = NowPlayingRetention(graceInterval: 10)
    private var renderedStatusTitle = ""
    private var renderedStatusArtworkURL: URL?
    private var statusArtworkTask: URLSessionDataTask?
    private var globalDismissMonitor: Any?
    private var localDismissMonitor: Any?
    private var isPolling = false

    init(
        statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength),
        formatter: MenuBarTitleFormatter = MenuBarTitleFormatter(maxCharacters: 42),
        provider: NowPlayingProviding,
        navigator: NowPlayingNavigating,
        playbackController: NowPlayingPlaybackControlling
    ) {
        self.statusItem = statusItem
        self.formatter = formatter
        self.provider = provider
        self.navigator = navigator
        self.playbackController = playbackController
        super.init()
        configureStatusItem()
    }

    func start() {
        refresh()
        refreshTimer = Timer.scheduledTimer(
            timeInterval: 3,
            target: self,
            selector: #selector(refresh),
            userInfo: nil,
            repeats: true
        )
    }

    private func configureStatusItem() {
        statusItem.button?.title = renderedStatusTitle
        statusItem.button?.wantsLayer = true
        statusItem.button?.imagePosition = .imageLeading
        statusItem.button?.imageScaling = .scaleProportionallyDown
        statusItem.button?.image = idleStatusImage()
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem.button?.toolTip = "Open player"

        popover.behavior = .transient
        popover.delegate = self
        popover.contentSize = NSSize(width: 414, height: 176)
        popover.contentViewController = popoverViewController
        if #available(macOS 14.0, *) {
            popoverViewController.loadViewIfNeeded()
        } else {
            _ = popoverViewController.view
        }
        popoverViewController.onPrevious = { [weak self] in self?.previousTrack() }
        popoverViewController.onTogglePlayPause = { [weak self] in self?.togglePlayPause() }
        popoverViewController.onNext = { [weak self] in self?.nextTrack() }
        popoverViewController.onOpen = { [weak self] in self?.goToPlayingApp() }

        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quitFromMenu), keyEquivalent: "q")
        quitMenuItem.target = self
        quitMenu.addItem(quitMenuItem)
    }

    @objc private func refresh() {
        guard !isPolling else {
            return
        }

        isPolling = true
        pollingQueue.async { [weak self] in
            guard let self else {
                return
            }

            let item = retention.displayItem(for: provider.currentItem())
            let title = item == nil ? "" : formatter.title(for: item)

            DispatchQueue.main.async { [weak self] in
                self?.updateStatusTitle(title)
                self?.updateStatusArtwork(url: item?.artworkURL)
                self?.currentItem = item
                self?.popoverViewController.update(item: item)
                self?.isPolling = false
            }
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else {
            return
        }

        if NSApp.currentEvent?.type == .rightMouseUp {
            popover.performClose(nil)
            statusItem.menu = quitMenu
            button.performClick(nil)
            statusItem.menu = nil
            return
        }

        popoverViewController.update(item: currentItem)

        if popover.isShown {
            closePopover()
        } else {
            showPopover(from: button)
        }
    }

    private func showPopover(from button: NSStatusBarButton) {
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        installDismissMonitors()
    }

    private func closePopover() {
        removeDismissMonitors()
        popover.performClose(nil)
    }

    private func installDismissMonitors() {
        removeDismissMonitors()

        globalDismissMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.closePopover()
            }
        }

        localDismissMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 53 {
                self?.closePopover()
                return nil
            }

            return event
        }
    }

    private func removeDismissMonitors() {
        if let globalDismissMonitor {
            NSEvent.removeMonitor(globalDismissMonitor)
            self.globalDismissMonitor = nil
        }

        if let localDismissMonitor {
            NSEvent.removeMonitor(localDismissMonitor)
            self.localDismissMonitor = nil
        }
    }

    private func goToPlayingApp() {
        navigator.open(item: currentItem)
    }

    private func previousTrack() {
        playbackController.send(.previous, to: currentItem)
    }

    private func togglePlayPause() {
        playbackController.send(.togglePlayPause, to: currentItem)
    }

    private func nextTrack() {
        playbackController.send(.next, to: currentItem)
    }

    private func quit() {
        NSApp.terminate(nil)
    }

    @objc private func quitFromMenu() {
        quit()
    }

    private func updateStatusTitle(_ title: String) {
        guard renderedStatusTitle != title else {
            return
        }

        if !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion,
           let button = statusItem.button {
            let transition = CATransition()
            transition.type = .push
            transition.subtype = .fromTop
            transition.duration = 0.18
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            button.layer?.add(transition, forKey: "listeningNowStatusTitlePush")
        }

        renderedStatusTitle = title
        statusItem.button?.title = title
    }

    private func updateStatusArtwork(url: URL?) {
        guard renderedStatusArtworkURL != url else {
            return
        }

        renderedStatusArtworkURL = url
        statusArtworkTask?.cancel()

        guard let url else {
            statusItem.button?.image = idleStatusImage()
            return
        }

        if let cachedImage = ArtworkImageCache.shared.image(for: url) {
            statusItem.button?.image = cachedImage.statusBarArtworkImage()
            return
        }

        statusArtworkTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = NSImage(data: data) else {
                return
            }

            ArtworkImageCache.shared.store(image, for: url)

            DispatchQueue.main.async {
                guard self?.renderedStatusArtworkURL == url else {
                    return
                }

                self?.statusItem.button?.image = image.statusBarArtworkImage()
            }
        }
        statusArtworkTask?.resume()
    }
}

extension StatusBarController: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        removeDismissMonitors()
    }
}

private extension NSImage {
    static func idleStatusImage() -> NSImage? {
        guard let image = NSImage(systemSymbolName: "play.circle.fill", accessibilityDescription: nil) else {
            return nil
        }

        let configuredImage = image.withSymbolConfiguration(
            NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        ) ?? image
        configuredImage.isTemplate = true
        return configuredImage
    }

    func statusBarArtworkImage() -> NSImage {
        let artworkSize = NSSize(width: 18, height: 18)
        let canvasSize = NSSize(width: 24, height: 18)
        let image = NSImage(size: canvasSize)
        image.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high
        let rect = NSRect(origin: .zero, size: artworkSize)
        NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4).addClip()
        draw(in: rect, from: .zero, operation: .copy, fraction: 1)

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}

private func idleStatusImage() -> NSImage? {
    NSImage.idleStatusImage()
}
