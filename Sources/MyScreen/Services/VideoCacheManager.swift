import Foundation

/// Manages caching of wallpapers safely within the application's support directory.
public final class VideoCacheManager {
    public static let shared = VideoCacheManager()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.cacheDirectory = appSupport.appendingPathComponent("MyScreen/Cache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Safely sanitizes a filename to prevent directory traversal
    private func sanitize(filename: String) -> String {
        let safeName = filename.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "..", with: "")
        return safeName.isEmpty ? UUID().uuidString : safeName
    }

    public func localCachedURL(for remoteURL: URL) -> URL? {
        let filename = sanitize(filename: remoteURL.lastPathComponent)
        let localURL = cacheDirectory.appendingPathComponent(filename)
        if fileManager.fileExists(atPath: localURL.path) {
            return localURL
        }
        return nil
    }

    /// Checks if a 4K Master Video is cached locally for this wallpaper ID
    public func cachedMasterURL(for id: String) -> URL? {
        let cleanId = sanitize(filename: id)
        
        // 1. Check MyScreen's own master cache
        let localURL = cacheDirectory.appendingPathComponent("\(cleanId)_master.mp4")
        if fileManager.fileExists(atPath: localURL.path) {
            return localURL
        }

        // 2. Secondary local cache fallback
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let fallbackMaster = homeDir.appendingPathComponent("Library/Caches/Wallspace/Wallpapers/\(cleanId).mp4")
        if fileManager.fileExists(atPath: fallbackMaster.path) {
            return fallbackMaster
        }

        return nil
    }

    /// Destination URL on SSD where the 4K Master Video should be stored
    public func destinationMasterURL(for id: String) -> URL {
        let cleanId = sanitize(filename: id)
        return cacheDirectory.appendingPathComponent("\(cleanId)_master.mp4")
    }

    public func cacheVideo(from sourceURL: URL, filename: String) throws -> URL {
        let safeFilename = sanitize(filename: filename)
        let destinationURL = cacheDirectory.appendingPathComponent(safeFilename)
        if fileManager.fileExists(atPath: destinationURL.path) {
            return destinationURL
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }

    public func clearCache() {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        for file in files {
            try? fileManager.removeItem(at: file)
        }
    }

    public func cacheSizeString() -> String {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return "0 MB"
        }
        var totalBytes: Int64 = 0
        for file in files {
            if let resources = try? file.resourceValues(forKeys: [.fileSizeKey]), let size = resources.fileSize {
                totalBytes += Int64(size)
            }
        }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }
}
