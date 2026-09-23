import SwiftUI
import AVKit

public struct VideoPlayerView: NSViewRepresentable {
    public let url: URL
    public var isMuted: Bool = true
    public var shouldLoop: Bool = true

    public init(url: URL, isMuted: Bool = true, shouldLoop: Bool = true) {
        self.url = url
        self.isMuted = isMuted
        self.shouldLoop = shouldLoop
    }

    public func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.black.cgColor

        loadVideo(for: url, in: container, context: context)
        return container
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        // If URL changed, reload the player immediately
        if context.coordinator.currentURL != url {
            loadVideo(for: url, in: nsView, context: context)
        }

        if let player = context.coordinator.player {
            player.isMuted = isMuted
        }
        if let sublayer = nsView.layer?.sublayers?.first as? AVPlayerLayer {
            sublayer.frame = nsView.bounds
        }
    }

    private func loadVideo(for url: URL, in container: NSView, context: Context) {
        context.coordinator.currentURL = url
        context.coordinator.looper?.disableLooping()
        context.coordinator.looper = nil
        context.coordinator.player?.pause()

        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVQueuePlayer(playerItem: playerItem)
        player.isMuted = isMuted

        // Reuse or create player layer
        let playerLayer: AVPlayerLayer
        if let existing = container.layer?.sublayers?.first as? AVPlayerLayer {
            playerLayer = existing
            playerLayer.player = player
        } else {
            playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            container.layer?.addSublayer(playerLayer)
        }

        if shouldLoop {
            context.coordinator.looper = AVPlayerLooper(player: player, templateItem: playerItem)
        }

        context.coordinator.player = player
        player.play()
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public final class Coordinator {
        var currentURL: URL?
        var player: AVQueuePlayer?
        var looper: AVPlayerLooper?

        deinit {
            looper?.disableLooping()
            player?.pause()
        }
    }
}
