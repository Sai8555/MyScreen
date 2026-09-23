import Foundation

public struct WallpaperItem: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public var title: String
    public var creator: String
    public var category: String
    public var videoUrl: URL
    public var thumbnailUrl: URL?
    public var durationSeconds: Int
    public var resolution: String
    public var downloads: Int
    public var likes: Int
    public var isLocal: Bool
    public var tags: [String]
    public var localPath: String?

    public init(
        id: String = UUID().uuidString,
        title: String,
        creator: String = "MyScreen Community",
        category: String,
        videoUrl: URL,
        thumbnailUrl: URL? = nil,
        durationSeconds: Int = 15,
        resolution: String = "4K UHD",
        downloads: Int = 1250,
        likes: Int = 340,
        isLocal: Bool = false,
        tags: [String] = [],
        localPath: String? = nil
    ) {
        self.id = id
        self.title = title
        self.creator = creator
        self.category = category
        self.videoUrl = videoUrl
        self.thumbnailUrl = thumbnailUrl
        self.durationSeconds = durationSeconds
        self.resolution = resolution
        self.downloads = downloads
        self.likes = likes
        self.isLocal = isLocal
        self.tags = tags
        self.localPath = localPath
    }

    /// Full-resolution 4K Ultra HD master video URL (25+ Mbps)
    public var masterVideoUrl: URL {
        if isLocal { return videoUrl }
        let str = videoUrl.absoluteString
        if str.contains("previewhd.mp4") {
            return URL(string: str.replacingOccurrences(of: "previewhd.mp4", with: "master.mp4")) ?? videoUrl
        } else if str.contains("preview.mp4") {
            return URL(string: str.replacingOccurrences(of: "preview.mp4", with: "master.mp4")) ?? videoUrl
        }
        return videoUrl
    }
}
