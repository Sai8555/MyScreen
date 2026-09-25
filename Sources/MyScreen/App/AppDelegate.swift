import AppKit
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    public static var shared: AppDelegate?
    public private(set) var mainWindow: NSWindow?
    public private(set) var preferencesWindow: NSWindow?

    public override init() {
        super.init()
        AppDelegate.shared = self
    }

    /// Accurately identifies the primary application window, excluding MenuBarExtra popovers, WallpaperWindows, preferences, and status panels
    public func isMainAppWindow(_ win: NSWindow) -> Bool {
        return win != preferencesWindow &&
               !(win is WallpaperWindow) &&
               !(win is NSPanel) &&
               win.level == .normal &&
               !win.className.contains("StatusBarWindow") &&
               !win.className.contains("MenuBar") &&
               !win.className.contains("Panel") &&
               !win.className.contains("Popover") &&
               win.canBecomeMain
    }

    private func configureUIWindows() {
        for win in NSApp.windows where isMainAppWindow(win) {
            self.mainWindow = win
            win.isReleasedWhenClosed = false
            win.delegate = self
        }
    }

    /// Red cross button: Hides window to background without quitting the app or stopping wallpaper
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        if sender == preferencesWindow {
            sender.orderOut(nil)
            return false // Keep preferences window in memory
        }
        if isMainAppWindow(sender) {
            self.mainWindow = sender
            sender.orderOut(nil)
            print("[AppDelegate] Main window hidden to background. Wallpaper & menu bar continue.")
            for session in WallpaperEngine.shared.activeSessions {
                session.window?.orderFrontRegardless()
            }
            return false // Keep window instance alive in memory
        }
        return true
    }

    /// Opens the dedicated Preferences window directly
    public func openPreferencesWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if let win = preferencesWindow {
            if win.isMiniaturized {
                win.deminiaturize(nil)
            }
            win.setIsVisible(true)
            win.makeKeyAndOrderFront(nil)
            win.orderFrontRegardless()
            return
        }

        let hostingView = NSHostingView(
            rootView: SettingsView(onClose: { [weak self] in
                self?.preferencesWindow?.orderOut(nil)
            })
            .preferredColorScheme(.dark)
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 670),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = hostingView
        window.center()
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1.0)

        self.preferencesWindow = window
        window.setIsVisible(true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Enforce single instance: prevent two MyScreen instances from running at the same time
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let bundleID = Bundle.main.bundleIdentifier ?? "com.myscreen.wallpaper"
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        for app in runningApps where app.processIdentifier != currentPID {
            print("[AppDelegate] Another instance of MyScreen is already active (PID \(app.processIdentifier)). Bringing it to front.")
            app.activate(options: .activateIgnoringOtherApps)
            NSApp.terminate(nil)
            return
        }

        NSApp.setActivationPolicy(.regular)

        // Capture main window immediately and configure
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.configureUIWindows()
        }

        // Listen for new window appearances
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            guard let self = self,
                  let win = notif.object as? NSWindow,
                  self.isMainAppWindow(win) else { return }

            self.mainWindow = win
            win.isReleasedWhenClosed = false
            if win.delegate == nil || !(win.delegate is AppDelegate) {
                win.delegate = self
            }
        }

        // Restore previously saved wallpaper(s) across all displays
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            WallpaperEngine.shared.restoreSavedWallpapers()
        }
    }



    public func windowWillClose(_ notification: Notification) {
        for session in WallpaperEngine.shared.activeSessions {
            session.window?.orderFrontRegardless()
        }
    }

    /// Keep running in background when window is closed
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    /// Clicking Dock icon restores main window
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        reopenMainWindow()
        return true
    }

    /// Opening app from Applications, Spotlight, or Launchpad when already running restores main window
    public func applicationDidBecomeActive(_ notification: Notification) {
        let hasVisibleUIWindow = NSApp.windows.contains { win in
            self.isMainAppWindow(win) && win.isVisible
        }
        if !hasVisibleUIWindow {
            reopenMainWindow()
        }
    }

    /// Restores the main application window smoothly
    public func reopenMainWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let target = (mainWindow != nil && isMainAppWindow(mainWindow!)) ? mainWindow : NSApp.windows.first(where: { isMainAppWindow($0) })

        if let win = target {
            self.mainWindow = win
            win.isReleasedWhenClosed = false
            win.delegate = self
            if win.isMiniaturized {
                win.deminiaturize(nil)
            }
            win.setIsVisible(true)
            win.makeKeyAndOrderFront(nil)
            win.orderFrontRegardless()
        }
    }
}
