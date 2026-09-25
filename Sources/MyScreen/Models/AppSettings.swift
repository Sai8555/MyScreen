import Foundation
import Combine
import AppKit
import ServiceManagement

public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    private enum Keys {
        static let volume = "myscreen_volume"
        static let isMuted = "myscreen_is_muted"
        static let pauseOnBattery = "myscreen_pause_battery"
        static let pauseOnScreenSleep = "myscreen_pause_sleep"
        static let autoStartOnLogin = "myscreen_auto_start"
        static let currentWallpaperId = "myscreen_current_wallpaper_id"
        static let favoriteIds = "myscreen_favorites"
        static let selectedDisplayMode = "myscreen_display_mode" // "all" or specific display index
        static let selectedScope = "myscreen_selected_scope" // "Both", "Desktop", "Lockscreen"
        static let displayWallpapers = "myscreen_display_wallpapers"
    }

    private let defaults = UserDefaults.standard

    @Published public var volume: Double {
        didSet { defaults.set(volume, forKey: Keys.volume) }
    }

    @Published public var isMuted: Bool {
        didSet { defaults.set(isMuted, forKey: Keys.isMuted) }
    }

    @Published public var pauseOnBattery: Bool {
        didSet { defaults.set(pauseOnBattery, forKey: Keys.pauseOnBattery) }
    }

    @Published public var pauseOnScreenSleep: Bool {
        didSet { defaults.set(pauseOnScreenSleep, forKey: Keys.pauseOnScreenSleep) }
    }

    @Published public var autoStartOnLogin: Bool {
        didSet {
            defaults.set(autoStartOnLogin, forKey: Keys.autoStartOnLogin)
            if #available(macOS 13.0, *) {
                do {
                    if autoStartOnLogin {
                        if SMAppService.mainApp.status != .enabled {
                            try SMAppService.mainApp.register()
                            print("[AppSettings] Registered MyScreen for automatic background launch")
                        }
                    } else {
                        if SMAppService.mainApp.status == .enabled {
                            try SMAppService.mainApp.unregister()
                            print("[AppSettings] Unregistered MyScreen from background launch")
                        }
                    }
                } catch {
                    print("[AppSettings] SMAppService error: \(error)")
                }
            }
        }
    }

    @Published public var currentWallpaperId: String? {
        didSet { defaults.set(currentWallpaperId, forKey: Keys.currentWallpaperId) }
    }

    @Published public var favoriteIds: Set<String> {
        didSet {
            let array = Array(favoriteIds)
            defaults.set(array, forKey: Keys.favoriteIds)
        }
    }

    @Published public var selectedDisplayMode: String {
        didSet { defaults.set(selectedDisplayMode, forKey: Keys.selectedDisplayMode) }
    }

    @Published public var selectedScope: String {
        didSet { defaults.set(selectedScope, forKey: Keys.selectedScope) }
    }

    @Published public var displayWallpapers: [String: String] {
        didSet { defaults.set(displayWallpapers, forKey: Keys.displayWallpapers) }
    }

    private init() {
        self.volume = defaults.object(forKey: Keys.volume) != nil ? defaults.double(forKey: Keys.volume) : 0.0
        self.isMuted = defaults.object(forKey: Keys.isMuted) != nil ? defaults.bool(forKey: Keys.isMuted) : true
        self.pauseOnBattery = defaults.object(forKey: Keys.pauseOnBattery) != nil ? defaults.bool(forKey: Keys.pauseOnBattery) : true
        self.pauseOnScreenSleep = defaults.object(forKey: Keys.pauseOnScreenSleep) != nil ? defaults.bool(forKey: Keys.pauseOnScreenSleep) : true
        if #available(macOS 13.0, *) {
            let hasInitialized = defaults.bool(forKey: "hasInitializedBackgroundService")
            if !hasInitialized {
                defaults.set(true, forKey: "hasInitializedBackgroundService")
                try? SMAppService.mainApp.register()
            }
            self.autoStartOnLogin = SMAppService.mainApp.status == .enabled
        } else {
            self.autoStartOnLogin = defaults.bool(forKey: Keys.autoStartOnLogin)
        }
        self.currentWallpaperId = defaults.string(forKey: Keys.currentWallpaperId)
        let savedFavorites = defaults.stringArray(forKey: Keys.favoriteIds) ?? []
        self.favoriteIds = Set(savedFavorites)
        self.selectedDisplayMode = defaults.string(forKey: Keys.selectedDisplayMode) ?? "all"
        self.selectedScope = defaults.string(forKey: Keys.selectedScope) ?? "Both"
        self.displayWallpapers = defaults.dictionary(forKey: Keys.displayWallpapers) as? [String: String] ?? [:]
    }

    public func toggleFavorite(id: String) {
        if favoriteIds.contains(id) {
            favoriteIds.remove(id)
        } else {
            favoriteIds.insert(id)
        }
    }

    public func isFavorite(id: String) -> Bool {
        favoriteIds.contains(id)
    }

    public func openBackgroundPermissions() {
        if #available(macOS 13.0, *) {
            SMAppService.openSystemSettingsLoginItems()
        } else if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    public func openWallpaperSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Wallpaper-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
