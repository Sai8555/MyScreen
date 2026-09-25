import SwiftUI
import AppKit
import UniformTypeIdentifiers

public enum MyScreenTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case explore = "Explore"
    case library = "Library"

    public var id: String { rawValue }
}

public struct MainContainerView: View {
    @State private var selectedTab: MyScreenTab = .home
    @State private var selectedCategory: String = "all"
    @State private var previewItem: WallpaperItem?
    @State private var showSettings: Bool = false

    @ObservedObject private var engine = WallpaperEngine.shared
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var localManager = LocalWallpaperManager.shared

    public init() {}

    public var body: some View {
        ZStack(alignment: .top) {
            // Main Content Area
            Group {
                switch selectedTab {
                case .home:
                    HomeView(
                        onSelectWallpaper: { item in
                            previewItem = item
                        },
                        onSelectCategory: { categoryId in
                            selectedCategory = categoryId
                            selectedTab = .explore
                        }
                    )
                case .explore:
                    ExploreView(
                        selectedCategory: $selectedCategory,
                        onSelectWallpaper: { item in
                            previewItem = item
                        }
                    )
                case .library:
                    LibraryView(
                        onSelectWallpaper: { item in
                            previewItem = item
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 64) // Space for floating top navigation bar

            // Floating Glassmorphic Top Navigation Header
            topNavigationBar

            // Fullscreen Wallpaper Detail Modal
            if let item = previewItem {
                DetailModalView(item: item) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        previewItem = nil
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(100)
            }
        }
        .frame(minWidth: 1020, minHeight: 700)
        .background(DesignTokens.background)
        .sheet(isPresented: $showSettings) {
            SettingsView(onClose: {
                showSettings = false
            })
        }
    }

    // MARK: - Floating Top Navigation Bar
    private var topNavigationBar: some View {
        HStack(spacing: 20) {
            // Left: Logo & App Title
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 30, height: 30)

                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("MyScreen")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.leading, 72) // Space for macOS traffic lights

            Spacer()

            // Center: Capsule Pill Navigation: [ Home | Explore | Library ]
            HStack(spacing: 2) {
                ForEach(MyScreenTab.allCases) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedTab = tab
                        }
                    }) {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: selectedTab == tab ? .bold : .medium))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 7)
                            .background(
                                selectedTab == tab
                                    ? Color.white
                                    : Color.clear
                            )
                            .foregroundColor(selectedTab == tab ? .black : DesignTokens.textSecondary)
                            .cornerRadius(18)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color.black.opacity(0.5))
            .background(.ultraThinMaterial)
            .cornerRadius(22)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )

            Spacer()

            // Right: Circular Action Buttons (PRO tag removed per user request)
            HStack(spacing: 10) {
                // Search Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedTab = .explore
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.45))
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Search Wallpapers")

                // "+" Import Video Button
                Button(action: openQuickImport) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.45))
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Import Custom Video")

                // Settings Gear Button
                Button(action: {
                    AppDelegate.shared?.openPreferencesWindow()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.45))
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Preferences")
            }
            .padding(.trailing, 24)
        }
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.65), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func openQuickImport() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [
            UTType.movie,
            UTType.mpeg4Movie,
            UTType.quickTimeMovie
        ]

        if panel.runModal() == .OK {
            Task {
                for url in panel.urls {
                    if let item = await localManager.importVideo(from: url) {
                        await MainActor.run {
                            selectedTab = .library
                            previewItem = item
                        }
                    }
                }
            }
        }
    }
}
