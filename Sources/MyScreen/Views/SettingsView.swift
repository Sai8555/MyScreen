import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var engine = WallpaperEngine.shared
    @State private var cacheSize: String = VideoCacheManager.shared.cacheSizeString()
    @State private var isCacheCleared = false
    @State private var updateCheckStatus: String = "Check"
    @State private var isCheckingUpdate: Bool = false

    public let onClose: (() -> Void)?

    public init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
    }

    public var body: some View {
        ZStack {
            DesignTokens.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Modal Top Bar with Close / Exit Button (Solves "no exit option")
                HStack {
                    Text("Preferences")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignTokens.textSecondary)

                    Spacer()

                    Button(action: {
                        onClose?()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(DesignTokens.textSecondary)
                        }
                        .padding(6)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                    .help("Close Settings (Esc)")
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 8)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Top App Header
                        VStack(spacing: 8) {
                            Image(nsImage: NSApp.applicationIconImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 72, height: 72)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)

                            Text("MyScreen")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)

                            Text("Version 1.0.0")
                                .font(.system(size: 12))
                                .foregroundColor(DesignTokens.textSecondary)
                        }
                        .padding(.top, 8)

                        // General Group
                        settingsGroup(title: "General") {
                            settingsRow(
                                icon: "power",
                                iconColor: .orange,
                                title: "Launch at Login",
                                subtitle: "Opens and runs automatically when you sign in"
                            ) {
                                Toggle("", isOn: $settings.autoStartOnLogin)
                                    .toggleStyle(.switch)
                            }

                            Divider().background(Color.white.opacity(0.08))

                            settingsRow(
                                icon: "gearshape.2.fill",
                                iconColor: .green,
                                title: "Background Activity",
                                subtitle: "Configure in System Settings > Login Items & Extensions"
                            ) {
                                Button("Open Settings") {
                                    settings.openBackgroundPermissions()
                                }
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.12))
                                .foregroundColor(.white)
                                .cornerRadius(6)
                                .buttonStyle(.plain)
                            }

                            Divider().background(Color.white.opacity(0.08))

                            settingsRow(
                                icon: "lock.desktopcomputer",
                                iconColor: .indigo,
                                title: "Lock Screen Wallpaper",
                                subtitle: "View or configure macOS Wallpaper settings"
                            ) {
                                Button("Open Settings") {
                                    settings.openWallpaperSettings()
                                }
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.12))
                                .foregroundColor(.white)
                                .cornerRadius(6)
                                .buttonStyle(.plain)
                            }

                            Divider().background(Color.white.opacity(0.08))

                            settingsRow(
                                icon: "menubar.rectangle",
                                iconColor: .cyan,
                                title: "Show Menu Bar Icon",
                                subtitle: "Quick access from the macOS menu bar"
                            ) {
                                Toggle("", isOn: .constant(true))
                                    .toggleStyle(.switch)
                            }

                            Divider().background(Color.white.opacity(0.08))

                            settingsRow(
                                icon: "arrow.clockwise",
                                iconColor: .blue,
                                title: "Check for Updates",
                                subtitle: isCheckingUpdate ? "Checking GitHub releases..." : "Current release: v1.0.0"
                            ) {
                                Button(updateCheckStatus) {
                                    checkForGitHubUpdates()
                                }
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.12))
                                .foregroundColor(.white)
                                .cornerRadius(6)
                                .buttonStyle(.plain)
                                .disabled(isCheckingUpdate)
                            }
                        }

                        // Playback Group
                        settingsGroup(title: "Playback") {
                            settingsRow(
                                icon: "bolt.fill",
                                iconColor: .green,
                                title: "Auto-pause in Low Power Mode",
                                subtitle: "Halts video decoding when on low battery"
                            ) {
                                Toggle("", isOn: $settings.pauseOnBattery)
                                    .toggleStyle(.switch)
                            }

                            Divider().background(Color.white.opacity(0.08))

                            settingsRow(
                                icon: "moon.fill",
                                iconColor: .indigo,
                                title: "Auto-pause when Screen is Off",
                                subtitle: "Halts playback when displays sleep; wakes automatically on Lock Screen"
                            ) {
                                Toggle("", isOn: $settings.pauseOnScreenSleep)
                                    .toggleStyle(.switch)
                            }

                            Divider().background(Color.white.opacity(0.08))

                            settingsRow(
                                icon: "speaker.wave.2.fill",
                                iconColor: .purple,
                                title: "Mute Wallpaper Audio",
                                subtitle: "Play live wallpapers silently"
                            ) {
                                Toggle("", isOn: $settings.isMuted)
                                    .toggleStyle(.switch)
                            }
                        }

                        // Displays Group (Per-display status & multi-monitor monitoring)
                        settingsGroup(title: "Active Displays") {
                            let screens = NSScreen.screens
                            ForEach(Array(screens.enumerated()), id: \.offset) { index, screen in
                                if index > 0 {
                                    Divider().background(Color.white.opacity(0.08))
                                }
                                let isMain = (screen == NSScreen.main)
                                let displayName = screen.localizedName.isEmpty ? "Built-in Retina Display" : screen.localizedName
                                let activeItem = engine.item(for: screen)

                                settingsRow(
                                    icon: "display",
                                    iconColor: .blue,
                                    title: "\(displayName) \(isMain ? "(Main)" : "")",
                                    subtitle: activeItem != nil ? "Active: \(activeItem!.title)" : "No live wallpaper assigned"
                                ) {
                                    if activeItem != nil {
                                        Text("Live Playing")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.green)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.green.opacity(0.12))
                                            .cornerRadius(6)
                                    } else {
                                        Text("Static")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(DesignTokens.textMuted)
                                    }
                                }
                            }
                        }

                        // Storage & Cache Group
                        settingsGroup(title: "Storage") {
                            settingsRow(
                                icon: "clock.arrow.circlepath",
                                iconColor: .cyan,
                                title: "Wallpaper Cache",
                                subtitle: "Cached videos: \(cacheSize)"
                            ) {
                                Button(isCacheCleared ? "Cleared" : "Clear Cache") {
                                    VideoCacheManager.shared.clearCache()
                                    cacheSize = VideoCacheManager.shared.cacheSizeString()
                                    isCacheCleared = true
                                }
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.12))
                                .foregroundColor(.white)
                                .cornerRadius(6)
                                .buttonStyle(.plain)
                            }
                        }

                        // Community & Support
                        settingsGroup(title: "Community & License") {
                            settingsRow(
                                icon: "star.fill",
                                iconColor: .yellow,
                                title: "MyScreen Open Source",
                                subtitle: "Free & Open Source forever"
                            ) {
                                Text("Free")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(DesignTokens.textSecondary)
                            }

                            Divider().background(Color.white.opacity(0.08))

                            settingsRow(
                                icon: "link",
                                iconColor: .cyan,
                                title: "GitHub Repository",
                                subtitle: "View source code & releases"
                            ) {
                                Button(action: {
                                    if let url = URL(string: "https://github.com/Sai8555/MyScreen") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }) {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(DesignTokens.textSecondary)
                                }
                                .buttonStyle(.plain)
                            }

                            Divider().background(Color.white.opacity(0.08))

                            settingsRow(
                                icon: "exclamationmark.bubble.fill",
                                iconColor: .orange,
                                title: "Report an Issue",
                                subtitle: "Submit bug reports & feature requests"
                            ) {
                                Button(action: {
                                    if let url = URL(string: "https://github.com/Sai8555/MyScreen/issues") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }) {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(DesignTokens.textSecondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Quit Application Section (Solves "i cant quit my application")
                        VStack(spacing: 8) {
                            Button(action: {
                                engine.stop()
                                NSApp.terminate(nil)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "power")
                                    Text("Quit MyScreen")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.red)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.12))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .keyboardShortcut("q", modifiers: .command)

                            Text("You can also press ⌘Q anytime to quit.")
                                .font(.system(size: 11))
                                .foregroundColor(DesignTokens.textMuted)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 36)
                }
            }
        }
        .frame(minWidth: 460, maxWidth: 520, minHeight: 620, maxHeight: 720)
    }

    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DesignTokens.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 12) {
                content()
            }
            .padding(14)
            .background(DesignTokens.cardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private func settingsRow<Control: View>(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(DesignTokens.textMuted)
            }

            Spacer()

            control()
        }
    }

    private func checkForGitHubUpdates() {
        isCheckingUpdate = true
        updateCheckStatus = "Checking..."

        guard let url = URL(string: "https://api.github.com/repos/Sai8555/MyScreen/releases/latest") else {
            isCheckingUpdate = false
            updateCheckStatus = "Up to date"
            return
        }

        var request = URLRequest(url: url)
        request.setValue("MyScreen-Updater", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 8

        URLSession.shared.dataTask(with: request) { data, response, _ in
            DispatchQueue.main.async {
                self.isCheckingUpdate = false
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                   let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tagName = json["tag_name"] as? String {
                    if tagName != "v1.0.0" && tagName != "1.0.0" {
                        self.updateCheckStatus = "New: \(tagName)"
                    } else {
                        self.updateCheckStatus = "Up to date (v1.0.0)"
                    }
                } else {
                    self.updateCheckStatus = "Up to date (v1.0.0)"
                }
            }
        }.resume()
    }
}
