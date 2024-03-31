//
//  SettingsService.swift
//  MacOverSight
//
//  Created by kyle on 1/9/24.
//

import Foundation
import ServiceManagement
import UserNotifications

class SettingsService {
    static var settingsService: SettingsService = .init()
    private var logger = Logger(current: SettingsService.self)
    var launchStartup: Bool?
    var userSettingsViewModel: UserSettingsViewModel?
    var devPlist: String?
    private var appDirectoryURL: URL?
    private var fileManager: FileManager?
    private var userSettingsUrl: URL?
    private var devSettingsUrl: URL?
    private var notificationsAllowed: Bool = false
    private var center: UNUserNotificationCenter
    private var version: String


    init() {
        version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        fileManager = FileManager.default
        center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            self.notificationsAllowed = granted
        }
        getAppDirectory()
        createSettingsPlist()
        enableDevLogger()
    }

    func enableDevLogger() {
        if userSettingsViewModel?.devModeEnabled != nil, userSettingsViewModel!.devModeEnabled {
            Logger.isDevMode = true
            createDevSettingsPlist()
        }
    }

    func showNotification(title: String, subTitle: String, body: String, interval: Double) {
        if !userSettingsViewModel!.notifications { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subTitle
        content.body = body
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)

        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)

        // adds noti request to notification center
        center.add(request) { error in
            if error != nil {
                self.logger.error("\(String(describing: error))")
            }
        }
    }

    func getNotificationsAllowed() -> Bool {
        return notificationsAllowed
    }

    func getAppDirectory() {
        do {
            let appSupportURL = try fileManager?.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

            appDirectoryURL = appSupportURL?.appendingPathComponent("OverSightGuardian", isDirectory: true) // is in its own container in library for sandboxed
        } catch {
            logger.error("Could not get app directory")
        }
    }

    func createSettingsPlist() {
        if fileManager == nil || appDirectoryURL == nil { return }
        do {
            if !fileManager!.fileExists(atPath: appDirectoryURL!.path) {
                try fileManager!.createDirectory(at: appDirectoryURL!, withIntermediateDirectories: true, attributes: nil)
            }
            userSettingsUrl = appDirectoryURL!.appendingPathComponent("UserSettings.plist")
            devSettingsUrl = appDirectoryURL!.appendingPathComponent("DevSettings.plist")

            if !fileManager!.fileExists(atPath: userSettingsUrl!.path) {
                logger.info("Creating default settings")
                writeDefaults()
            } else {
                logger.info("Restoring settings")
                readUserPlist()
            }

        } catch {
            logger.error("Error: \(error)")
        }
    }

    func writeDefaults() {
        do {
            let plistData: [String: Any] = ["darkMode": false, "startApiOnStartup": true, "notifications": true, "monitoredApps": [], "quitList": [], "reopenList": [], "openAppOnSystemStartup": false, "monitorCameras": true, "monitorCpu": true, "monitorMicrophones": true, "monitorRam": true, "monitorBattery": true, "monitorOpenApps": true, "devModeEnabled": false, "startPort": 5005, "endPort": 5015]
            let data = try PropertyListSerialization.data(fromPropertyList: plistData, format: .xml, options: 0)
            try data.write(to: userSettingsUrl!)
            logger.info("Created default settings")
            readUserPlist()
            userSettingsViewModel?.updateGuideCount(count: 0)
        } catch {
            logger.error("Error: \(error)")
        }
    }

    func readUserPlist() {
        if userSettingsUrl == nil { return }
        do {
    
            let data = try Data(contentsOf: userSettingsUrl!)
            guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
                logger.error("Failed to read property list.")
                return
            }

            logger.debug("Read property list: \(plist)")


            let darkMode = plist.keys.contains("darkMode") ? plist["darkMode"] as! Bool : false
            let devModeEnabled = plist.keys.contains("devModeEnabled") ? plist["devModeEnabled"] as! Bool : false
            Logger.isDevMode = devModeEnabled
            let startPort = plist.keys.contains("startPort") ? plist["startPort"] as! Int : 5005
            let endPort = plist.keys.contains("endPort") ? plist["endPort"] as! Int : startPort + 10
            let monitorBattery = plist.keys.contains("monitorBattery") ? plist["monitorBattery"] as! Bool : true
            let monitorCameras = plist.keys.contains("monitorCameras") ? plist["monitorCameras"] as! Bool : true
            let monitorCpu = plist.keys.contains("monitorCpu") ? plist["monitorCpu"] as! Bool : true
            let monitorMicrophones = plist.keys.contains("monitorMicrophones") ? plist["monitorMicrophones"] as! Bool : true
            let monitorOpenApps = plist.keys.contains("monitorOpenApps") ? plist["monitorOpenApps"] as! Bool : true
            let monitorRam = plist.keys.contains("monitorRam") ? plist["monitorRam"] as! Bool : true
            let monitoredApps = plist.keys.contains("monitoredApps") ? plist["monitoredApps"] as! [String] : []
            let notifications = plist.keys.contains("notifications") ? plist["notifications"] as! Bool : true
            let openAppOnSystemStartup = plist.keys.contains("openAppOnSystemStartup") ? plist["openAppOnSystemStartup"] as! Bool : false
            let reopenList = plist.keys.contains("reopenList") ? plist["reopenList"] as? [String: String] : [String: String]()
            let startApiOnStartup = plist.keys.contains("startApiOnStartup") ? plist["startApiOnStartup"] as! Bool : true
            let quitList = plist.keys.contains("quitList") ? plist["quitList"] as? [String: Int] : [String: Int]()
            if userSettingsViewModel == nil {
                userSettingsViewModel = UserSettingsViewModel(appVersion: version, darkMode: darkMode, devModeEnabled: devModeEnabled, endPort: endPort, monitorBattery: monitorBattery, monitorCameras: monitorCameras, monitorCpu: monitorCpu, monitorMicrophones: monitorMicrophones, monitorOpenApps: monitorOpenApps, monitorRam: monitorRam, monitoredApps: monitoredApps, notifications: notifications, openAppOnSystemStartup: openAppOnSystemStartup, startApiOnStartup: startApiOnStartup, startPort: startPort, quitList: quitList ?? [String: Int](), reopenList: reopenList ?? [String: String]())
            } else {
                userSettingsViewModel!.updateAll(appVersion: version, darkMode: darkMode, devModeEnabled: devModeEnabled, endPort: endPort, monitorBattery: monitorBattery, monitorCameras: monitorCameras, monitorCpu: monitorCpu, monitorMicrophones: monitorMicrophones, monitorOpenApps: monitorOpenApps, monitorRam: monitorRam, monitoredApps: monitoredApps, notifications: notifications, openAppOnSystemStartup: openAppOnSystemStartup, startApiOnStartup: startApiOnStartup, startPort: startPort, quitList: quitList ?? [String: Int](), reopenList: reopenList ?? [String: String]())
            }
            launchStartup = userSettingsViewModel?.openAppOnSystemStartup

        } catch {
            logger.error("Error reading property list: \(error)")
        }
    }

    func saveSettings() {
        DispatchQueue.main.async {
            do {
                let plistData: [String: Any] = ["darkMode": self.userSettingsViewModel?.darkMode ?? false, "startApiOnStartup": self.userSettingsViewModel?.startApiOnStartup ?? true, "notifications": self.userSettingsViewModel?.notifications ?? true, "monitoredApps": Array(self.userSettingsViewModel?.monitoredApps ?? []), "quitList": self.userSettingsViewModel?.quitList ?? [], "reopenList": self.userSettingsViewModel?.reopenList ?? [], "openAppOnSystemStartup": self.userSettingsViewModel?.openAppOnSystemStartup ?? false, "monitorMicrophones": self.userSettingsViewModel?.monitorMicrophones ?? true, "monitorCpu": self.userSettingsViewModel?.monitorCpu ?? true, "monitorCameras": self.userSettingsViewModel?.monitorCameras ?? true, "monitorRam": self.userSettingsViewModel?.monitorRam ?? true, "monitorBattery": self.userSettingsViewModel?.monitorBattery ?? true, "monitorOpenApps": self.userSettingsViewModel?.monitorOpenApps ?? true, "devModeEnabled": self.userSettingsViewModel?.devModeEnabled ?? false, "startPort": self.userSettingsViewModel?.startPort ?? 5005, "endPort": self.userSettingsViewModel?.endPort ?? 5015]
                let data = try PropertyListSerialization.data(fromPropertyList: plistData, format: .xml, options: 0)
                try data.write(to: self.userSettingsUrl!)
                Logger.isDevMode = self.userSettingsViewModel?.devModeEnabled ?? false
                if Logger.isDevMode {
                    self.enableDevLogger()
                }
                self.logger.info("Saved settings succesfully.")

                self.userSettingsViewModel?.sendStatusSignal(status: true, message: "Settings saved successfully.")
            } catch {
                self.logger.error("Error: \(error)")
                self.userSettingsViewModel?.sendStatusSignal(status: false, message: "Error saving settings. Please try again.")
            }
            if self.launchStartup == self.userSettingsViewModel?.openAppOnSystemStartup {
                self.logger.debug("skipping")
                return
            }
            self.launchStartup = self.userSettingsViewModel?.openAppOnSystemStartup
            do {
                self.userSettingsViewModel?.openAppOnSystemStartup ?? false ? try SMAppService.mainApp.register() : try SMAppService.mainApp.unregister()

            } catch {
                self.logger.error("Error: \(error)")
            }
        }
    }

    func saveDevSettings() {
        DispatchQueue.main.async {
            do {
                var plistData = [String: Any]()

                let loggerData = [
                    "APIService": Logger.loggerViewModel.loggerValDict["APIService"] != nil ? Logger.loggerViewModel.loggerValDict["APIService"]! : "info",
                    "AppManager": Logger.loggerViewModel.loggerValDict["AppManager"] != nil ? Logger.loggerViewModel.loggerValDict["AppManager"]! : "info",
                    "AppDelegate": Logger.loggerViewModel.loggerValDict["AppDelegate"] != nil ? Logger.loggerViewModel.loggerValDict["AppDelegate"]! : "info",
                    "AppViewModel": Logger.loggerViewModel.loggerValDict["AppViewModel"] != nil ? Logger.loggerViewModel.loggerValDict["AppViewModel"]! : "info",
                    "BatteryManager": Logger.loggerViewModel.loggerValDict["BatteryManager"] != nil ? Logger.loggerViewModel.loggerValDict["BatteryManager"]! : "info",
                    "CameraDevice": Logger.loggerViewModel.loggerValDict["CameraDevice"] != nil ? Logger.loggerViewModel.loggerValDict["CameraDevice"]! : "info",
                    "CpuManager": Logger.loggerViewModel.loggerValDict["CpuManager"] != nil ? Logger.loggerViewModel.loggerValDict["CpuManager"]! : "info",
                    "CPUViewModel": Logger.loggerViewModel.loggerValDict["CPUViewModel"] != nil ? Logger.loggerViewModel.loggerValDict["CPUViewModel"]! : "info",
                    "DeviceManager": Logger.loggerViewModel.loggerValDict["DeviceManager"] != nil ? Logger.loggerViewModel.loggerValDict["DeviceManager"]! : "info",
                    "DeviceViewModel": Logger.loggerViewModel.loggerValDict["DeviceViewModel"] != nil ? Logger.loggerViewModel.loggerValDict["DeviceViewModel"]! : "info",
                    "EchoHandler": Logger.loggerViewModel.loggerValDict["EchoHandler"] != nil ? Logger.loggerViewModel.loggerValDict["EchoHandler"]! : "info",
                    "LoggerViewModel": Logger.loggerViewModel.loggerValDict["LoggerViewModel"] != nil ? Logger.loggerViewModel.loggerValDict["LoggerViewModel"]! : "info",
                    "MemoryManager": Logger.loggerViewModel.loggerValDict["MemoryManager"] != nil ? Logger.loggerViewModel.loggerValDict["MemoryManager"]! : "info",
                    "MemoryViewModel": Logger.loggerViewModel.loggerValDict["MemoryViewModel"] != nil ? Logger.loggerViewModel.loggerValDict["MemoryViewModel"]! : "info",
                    "MicrophoneDevice": Logger.loggerViewModel.loggerValDict["MicrophoneDevice"] != nil ? Logger.loggerViewModel.loggerValDict["MicrophoneDevice"]! : "info",
                    "OverSightGuardian": Logger.loggerViewModel.loggerValDict["OverSightGuardian"] != nil ? Logger.loggerViewModel.loggerValDict["OverSightGuardian"]! : "info",
                    "PreferencesView": Logger.loggerViewModel.loggerValDict["PreferencesView"] != nil ? Logger.loggerViewModel.loggerValDict["PreferencesView"]! : "info",
                    "SettingsService": Logger.loggerViewModel.loggerValDict["SettingsService"] != nil ? Logger.loggerViewModel.loggerValDict["SettingsService"]! : "info",
                    "SystemManager": Logger.loggerViewModel.loggerValDict["SystemManager"] != nil ? Logger.loggerViewModel.loggerValDict["SystemManager"]! : "info",
                    "SystemViewModel": Logger.loggerViewModel.loggerValDict["SystemViewModel"] != nil ? Logger.loggerViewModel.loggerValDict["SystemViewModel"]! : "info",
                    "UserSettingsViewModel": Logger.loggerViewModel.loggerValDict["UserSettingsViewModel"] != nil ? Logger.loggerViewModel.loggerValDict["UserSettingsViewModel"]! : "info",
                ]
                plistData["logger"] = loggerData

                let data = try PropertyListSerialization.data(fromPropertyList: plistData, format: .xml, options: 0)
                try data.write(to: self.devSettingsUrl!)
                Logger.loggerValDict = Logger.loggerViewModel.loggerValDict
                self.logger.info("Saved dev settings succesfully.")
            } catch {
                self.logger.error("Dev log Error: \(error)")
            }
        }
    }

    func createDevSettingsPlist() {
        if !fileManager!.fileExists(atPath: devSettingsUrl!.path) {
            logger.info("Creating default settings")
            writeDevDefaults()
        } else {
            logger.info("Restoring settings")
            readDevPlist()
        }
    }

    func writeDevDefaults() {
        do {
            let loggerData = [
                "APIService": "info",
                "AppManager": "info",
                "AppDelegate": "info",
                "AppViewModel": "info",
                "BatteryManager": "info",
                "CameraDevice": "info",
                "CpuManager": "info",
                "CPUViewModel": "info",
                "DeviceManager": "info",
                "DeviceViewModel": "info",
                "EchoHandler": "info",
                "LoggerViewModel": "info",
                "MemoryManager": "info",
                "MemoryViewModel": "info",
                "MicrophoneDevice": "info",
                "OverSightGuardian": "info",
                "PreferencesView": "info",
                "SettingsService": "info",
                "SystemManager": "info",
                "SystemViewModel": "info",
                "UserSettingsViewModel": "info",
            ]

            let plistData: [String: Any] = [
                "logger": loggerData,
            ]
            let data = try PropertyListSerialization.data(fromPropertyList: plistData, format: .xml, options: 0)
            try data.write(to: devSettingsUrl!)
            logger.info("Created default dev settings")
            readDevPlist()
        } catch {
            logger.error("Error: \(error)")
        }
    }

    func readDevPlist() {
        if devSettingsUrl == nil { return }
        do {
            let data = try Data(contentsOf: devSettingsUrl!)
            guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
                logger.error("Failed to read dev property list.")
                return
            }
            logger.debug("Read dev property list: \(plist)")
            let logger = plist.keys.contains("logger") ? plist["logger"] as! [String: Any] : [String: Any]()
            let apiServiceBool = logger.keys.contains("APIService") ? logger["APIService"] as! String : "info"
            let AppManagerBool = logger.keys.contains("AppManager") ? logger["AppManager"] as! String : "info"
            let AppDelegateBool = logger.keys.contains("AppDelegate") ? logger["AppDelegate"] as! String : "info"
            let AppViewModelBool = logger.keys.contains("AppViewModel") ? logger["AppViewModel"] as! String : "info"
            let BatteryManagerBool = logger.keys.contains("BatteryManager") ? logger["BatteryManager"] as! String : "info"
            let CameraDeviceBool = logger.keys.contains("CameraDevice") ? logger["CameraDevice"] as! String : "info"
            let CpuManagerBool = logger.keys.contains("CpuManager") ? logger["CpuManager"] as! String : "info"
            let CPUViewModelBool = logger.keys.contains("CPUViewModel") ? logger["CPUViewModel"] as! String : "info"
            let DeviceManagerBool = logger.keys.contains("DeviceManager") ? logger["DeviceManager"] as! String : "info"
            let DeviceViewModelBool = logger.keys.contains("DeviceViewModel") ? logger["DeviceViewModel"] as! String : "info"
            let EchoHandlerBool = logger.keys.contains("EchoHandler") ? logger["EchoHandler"] as! String : "info"
            let LoggerViewModelBool = logger.keys.contains("LoggerViewModel") ? logger["LoggerViewModel"] as! String : "info"
            let MemoryManagerBool = logger.keys.contains("MemoryManager") ? logger["MemoryManager"] as! String : "info"
            let MemoryViewModelBool = logger.keys.contains("MemoryViewModel") ? logger["MemoryViewModel"] as! String : "info"
            let MicrophoneDeviceBool = logger.keys.contains("MicrophoneDevice") ? logger["MicrophoneDevice"] as! String : "info"
            let OverSightGuardianBool = logger.keys.contains("OverSightGuardian") ? logger["OverSightGuardian"] as! String : "info"
            let PreferencesViewBool = logger.keys.contains("PreferencesView") ? logger["PreferencesView"] as! String : "info"
            let SettingsServiceBool = logger.keys.contains("SettingsService") ? logger["SettingsService"] as! String : "info"
            let SystemManagerBool = logger.keys.contains("SystemManager") ? logger["SystemManager"] as! String : "info"
            let SystemViewModelBool = logger.keys.contains("SystemViewModel") ? logger["SystemViewModel"] as! String : "info"
            let UserSettingsViewModelBool = logger.keys.contains("UserSettingsViewModel") ? logger["UserSettingsViewModel"] as! String : "info"

            Logger.loggerValDict["APIService"] = apiServiceBool
            Logger.loggerValDict["AppManager"] = AppManagerBool
            Logger.loggerValDict["AppDelegate"] = AppDelegateBool
            Logger.loggerValDict["AppViewModel"] = AppViewModelBool
            Logger.loggerValDict["BatteryManager"] = BatteryManagerBool
            Logger.loggerValDict["CameraDevice"] = CameraDeviceBool
            Logger.loggerValDict["CpuManager"] = CpuManagerBool
            Logger.loggerValDict["CPUViewModel"] = CPUViewModelBool
            Logger.loggerValDict["DeviceManager"] = DeviceManagerBool
            Logger.loggerValDict["DeviceViewModel"] = DeviceViewModelBool
            Logger.loggerValDict["EchoHandler"] = EchoHandlerBool
            Logger.loggerValDict["LoggerViewModel"] = LoggerViewModelBool
            Logger.loggerValDict["MemoryManager"] = MemoryManagerBool
            Logger.loggerValDict["MemoryViewModel"] = MemoryViewModelBool
            Logger.loggerValDict["MicrophoneDevice"] = MicrophoneDeviceBool
            Logger.loggerValDict["OverSightGuardian"] = OverSightGuardianBool
            Logger.loggerValDict["PreferencesView"] = PreferencesViewBool
            Logger.loggerValDict["SettingsService"] = SettingsServiceBool
            Logger.loggerValDict["SystemManager"] = SystemManagerBool
            Logger.loggerValDict["SystemViewModel"] = SystemViewModelBool
            Logger.loggerValDict["UserSettingsViewModel"] = UserSettingsViewModelBool
            Logger.loggerViewModel.updateLoggerValDict(classDict: Logger.loggerValDict)

        } catch {
            logger.error("Error reading dev property list: \(error)")
        }
    }
}
