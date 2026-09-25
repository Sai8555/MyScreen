import SwiftUI
import AppKit

public final class ImageLoaderCache {
    public static let shared = ImageLoaderCache()
    private let cache = NSCache<NSURL, NSImage>()

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 120 * 1024 * 1024 // 120 MB
    }

    public func image(for url: URL) -> NSImage? {
        cache.object(forKey: url as NSURL)
    }

    public func insertImage(_ image: NSImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

public struct RemoteImageView: View {
    public let url: URL?
    @State private var image: NSImage?
    @State private var isLoading = false

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()

    public init(url: URL?) {
        self.url = url
    }

    public var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                    ProgressView()
                        .controlSize(.small)
                }
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.purple.opacity(0.2), Color.indigo.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "photo.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .onAppear {
            loadImage(for: url)
        }
        .onChange(of: url) { newUrl in
            self.image = nil
            loadImage(for: newUrl)
        }
    }

    private func loadImage(for targetURL: URL?) {
        guard let url = targetURL else {
            self.image = nil
            return
        }

        // Local file validation
        if url.isFileURL {
            let standardized = url.standardizedFileURL.resolvingSymlinksInPath()
            if FileManager.default.fileExists(atPath: standardized.path),
               let img = NSImage(contentsOf: standardized) {
                self.image = img
            }
            return
        }

        // HTTPS scheme validation (Block insecure HTTP or arbitrary URL schemes)
        guard let scheme = url.scheme?.lowercased(), scheme == "https" else {
            print("[RemoteImageView] Security: Blocked non-HTTPS image URL: \(url)")
            return
        }

        // Memory cache check
        if let cached = ImageLoaderCache.shared.image(for: url) {
            self.image = cached
            return
        }

        // Network fetch with security headers & size limit
        isLoading = true
        var request = URLRequest(url: url)
        request.setValue("MyScreen-Wallpaper/1.0", forHTTPHeaderField: "User-Agent")

        Self.session.dataTask(with: request) { data, response, error in
            guard let data = data,
                  error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  data.count <= 25 * 1024 * 1024, // 25 MB max image size defense
                  let downloadedImage = NSImage(data: data) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }

            ImageLoaderCache.shared.insertImage(downloadedImage, for: url)

            DispatchQueue.main.async {
                self.image = downloadedImage
                self.isLoading = false
            }
        }.resume()
    }
}
