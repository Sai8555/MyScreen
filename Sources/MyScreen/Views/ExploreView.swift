import SwiftUI

public struct ExploreView: View {
    @ObservedObject private var service = WallpaperService.shared
    @ObservedObject private var engine = WallpaperEngine.shared

    @State private var searchText = ""
    @Binding public var selectedCategory: String
    public let onSelectWallpaper: (WallpaperItem) -> Void

    public init(
        selectedCategory: Binding<String>,
        onSelectWallpaper: @escaping (WallpaperItem) -> Void
    ) {
        self._selectedCategory = selectedCategory
        self.onSelectWallpaper = onSelectWallpaper
    }

    private var filteredItems: [WallpaperItem] {
        service.search(query: searchText, category: selectedCategory)
    }

    private let columns = [
        GridItem(.adaptive(minimum: 240, maximum: 320), spacing: 18)
    ]

    public var body: some View {
        VStack(spacing: 24) {
            // Search Input & Category Pills
            VStack(spacing: 16) {
                // Search Input Box
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DesignTokens.textMuted)

                    TextField("Search by title, artist, or tags...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundColor(.white)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(DesignTokens.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(DesignTokens.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 32)
                .padding(.top, 24)

                // Category Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(WallpaperCategory.allCategories) { cat in
                            Button(action: {
                                selectedCategory = cat.id
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 11))
                                    Text(cat.name)
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    selectedCategory == cat.id
                                        ? Color.white
                                        : Color.white.opacity(0.07)
                                )
                                .foregroundColor(selectedCategory == cat.id ? .black : .white)
                                .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 32)
                }
            }

            // Results Grid
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(DesignTokens.textMuted)
                    Text("No wallpapers found")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignTokens.textSecondary)
                    Text("Try searching with different keywords or selecting another category.")
                        .font(.system(size: 12))
                        .foregroundColor(DesignTokens.textMuted)
                    Spacer()
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(filteredItems) { item in
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
        .background(DesignTokens.background)
    }
}
