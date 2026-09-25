import SwiftUI
import AppKit

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

// MARK: - Crystalline Glass Lens Pedestal
struct GlassLensPedestal: View {
    var isHighlighted: Bool = false

    var body: some View {
        ZStack {
            // Highly transparent glass refraction body
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

            // Specular glass highlight rim
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

    private var backgroundImage: NSImage? {
        let candidates: [URL?] = [
            Bundle.main.resourceURL?.appendingPathComponent("installer_scenery.png"),
            Bundle.main.url(forResource: "installer_scenery", withExtension: "png"),
            URL(fileURLWithPath: "Sources/MyScreen/Resources/installer_scenery.png"),
            URL(fileURLWithPath: "docs/assets/installer_scenery.png")
        ]
        for candidate in candidates {
            if let url = candidate, FileManager.default.fileExists(atPath: url.path), let img = NSImage(contentsOf: url) {
                return img
            }
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
            // 1. High-Resolution Static Scenery Background Layer
            if let bgImage = backgroundImage {
                Image(nsImage: bgImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color.black.edgesIgnoringSafeArea(.all)
            }

            // 2. Subtle Dark Vignette for contrast & text readability
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.38),
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.42)
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
                HStack(spacing: 48) {
                    // Left Column: MyScreen App Icon & Label
                    VStack(spacing: 10) {
                        ZStack {
                            // Crystalline Transparent Glass Pedestal
                            GlassLensPedestal(isHighlighted: false)

                            // Interactive Draggable Icon
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

                                            if value.translation.width > 140 && abs(value.translation.height) < 90 {
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

                                            if value.translation.width > 140 && abs(value.translation.height) < 90 {
                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                                    iconOffset = CGSize(width: 290, height: 0)
                                                }
                                                performInstall()
                                            } else {
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

                        // Application Name below icon
                        Text("MyScreen")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.85), radius: 5, y: 2)
                    }
                    .zIndex(isDraggingIcon ? 100 : 1)

                    // Center Column: Arrow / Status / Click-to-Install
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

                        if !isCompleted && !isInstalling {
                            Button(action: { performInstall() }) {
                                Text("or Click to Install")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.85))
                                    .underline()
                                    .shadow(color: .black.opacity(0.8), radius: 4, y: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 2)
                        }
                    }
                    .frame(width: 150)

                    // Right Column: Applications Folder Pedestal & Label
                    VStack(spacing: 10) {
                        ZStack {
                            GlassLensPedestal(isHighlighted: isTargetHovered)
                                .scaleEffect(isTargetHovered ? 1.06 : 1.0)
                                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isTargetHovered)

                            Image(nsImage: NSWorkspace.shared.icon(forFile: "/Applications"))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 92, height: 92)
                                .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
                        }

                        // Application Name below icon
                        Text("Applications")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.85), radius: 5, y: 2)
                    }
                }

                Spacer()

                // Bottom Section: Success actions
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
        errorMessage = nil
        statusText = "Installing..."

        DispatchQueue.global(qos: .userInitiated).async {
            var candidatePaths: [URL] = []

            // 1. Inside installer bundle Resources
            if let resURL = Bundle.main.resourceURL {
                candidatePaths.append(resURL.appendingPathComponent("MyScreen.app"))
            }
            // 2. Sibling next to installer bundle
            candidatePaths.append(Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("MyScreen.app"))
            // 3. Mounted DMG root
            candidatePaths.append(URL(fileURLWithPath: "/Volumes/MyScreen/MyScreen.app"))
            // 4. Local workspace build directory
            candidatePaths.append(URL(fileURLWithPath: "build/MyScreen.app"))

            // Dynamically check any mounted volume
            if let volumeURLs = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: [.skipHiddenVolumes]) {
                for vol in volumeURLs {
                    candidatePaths.append(vol.appendingPathComponent("MyScreen.app"))
                }
            }

            guard let sourceURL = candidatePaths.first(where: {
                var isDir: ObjCBool = false
                return FileManager.default.fileExists(atPath: $0.path, isDirectory: &isDir) && isDir.boolValue
            }) else {
                DispatchQueue.main.async {
                    self.isInstalling = false
                    self.errorMessage = "Could not locate MyScreen.app to install."
                    self.statusText = "Installation Failed"
                }
                return
            }

            let destinationURL = URL(fileURLWithPath: "/Applications/MyScreen.app")

            // Use /usr/bin/ditto for atomic, permission-preserving bundle copy
            let ditto = Process()
            ditto.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            ditto.arguments = [sourceURL.path, destinationURL.path]

            do {
                try ditto.run()
                ditto.waitUntilExit()

                // Automatically remove download quarantine attributes so macOS Gatekeeper never blocks the app
                let xattr = Process()
                xattr.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
                xattr.arguments = ["-cr", destinationURL.path]
                try? xattr.run()
                xattr.waitUntilExit()

                if ditto.terminationStatus == 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            self.isInstalling = false
                            self.isCompleted = true
                            self.statusText = "Installation Complete"
                        }
                    }
                } else {
                    // Fallback to FileManager copy
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try? FileManager.default.removeItem(at: destinationURL)
                    }
                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

                    let fallbackXattr = Process()
                    fallbackXattr.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
                    fallbackXattr.arguments = ["-cr", destinationURL.path]
                    try? fallbackXattr.run()
                    fallbackXattr.waitUntilExit()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            self.isInstalling = false
                            self.isCompleted = true
                            self.statusText = "Installation Complete"
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isInstalling = false
                    self.errorMessage = error.localizedDescription
                    self.statusText = "Installation Failed"
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
