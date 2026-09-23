import Foundation

public struct WallpaperCategory: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let icon: String

    public init(id: String, name: String, icon: String) {
        self.id = id
        self.name = name
        self.icon = icon
    }

    public static let allCategories: [WallpaperCategory] = [
        WallpaperCategory(id: "all", name: "All Wallpapers", icon: "sparkles"),
        WallpaperCategory(id: "trending", name: "Trending", icon: "flame.fill"),
        WallpaperCategory(id: "nature", name: "Nature & Scenery", icon: "leaf.fill"),
        WallpaperCategory(id: "scifi", name: "Space & Sci-Fi", icon: "moon.stars.fill"),
        WallpaperCategory(id: "anime", name: "Anime", icon: "sparkles.tv.fill"),
        WallpaperCategory(id: "gaming", name: "Video Games", icon: "gamecontroller.fill"),
        WallpaperCategory(id: "cars", name: "Cars & Vehicles", icon: "car.fill"),
        WallpaperCategory(id: "city", name: "City & Urban", icon: "building.2.fill"),
        WallpaperCategory(id: "lofi", name: "Lo-Fi & Cozy", icon: "cup.and.saucer.fill"),
        WallpaperCategory(id: "local", name: "My Videos", icon: "folder.fill")
    ]
}
