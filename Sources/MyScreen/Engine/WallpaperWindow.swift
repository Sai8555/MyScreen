import AppKit
import AVFoundation

public final class WallpaperWindow: NSWindow {
    private let playerView: NSView
    private let playerLayer: AVPlayerLayer
    public private(set) var targetScreen: NSScreen?

    public override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        self.playerView = NSView(frame: contentRect)
        self.playerLayer = AVPlayerLayer()

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: backingStoreType,
            defer: flag
        )

        setupWindowProperties()
        setupPlayerLayer()
    }

    public convenience init(screen: NSScreen, player: AVPlayer) {
        self.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.targetScreen = screen
        self.playerLayer.player = player
        self.updateFrame(for: screen)
    }

    private func setupWindowProperties() {
        // Place window right behind desktop icons and above desktop background
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        self.backgroundColor = .black
        self.isOpaque = true
        self.hasShadow = false
        // CRITICAL: Let mouse clicks pass straight through to desktop icons
        self.ignoresMouseEvents = true
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
        self.canHide = false
    }

    private func setupPlayerLayer() {
        playerView.wantsLayer = true
        let scale = targetScreen?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
        playerView.layer?.contentsScale = scale
        playerLayer.contentsScale = scale
        playerLayer.frame = playerView.bounds
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

        if let rootLayer = playerView.layer {
            rootLayer.addSublayer(playerLayer)
        }

        self.contentView = playerView
    }

    public func updateFrame(for screen: NSScreen) {
        self.targetScreen = screen
        let scale = screen.backingScaleFactor
        self.setFrame(screen.frame, display: true)
        self.playerView.frame = NSRect(origin: .zero, size: screen.frame.size)
        self.playerView.layer?.contentsScale = scale
        self.playerLayer.contentsScale = scale
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        self.playerLayer.frame = self.playerView.bounds
        CATransaction.commit()
    }

    public func updatePlayer(_ player: AVPlayer) {
        self.playerLayer.player = player
    }
}
