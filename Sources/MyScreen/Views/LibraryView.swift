import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct LibraryView: View {
    @ObservedObject private var localManager = LocalWallpaperManager.shared
    @ObservedObject private var service = WallpaperService.shared
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var engine = WallpaperEngine.shared

    @State private var selectedSubTab: String = "Custom" // "Custom", "Favorites"
    @State private var isTargetedForDrop = false

    public let onSelectWallpaper: (WallpaperItem) -> Void

    public init(onSelectWallpaper: @escaping (WallpaperItem) -> Void) {
        self.onSelectWallpaper = onSelectWallpaper
    }

    private var favoriteItems: [WallpaperItem] {
        service.allWallpapers.filter { settings.isFavorite(id: $0.id) }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 240, maximum: 320), spacing: 18)
    ]

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header with Sub-tab Capsule Selector
                HStack {
                    HStack(spacing: 4) {
                        ForEach(["Custom Videos", "Favorites"], id: \.self) { subTab in
                            let isSelected = (subTab == "Custom Videos" && selectedSubTab == "Custom") ||
                                             (subTab == "Favorites" && selectedSubTab == "Favorites")
                            Button(action: {
                                selectedSubTab = (subTab == "Custom Videos") ? "Custom" : "Favorites"
                            }) {
                                Text(subTab)
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Color.white : Color.clear)
                                    .foregroundColor(isSelected ? .black : .white)
                                    .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(24)

                    Spacer()

                    if selectedSubTab == "Custom" {
                        Button(action: openFilePicker) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Import Video")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)

                // Custom Videos Mode
                if selectedSubTab == "Custom" {
                    // Drag & Drop Area
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isTargetedForDrop ? DesignTokens.accent : Color.white.opacity(0.12),
                                style: StrokeStyle(lineWidth: 1.5, dash: [6])
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isTargetedForDrop ? DesignTokens.accent.opacity(0.1) : Color.white.opacity(0.02))
                            )

                        VStack(spacing: 8) {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 26))
                                .foregroundColor(isTargetedForDrop ? DesignTokens.accent : DesignTokens.textSecondary)

                            Text("Drop MP4 or MOV videos here")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Text("Automatically looped and displayed on desktop")
                                .font(.system(size: 12))
                                .foregroundColor(DesignTokens.textMuted)
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 32)
                    .onDrop(of: [.movie, .video, .fileURL], isTargeted: $isTargetedForDrop) { providers in
                        handleDrop(providers: providers)
                    }

                    // Grid of Local Wallpapers
                    if localManager.localWallpapers.isEmpty {
                        VStack(spacing: 10) {
                            Text("No custom wallpapers added yet")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DesignTokens.textSecondary)
                            Text("Drag and drop any video or click Import Video above.")
                                .font(.system(size: 12))
                                .foregroundColor(DesignTokens.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)
                    } else {
                        LazyVGrid(columns: columns, spacing: 18) {
                            ForEach(localManager.localWallpapers) { item in
                                WallpaperCardView(
                                    item: item,
                                    isSelected: engine.currentItem?.id == item.id,
                                    onSelect: {
                                        onSelectWallpaper(item)
                                    },
                                    onApply: {
                                        engine.applyWallpaper(item, scope: engine.selectedScope, screenIndex: engine.selectedScreenIndex)
                                    },
                                    onDelete: {
                                        localManager.deleteWallpaper(id: item.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                    }
                } else {
                    // Favorites Mode
                    if favoriteItems.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "heart.slash")
                                .font(.system(size: 36))
                                .foregroundColor(DesignTokens.textMuted)
                            Text("No favorites yet")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(DesignTokens.textSecondary)
                            Text("Click the heart icon on any wallpaper card to save it here.")
                                .font(.system(size: 12))
                                .foregroundColor(DesignTokens.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 18) {
                            ForEach(favoriteItems) { item in
                                WallpaperCardView(
                                    item: item,
                                    isSelected: engine.currentItem?.id == item.id,
                                    onSelect: {
                                        onSelectWallpaper(item)
                                    },
                                    onApply: {
                                        engine.applyWallpaper(item, scope: engine.selectedScope, screenIndex: engine.selectedScreenIndex)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .background(DesignTokens.background)
    }

    private func openFilePicker() {
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
                    _ = await localManager.importVideo(from: url)
                }
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    return
                }

                let ext = url.pathExtension.lowercased()
                if ["mp4", "mov", "m4v"].contains(ext) {
                    Task {
                        _ = await localManager.importVideo(from: url)
                    }
                }
            }
        }
        return true
    }
}
