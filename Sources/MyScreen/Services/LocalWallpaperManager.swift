import Foundation
import AVFoundation
import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers

/// Manages local user imported wallpapers securely with sandboxing & path validation.
public final class LocalWallpaperManager: ObservableObject {
    public static let shared = LocalWallpaperManager()

    @Published public private(set) var localWallpapers: [WallpaperItem] = []

    private let fileManager = FileManager.default
    private let storageURL: URL
    private let thumbnailsDir: URL
    private let allowedExtensions: Set<String> = ["mp4", "mov", "m4v"]
    private let maxFileSizeBytes: Int64 = 5 * 1024 * 1024 * 1024 // 5 GB limit

    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let baseDir = appSupport.appendingPathComponent("MyScreen", isDirectory: true)
        self.storageURL = baseDir.appendingPathComponent("local_wallpapers.json")
        self.thumbnailsDir = baseDir.appendingPathComponent("Thumbnails", isDirectory: true)

        do {
            try fileManager.createDirectory(at: thumbnailsDir, withIntermediateDirectories: true)
        } catch {
            print("[LocalWallpaperManager] Security: Could not initialize thumbnails directory: \(error)")
        }
        loadSavedWallpapers()
    }

    private func loadSavedWallpapers() {
        guard fileManager.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let items = try JSONDecoder().decode([WallpaperItem].self, from: data)
            // Filter to only items where the local file still safely exists
            self.localWallpapers = items.filter { item in
                guard let path = item.localPath else { return false }
                return fileManager.fileExists(atPath: path)
            }
        } catch {
            print("[LocalWallpaperManager] Security: Failed to load or decode saved wallpapers: \(error)")
        }
    }

    private func saveWallpapers() {
        do {
            let data = try JSONEncoder().encode(localWallpapers)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("[LocalWallpaperManager] Security: Failed to save wallpapers atomically: \(error)")
        }
    }

    /// Securely imports a video file with path traversal validation, type check, and size limit.
    public func importVideo(from sourceURL: URL) async -> WallpaperItem? {
        // Standardize and resolve symlinks to prevent path traversal
        let standardizedURL = sourceURL.standardizedFileURL.resolvingSymlinksInPath()
        let fileExtension = standardizedURL.pathExtension.lowercased()

        // 1. Extension check
        guard allowedExtensions.contains(fileExtension) else {
            print("[LocalWallpaperManager] Security: Rejected unsupported video format: .\(fileExtension)")
            return nil
        }

        // 2. Existence & Size check
        guard fileManager.fileExists(atPath: standardizedURL.path) else {
            print("[LocalWallpaperManager] Security: File does not exist at path: \(standardizedURL.path)")
            return nil
        }

        if let attributes = try? fileManager.attributesOfItem(atPath: standardizedURL.path),
           let fileSize = attributes[.size] as? Int64 {
            guard fileSize > 0 && fileSize <= maxFileSizeBytes else {
                print("[LocalWallpaperManager] Security: Rejected file due to invalid size (\(fileSize) bytes)")
                return nil
            }
        }

        let asset = AVURLAsset(url: standardizedURL)

        // Read duration safely
        let durationSeconds: Int
        if let duration = try? await asset.load(.duration) {
            let seconds = CMTimeGetSeconds(duration)
            durationSeconds = (seconds.isFinite && seconds > 0) ? max(1, Int(seconds)) : 15
        } else {
            durationSeconds = 15
        }

        // Read resolution safely
        var resolutionStr = "1080p HD"
        if let tracks = try? await asset.loadTracks(withMediaType: .video), let track = tracks.first {
            if let size = try? await track.load(.naturalSize) {
                let w = Int(size.width)
                let h = Int(size.height)
                if (w >= 3840 || h >= 2160) {
                    resolutionStr = "3840x2160"
                } else if (w >= 2560 || h >= 1440) {
                    resolutionStr = "2560x1440"
                } else if w > 0 && h > 0 {
                    resolutionStr = "\(w)x\(h)"
                }
            }
        }

        // Safe sanitized identifier for thumbnail filename
        let safeId = UUID().uuidString
        let thumbnailURL = await generateThumbnail(for: asset, filenameId: safeId)

        let cleanTitle = standardizedURL.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized

        let newItem = WallpaperItem(
            id: safeId,
            title: cleanTitle.isEmpty ? "Custom Video Wallpaper" : cleanTitle,
            creator: "Local User",
            category: "local",
            videoUrl: standardizedURL,
            thumbnailUrl: thumbnailURL,
            durationSeconds: durationSeconds,
            resolution: resolutionStr,
            downloads: 1,
            likes: 1,
            isLocal: true,
            tags: ["Local", "Custom"],
            localPath: standardizedURL.path
        )

        await MainActor.run {
            self.localWallpapers.removeAll { $0.videoUrl == standardizedURL }
            self.localWallpapers.insert(newItem, at: 0)
            self.saveWallpapers()
        }

        return newItem
    }

    /// Safely deletes a local wallpaper and only removes thumbnail files within the app sandbox.
    public func deleteWallpaper(id: String) {
        DispatchQueue.main.async {
            guard let item = self.localWallpapers.first(where: { $0.id == id }) else { return }

            // If currently playing, halt wallpaper
            if WallpaperEngine.shared.currentItem?.id == id {
                WallpaperEngine.shared.stop()
            }

            // Security check: Only delete thumbnail if it resides strictly inside our thumbnailsDir
            if let thumbUrl = item.thumbnailUrl, thumbUrl.isFileURL {
                let standardizedThumb = thumbUrl.standardizedFileURL.resolvingSymlinksInPath()
                let thumbnailsBasePath = self.thumbnailsDir.standardizedFileURL.resolvingSymlinksInPath().path
                if standardizedThumb.path.hasPrefix(thumbnailsBasePath) {
                    try? self.fileManager.removeItem(at: standardizedThumb)
                }
            }

            withAnimation(.easeInOut(duration: 0.2)) {
                self.localWallpapers.removeAll { $0.id == id }
            }
            self.saveWallpapers()

            AppSettings.shared.favoriteIds.remove(id)
            print("[LocalWallpaperManager] Securely removed local wallpaper: \(item.title) (\(id))")
        }
    }

    private func generateThumbnail(for asset: AVAsset, filenameId: String) async -> URL? {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 800, height: 450)

        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else {
            return nil
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.85]) else {
            return nil
        }

        let thumbFile = thumbnailsDir.appendingPathComponent("\(filenameId)_thumb.jpg")
        try? jpegData.write(to: thumbFile, options: .atomic)
        return thumbFile
    }
}
