import Foundation
import Combine

public final class WallpaperService: ObservableObject {
    public static let shared = WallpaperService()

    @Published public private(set) var allWallpapers: [WallpaperItem] = []
    @Published public private(set) var curatedWallpapers: [WallpaperItem] = []
    @Published public private(set) var featuredWallpaper: WallpaperItem?

    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadCuratedCatalog()
        observeLocalWallpapers()
    }

    private func observeLocalWallpapers() {
        LocalWallpaperManager.shared.$localWallpapers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] locals in
                self?.mergeLocalWallpapers(locals)
            }
            .store(in: &cancellables)
    }

    private func mergeLocalWallpapers(_ locals: [WallpaperItem]) {
        // Resolve any local items that have purely numeric titles
        let sanitizedLocals = locals.map { item -> WallpaperItem in
            var copy = item
            if copy.title.allSatisfy({ $0.isNumber }) {
                if let match = curatedWallpapers.first(where: { $0.id == copy.title || $0.videoUrl.absoluteString.contains(copy.title) }) {
                    copy.title = match.title
                } else {
                    copy.title = "Custom Live Wallpaper"
                }
            }
            return copy
        }

        self.allWallpapers = sanitizedLocals + curatedWallpapers
    }

    private func loadCuratedCatalog() {
        let catalogURL = Bundle.main.url(forResource: "catalog", withExtension: "json")
            ?? Bundle.main.resourceURL?.appendingPathComponent("catalog.json")

        if let url = catalogURL,
           let data = try? Data(contentsOf: url),
           let items = try? JSONDecoder().decode([WallpaperItem].self, from: data),
           !items.isEmpty {
            self.curatedWallpapers = items
            self.allWallpapers = items
            self.featuredWallpaper = items.first
            print("[WallpaperService] Successfully loaded \(items.count) wallpapers from bundle catalog.json")
            return
        }

        // Fallback starter item
        let fallback = [
            WallpaperItem(
                id: "886457657200565",
                title: "Vibrant Cosmic Galaxy",
                creator: "StellarStudios",
                category: "scifi",
                videoUrl: URL(string: "https://s4.wallspace.app/wallpaper/886457657200565/previewhd.mp4")!,
                thumbnailUrl: URL(string: "https://s4.wallspace.app/wallpaper/886457657200565/poster.webp"),
                durationSeconds: 14,
                resolution: "4K UHD",
                downloads: 25440,
                likes: 3420,
                tags: ["Cosmic", "Galaxy", "Stars", "Space"]
            )
        ]
        self.curatedWallpapers = fallback
        self.allWallpapers = fallback
        self.featuredWallpaper = fallback.first
    }

    public func wallpapers(for category: String) -> [WallpaperItem] {
        let key = category.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        switch key {
        case "all":
            return allWallpapers
        case "trending":
            return allWallpapers.sorted { $0.downloads > $1.downloads }
        case "local":
            return allWallpapers.filter { $0.isLocal }
        case "city", "urban":
            return allWallpapers.filter { item in
                item.category.lowercased() == "urban" ||
                item.title.lowercased().contains("city") ||
                item.title.lowercased().contains("urban") ||
                item.tags.contains(where: { $0.lowercased().contains("city") || $0.lowercased().contains("urban") })
            }
        case "gaming", "game", "videogames":
            let gameKeywords = ["game", "gaming", "elden", "dark souls", "spiderman", "pokemon", "zelda", "mario", "cyberpunk", "witcher", "sekiro", "halo", "gta"]
            return allWallpapers.filter { item in
                gameKeywords.contains { kw in
                    item.title.lowercased().contains(kw) ||
                    item.tags.contains(where: { $0.lowercased().contains(kw) })
                }
            }
        case "scifi", "space":
            return allWallpapers.filter { item in
                item.category.lowercased() == "scifi" ||
                item.tags.contains(where: { $0.lowercased().contains("space") || $0.lowercased().contains("galaxy") || $0.lowercased().contains("sci-fi") })
            }
        case "nature":
            return allWallpapers.filter { item in
                item.category.lowercased() == "nature" ||
                item.tags.contains(where: { $0.lowercased().contains("nature") || $0.lowercased().contains("scenery") || $0.lowercased().contains("mountain") })
            }
        case "anime":
            return allWallpapers.filter { item in
                item.category.lowercased() == "anime"
            }
        case "cars":
            return allWallpapers.filter { item in
                item.category.lowercased() == "cars" ||
                item.tags.contains(where: { $0.lowercased().contains("car") || $0.lowercased().contains("vehicle") })
            }
        case "lofi":
            return allWallpapers.filter { item in
                item.category.lowercased() == "lofi" ||
                item.tags.contains(where: { $0.lowercased().contains("cozy") || $0.lowercased().contains("lo-fi") })
            }
        default:
            let matches = allWallpapers.filter { $0.category.lowercased() == key }
            return matches.isEmpty ? allWallpapers : matches
        }
    }

    public func search(query: String, category: String = "all") -> [WallpaperItem] {
        let baseList = wallpapers(for: category)
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return baseList }

        return baseList.filter { item in
            item.title.lowercased().contains(trimmed) ||
            item.creator.lowercased().contains(trimmed) ||
            item.tags.contains(where: { $0.lowercased().contains(trimmed) })
        }
    }
}
