//
//  DevSettings.swift
//  OverSightGuardian
//
//  Created by kyle on 1/24/24.
//

import Foundation
// not needed
enum DevSettings {
    static var APIService = "info"
    static var AppManager = "info"
    static var AppDelegate = "info"
    static var AppViewModel = "info"
    static var BatteryManager = "info"
    static var CameraDevice = "info"
    static var CpuManager = "info"
    static var CPUViewModel = "info"
    static var DeviceManager = "info"
    static var DeviceViewModel = "info"
    static var EchoHandler = "info"
    static var LoggerViewModel = "info"
    static var MemoryManager = "info"
    static var MemoryViewModel = "info"
    static var MicrophoneDevice = "info"
    static var OverSightGuardian = "info"
    static var SettingsService = "info"
    static var SystemManager = "info"
    static var SystemViewModel = "info"
    static var UserSettingsViewModel = "info"

    static func updateLoggers(APIService: String,
                              AppManager: String,
                              AppDelegate: String,
                              AppViewModel: String,
                              BatteryManager: String,
                              CameraDevice: String,
                              CpuManager: String,
                              CPUViewModel: String,
                              DeviceManager: String,
                              DeviceViewModel: String,
                              EchoHandler: String,
                              LoggerViewModel: String,
                              MemoryManager: String,
                              MemoryViewModel: String,
                              MicrophoneDevice: String,
                              OverSightGuardian: String,
                              SettingsService: String,
                              SystemManager: String,
                              SystemViewModel: String,
                              UserSettingsViewModel: String)
    {
        self.APIService = APIService
        self.AppManager = AppManager
        self.AppDelegate = AppDelegate
        self.AppViewModel = AppViewModel
        self.BatteryManager = BatteryManager
        self.CameraDevice = CameraDevice
        self.CpuManager = CpuManager
        self.CPUViewModel = CPUViewModel
        self.DeviceManager = DeviceManager
        self.DeviceViewModel = DeviceViewModel
        self.EchoHandler = EchoHandler
        self.LoggerViewModel = LoggerViewModel
        self.MemoryManager = MemoryManager
        self.MemoryViewModel = MemoryViewModel
        self.MicrophoneDevice = MicrophoneDevice
        self.OverSightGuardian = OverSightGuardian
        self.SettingsService = SettingsService
        self.SystemManager = SystemManager
        self.SystemViewModel = SystemViewModel
        self.UserSettingsViewModel = UserSettingsViewModel
    }
}
