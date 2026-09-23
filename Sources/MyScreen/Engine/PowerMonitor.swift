import AppKit
import Foundation
import Combine

public final class PowerMonitor: ObservableObject {
    public static let shared = PowerMonitor()

    @Published public private(set) var isScreenLocked: Bool = false
    @Published public private(set) var isSystemSleeping: Bool = false
    @Published public private(set) var isLowPowerMode: Bool = false

    public var onPowerStateChanged: ((Bool) -> Void)? // true = should pause, false = should resume

    private var observers: [Any] = []
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupObservers()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    private func setupObservers() {
        let wsCenter = NSWorkspace.shared.notificationCenter

        // System Sleep & Wake
        observers.append(wsCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.isSystemSleeping = true
            self?.evaluatePolicy()
        })

        observers.append(wsCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.isSystemSleeping = false
            self?.evaluatePolicy()
        })

        // Displays Sleep & Wake (Screen Off & Screen On)
        observers.append(wsCenter.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.isSystemSleeping = true
            self?.evaluatePolicy()
        })

        observers.append(wsCenter.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.isSystemSleeping = false
            self?.evaluatePolicy()
        })

        // Screen Lock & Unlock (DistributedNotificationCenter)
        let distCenter = DistributedNotificationCenter.default()
        distCenter.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isScreenLocked = true
            self?.evaluatePolicy()
        }

        distCenter.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isScreenLocked = false
            self?.evaluatePolicy()
        }

        // Low Power Mode
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
            self?.evaluatePolicy()
        }

        // Settings observers
        AppSettings.shared.$pauseOnScreenSleep
            .sink { [weak self] _ in self?.evaluatePolicy() }
            .store(in: &cancellables)

        AppSettings.shared.$pauseOnBattery
            .sink { [weak self] _ in self?.evaluatePolicy() }
            .store(in: &cancellables)
    }

    private func evaluatePolicy() {
        // Only pause when screen/system is OFF (displays sleeping) or in Low Power Mode
        // Do NOT pause when screen is locked and active (Lock Screen should display/play wallpaper)
        let shouldPause = (isSystemSleeping && AppSettings.shared.pauseOnScreenSleep) || (isLowPowerMode && AppSettings.shared.pauseOnBattery)
        onPowerStateChanged?(shouldPause)
    }
}
