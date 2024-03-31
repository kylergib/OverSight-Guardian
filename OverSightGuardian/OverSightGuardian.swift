//
//  MacOverSightApp.swift
//  MacOverSight
//
//  Created by kyle on 12/16/23.
//

import AppKit
import NIO
import SwiftUI
import UserNotifications

@main
struct OverSightGuardian: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private var logger = Logger(current: OverSightGuardian.self)

    var body: some Scene {
        MenuBarExtra {
            Button("Show Guide") {
                appDelegate.openGuide()
            }
            Button("Open Preferences") {
                appDelegate.openPreferences()
            }

            Divider()
            Button("Quit") { appDelegate.quitApp() }
        } label: {
            Text("OverSight Guardian")
        }
    }

    func initializeApp() {
        Task {}
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var preferencesWindowController: PreferencesWindowController?
    var settingsService: SettingsService = .settingsService
    @ObservedObject var viewModel: DeviceViewModel = .init()
    @ObservedObject var cpuViewModel: CPUViewModel = .init()
    @ObservedObject var memoryViewModel: MemoryViewModel = .init()
    @ObservedObject var batteryViewModel: BatteryViewModel = .init()

    @ObservedObject var apiViewModel: ApiViewModel = .init()
    @ObservedObject var systemViewModel: SystemViewModel = .init()
    @ObservedObject var userSettingsViewModel: UserSettingsViewModel = SettingsService.settingsService.userSettingsViewModel!
    @ObservedObject var appViewModel: AppViewModel = .init(monitorList: SettingsService.settingsService.userSettingsViewModel!.monitoredApps, quitList: SettingsService.settingsService.userSettingsViewModel!.quitList, reopenList: SettingsService.settingsService.userSettingsViewModel!.reopenList)
    var deviceManager: DeviceManager?
    var memoryManager: MemoryManager?
    var cpuManager: CpuManager?
    var batteryManager: BatteryManager?
    var appManager: AppManager?
    var updateTimer: Timer?
    var apiService: APIService?
    var systemManager: SystemManager?

    private var logger = Logger(current: AppDelegate.self)

    override init() {
        super.init()
        memoryManager = MemoryManager(viewModel: memoryViewModel)
        deviceManager = DeviceManager(viewModel: viewModel)
        cpuManager = CpuManager(viewModel: cpuViewModel)
        batteryManager = BatteryManager(viewModel: batteryViewModel)
        appManager = AppManager(viewModel: appViewModel)

        systemManager = SystemManager(systemViewModel: systemViewModel)
        apiService = APIService(viewModel: apiViewModel)
        apiService?.setManagers(deviceManager: deviceManager!, memoryManager: memoryManager!, cpuManager: cpuManager!, batteryManager: batteryManager!, appManager: appManager!) // TODO: add system manager
    }

    /// NOTE: Called when the application has completed initial launch setup
    func applicationDidFinishLaunching(_ notification: Notification) {

        DispatchQueue.global(qos: .background).async {
            self.logger.debug("Starting timer")
            self.updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in

                self?.logger.debug("checking managers")
                // left off adding logic for monitoring bools
                self?.logger.debug("Monitoring Apps: \(String(describing: SettingsService.settingsService.userSettingsViewModel?.monitorOpenApps))")
                self?.logger.debug("Monitoring Mics: \(String(describing: SettingsService.settingsService.userSettingsViewModel?.monitorMicrophones))")
                self?.logger.debug("Monitoring Cams: \(String(describing: SettingsService.settingsService.userSettingsViewModel?.monitorCameras))")
                self?.logger.debug("Monitoring RAM: \(String(describing: SettingsService.settingsService.userSettingsViewModel?.monitorRam))")

                self?.logger.debug("Monitoring Battery: \(String(describing: SettingsService.settingsService.userSettingsViewModel?.monitorBattery))")
                self?.logger.debug("Monitoring CPU: \(String(describing: SettingsService.settingsService.userSettingsViewModel?.monitorCpu))")

                if SettingsService.settingsService.userSettingsViewModel?.monitorCpu ?? true {
                    self?.cpuManager?.getCpuInfo()
                }
                if SettingsService.settingsService.userSettingsViewModel?.monitorOpenApps ?? true {
                    self?.appManager?.getApps()
                }

                if SettingsService.settingsService.userSettingsViewModel?.monitorMicrophones ?? true {
                    self?.deviceManager?.getAudioInputDevices()
                }
                if SettingsService.settingsService.userSettingsViewModel?.monitorCameras ?? true {
                    self?.deviceManager?.getVideoInputDevices()
                }

                if SettingsService.settingsService.userSettingsViewModel?.monitorRam ?? true {
                    self?.memoryManager?.getMemory()
                }
//                self?.cpuManager?.getCpuUsagePerCore()
                if SettingsService.settingsService.userSettingsViewModel?.monitorBattery ?? true && self?.batteryManager?.hasBattery ?? true {
                    self?.batteryManager?.getBatteryDetails()
                }

                self?.systemManager?.getVolumeData()
                self?.systemManager?.updateSystem()
            }
            if self.updateTimer != nil {
                RunLoop.current.add(self.updateTimer!, forMode: .default)
                RunLoop.current.run()
            }
        }
        logger.debug("API on Startup: \(userSettingsViewModel.startApiOnStartup)")
        if userSettingsViewModel.startApiOnStartup {
            DispatchQueue.global(qos: .background).async {
                self.apiService?.tryServer()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        updateTimer?.invalidate()
    }


    /// NOTE: Marked with @objc to allow it to be used as a selector for menu actions.
    @objc func openPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(viewModel: viewModel, cpuViewModel: cpuViewModel, memoryViewModel: memoryViewModel, batteryViewModel: batteryViewModel, appViewModel: appViewModel, apiViewModel: apiViewModel, userSettingsViewModel: userSettingsViewModel, systemViewModel: systemViewModel)
        }
        preferencesWindowController?.showWindow(true)
        // Note: brings the application to the foreground.
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openGuide() {
        openPreferences()
        userSettingsViewModel.updateTabSelection(selection: 1)
        userSettingsViewModel.updateGuideCount(count: 0)
    }

    /// NOTE: Marked with @objc to allow it to be used as a selector for menu actions.
    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
}
