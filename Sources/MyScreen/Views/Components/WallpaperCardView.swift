import SwiftUI
import AppKit

public struct WallpaperCardView: View {
    public let item: WallpaperItem
    public let isSelected: Bool
    public let onSelect: () -> Void
    public let onApply: () -> Void
    public let onDelete: (() -> Void)?

    @ObservedObject private var settings = AppSettings.shared
    @State private var isHovered = false

    public init(
        item: WallpaperItem,
        isSelected: Bool = false,
        onSelect: @escaping () -> Void,
        onApply: @escaping () -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.item = item
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onApply = onApply
        self.onDelete = onDelete
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // Clickable Preview Area (Thumbnail + Gradient + Info)
                Button(action: onSelect) {
                    ZStack(alignment: .bottomLeading) {
                        // Main Thumbnail
                        RemoteImageView(url: item.thumbnailUrl)
                            .frame(height: 145)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .background(Color(red: 0.12, green: 0.13, blue: 0.16))

                        // Gradient for text readability
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.7)],
                            startPoint: .center,
                            endPoint: .bottom
                        )

                        // Bottom Title & Creator
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            HStack(spacing: 4) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 9))
                                Text("\(item.durationSeconds)s")
                                    .font(.system(size: 10, weight: .medium))

                                Spacer()
                            }
                            .foregroundColor(Color(white: 0.75))
                        }
                        .padding(10)

                        // Center "Apply" Button on Hover (doesn't cover top badges)
                        if isHovered {
                            Color.black.opacity(0.3)
                                .transition(.opacity)

                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: onApply) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 10))
                                            Text("Apply")
                                                .font(.system(size: 12, weight: .bold))
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(Color.white)
                                        .foregroundColor(.black)
                                        .cornerRadius(20)
                                        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                                    }
                                    .buttonStyle(.plain)
                                    Spacer()
                                }
                                Spacer()
                            }
                            .padding(.top, 36) // Keep top area completely clear for buttons
                        }
                    }
                    .frame(height: 145)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Top Header Badges & Action Buttons (Rendered at top of ZStack with highest zIndex)
                HStack(spacing: 6) {
                    if item.resolution.contains("4K") || item.resolution.contains("3840") {
                        Text("4K")
                            .font(.system(size: 9, weight: .heavy))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.65))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }

                    Spacer()

                    // Direct Delete Button for Local Wallpapers
                    if item.isLocal && onDelete != nil {
                        Button(action: {
                            onDelete?()
                        }) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(Color.red))
                                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .help("Delete from My Videos")
                    }

                    // Favorite Button
                    Button(action: {
                        settings.toggleFavorite(id: item.id)
                    }) {
                        Image(systemName: settings.isFavorite(id: item.id) ? "heart.fill" : "heart")
                            .font(.system(size: 12))
                            .foregroundColor(settings.isFavorite(id: item.id) ? .red : .white)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .help(settings.isFavorite(id: item.id) ? "Favorited" : "Favorite")
                }
                .padding(8)
                .zIndex(20) // Always above hover overlay and thumbnail
            }
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color.white : (isHovered ? Color.white.opacity(0.4) : Color.white.opacity(0.08)),
                        lineWidth: isSelected ? 2.5 : 1
                    )
            )
            .shadow(color: isSelected ? Color.white.opacity(0.2) : Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.16)) {
                isHovered = hovering
            }
        }
        // Right-Click Context Menu (Preserved per user request)
        .contextMenu {
            Button {
                onApply()
            } label: {
                Label("Set as Live Wallpaper", systemImage: "play.fill")
            }

            Button {
                settings.toggleFavorite(id: item.id)
            } label: {
                Label(settings.isFavorite(id: item.id) ? "Remove from Favorites" : "Add to Favorites",
                      systemImage: settings.isFavorite(id: item.id) ? "heart.slash" : "heart")
            }

            if let path = item.localPath {
                Button {
                    NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                } label: {
                    Label("Reveal in Finder", systemImage: "folder")
                }
            }

            if item.isLocal && onDelete != nil {
                Divider()
                Button(role: .destructive) {
                    onDelete?()
                } label: {
                    Label("Delete from My Videos", systemImage: "trash")
                }
            }
        }
    }
}
