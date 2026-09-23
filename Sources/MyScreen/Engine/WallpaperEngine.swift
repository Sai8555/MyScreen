import AppKit
import AVFoundation
import Combine

// MARK: - Screen Identification Extension
extension NSScreen {
    public var displayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        if let num = deviceDescription[key] as? NSNumber {
            return CGDirectDisplayID(num.uint32Value)
        }
        return CGDirectDisplayID(hashValue)
    }

    public var displayKey: String {
        return "\(localizedName)_\(displayID)"
    }
}

// MARK: - Per-Display Playback Session
public final class ScreenPlaybackSession {
    public let displayID: CGDirectDisplayID
    public internal(set) var screen: NSScreen
    public internal(set) var item: WallpaperItem
    public internal(set) var scope: String
    public internal(set) var player: AVQueuePlayer?
    public internal(set) var looper: AVPlayerLooper?
    public internal(set) var window: WallpaperWindow?
    public internal(set) var activeDownloadTask: URLSessionDownloadTask?
    public internal(set) var isPlaying: Bool = false

    public init(displayID: CGDirectDisplayID, screen: NSScreen, item: WallpaperItem, scope: String) {
        self.displayID = displayID
        self.screen = screen
        self.item = item
        self.scope = scope
    }

    public func stop() {
        activeDownloadTask?.cancel()
        activeDownloadTask = nil
        looper?.disableLooping()
        looper = nil
        player?.pause()
        player = nil
        window?.orderOut(nil)
        window?.close()
        window = nil
        isPlaying = false
    }

    public func pause() {
        player?.pause()
        isPlaying = false
    }

    public func resume() {
        guard let p = player else { return }
        p.play()
        if p.rate == 0 {
            p.playImmediately(atRate: 1.0)
        }
        isPlaying = true
    }
}

// MARK: - Multi-Display Wallpaper Engine
public final class WallpaperEngine: ObservableObject {
    public static let shared = WallpaperEngine()

    @Published public private(set) var currentItem: WallpaperItem?
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var isPausedByPower: Bool = false
    @Published public var selectedScope: String = "Desktop" // "Both", "Desktop", "Lockscreen"
    @Published public var selectedScreenIndex: Int? = nil // nil = All screens

