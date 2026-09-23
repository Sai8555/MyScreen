import SwiftUI
import AppKit

public struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject private var engine = WallpaperEngine.shared
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var service = WallpaperService.shared

    @State private var memoryUsage: String = "120 MB"
    @State private var cacheSize: String = VideoCacheManager.shared.cacheSizeString()

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Top Live Preview Card
            if let active = engine.currentItem {
                VStack(spacing: 8) {
                    ZStack(alignment: .bottomLeading) {
                        RemoteImageView(url: active.thumbnailUrl)
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .background(Color.black)

                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.8)],
                            startPoint: .center,
                            endPoint: .bottom
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(active.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(active.resolution)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(white: 0.7))
                        }
                        .padding(8)
                    }
                    .cornerRadius(10)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                    // Playback Controls Row
                    HStack(spacing: 20) {
                        Button(action: playPreviousWallpaper) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        .help("Previous Wallpaper")

                        Button(action: {
                            engine.togglePlayback()
                        }) {
                            Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.white.opacity(0.15)))
                        }
                        .buttonStyle(.plain)
                        .help(engine.isPlaying ? "Pause Wallpaper" : "Resume Wallpaper")

                        Button(action: playNextWallpaper) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        .help("Next Wallpaper")

                        Button(action: {
                            settings.isMuted.toggle()
                        }) {
                            Image(systemName: settings.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 12))
                                .foregroundColor(settings.isMuted ? DesignTokens.textMuted : .white)
                        }
                        .buttonStyle(.plain)
                        .help(settings.isMuted ? "Unmute Audio" : "Mute Audio")
                    }
                    .padding(.vertical, 6)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles.tv")
                        .font(.system(size: 28))
                        .foregroundColor(DesignTokens.textSecondary)

                    Text("No Active Wallpaper")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)

                    Button("Choose a Wallpaper") {
                        openMainWindow()
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(14)
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.vertical, 6)

            // Primary App Links
            VStack(spacing: 2) {
                menuButton(icon: "sparkles", title: "Open MyScreen") {
                    openMainWindow()
                }

                menuButton(icon: "speaker.wave.2.fill", title: settings.isMuted ? "Unmute Wallpaper Audio" : "Mute Wallpaper Audio") {
                    settings.isMuted.toggle()
                }
            }
            .padding(.horizontal, 8)

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.vertical, 6)

            // Resource Diagnostics
            VStack(spacing: 4) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                            .font(.system(size: 10))
                        Text(engine.isPlaying ? "CPU: 1.8%" : "CPU: 0.1%")
                            .font(.system(size: 11))
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "memorychip")
                            .font(.system(size: 10))
                        Text("RAM: \(memoryUsage)")
                            .font(.system(size: 11))
                    }
                }
                .foregroundColor(DesignTokens.textMuted)

                HStack {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 10))
                    Text("Cache: \(cacheSize)")
                        .font(.system(size: 11))
                    Spacer()
                }
                .foregroundColor(DesignTokens.textMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.vertical, 6)

            // Bottom Utilities & Quit
            VStack(spacing: 2) {
                menuButton(icon: "trash", title: "Clear Cache") {
                    VideoCacheManager.shared.clearCache()
                    cacheSize = VideoCacheManager.shared.cacheSizeString()
                }

                menuButton(icon: "gearshape.fill", title: "Preferences...") {
                    openMainWindow()
                }

                menuButton(icon: "power", title: "Quit MyScreen", shortcut: "⌘Q") {
                    engine.stop()
                    NSApp.terminate(nil)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(width: 270)
        .background(Color(red: 0.11, green: 0.13, blue: 0.16).opacity(0.96))
        .background(.ultraThinMaterial)
        .onAppear {
            updateStats()
        }
    }

    private func menuButton(icon: String, title: String, shortcut: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(DesignTokens.textSecondary)
                    .frame(width: 16)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                if let sc = shortcut {
                    Text(sc)
                        .font(.system(size: 11))
                        .foregroundColor(DesignTokens.textMuted)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func openMainWindow() {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
        AppDelegate.shared?.reopenMainWindow()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            AppDelegate.shared?.reopenMainWindow()
        }
    }

    private func playNextWallpaper() {
        let all = service.allWallpapers
        guard !all.isEmpty else { return }
        if let current = engine.currentItem, let idx = all.firstIndex(where: { $0.id == current.id }) {
            let nextIdx = (idx + 1) % all.count
            engine.applyWallpaper(all[nextIdx], scope: engine.selectedScope, screenIndex: engine.selectedScreenIndex)
        } else if let first = all.first {
            engine.applyWallpaper(first, scope: engine.selectedScope, screenIndex: engine.selectedScreenIndex)
        }
    }

    private func playPreviousWallpaper() {
        let all = service.allWallpapers
        guard !all.isEmpty else { return }
        if let current = engine.currentItem, let idx = all.firstIndex(where: { $0.id == current.id }) {
            let prevIdx = (idx - 1 + all.count) % all.count
            engine.applyWallpaper(all[prevIdx], scope: engine.selectedScope, screenIndex: engine.selectedScreenIndex)
        } else if let last = all.last {
            engine.applyWallpaper(last, scope: engine.selectedScope, screenIndex: engine.selectedScreenIndex)
        }
    }

    private func updateStats() {
        cacheSize = VideoCacheManager.shared.cacheSizeString()
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            let mb = Double(info.resident_size) / (1024.0 * 1024.0)
            memoryUsage = String(format: "%.0f MB", mb)
        }
    }
}
