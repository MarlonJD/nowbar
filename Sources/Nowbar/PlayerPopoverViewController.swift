import AppKit
import ListeningNowCore
import QuartzCore

final class PlayerPopoverViewController: NSViewController {
    var onPrevious: (() -> Void)?
    var onTogglePlayPause: (() -> Void)?
    var onNext: (() -> Void)?
    var onOpen: (() -> Void)?

    private let artworkView = NSImageView()
    private let artworkPlaceholder = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "Not Playing")
    private let subtitleLabel = NSTextField(labelWithString: "No active media")
    private let controlRail = NSVisualEffectView()
    private let previousButton = NSButton()
    private let playPauseButton = NSButton()
    private let nextButton = NSButton()
    private var renderedTitle = "Not Playing"
    private var renderedSubtitle = "No active media"
    private var renderedArtworkURL: URL?
    private var artworkTask: URLSessionDataTask?
    private var hasRenderedContent = false

    override func loadView() {
        view = NSVisualEffectView()
        view.frame = NSRect(x: 0, y: 0, width: 414, height: 176)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureMaterial()
        configureSubviews()
        layoutSubviews()
    }

    func update(item: NowPlayingItem?) {
        let info = NowPlayingDisplayInfoFormatter.displayInfo(for: item)
        let animated = hasRenderedContent
        update(label: titleLabel, renderedValue: &renderedTitle, nextValue: info.title, animated: animated)
        update(label: subtitleLabel, renderedValue: &renderedSubtitle, nextValue: info.subtitle, animated: animated)
        updateArtwork(url: item?.artworkURL)

        let hasPlaybackTarget = NowPlayingPlaybackCommandTargetResolver.target(for: item) != nil
        previousButton.isEnabled = hasPlaybackTarget
        playPauseButton.isEnabled = hasPlaybackTarget
        nextButton.isEnabled = hasPlaybackTarget
        updatePlayPauseIcon(for: item)
        hasRenderedContent = true
    }

    private func configureMaterial() {
        guard let materialView = view as? NSVisualEffectView else {
            return
        }

        materialView.material = .hudWindow
        materialView.blendingMode = .behindWindow
        materialView.state = .active
        materialView.wantsLayer = true
        materialView.layer?.cornerRadius = 24
        materialView.layer?.masksToBounds = true
        materialView.layer?.borderColor = NSColor.white.withAlphaComponent(0.22).cgColor
        materialView.layer?.borderWidth = 0.7
    }

    private func configureSubviews() {
        controlRail.material = .contentBackground
        controlRail.blendingMode = .withinWindow
        controlRail.state = .active
        controlRail.wantsLayer = true
        controlRail.layer?.cornerRadius = 18
        controlRail.layer?.masksToBounds = true
        controlRail.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.10).cgColor
        controlRail.layer?.borderColor = NSColor.white.withAlphaComponent(0.16).cgColor
        controlRail.layer?.borderWidth = 0.5

        artworkPlaceholder.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: nil)
        artworkPlaceholder.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 34, weight: .medium)
        artworkPlaceholder.imageScaling = .scaleProportionallyUpOrDown
        artworkPlaceholder.contentTintColor = .secondaryLabelColor

        artworkView.imageScaling = .scaleProportionallyUpOrDown
        artworkView.wantsLayer = true
        artworkView.layer?.cornerRadius = 12
        artworkView.layer?.masksToBounds = true
        artworkView.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.42).cgColor
        artworkView.layer?.borderColor = NSColor.white.withAlphaComponent(0.30).cgColor
        artworkView.layer?.borderWidth = 0.8

        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.maximumNumberOfLines = 1
        titleLabel.wantsLayer = true

        subtitleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.maximumNumberOfLines = 1
        subtitleLabel.wantsLayer = true

        configureSymbolButton(previousButton, symbolName: "backward.fill", action: #selector(previous))
        configureSymbolButton(playPauseButton, symbolName: "pause.fill", action: #selector(togglePlayPause))
        configureSymbolButton(nextButton, symbolName: "forward.fill", action: #selector(next))
        [artworkView, titleLabel, subtitleLabel].forEach { view in
            view.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(openPlayingApp)))
        }

        [artworkView, artworkPlaceholder, titleLabel, subtitleLabel, controlRail, previousButton, playPauseButton, nextButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }

    private func layoutSubviews() {
        NSLayoutConstraint.activate([
            artworkView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            artworkView.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
            artworkView.widthAnchor.constraint(equalToConstant: 142),
            artworkView.heightAnchor.constraint(equalToConstant: 142),

            artworkPlaceholder.centerXAnchor.constraint(equalTo: artworkView.centerXAnchor),
            artworkPlaceholder.centerYAnchor.constraint(equalTo: artworkView.centerYAnchor),
            artworkPlaceholder.widthAnchor.constraint(equalToConstant: 54),
            artworkPlaceholder.heightAnchor.constraint(equalToConstant: 54),

            titleLabel.leadingAnchor.constraint(equalTo: artworkView.trailingAnchor, constant: 22),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 28),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            controlRail.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            controlRail.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            controlRail.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            controlRail.heightAnchor.constraint(equalToConstant: 54),

            previousButton.leadingAnchor.constraint(equalTo: controlRail.leadingAnchor, constant: 18),
            previousButton.centerYAnchor.constraint(equalTo: controlRail.centerYAnchor),
            previousButton.widthAnchor.constraint(equalToConstant: 42),
            previousButton.heightAnchor.constraint(equalToConstant: 42),

            playPauseButton.centerXAnchor.constraint(equalTo: controlRail.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: controlRail.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 46),
            playPauseButton.heightAnchor.constraint(equalToConstant: 44),

            nextButton.trailingAnchor.constraint(equalTo: controlRail.trailingAnchor, constant: -18),
            nextButton.centerYAnchor.constraint(equalTo: controlRail.centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 42),
            nextButton.heightAnchor.constraint(equalToConstant: 42)
        ])
    }

    private func configureSymbolButton(_ button: NSButton, symbolName: String, action: Selector) {
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        button.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 25, weight: .semibold)
        button.contentTintColor = .labelColor
        button.target = self
        button.action = action
        button.isEnabled = false
    }

    private func updatePlayPauseIcon(for item: NowPlayingItem?) {
        let symbolName = item?.playbackState == .paused ? "play.fill" : "pause.fill"
        playPauseButton.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        playPauseButton.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 25, weight: .semibold)
    }

    private func update(label: NSTextField, renderedValue: inout String, nextValue: String, animated: Bool) {
        guard renderedValue != nextValue else {
            return
        }

        if animated && shouldAnimateTextChanges {
            let transition = CATransition()
            transition.type = .push
            transition.subtype = .fromTop
            transition.duration = 0.22
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            label.layer?.add(transition, forKey: "listeningNowTextPush")
        }

        renderedValue = nextValue
        label.stringValue = nextValue
    }

    private var shouldAnimateTextChanges: Bool {
        !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    private func updateArtwork(url: URL?) {
        guard renderedArtworkURL != url else {
            return
        }

        renderedArtworkURL = url
        artworkTask?.cancel()

        guard let url else {
            setArtworkImage(nil, animated: hasRenderedContent)
            return
        }

        if let cachedImage = ArtworkImageCache.shared.image(for: url) {
            setArtworkImage(cachedImage, animated: false)
            return
        }

        artworkTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = NSImage(data: data) else {
                return
            }

            ArtworkImageCache.shared.store(image, for: url)

            DispatchQueue.main.async {
                guard self?.renderedArtworkURL == url else {
                    return
                }

                self?.setArtworkImage(image, animated: self?.hasRenderedContent == true)
            }
        }
        artworkTask?.resume()
    }

    private func setArtworkImage(_ image: NSImage?, animated: Bool) {
        if animated && shouldAnimateTextChanges {
            let transition = CATransition()
            transition.type = .fade
            transition.duration = 0.18
            artworkView.layer?.add(transition, forKey: "listeningNowArtworkFade")
        }

        artworkView.image = image
        artworkPlaceholder.isHidden = image != nil
    }

    @objc private func previous() {
        onPrevious?()
    }

    @objc private func togglePlayPause() {
        onTogglePlayPause?()
    }

    @objc private func next() {
        onNext?()
    }

    @objc private func openPlayingApp() {
        onOpen?()
    }
}
