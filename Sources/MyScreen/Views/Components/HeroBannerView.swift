import SwiftUI

public struct HeroBannerView: View {
    public let items: [WallpaperItem]
    @Binding public var selectedIndex: Int
    public let onApply: (WallpaperItem) -> Void
    public let onPreview: (WallpaperItem) -> Void

    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var engine = WallpaperEngine.shared

    private var currentItem: WallpaperItem? {
        guard !items.isEmpty, selectedIndex >= 0 && selectedIndex < items.count else {
            return items.first
        }
        return items[selectedIndex]
    }

    public init(
        items: [WallpaperItem],
        selectedIndex: Binding<Int>,
        onApply: @escaping (WallpaperItem) -> Void,
        onPreview: @escaping (WallpaperItem) -> Void
    ) {
        self.items = items
        self._selectedIndex = selectedIndex
        self.onApply = onApply
        self.onPreview = onPreview
    }

    public var body: some View {
        if let item = currentItem {
            ZStack(alignment: .bottomLeading) {
                // Background Video / Image
                ZStack {
                    RemoteImageView(url: item.thumbnailUrl)
                        .id(item.id)
                        .frame(height: 480)
                        .frame(maxWidth: .infinity)
                        .clipped()

                    VideoPlayerView(url: item.videoUrl, isMuted: true, shouldLoop: true)
                        .id(item.id)
                        .frame(height: 480)
                        .frame(maxWidth: .infinity)
                        .clipped()
                }

                // Cinematic Multi-Stop Gradients
                LinearGradient(
                    stops: [
                        .init(color: Color.black.opacity(0.4), location: 0.0),
                        .init(color: Color.clear, location: 0.25),
                        .init(color: Color.black.opacity(0.3), location: 0.6),
                        .init(color: DesignTokens.background, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 480)

                LinearGradient(
                    colors: [Color.black.opacity(0.65), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 480)

                // Foreground Content & Thumbnail Selector
                VStack(alignment: .leading, spacing: 20) {
                    Spacer()

                    // Text & Action Buttons
                    VStack(alignment: .leading, spacing: 10) {
                        Text("FEATURED")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(Color(white: 0.8))

                        Text(item.title)
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.7), radius: 6, x: 0, y: 2)

                        // Metadata line (Category • Resolution • Duration)
                        HStack(spacing: 12) {
                            Text(item.category.capitalized)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(white: 0.75))

                            Text(item.resolution)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(white: 0.75))

                            Text("\(item.durationSeconds)s")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(white: 0.75))
                        }

                        // Buttons
                        HStack(spacing: 12) {
                            Button(action: { onPreview(item) }) {
                                HStack(spacing: 6) {
                                    Text("View Wallpaper")
                                        .font(.system(size: 13, weight: .semibold))
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .background(Color.white.opacity(0.2))
                                .background(.ultraThinMaterial)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                settings.toggleFavorite(id: item.id)
                            }) {
                                Image(systemName: settings.isFavorite(id: item.id) ? "heart.fill" : "heart")
                                    .font(.system(size: 14))
                                    .foregroundColor(settings.isFavorite(id: item.id) ? .red : .white)
                                    .padding(9)
                                    .background(Color.white.opacity(0.15))
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                onApply(item)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: engine.currentItem?.id == item.id ? "checkmark.circle.fill" : "play.fill")
                                        .font(.system(size: 11))
                                    Text(engine.currentItem?.id == item.id ? "Active" : "Apply")
                                        .font(.system(size: 13, weight: .bold))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 32)

                    // Mini Thumbnail Selector Bar
                    if items.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(Array(items.prefix(8).enumerated()), id: \.element.id) { index, thumbItem in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            selectedIndex = index
                                        }
                                    }) {
                                        ZStack {
                                            RemoteImageView(url: thumbItem.thumbnailUrl)
                                                .frame(width: 120, height: 68)
                                                .clipped()
                                                .cornerRadius(12)
                                        }
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    selectedIndex == index ? Color.white : Color.white.opacity(0.15),
                                                    lineWidth: selectedIndex == index ? 2.5 : 1
                                                )
                                        )
                                        .shadow(color: selectedIndex == index ? Color.white.opacity(0.3) : Color.clear, radius: 6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .frame(height: 480)
            .clipped()
        }
    }
}