    // Independent per-display playback sessions
    private var sessions: [CGDirectDisplayID: ScreenPlaybackSession] = [:]
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupObservers()
    }

    private func setupObservers() {
        // Monitor display configuration changes (connecting/disconnecting iPad Sidecar, external monitors)
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reconfigureDisplays()
        }

        // Power & Sleep monitoring
        PowerMonitor.shared.onPowerStateChanged = { [weak self] shouldPause in
            DispatchQueue.main.async {
                self?.handlePowerState(shouldPause: shouldPause)
            }
        }

        // Settings observers: volume and mute updates across all active screen players
        AppSettings.shared.$volume
            .sink { [weak self] vol in
                guard let self = self else { return }
                for (_, session) in self.sessions {
                    session.player?.volume = Float(vol)
                }
            }
            .store(in: &cancellables)

        AppSettings.shared.$isMuted
            .sink { [weak self] muted in
                guard let self = self else { return }
                for (_, session) in self.sessions {
                    let isMain = (session.screen == NSScreen.main)
                    session.player?.isMuted = muted || !isMain
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Queries
    public func item(for screen: NSScreen) -> WallpaperItem? {
        return sessions[screen.displayID]?.item
    }

    public func item(for screenIndex: Int) -> WallpaperItem? {
        let screens = NSScreen.screens
        guard screenIndex >= 0 && screenIndex < screens.count else { return nil }
        return sessions[screens[screenIndex].displayID]?.item
    }

    public func isPlaying(on screen: NSScreen) -> Bool {
        return sessions[screen.displayID]?.isPlaying ?? false
    }

    public var activeSessions: [ScreenPlaybackSession] {
        return Array(sessions.values)
    }

    // MARK: - Apply Wallpaper
    public func applyWallpaper(_ item: WallpaperItem, scope: String? = nil, screenIndex: Int? = nil) {
        let effectiveScope = scope ?? AppSettings.shared.selectedScope
        self.currentItem = item
        self.selectedScope = effectiveScope
        self.selectedScreenIndex = screenIndex
        AppSettings.shared.selectedScope = effectiveScope
        AppSettings.shared.currentWallpaperId = item.id

        let allScreens = NSScreen.screens
        let targetScreens: [NSScreen]
        if let idx = screenIndex, idx >= 0 && idx < allScreens.count {
            targetScreens = [allScreens[idx]]
        } else {
            targetScreens = allScreens
        }

        // 1. Update macOS system desktop and lock screen image for target display(s)
        setSystemWallpaper(for: item, screens: targetScreens)

        // 2. Start or update independent live video playback for target display(s)
        for screen in targetScreens {
            if effectiveScope == "Desktop" || effectiveScope == "Both" {
                startSession(for: screen, item: item, scope: effectiveScope)
            } else {
                // Lockscreen only: stop video session for this screen
                if let session = sessions[screen.displayID] {
                    session.stop()
                    sessions.removeValue(forKey: screen.displayID)
                }
            }
        }

        self.isPlaying = sessions.values.contains(where: { $0.isPlaying })
        print("[WallpaperEngine] Applied '\(item.title)' [\(effectiveScope)] to \(targetScreens.count) display(s). Active sessions: \(sessions.count)")
    }

    private func startSession(for screen: NSScreen, item: WallpaperItem, scope: String) {
        let displayID = screen.displayID

        // If this screen already has a session, stop only this session
        if let existing = sessions[displayID] {
            existing.stop()
            sessions.removeValue(forKey: displayID)
        }

        let session = ScreenPlaybackSession(displayID: displayID, screen: screen, item: item, scope: scope)
        sessions[displayID] = session

        // Record per-display mapping in settings
        AppSettings.shared.displayWallpapers[screen.displayKey] = item.id

        // Determine effective URL (check 4K master cache)
        let effectiveURL: URL
        if item.isLocal {
            effectiveURL = item.videoUrl
        } else if let cached = VideoCacheManager.shared.cachedMasterURL(for: item.id) {
            effectiveURL = cached
            print("[WallpaperEngine] Playing 4K Master Video on [\(screen.localizedName)]: \(cached.lastPathComponent)")
        } else {
            effectiveURL = item.videoUrl
            downloadAndUpgradeToMaster(session: session, item: item)
        }

        let asset = AVURLAsset(url: effectiveURL)
        let playerItem = AVPlayerItem(asset: asset)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)

        // Primary display plays audio (if unmuted); secondary displays are muted to avoid audio conflict
        let isMain = (screen == NSScreen.main)
        queuePlayer.isMuted = AppSettings.shared.isMuted || !isMain
        queuePlayer.volume = Float(AppSettings.shared.volume)
        queuePlayer.actionAtItemEnd = .none

        session.looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        session.player = queuePlayer

        let win = WallpaperWindow(screen: screen, player: queuePlayer)
        win.orderBack(nil)
        session.window = win

        queuePlayer.play()
        session.isPlaying = true

        self.isPlaying = true
        self.isPausedByPower = false
        print("[WallpaperEngine] Started live playback on screen [\(screen.localizedName)] (ID: \(displayID)) with '\(item.title)'")
    }

    private func downloadAndUpgradeToMaster(session: ScreenPlaybackSession, item: WallpaperItem) {
        guard !item.isLocal else { return }
        let masterURL = item.masterVideoUrl
        guard masterURL != item.videoUrl else { return }

        let destination = VideoCacheManager.shared.destinationMasterURL(for: item.id)
        if FileManager.default.fileExists(atPath: destination.path) {
            upgradePlaybackToMaster(session: session, cachedURL: destination)
            return
        }

        print("[WallpaperEngine] Background downloading full 4K Master Video for '\(item.title)' on screen [\(session.screen.localizedName)]...")

        let task = URLSession.shared.downloadTask(with: masterURL) { [weak self, weak session] tempURL, _, error in
            guard let self = self, let session = session, let tempURL = tempURL, error == nil else {
                if let err = error as NSError?, err.code != NSURLErrorCancelled {
                    print("[WallpaperEngine] 4K Master download failed: \(err.localizedDescription)")
                }
                return
            }

            do {
                try FileManager.default.moveItem(at: tempURL, to: destination)
                print("[WallpaperEngine] 4K Master Video cached successfully: \(destination.lastPathComponent)")

                DispatchQueue.main.async {
                    if session.item.id == item.id && session.isPlaying {
                        self.upgradePlaybackToMaster(session: session, cachedURL: destination)
                    }
                }
            } catch {
                print("[WallpaperEngine] Error saving 4K master video: \(error)")
            }
        }
        session.activeDownloadTask = task
        task.resume()
    }

    private func upgradePlaybackToMaster(session: ScreenPlaybackSession, cachedURL: URL) {
        guard let player = session.player, let window = session.window else { return }
        let currentTime = player.currentTime()
        let asset = AVURLAsset(url: cachedURL)
        let playerItem = AVPlayerItem(asset: asset)

        session.looper?.disableLooping()
        session.looper = nil
        player.pause()

        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        let isMain = (session.screen == NSScreen.main)
        queuePlayer.isMuted = AppSettings.shared.isMuted || !isMain
        queuePlayer.volume = Float(AppSettings.shared.volume)
        queuePlayer.actionAtItemEnd = .none

        session.looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        session.player = queuePlayer

        window.updatePlayer(queuePlayer)

        queuePlayer.seek(to: currentTime)
        queuePlayer.play()
        print("[WallpaperEngine] Seamlessly upgraded screen [\(session.screen.localizedName)] to Full 4K Ultra HD Master Quality!")
    }

    // MARK: - System Desktop & Lockscreen Wallpaper
    public func setSystemWallpaper(for item: WallpaperItem, screens: [NSScreen]) {
        let targetDisplayIDs = screens.map { $0.displayID }
        Task.detached(priority: .userInitiated) {
            guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
            let lockScreenDir = appSupport.appendingPathComponent("MyScreen/LockScreen", isDirectory: true)
            try? FileManager.default.createDirectory(at: lockScreenDir, withIntermediateDirectories: true)

            var jpegData: Data? = nil

            // Attempt 1: From thumbnail URL (local or remote)
            if let thumbURL = item.thumbnailUrl {
                if thumbURL.isFileURL {
                    if let image = NSImage(contentsOf: thumbURL),
                       let tiff = image.tiffRepresentation,
                       let bitmap = NSBitmapImageRep(data: tiff) {
                        jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.95])
                    }
                } else {
                    if let (data, _) = try? await URLSession.shared.data(from: thumbURL),
                       let image = NSImage(data: data),
                       let tiff = image.tiffRepresentation,
                       let bitmap = NSBitmapImageRep(data: tiff) {
                        jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.95])
                    }
                }
            }

            // Attempt 2: If thumbnail is missing or conversion failed, generate a pristine frame from the video
            if jpegData == nil {
                let asset = AVURLAsset(url: item.videoUrl)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = CGSize(width: 3840, height: 2160) // High-def 4K frame
                let time = CMTime(seconds: 1.0, preferredTimescale: 600)
                if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                    let bitmap = NSBitmapImageRep(cgImage: cgImage)
                    jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.95])
                }
            }

            guard let finalJpegData = jpegData else {
                print("[WallpaperEngine] Warning: Could not generate lockscreen image for \(item.title)")
                return
            }

            // Unique timestamped filename to force macOS WallpaperAgent to refresh cache
            let safeId = item.id.filter { $0.isLetter || $0.isNumber }
            let timestamp = Int(Date().timeIntervalSince1970)
            let uniqueFileURL = lockScreenDir.appendingPathComponent("lockscreen_\(safeId)_\(timestamp).jpg")

            do {
                try finalJpegData.write(to: uniqueFileURL, options: .atomic)
            } catch {
                print("[WallpaperEngine] Error writing lockscreen image: \(error)")
                return
            }

            // Set desktop & lockscreen image on main thread for the specific screens
            await MainActor.run {
                let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
                    .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
                    .allowClipping: true
                ]
                let matchedScreens = NSScreen.screens.filter { targetDisplayIDs.contains($0.displayID) }
                for screen in matchedScreens {
                    do {
                        try NSWorkspace.shared.setDesktopImageURL(uniqueFileURL, for: screen, options: options)
                        print("[WallpaperEngine] Updated Lock Screen image for [\(screen.localizedName)] -> \(uniqueFileURL.lastPathComponent)")
                    } catch {
                        print("[WallpaperEngine] Error setting desktop image: \(error.localizedDescription)")
                    }
                }
            }

            // Clean up older lockscreen cache files while preserving recent files for all screens
            if let files = try? FileManager.default.contentsOfDirectory(at: lockScreenDir, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) {
                let sorted = files
                    .filter { $0.lastPathComponent.hasPrefix("lockscreen_") }
                    .sorted {
                        let d1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                        let d2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                        return d1 > d2
                    }
                for file in sorted.dropFirst(10) {
                    try? FileManager.default.removeItem(at: file)
                }
            }
        }
    }

    // MARK: - Playback Controls
    public func pause() {
        for (_, session) in sessions {
            session.pause()
        }
        isPlaying = false
    }

    public func resume() {
        for (_, session) in sessions {
            session.resume()
        }
        isPlaying = !sessions.isEmpty
    }

    public func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    public func stop() {
        for (_, session) in sessions {
            session.stop()
        }
        sessions.removeAll()
        currentItem = nil
        isPlaying = false
    }

    // MARK: - Display & Power Management
    private func handlePowerState(shouldPause: Bool) {
        if shouldPause {
            if isPlaying {
                isPausedByPower = true
                for (_, session) in sessions {
                    session.pause()
                }
                print("[WallpaperEngine] Display OFF: Auto-deactivated all screens to save power")
            }
        } else {
            if isPausedByPower {
                isPausedByPower = false
                for (_, session) in sessions {
                    session.resume()
                }
                print("[WallpaperEngine] Display AWAKE: Automatically resumed on all active screens")
            }
        }
    }

    private func reconfigureDisplays() {
        print("[WallpaperEngine] Displays reconfigured, adapting sessions...")
        let currentScreens = NSScreen.screens
        var currentIDs = Set<CGDirectDisplayID>()

        for (index, screen) in currentScreens.enumerated() {
            let id = screen.displayID
            currentIDs.insert(id)
            if let session = sessions[id] {
                session.screen = screen
                session.window?.updateFrame(for: screen)
                session.window?.orderBack(nil)
                if session.isPlaying {
                    session.player?.play()
                }
            } else if let savedId = AppSettings.shared.displayWallpapers[screen.displayKey],
                      let item = findWallpaper(id: savedId) {
                print("[WallpaperEngine] Restoring wallpaper for newly connected display [\(screen.localizedName)]: \(item.title)")
                applyWallpaper(item, scope: selectedScope, screenIndex: index)
            } else if let defaultId = AppSettings.shared.currentWallpaperId,
                      let item = findWallpaper(id: defaultId) {
                print("[WallpaperEngine] Applying current wallpaper to newly connected display [\(screen.localizedName)]: \(item.title)")
                applyWallpaper(item, scope: selectedScope, screenIndex: index)
            }
        }

        // Clean up disconnected displays
        for (id, session) in sessions where !currentIDs.contains(id) {
            print("[WallpaperEngine] Display disconnected (ID: \(id)), removing session.")
            session.stop()
            sessions.removeValue(forKey: id)
        }

        self.isPlaying = sessions.values.contains(where: { $0.isPlaying })
    }

    // MARK: - Saved Wallpapers Restoration
    public func restoreSavedWallpapers() {
        let screens = NSScreen.screens
        var restoredAny = false

        for (index, screen) in screens.enumerated() {
            if let savedId = AppSettings.shared.displayWallpapers[screen.displayKey],
               let item = findWallpaper(id: savedId) {
                print("[WallpaperEngine] Restoring saved wallpaper for [\(screen.localizedName)]: \(item.title)")
                applyWallpaper(item, scope: AppSettings.shared.selectedScope, screenIndex: index)
                restoredAny = true
            }
        }

        // Fallback to currentWallpaperId if no per-display mapping
        if !restoredAny, let defaultId = AppSettings.shared.currentWallpaperId,
           let item = findWallpaper(id: defaultId) {
            print("[WallpaperEngine] Restoring default wallpaper: \(item.title)")
            applyWallpaper(item, scope: AppSettings.shared.selectedScope, screenIndex: nil)
        }
    }

    private func findWallpaper(id: String) -> WallpaperItem? {
        return WallpaperService.shared.allWallpapers.first(where: { $0.id == id }) ??
               LocalWallpaperManager.shared.localWallpapers.first(where: { $0.id == id })
    }
}
