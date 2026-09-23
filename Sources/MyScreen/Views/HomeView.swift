import SwiftUI

public struct HomeView: View {
    @ObservedObject private var service = WallpaperService.shared
    @ObservedObject private var engine = WallpaperEngine.shared
    @State private var heroIndex = 0

    public let onSelectWallpaper: (WallpaperItem) -> Void
    public let onSelectCategory: (String) -> Void

    public init(
        onSelectWallpaper: @escaping (WallpaperItem) -> Void,
        onSelectCategory: @escaping (String) -> Void
    ) {
        self.onSelectWallpaper = onSelectWallpaper
        self.onSelectCategory = onSelectCategory
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 36) {
                // 1. Hero Spotlight Banner
                if !service.curatedWallpapers.isEmpty {
                    HeroBannerView(
                        items: Array(service.curatedWallpapers.prefix(8)),
                        selectedIndex: $heroIndex,
                        onApply: { item in
                            engine.applyWallpaper(item, scope: engine.selectedScope, screenIndex: engine.selectedScreenIndex)
                        },
                        onPreview: { item in
                            onSelectWallpaper(item)
                        }
                    )
                }

                // 2. Curated Picks
                WallpaperCarouselSection(
                    title: "MyScreen's Pick",
                    subtitle: "Curated selection of the finest wallpapers",
                    items: service.wallpapers(for: "trending"),
                    onSelect: onSelectWallpaper,
                    onApply: { item in engine.applyWallpaper(item, scope: engine.selectedScope, screenIndex: engine.selectedScreenIndex) }
                )

                // 3. Latest Collection
                WallpaperCarouselSection(
                    title: "Latest Collection",
                    subtitle: "Most recent community wallpapers",
                    items: Array(service.curatedWallpapers.suffix(30)),
                    onSelect: onSelectWallpaper,
                    onApply: { item in engine.applyWallpaper(item, scope: engine.selectedScope, screenIndex: engine.selectedScreenIndex) }
                )

                // 4. Categories Visual Grid
                categoryVisualGrid

                // 5. Video Games Section
                WallpaperCarouselSection(
                    title: "Video Games",
                    subtitle: "Epic gaming moments, Elden Ring, Souls, and heroic legends",
                    items: service.wallpapers(for: "gaming"),
                    onSelect: onSelectWallpaper,
                    onApply: { item in engine.applyWallpaper(item, scope: engine.selectedScope, screenIndex: engine.selectedScreenIndex) }
                )

                // 6. City & Urban Architecture
                WallpaperCarouselSection(
                    title: "City & Urban",
                    subtitle: "Neon metropolises, night skylines, and rainy streets",
                    items: service.wallpapers(for: "city"),
                    onSelect: onSelectWallpaper,
                    onApply: { item in engine.applyWallpaper(item, scope: engine.selectedScope, screenIndex: engine.selectedScreenIndex) }
                )

                // 7. Nature & Scenery
                WallpaperCarouselSection(
                    title: "Nature & Scenery",
                    subtitle: "Peaceful landscapes, lakes, and forests",
                    items: service.wallpapers(for: "nature"),
                    onSelect: onSelectWallpaper,
                    onApply: { item in engine.applyWallpaper(item, scope: engine.selectedScope, screenIndex: engine.selectedScreenIndex) }
                )

                // 8. Anime Worlds
                WallpaperCarouselSection(
                    title: "Anime",
                    subtitle: "Iconic anime aesthetics and cinematic scenes",
                    items: service.wallpapers(for: "anime"),
                    onSelect: onSelectWallpaper,
                    onApply: { item in engine.applyWallpaper(item, scope: engine.selectedScope, screenIndex: engine.selectedScreenIndex) }
                )

                // 9. Space & Sci-Fi
                WallpaperCarouselSection(
                    title: "Space & Sci-Fi",
                    subtitle: "Deep cosmos, wormholes, and interstellar voyages",
                    items: service.wallpapers(for: "scifi"),
                    onSelect: onSelectWallpaper,
                    onApply: { item in engine.applyWallpaper(item, scope: engine.selectedScope, screenIndex: engine.selectedScreenIndex) }
                )

                // 10. Cars & Speed
                WallpaperCarouselSection(
                    title: "Cars & Speed",
                    subtitle: "Track concepts, supercars, and automotive beauty",
                    items: service.wallpapers(for: "cars"),
                    onSelect: onSelectWallpaper,
                    onApply: { item in engine.applyWallpaper(item, scope: engine.selectedScope, screenIndex: engine.selectedScreenIndex) }
                )
            }
            .padding(.bottom, 60)
        }
        .background(DesignTokens.background)
    }

    private var categoryVisualGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Categories")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)

                Text("Browse wallpapers by category")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(DesignTokens.textSecondary)
            }
            .padding(.horizontal, 32)

            let catItems: [(id: String, name: String, icon: String)] = [
                ("nature", "Nature", "leaf.fill"),
                ("scifi", "Space", "moon.stars.fill"),
                ("anime", "Anime", "sparkles.tv.fill"),
                ("cars", "Cars", "car.fill"),
                ("city", "City", "building.2.fill"),
                ("gaming", "Video Games", "gamecontroller.fill")
            ]

            let columns = [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(catItems, id: \.id) { cat in
                    let sampleThumb = service.wallpapers(for: cat.id).first?.thumbnailUrl
                    CategoryCardView(
                        title: cat.name,
                        sampleImageURL: sampleThumb,
                        iconName: cat.icon
                    ) {
                        onSelectCategory(cat.id)
                    }
                }
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Carousel Section with Interactive Navigation & Alignment
private struct WallpaperCarouselSection: View {
    let title: String
    let subtitle: String
    let items: [WallpaperItem]
    let onSelect: (WallpaperItem) -> Void
    let onApply: (WallpaperItem) -> Void

    @ObservedObject private var engine = WallpaperEngine.shared
    @State private var currentIndex = 0

    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 14) {
                // Header with Subtitle and Functional Navigation Chevrons
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(DesignTokens.textPrimary)

                        Text(subtitle)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(DesignTokens.textSecondary)
                    }

                    Spacer()

                    // Functional Interactive Chevron Buttons
                    HStack(spacing: 8) {
                        Button(action: {
                            if currentIndex > 0 {
                                currentIndex = max(0, currentIndex - 2)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    proxy.scrollTo(currentIndex, anchor: .leading)
                                }
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(currentIndex > 0 ? .white : DesignTokens.textMuted)
                                .padding(6)
                                .background(Circle().fill(Color.white.opacity(currentIndex > 0 ? 0.15 : 0.05)))
                        }
                        .buttonStyle(.plain)
                        .disabled(currentIndex == 0)

                        Button(action: {
                            let maxIndex = min(items.count - 1, 19)
                            if currentIndex < maxIndex {
                                currentIndex = min(maxIndex, currentIndex + 2)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    proxy.scrollTo(currentIndex, anchor: .leading)
                                }
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Circle().fill(Color.white.opacity(0.15)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 32)

                // Horizontal Carousel (Padded on outer ScrollView so cards never bleed into window margins)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(Array(items.prefix(20).enumerated()), id: \.element.id) { index, item in
                            WallpaperCardView(
                                item: item,
                                isSelected: engine.currentItem?.id == item.id,
                                onSelect: {
                                    onSelect(item)
                                },
                                onApply: {
                                    onApply(item)
                                }
                            )
                            .frame(width: 260)
                            .id(index)
                        }
                    }
                    .padding(.horizontal, 2)
                    .snapLayout()
                }
                .padding(.horizontal, 32)
                .snapCarousel()
            }
        }
    }
}

// MARK: - Carousel Snap Alignment Helpers
private extension View {
    @ViewBuilder
    func snapCarousel() -> some View {
        if #available(macOS 14.0, *) {
            self.scrollTargetBehavior(.viewAligned)
        } else {
            self
        }
    }

    @ViewBuilder
    func snapLayout() -> some View {
        if #available(macOS 14.0, *) {
            self.scrollTargetLayout()
        } else {
            self
        }
    }
}
