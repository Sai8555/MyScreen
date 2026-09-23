import SwiftUI
import AppKit

@main
struct MyScreenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var engine = WallpaperEngine.shared
    @ObservedObject private var settings = AppSettings.shared

    var body: some Scene {
        WindowGroup(id: "main") {
            MainContainerView()
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1120, height: 740)
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Quit MyScreen") {
                    WallpaperEngine.shared.stop()
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }

        MenuBarExtra("MyScreen", systemImage: "sparkles.tv") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
