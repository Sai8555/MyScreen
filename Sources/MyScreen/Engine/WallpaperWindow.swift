import AppKit
import AVFoundation

public final class PlayerHostingView: NSView {
    public var playerLayer: AVPlayerLayer {
        return self.layer as! AVPlayerLayer
    }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
    }

    public override func makeBackingLayer() -> CALayer {
        let layer = AVPlayerLayer()
        layer.videoGravity = .resizeAspectFill
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        return layer
    }
}

public final class WallpaperWindow: NSWindow {
    private let playerView: PlayerHostingView
    public private(set) var targetScreen: NSScreen?

    public convenience init(screen: NSScreen, player: AVPlayer) {
        self.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.targetScreen = screen
        self.playerView.playerLayer.player = player
        self.updateFrame(for: screen)
    }

    public override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        self.playerView = PlayerHostingView(frame: contentRect)

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: backingStoreType,
            defer: flag
        )

        setupWindowProperties()
        self.contentView = playerView
    }

    private func setupWindowProperties() {
        // Place window right above desktop background and behind desktop icons
        let desktopLevel = Int(CGWindowLevelForKey(.desktopWindow))
        self.level = NSWindow.Level(desktopLevel + 1)
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        self.backgroundColor = .clear
        self.isOpaque = true
        self.hasShadow = false
        // CRITICAL: Let mouse clicks pass straight through to desktop icons
        self.ignoresMouseEvents = true
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
        self.canHide = false
    }

    public func updateFrame(for screen: NSScreen) {
        self.targetScreen = screen
        let scale = screen.backingScaleFactor
        self.setFrame(screen.frame, display: true)
        self.playerView.frame = NSRect(origin: .zero, size: screen.frame.size)
        self.playerView.layer?.contentsScale = scale
        self.playerView.playerLayer.contentsScale = scale
    }

    public func updatePlayer(_ player: AVPlayer) {
        self.playerView.playerLayer.player = player
    }
}
