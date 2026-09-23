import SwiftUI
import AppKit

public struct DetailModalView: View {
    public let item: WallpaperItem
    public let onClose: () -> Void

    @ObservedObject private var engine = WallpaperEngine.shared
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var service = WallpaperService.shared

    @State private var isMuted = true
    @State private var showDisplayPopover = false
    @State private var selectedDisplayScope: String = AppSettings.shared.selectedScope
    @State private var selectedScreenIndex: Int? = nil // nil = All displays
    @State private var selectedWallpaper: WallpaperItem?
    @State private var isAppliedBannerVisible = false

    public init(item: WallpaperItem, onClose: @escaping () -> Void) {
        self.item = item
        self.onClose = onClose
        self._selectedDisplayScope = State(initialValue: AppSettings.shared.selectedScope)
    }

    private var activeItem: WallpaperItem {
        selectedWallpaper ?? item
    }

    private var isCurrentlyActive: Bool {
        engine.currentItem?.id == activeItem.id && engine.isPlaying
    }

    private var similarItems: [WallpaperItem] {
        let stopWords: Set<String> = [
            "and", "the", "in", "of", "a", "to", "for", "with", "4k", "uhd", "hd",
            "live", "wallpaper", "custom", "video", "portrait", "1080p", "fps"
        ]

        let titleWords = activeItem.title
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !stopWords.contains($0) && $0.count > 2 }

        let currentCategory = activeItem.category.lowercased()

        // Score all candidates by title keyword relevance and category
        var scoredItems: [(item: WallpaperItem, score: Int)] = []

        for candidate in service.allWallpapers {
            guard candidate.id != activeItem.id else { continue }

            let candidateTitle = candidate.title.lowercased()
            var score = 0

            // Match title keywords (high weight)
            for word in titleWords {
                if candidateTitle.contains(word) {
                    score += 8
                }
            }

            // Same category (medium weight)
            if candidate.category.lowercased() == currentCategory {
                score += 3
            }

            if score > 0 {
                scoredItems.append((candidate, score))
            }
        }

        // Sort by relevance score, then by download popularity
        scoredItems.sort {
            if $0.score != $1.score {
                return $0.score > $1.score
            }
            return $0.item.downloads > $1.item.downloads
        }

        var result = scoredItems.prefix(9).map { $0.item }

        // Fallback: If fewer than 6, fill with top wallpapers from the same category
        if result.count < 6 {
            let seenIds = Set(result.map { $0.id } + [activeItem.id])
            let categoryFallbacks = service.wallpapers(for: activeItem.category)
                .filter { !seenIds.contains($0.id) }
                .sorted { $0.downloads > $1.downloads }

            result.append(contentsOf: categoryFallbacks.prefix(6 - result.count))
        }

