import SwiftUI
import AppKit
import AVFoundation

// MARK: - Native Window Drag Area
struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        DraggableView()
    }
    func updateNSView(_ nsView: NSView, context: Context) {}

    class DraggableView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}

// MARK: - Looping Video View (AVPlayerLayer)
struct VideoBackgroundView: NSViewRepresentable {
    let videoURL: URL?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true

        guard let videoURL = videoURL else { return view }

        let asset = AVURLAsset(url: videoURL)
        let item = AVPlayerItem(asset: asset)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true

        let playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        context.coordinator.looper = playerLooper
        context.coordinator.player = queuePlayer

        let playerLayer = AVPlayerLayer(player: queuePlayer)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        playerLayer.frame = view.bounds
        view.layer?.addSublayer(playerLayer)

        queuePlayer.play()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let layer = nsView.layer?.sublayers?.first as? AVPlayerLayer {
            layer.frame = nsView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var player: AVQueuePlayer?
        var looper: AVPlayerLooper?
    }
}

// MARK: - Crystalline Glass Lens Pedestal
struct GlassLensPedestal: View {
    var isHighlighted: Bool = false

    var body: some View {
        ZStack {
            // Highly transparent glass refraction body (never opaque/black)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHighlighted ? 0.35 : 0.16),
                            Color.white.opacity(isHighlighted ? 0.12 : 0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 126, height: 126)

            // Specular glass highlight rim (catches top-left light)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHighlighted ? 0.95 : 0.65),
                            Color.white.opacity(isHighlighted ? 0.35 : 0.12),
                            Color.white.opacity(isHighlighted ? 0.75 : 0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isHighlighted ? 2.5 : 1.5
                )
                .frame(width: 126, height: 126)
        }
        .shadow(color: isHighlighted ? Color.white.opacity(0.35) : Color.black.opacity(0.2), radius: isHighlighted ? 20 : 12, x: 0, y: 6)
    }
}

// MARK: - Installer View
struct InstallerView: View {
    @State private var isInstalling = false
    @State private var isCompleted = false
    @State private var statusText: String = "Drag to install"
    @State private var errorMessage: String?

    // Drag-and-drop state
    @State private var iconOffset: CGSize = .zero
    @State private var isDraggingIcon = false
    @State private var isTargetHovered = false

    private var videoURL: URL? {
        if let bundleURL = Bundle.main.url(forResource: "installer_bg", withExtension: "mp4") {
            return bundleURL
        }
        let localPath = URL(fileURLWithPath: "docs/assets/installer_bg.mp4")
        if FileManager.default.fileExists(atPath: localPath.path) {
            return localPath
        }
        return nil
    }

    private var appIconImage: NSImage {
        if let img = NSImage(named: "AppIcon") {
            return img
        }
        let candidates: [URL] = [
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/AppIcon.icns"),
            Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("MyScreen.app/Contents/Resources/AppIcon.icns"),
            URL(fileURLWithPath: "Sources/MyScreen/Resources/AppIcon.icns"),
            URL(fileURLWithPath: "docs/assets/app_icon.png")
        ]
        for url in candidates {
            if let img = NSImage(contentsOf: url) {
                return img
            }
        }
        return NSWorkspace.shared.icon(forFile: "/Applications")
    }

