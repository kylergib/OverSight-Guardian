//
//  UserSettings.swift
//  MacOverSight
//
//  Created by kyle on 1/9/24.
//

// TODO:
/// settings ideas
/// custom timer amount (default is 1)
/// hide devices when disconnected
/// save devices when quitting and always show
/// custom colors for in use/connected
///
///
/// // dev mode:
/// prolly button to export logs
/// dropdown to filter logs?
import Foundation

class UserSettingsViewModel: ObservableObject {
    // below are defaults
    private var logger = Logger(current: UserSettingsViewModel.self)
    @Published var appVersion: String
    @Published var darkMode: Bool // TODO: prolly should be system
    @Published var devModeEnabled: Bool
    @Published var endPort: Int
    @Published var endPortString: String
    @Published var monitorBattery: Bool
    @Published var monitorCameras: Bool
    @Published var monitorCpu: Bool
    @Published var monitorMicrophones: Bool
    @Published var monitorOpenApps: Bool
    @Published var monitorRam: Bool
    @Published var monitoredApps: Set<String>
    @Published var notifications: Bool
    @Published var openAppOnSystemStartup: Bool
    @Published var startApiOnStartup: Bool
    @Published var startPort: Int
    @Published var startPortString: String
    @Published var quitList: [String: Int]
    @Published var reopenList: [String: String]
    @Published var statusText: String = ""
    @Published var statusBool: Bool = false
    @Published var showStatus: Bool = false
    @Published var guideCount: Int = -1
    @Published var tabSelection: Int = 1

    init(appVersion: String, darkMode: Bool, devModeEnabled: Bool, endPort: Int, monitorBattery: Bool, monitorCameras: Bool, monitorCpu: Bool, monitorMicrophones: Bool, monitorOpenApps: Bool, monitorRam: Bool, monitoredApps: [String], notifications: Bool, openAppOnSystemStartup: Bool, startApiOnStartup: Bool, startPort: Int, quitList: [String: Int], reopenList: [String: String]) {
        self.appVersion = appVersion
        self.darkMode = darkMode
        self.devModeEnabled = devModeEnabled
        self.endPort = endPort
        self.endPortString = "\(endPort)"
        self.monitorBattery = monitorBattery
        self.monitorCameras = monitorCameras
        self.monitorCpu = monitorCpu
        self.monitorMicrophones = monitorMicrophones
        self.monitorOpenApps = monitorOpenApps
        self.monitorRam = monitorRam
        self.monitoredApps = Set(monitoredApps)
        self.notifications = notifications
        self.openAppOnSystemStartup = openAppOnSystemStartup
        self.startApiOnStartup = startApiOnStartup
        self.startPort = startPort
        self.startPortString = "\(startPort)"
        self.quitList = quitList
        self.reopenList = reopenList
    }

    func updateAll(appVersion: String, darkMode: Bool, devModeEnabled: Bool, endPort: Int, monitorBattery: Bool, monitorCameras: Bool, monitorCpu: Bool, monitorMicrophones: Bool, monitorOpenApps: Bool, monitorRam: Bool, monitoredApps: [String], notifications: Bool, openAppOnSystemStartup: Bool, startApiOnStartup: Bool, startPort: Int, quitList: [String: Int], reopenList: [String: String]) {
        DispatchQueue.main.async {
            self.appVersion = appVersion
            self.darkMode = darkMode
            self.devModeEnabled = devModeEnabled
            self.endPort = endPort
            self.endPortString = "\(endPort)"
            self.monitorBattery = monitorBattery
            self.monitorCameras = monitorCameras
            self.monitorCpu = monitorCpu
            self.monitorMicrophones = monitorMicrophones
            self.monitorOpenApps = monitorOpenApps
            self.monitorRam = monitorRam
            self.monitoredApps = Set(monitoredApps)
            self.notifications = notifications
            self.openAppOnSystemStartup = openAppOnSystemStartup
            self.startApiOnStartup = startApiOnStartup
            self.startPort = startPort
            self.startPortString = "\(startPort)"
            self.quitList = quitList
            self.reopenList = reopenList
        }
    }

    func updateTabSelection(selection: Int) {
        DispatchQueue.main.async {
            self.tabSelection = selection
        }
    }

    func updateGuideCount(count: Int) {
        DispatchQueue.main.async {
            self.guideCount = count
        }
    }

    func updateAppVersion(appVersion: String) {
        DispatchQueue.main.async {
            self.appVersion = appVersion
        }
    }

    func updateDarkMode(darkMode: Bool) {
        DispatchQueue.main.async {
            self.darkMode = darkMode
        }
    }

    func updateDevModeEnabled(devModeEnabled: Bool) {
        DispatchQueue.main.async {
            self.devModeEnabled = devModeEnabled
        }
    }

    func updateEndPort(endPort: Int) {
        DispatchQueue.main.async {
            self.endPort = endPort
            self.endPortString = "\(endPort)"
        }
    }

    func updateMonitorBattery(monitorBattery: Bool) {
        DispatchQueue.main.async {
            self.monitorBattery = monitorBattery
        }
    }

    func updateMonitorCpu(monitorCpu: Bool) {
        DispatchQueue.main.async {
            self.monitorCpu = monitorCpu
        }
    }

    func updateMonitorOpenApps(monitorOpenApps: Bool) {
        DispatchQueue.main.async {
            self.monitorOpenApps = monitorOpenApps
        }
    }

    func updateMonitorRam(monitorRam: Bool) {
        DispatchQueue.main.async {
            self.monitorRam = monitorRam
        }
    }

    func addMonitoredApp(appName: String) {
        DispatchQueue.main.async {
            self.monitoredApps.insert(appName)
            self.saveSettings()
        }
    }

    func removeMonitoredApp(appName: String) {
        DispatchQueue.main.async {
            self.monitoredApps.remove(appName)
            self.reopenList[appName] = nil
            self.quitList[appName] = nil
            self.saveSettings()
        }
    }

    func updateNotifications(notifications: Bool) {
        DispatchQueue.main.async {
            self.notifications = notifications
        }
    }

    func updateOpenAppOnSystemStartup(openAppOnSystemStartup: Bool) {
        DispatchQueue.main.async {
            self.openAppOnSystemStartup = openAppOnSystemStartup
        }
    }

    func updateStartApiOnStartup(startApiOnStartup: Bool) {
        DispatchQueue.main.async {
            self.startApiOnStartup = startApiOnStartup
        }
    }

    func updateStartPort(startPort: Int) {
        DispatchQueue.main.async {
            self.startPort = startPort
            self.startPortString = "\(startPort)"
        }
    }

    func updateQuitInfo(appName: String, quitAutomatically: Bool, quitMB: Int) {
        DispatchQueue.main.async {
            if quitAutomatically {
                self.quitList[appName] = quitMB
            } else {
                self.quitList[appName] = nil
            }
            self.saveSettings()
        }
    }

    func updateReopenAutomatically(appName: String, reopenAutomatically: Bool, path: String) {
        DispatchQueue.main.async {
            if reopenAutomatically {
                self.reopenList[appName] = path
            } else {
                self.reopenList[appName] = nil
            }
            self.saveSettings()
        }
    }

    func saveSettings() {
        DispatchQueue.main.async {
            SettingsService.settingsService.saveSettings()
        }
    }

    func saveDevSettings() {
        DispatchQueue.main.async {
            SettingsService.settingsService.saveDevSettings()
        }
    }

    func sendStatusSignal(status: Bool, message: String) {
        showStatus = true
        statusBool = status
        statusText = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.showStatus = false
            self.statusText = ""
        }
    }
}