        return result
    }

    public var body: some View {
        ZStack {
            DesignTokens.background
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 36) {
                    // Main Preview Canvas with Floating Bottom Island
                    ZStack(alignment: .bottom) {
                        // Video Player with dynamic item binding
                        VideoPlayerView(url: activeItem.videoUrl, isMuted: isMuted, shouldLoop: true)
                            .id(activeItem.id)
                            .frame(height: 520)
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                            .clipped()

                        // Top Controls (Back, Mute)
                        VStack {
                            HStack {
                                Button(action: onClose) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Button(action: { isMuted.toggle() }) {
                                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(24)
                            Spacer()
                        }

                        // Floating Bottom Control Island & Popover Overlay
                        VStack(spacing: 0) {
                            if showDisplayPopover {
                                HStack {
                                    Spacer()
                                    displaySelectionPopover
                                        .padding(.trailing, 28)
                                }
                                .transition(.scale(scale: 0.95, anchor: .bottomTrailing).combined(with: .opacity))
                            }

                            floatingControlBar
                                .padding(.top, 8)
                        }
                        .padding(.bottom, 24)
                    }

                    // "Similar Wallpapers" Section
                    if !similarItems.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Similar Wallpapers")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(DesignTokens.textPrimary)

                                Text("Picked to complement this one.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(DesignTokens.textSecondary)
                            }
                            .padding(.horizontal, 32)

                            let columns = [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ]

                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(similarItems) { similar in
                                    WallpaperCardView(
                                        item: similar,
                                        isSelected: activeItem.id == similar.id,
                                        onSelect: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedWallpaper = similar
                                                showDisplayPopover = false
                                            }
                                        },
                                        onApply: {
                                            applyCurrent(similar)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }

    // MARK: - Floating Control Bar
    private var floatingControlBar: some View {
        HStack(spacing: 16) {
            // Back chevron
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DesignTokens.textSecondary)
            }
            .buttonStyle(.plain)

            // Title & Info
            VStack(alignment: .leading, spacing: 2) {
                Text(activeItem.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "display")
                            .font(.system(size: 10))
                        Text(activeItem.resolution)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(DesignTokens.textMuted)

                    HStack(spacing: 3) {
                        Image(systemName: "doc")
                            .font(.system(size: 10))
                        Text("15MB")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(DesignTokens.textMuted)

                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("\(activeItem.durationSeconds)s")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(DesignTokens.textMuted)
                }
            }

            Spacer()

            // Share button
            Button(action: {
                let picker = NSSharingServicePicker(items: [activeItem.videoUrl])
                picker.show(relativeTo: .zero, of: NSApp.keyWindow?.contentView ?? NSView(), preferredEdge: .minY)
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)

            // Display scopes toggle button (Opens the Popover)
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    showDisplayPopover.toggle()
                }
            }) {
                Image(systemName: "slider.horizontal.2.square")
                    .font(.system(size: 13))
                    .foregroundColor(showDisplayPopover ? DesignTokens.accent : .white)
            }
            .buttonStyle(.plain)
            .help("Choose Display & Scope")

            // Heart Favorite
            Button(action: {
                settings.toggleFavorite(id: activeItem.id)
            }) {
                Image(systemName: settings.isFavorite(id: activeItem.id) ? "heart.fill" : "heart")
                    .font(.system(size: 13))
                    .foregroundColor(settings.isFavorite(id: activeItem.id) ? .red : .white)
            }
            .buttonStyle(.plain)

            // Delete button for local videos
            if activeItem.isLocal {
                Button(action: {
                    LocalWallpaperManager.shared.deleteWallpaper(id: activeItem.id)
                    onClose()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 11))
                        Text("Delete")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.85))
                    .foregroundColor(.white)
                    .cornerRadius(18)
                }
                .buttonStyle(.plain)
                .help("Delete from My Videos")
            }

            // "Set Wallpaper" White Rounded Button
            Button(action: {
                applyCurrent(activeItem)
            }) {
                HStack(spacing: 6) {
                    if isCurrentlyActive {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .heavy))
                    }
                    Text(isCurrentlyActive ? "Active" : "Set Wallpaper")
                        .font(.system(size: 13, weight: .bold))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.75))
        .background(.ultraThinMaterial)
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 16, x: 0, y: 8)
        .frame(maxWidth: 680)
    }

    // MARK: - Display Selection Popover
    private var displaySelectionPopover: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                // 1. Top Capsule Segmented Control: [ Both | Desktop | Lockscreen ]
                HStack(spacing: 2) {
                    ForEach(["Both", "Desktop", "Lockscreen"], id: \.self) { scope in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                selectedDisplayScope = scope
                                AppSettings.shared.selectedScope = scope
                            }
                        }) {
                            Text(scope)
                                .font(.system(size: 11, weight: selectedDisplayScope == scope ? .bold : .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    selectedDisplayScope == scope
                                        ? Color.white
                                        : Color.clear
                                )
                                .foregroundColor(selectedDisplayScope == scope ? .black : DesignTokens.textSecondary)
                                .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Color.black.opacity(0.45))
                .cornerRadius(16)

                // 2. Second Row: Choose display & All button
                HStack {
                    Text("Choose display")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignTokens.textMuted)

                    Spacer()

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            selectedScreenIndex = nil // Select All
                        }
                    }) {
                        Text("All")
                            .font(.system(size: 11, weight: selectedScreenIndex == nil ? .bold : .medium))
                            .foregroundColor(selectedScreenIndex == nil ? .white : DesignTokens.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                selectedScreenIndex == nil
                                    ? Color.white.opacity(0.2)
                                    : Color.white.opacity(0.06)
                            )
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)

                // 3. Display Cards
                let screens = NSScreen.screens
                ForEach(Array(screens.enumerated()), id: \.offset) { index, screen in
                    let isSelected = selectedScreenIndex == index
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            selectedScreenIndex = index
                        }
                        applyCurrent(activeItem)
                    }) {
                        VStack(spacing: 5) {
                            Image(systemName: "display")
                                .font(.system(size: 22))
                                .foregroundColor(isSelected ? .white : DesignTokens.textSecondary)

                            Text(screen.localizedName.isEmpty ? "Built-in Retina Display" : screen.localizedName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(screen == NSScreen.main ? "Main Display" : "Display \(index + 1)")
                                .font(.system(size: 10))
                                .foregroundColor(DesignTokens.textMuted)

                            if let activeOnScreen = engine.item(for: screen) {
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 5, height: 5)
                                    Text(activeOnScreen.title)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(Color.cyan.opacity(0.9))
                                        .lineLimit(1)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ? Color.white.opacity(0.6) : Color.white.opacity(0.08),
                                    lineWidth: isSelected ? 1.5 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                // 4. Action Button inside Popover
                Button(action: {
                    applyCurrent(activeItem)
                }) {
                    Text(selectedScreenIndex == nil ? "Apply to All Displays" : "Apply to Display \(selectedScreenIndex! + 1)")
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .frame(width: 250)
            .background(Color(red: 0.12, green: 0.14, blue: 0.17).opacity(0.96))
            .background(.ultraThinMaterial)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.6), radius: 24, x: 0, y: 12)

            // Little speech-bubble indicator arrow pointing down to Set Wallpaper
            TriangleIndicator()
                .fill(Color(red: 0.12, green: 0.14, blue: 0.17).opacity(0.96))
                .frame(width: 14, height: 7)
                .padding(.trailing, 40)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func applyCurrent(_ item: WallpaperItem) {
        engine.applyWallpaper(item, scope: selectedDisplayScope, screenIndex: selectedScreenIndex)
        withAnimation(.spring()) {
            showDisplayPopover = false
        }
    }
}

// Speech-bubble downward arrow shape
struct TriangleIndicator: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