    var body: some View {
        ZStack {
            // 1. Live Video Background Layer
            VideoBackgroundView(videoURL: videoURL)
                .edgesIgnoringSafeArea(.all)

            // 2. Subtle Dark Vignette for contrast
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.35),
                    Color.black.opacity(0.05),
                    Color.black.opacity(0.4)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            // Window Draggable Top Bar
            VStack {
                WindowDragArea()
                    .frame(height: 50)
                Spacer()
            }
            .edgesIgnoringSafeArea(.top)

            // 3. Foreground Installer UI
            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("MyScreen")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.6), radius: 6, y: 2)

                            Text("v1.0.0")
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.18))
                                        .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1))
                                )
                                .foregroundColor(.white)
                        }

                        Text("4K Live Video Wallpaper Engine for macOS")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.6), radius: 4, y: 1)
                    }
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.horizontal, 36)

                Spacer()

                // Center Stage: App Icon -> Arrow -> Applications Folder
                HStack(spacing: 50) {
                    // Left: MyScreen App Icon (Draggable & Always Forward on Drag)
                    VStack(spacing: 12) {
                        ZStack {
                            // Crystalline Transparent Glass Pedestal (Video shows through!)
                            GlassLensPedestal(isHighlighted: false)

                            // Interactive Draggable Icon (Always on forward side, disappears into Applications on install!)
                            Image(nsImage: appIconImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 92, height: 92)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(isDraggingIcon ? 0.75 : 0.5), radius: isDraggingIcon ? 28 : 10, y: isDraggingIcon ? 18 : 5)
                                .scaleEffect(isCompleted ? 0.01 : (isDraggingIcon ? 1.14 : 1.0))
                                .opacity(isCompleted ? 0.0 : 1.0)
                                .offset(iconOffset)
                                .zIndex(isDraggingIcon ? 100 : 10)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            guard !isCompleted && !isInstalling else { return }
                                            isDraggingIcon = true
                                            iconOffset = value.translation

                                            // Highlight target when dragged close to Applications (dx > 150)
                                            if value.translation.width > 150 && abs(value.translation.height) < 90 {
                                                isTargetHovered = true
                                                statusText = "Release to Install"
                                            } else {
                                                isTargetHovered = false
                                                statusText = "Drag into Applications"
                                            }
                                        }
                                        .onEnded { value in
                                            guard !isCompleted && !isInstalling else { return }
                                            isDraggingIcon = false

                                            if value.translation.width > 150 && abs(value.translation.height) < 90 {
                                                // Snapped into the Applications folder center!
                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                                    iconOffset = CGSize(width: 300, height: 0)
                                                }
                                                performInstall()
                                            } else {
                                                // Spring back to pedestal
                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                                    iconOffset = .zero
                                                }
                                                isTargetHovered = false
                                                statusText = "Drag to install"
                                            }
                                        }
                                )
                        }
                        .zIndex(isDraggingIcon ? 100 : 1)
                    }
                    .zIndex(isDraggingIcon ? 100 : 1)

                    // Center: Subtle Frosted Glass Arrow / Status
                    VStack(spacing: 8) {
                        if isInstalling {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                        } else if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundColor(.green)
                                .shadow(color: .green.opacity(0.6), radius: 12)
                        } else {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                                .shadow(color: .white.opacity(0.4), radius: 8)
                        }

                        Text(statusText)
                            .font(.system(size: 11, weight: .bold))
                            .textCase(.uppercase)
                            .tracking(1.2)
                            .foregroundColor(isCompleted ? .green : .white.opacity(0.9))
                            .shadow(color: .black.opacity(0.9), radius: 4, y: 2)
                    }
                    .frame(width: 150)

                    // Right: Applications Folder Pedestal (Target)
                    VStack(spacing: 12) {
                        ZStack {
                            // Crystalline Transparent Glass Pedestal (Highlights on hover!)
                            GlassLensPedestal(isHighlighted: isTargetHovered)
                                .scaleEffect(isTargetHovered ? 1.06 : 1.0)
                                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isTargetHovered)

                            Image(nsImage: NSWorkspace.shared.icon(forFile: "/Applications"))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 92, height: 92)
                                .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
                        }
                    }
                }

                Spacer()

                // Bottom Section: ONLY shown AFTER installation completes!
                Group {
                    if isCompleted {
                        HStack(spacing: 16) {
                            Button(action: launchApp) {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 13))
                                    Text("Launch MyScreen")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 26)
                                .padding(.vertical, 13)
                                .background(
                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .fill(Color.white.opacity(0.18))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                                .stroke(Color.green.opacity(0.7), lineWidth: 1.5)
                                        )
                                )
                                .shadow(color: Color.green.opacity(0.35), radius: 14, y: 4)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: openApplicationsFolder) {
                                HStack(spacing: 6) {
                                    Image(systemName: "folder")
                                    Text("Open in Finder")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .fill(Color.white.opacity(0.14))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        // Empty space so the beautiful coastal scenery remains open and visible!
                        Color.clear.frame(height: 48)
                    }
                }
                .padding(.bottom, 28)

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.bottom, 10)
                }
            }
        }
        .frame(width: 680, height: 430)
    }

    // MARK: - Installation Logic
    private func performInstall() {
        guard !isInstalling && !isCompleted else { return }
        isInstalling = true
        statusText = "Installing..."

        DispatchQueue.global(qos: .userInitiated).async {
            // Candidate paths for MyScreen.app
            let candidates: [URL] = [
                Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("MyScreen.app"),
                URL(fileURLWithPath: "build/MyScreen.app"),
                Bundle.main.url(forResource: "MyScreen", withExtension: "app") ?? URL(fileURLWithPath: "/dev/null")
            ]

            guard let sourceURL = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
                DispatchQueue.main.async {
                    self.isInstalling = false
                    self.errorMessage = "Could not locate MyScreen.app in bundle."
                    self.statusText = "Installation Failed"
                }
                return
            }

            let destinationURL = URL(fileURLWithPath: "/Applications/MyScreen.app")

            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }

                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        self.isInstalling = false
                        self.isCompleted = true
                        self.statusText = "Installation Complete"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isInstalling = false
                    self.errorMessage = error.localizedDescription
                    self.statusText = "Error"
                }
            }
        }
    }

    private func launchApp() {
        let appURL = URL(fileURLWithPath: "/Applications/MyScreen.app")
        NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration()) { _, _ in
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func openApplicationsFolder() {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: "/Applications")
    }
}

// MARK: - App Delegate & Main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = InstallerView()

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 430),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "MyScreen Installer"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = false
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
