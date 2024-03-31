//
//  PreferencesView.swift
//  MacOverSight
//
//  Created by kyle on 12/20/23.
//

// TODOa
// TODO: empty stale data when disabling monitoring? -> for now it just says monitoring is disabled
import SwiftUI

struct PreferencesView: View {
    private var logger = Logger(current: PreferencesView.self)
    @ObservedObject var viewModel: DeviceViewModel
    @ObservedObject var cpuViewModel: CPUViewModel
    @ObservedObject var memoryViewModel: MemoryViewModel
    @ObservedObject var batteryViewModel: BatteryViewModel
    @ObservedObject var appViewModel: AppViewModel
    @ObservedObject var apiViewModel: ApiViewModel
    @ObservedObject var userSettingsViewModel: UserSettingsViewModel
    @ObservedObject var systemViewModel: SystemViewModel
    @ObservedObject var loggerViewModel: LoggerViewModel
//    @State private var tabSelection = 1
    @State private var openAppSelection: String?
    @State private var monitoredAppSelection: String?
    @State private var showAppSettingsDropdown = false
    @State private var errorText = ""
//    @State private var infoShowingPopover = false
//    @State private var infoShowingPopoverText = ""
    @State private var infoShowingPopoverDict: [String: Bool] = [:]
    
    @State private var appNameDropDown: String = ""
    @State private var textFieldsData: [String: String] = [:]
    @State private var focusStates: [String: Bool] = [:]
    @State private var autoOpenOnQuitData: [String: String] = [:]
    @State private var autoOpenOnQuit: [String: Bool] = [:]
    @FocusState private var focusedField: String?
    @State private var saveSettingsLabelFocus = ""
    @State private var classLogLevelValid: [String: Bool] = [:]
    var levelList = ["info", "debug", "fine", "finer", "finest"]
    @State var invalidLevelSet = Set<String>()
//    @Binding var scrolledID String?
    @State private var scrolledID: String?
    @State private var autoScroll: Bool = true
    @State private var lastGuideNum: Int = 13
#if NON_SANDBOXED
    @State private var guideText = [
        "Thank you for downloading OverSight Guardian!",
        "Here you can view camera information.",
        "Here you can view microphone information.",
        "This displays the usage percentage for each core of your CPU.",
        "This section provides information about your system.",
        "If your Mac has a battery:\nOn the left, you'll find battery information. Click on each icon for more details.",
        "On the right is a button to enable/disable the API,\nalong with the port number it's running on, if enabled.",
        "Click the 'Apps' button at the top to view information about applications.",
        "Here you can see which apps are currently open.\nClick the plus icon to add them to your monitor list.",
        "This section allows you to monitor apps, quickly check if they are open, and view their RAM usage.\nClick the gear icon to access additional options, such as automatically quitting the app when it reaches a specific RAM usage amount.\nYou can also set the app to reopen automatically after it is closed,\nbut you must provide the path to the application.",
        "Click on 'Settings' to adjust your preferences.",
        "On this page, you can view a list of settings.\nClick the 'i' icon next to a setting for a brief description.",
        "On the right is a list of log messages for the app.",
        "Clicking the 'C' icon in the upper right-hand corner will clear the logs.\nClicking the 'A' icon will toggle whether the list of logs automatically scrolls."
    ]
#else
    @State private var guideText = [
        "Thank you for downloading OverSight Guardian!",
        "Here you can view camera information.",
        "Here you can view microphone information.",
        "This displays the usage percentage for each core of your CPU.",
        "This section provides information about your system.",
        "If your Mac has a battery:\nOn the left, you'll find battery information. Click on each icon for more details.",
        "On the right is a button to enable/disable the API,\nalong with the port number it's running on, if enabled.",
        "Click the 'Apps' button at the top to view information about applications.",
        "Here you can see which apps are currently open.\nClick the plus icon to add them to your monitor list.",
        "This section allows you to monitor apps and quickly check if they are open.\nClick the gear icon, then 'Remove' to delete an app from the monitor list.",
        "Click on 'Settings' to adjust your preferences.",
        "On this page, you can view a list of settings.\nClick the 'i' icon next to a setting for a brief description.",
        "On the right is a list of log messages for the app.",
        "Clicking the 'C' icon in the upper right-hand corner will clear the logs.\nClicking the 'A' icon will toggle whether the list of logs automatically scrolls."
    ]
#endif
    private var guideOpacity = 0.70
    
    private var customFont: Font = .system(size: 18, weight: .bold, design: .default)
    private let colWidth = CGFloat(200)
    let imageHeight = 20
    let windowHeight = CGFloat(540)
    let windowWidth = CGFloat(960)
    var tabHeight: CGFloat
    var tabWidth: CGFloat
    
    init(viewModel: DeviceViewModel, cpuViewModel: CPUViewModel, memoryViewModel: MemoryViewModel, batteryViewModel: BatteryViewModel, appViewModel: AppViewModel,
         apiViewModel: ApiViewModel, userSettingsViewModel: UserSettingsViewModel, systemViewModel: SystemViewModel)
    {
        self.viewModel = viewModel
        self.cpuViewModel = cpuViewModel
        self.memoryViewModel = memoryViewModel
        self.batteryViewModel = batteryViewModel
        self.appViewModel = appViewModel
        self.apiViewModel = apiViewModel
        self.userSettingsViewModel = userSettingsViewModel
        self.systemViewModel = systemViewModel
        loggerViewModel = Logger.loggerViewModel
        tabHeight = windowHeight - 150
        tabWidth = windowWidth - 150
    }
    // TODO: refactor this into separate classes.
    var body: some View {
        
        ZStack {
            VStack {
                // hstack is the tabs at top of window
                HStack {
                    
                    Button(action: {
                        userSettingsViewModel.tabSelection = 1
                    }) {
                        Text("System")
                            .padding(0)
                        
                            .cornerRadius(8)
                    }
                    .background(userSettingsViewModel.tabSelection == 1 ? Color(NSColor.controlColor) : Color.clear)
                    .padding(0)
                    .cornerRadius(8)
                    .overlay(userSettingsViewModel.guideCount != -1 ? Color.black.opacity(guideOpacity) : Color.clear)
                    
                    // Second button
                    Button(action: {
                        userSettingsViewModel.tabSelection = 2
                    }) {
                        Text("Apps")
                            
                            .foregroundColor(userSettingsViewModel.guideCount == 7 ? Color.black : Color.white)
                            .padding(0)
                        
                            .cornerRadius(8)
                    }
                    
                    .background(userSettingsViewModel.tabSelection == 2 ? Color(NSColor.controlColor) : userSettingsViewModel.guideCount == 7 ? Color.blue : Color.clear)
                    .padding(0)
                    .cornerRadius(8)
                    .overlay(userSettingsViewModel.guideCount == -1 || userSettingsViewModel.guideCount == 7 ? Color.clear : Color.black.opacity(guideOpacity)
                    )

                    Button(action: {
                        userSettingsViewModel.tabSelection = 3
                    }) {
                        Text("Settings")
                            .foregroundColor(userSettingsViewModel.guideCount == 10 ? Color.black : Color.white)
                            .padding(0)
                        
                            .cornerRadius(8)
                    }
                    .background(userSettingsViewModel.tabSelection == 3 ? Color(NSColor.controlColor) : userSettingsViewModel.guideCount == 10 ? Color.blue : Color.clear)
                    .cornerRadius(8)
                    .padding(0)
                    .overlay(userSettingsViewModel.guideCount == -1 || userSettingsViewModel.guideCount == 10 ? Color.clear : Color.black.opacity(guideOpacity))
                    // fourth action, only if dev mode is enabled
                    if userSettingsViewModel.devModeEnabled {
                        Button(action: {
                            userSettingsViewModel.tabSelection = 4
                        }) {
                            Text("Dev")
                                .padding(0)
                                .cornerRadius(8)
                        }
                        .background(userSettingsViewModel.tabSelection == 4 ? Color(NSColor.controlColor) : Color.clear)
                        .padding(0)
                        .cornerRadius(8)
                        .overlay(userSettingsViewModel.guideCount != -1 ? Color.black.opacity(guideOpacity) : Color.clear)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 10)
                Spacer()
                // this hstack is the content that will be displayed depending on what tabSelection is set to
                HStack {
                    if userSettingsViewModel.tabSelection == 1 {
                        createDeviceStack()
                    } else if userSettingsViewModel.tabSelection == 2 {
                        createApps()
                    } else if userSettingsViewModel.tabSelection == 3 {
                        VStack {
                            Text("Changing anything on this screen will take effect immediately.")

                                .font(.subheadline)
                            Text("Changes will not be saved if you quit the app without clicking save first.")
                                .font(.subheadline)
                            
                            HStack {
                                createSettings()
                                createLog()
                            }
                            let savedImage = userSettingsViewModel.statusBool ? "hand.thumbsup.fill" : "hand.thumbsdown.fill"
                            let color = userSettingsViewModel.statusBool ? Color.green : Color.red
                            if userSettingsViewModel.showStatus && userSettingsViewModel.tabSelection == 3 {
                                HStack {
                                    Text(userSettingsViewModel.statusText)
                                        .foregroundStyle(color)
                                    Image(systemName: savedImage)
                                        .foregroundStyle(color)
                                }
                            } else {
                                HStack {
                                    Text("hidden text")
                                        .hidden()
                                }
                            }
                        }
                    } else if userSettingsViewModel.tabSelection == 4 {
                        HStack {
                            createDevSettings()
                            Spacer()
                            createDevLog()
                        }
                    }
                }
                .frame(width: tabWidth, height: tabHeight)

                Spacer()
                // this it the bottom where battery stats, API port int, API disable/enable button are located
                bottomBarStack()
            }
            .frame(width: windowWidth, height: windowHeight)
            .padding(.bottom, 10)
            .background(userSettingsViewModel.guideCount != -1 ? .black.opacity(guideOpacity) : Color.clear)
            .zIndex(0)
            // if guideCount is NOT -1 then it will show the guide and walk through it.
            if userSettingsViewModel.guideCount != -1 {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            logger.debug("Skip")
                            userSettingsViewModel.guideCount = -1
                        } label: {
                            Text("Skip")
                        }
                    }
                    .padding()
                    Spacer()
                    HStack {
                        Button {
                            logger.debug("back")
                            userSettingsViewModel.guideCount -= 1
                            checkTabSelection()
                        } label: {
                            Text("Back")
                        }
                        .disabled(userSettingsViewModel.guideCount < 1)
                        
                        Spacer()
                        Button {
                            logger.debug("next/finish")
                            if userSettingsViewModel.guideCount == lastGuideNum {
                                userSettingsViewModel.guideCount = -1
                                userSettingsViewModel.tabSelection = 3
                            } else {
                                userSettingsViewModel.guideCount += 1
                                checkTabSelection()
                            }
                            
                        } label: {
                            Text(userSettingsViewModel.guideCount == lastGuideNum ? "Finish" : "Next")
                        }
                    }
                    .padding()
                }
                .zIndex(1)
                
                VStack {
                    if userSettingsViewModel.guideCount != 5 && userSettingsViewModel.guideCount != 6 {
                        Spacer()
                    }
                    if userSettingsViewModel.guideCount != -1 && guideText.count > userSettingsViewModel.guideCount {
                        Text(guideText[userSettingsViewModel.guideCount])
                            .font(.title)
                            .frame(alignment: .center)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.black)
                            .padding(10)
                            
                            .background(Color(NSColor.systemBlue))
                            .cornerRadius(15)
                    }
                }
                .zIndex(2)
                .padding(.bottom, userSettingsViewModel.guideCount == 9 ? 50 : 25)
            }
        }
    }

    func checkTabSelection() {
        // TODO: could be a switch statement?
        if userSettingsViewModel.guideCount < 8 {
            userSettingsViewModel.tabSelection = 1
        } else if userSettingsViewModel.guideCount >= 8 && userSettingsViewModel.guideCount < 11 {
            userSettingsViewModel.tabSelection = 2
        } else if userSettingsViewModel.guideCount >= 11 {
            userSettingsViewModel.tabSelection = 3
        }
    }
    
    // creates an return a view of an image/label so all battery stats at bottom have same style
    func batteryImageInfo(message: String, id: String, image: String? = nil, text: String? = nil, color: Color) -> some View {
        return Button {
            self.infoShowingPopoverDict[id] = true
        } label: {
            if image != nil {
                Image(systemName: image!)
                    .foregroundStyle(color)
                    .imageScale(.large)
            } else if text != nil {
                Text(text!)
                    .foregroundStyle(color)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: Binding(
            get: { self.infoShowingPopoverDict[id, default: false] },
            set: { self.infoShowingPopoverDict[id] = $0 }
        )) {
            Text(message)
                .font(.headline)
                .padding()
        }
    }

    func bottomBarStack() -> some View {
        ZStack {
            HStack {
                if batteryViewModel.hasBattery && userSettingsViewModel.monitorBattery {
                    HStack {
                        // TODO: take all colors and create a new file with hard coded colors, so it is easier to change?
                        let chargingText = batteryViewModel.isCharging! ? "Battery Charging" : "Battery Not Charging"
                        let chargingImage = batteryViewModel.isCharging! ? "bolt.batteryblock" : "batteryblock"
                        let chargingColor = batteryViewModel.isCharging! ? Color.green : Color.red
                        let capacityColor = batteryViewModel.currentCapacity! > 79 ? Color.green : batteryViewModel.currentCapacity! > 50 ? Color.yellow : batteryViewModel.currentCapacity! > 25 ? Color.orange : Color.red
                        let healthColor = batteryViewModel.batteryHealth! == "Good" ? Color.green : Color.red
                        let powerSource = batteryViewModel.powerSourceState! == "AC Power"
                        Text("Battery Stats:")
                        batteryImageInfo(message: chargingText, id: "isCharging", image: chargingImage, color: chargingColor)
                        //
                        batteryImageInfo(message: "Battery Capacity", id: "capacity", text: "\(batteryViewModel.currentCapacity!)%", color: capacityColor)
                        //
                        batteryImageInfo(message: "Battery Health: \(batteryViewModel.batteryHealth!)", id: "health", image: "cross.case.circle", color: healthColor)
                        if batteryViewModel.lpmActive! {
                            batteryImageInfo(message: "Low Power Mode Enabled", id: "lpm", text: "LPM", color: Color.yellow)
                        }
                        if powerSource {
                            batteryImageInfo(message: "Connected to AC Power", id: "powerSource", image: "powercord.fill", color: Color.white)
                        }
                        if batteryViewModel.timeToEmpty! > 0 {
                            batteryImageInfo(message: "Time till empty", id: "empty", text: "-\(parseTime(time: batteryViewModel.timeToEmpty!))", color: Color.yellow)
                        }
                        if batteryViewModel.timeToFullCharge! > 0 {
                            batteryImageInfo(message: "Time till full", id: "full", text: "-\(parseTime(time: batteryViewModel.timeToFullCharge!))", color: Color.yellow)
                        }
            
                        Spacer()
                        
                    }
                    .padding()
                } else {
                    HStack {
                        Text("Battery monitoring is disabled")
                        Spacer()
                    }
                    .padding()
                }
                HStack {
                    batteryImageInfo(message: "Connections to API", id: "numConnections", text: "\(apiViewModel.numConnections)", color: Color.white)
                    let buttonText = apiViewModel.apiRunning ? "Disable" : "Enable"
                    
                    Button(buttonText) {
                        if buttonText == "Disable" { apiViewModel.shutdownApi() } else { apiViewModel.enableApi() }
                    }
                    .accessibilityIdentifier("MainContentView")
                    Text(apiViewModel.apiRunning ? "Port: \(apiViewModel.port.map { String($0) } ?? "-1")" : "API Disabled")
                        .foregroundColor(apiViewModel.apiRunning ? Color.green : Color.red)
                }
                .padding()
            }
            .frame(width: tabWidth)
            .background(Color(Color(NSColor.controlBackgroundColor)))
            .cornerRadius(15)
            
            if userSettingsViewModel.guideCount != 5 && userSettingsViewModel.guideCount != 6 && userSettingsViewModel.guideCount != -1 {
              
                Rectangle()
                    .frame(width: tabWidth)
                    .frame(height: 52)
                    .foregroundColor(.black.opacity(guideOpacity))
                    .edgesIgnoringSafeArea(.all)
                    .cornerRadius(15)
//
                
                    .zIndex(5)
            } else if userSettingsViewModel.guideCount == 5 || userSettingsViewModel.guideCount == 6 {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: tabWidth)
                    .frame(height: 52)
                    .foregroundColor(.white.opacity(0.0))
                    .zIndex(5)
            }
        }
    }
    // creates the webcams/mics on tab selection 1
    func createDeviceStack() -> some View {
        HStack {
            VStack {
                ZStack {
                    if userSettingsViewModel.monitorCameras {
                        createInputs(viewModel.cameraInfos)
                            .cornerRadius(15)
                            .zIndex(0)
                    } else {
                        List {}
                            .zIndex(0)
                            .cornerRadius(15)
                            .id("systemView")
                    
                        Text("Camera monitoring is disabled")
                            .zIndex(1)
                            .padding()
                    }
                    if userSettingsViewModel.guideCount != 1 && userSettingsViewModel.guideCount != -1 {
                        Rectangle()
                            .foregroundColor(.black.opacity(guideOpacity))
                            .edgesIgnoringSafeArea(.all)
                            .cornerRadius(15)
                            .zIndex(5)
                    } else if userSettingsViewModel.guideCount == 1 {
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.blue, lineWidth: 3)
                            .foregroundColor(.white.opacity(0.0))
                            .zIndex(5)
                    }
                    
                    if !viewModel.receivedCameraConfigs && userSettingsViewModel.monitorCameras {
                        Text("Waiting on device service")
                            .zIndex(2)
                                                
                        Rectangle()
                            .foregroundColor(.black.opacity(0.9))
                            .edgesIgnoringSafeArea(.all)
                            .cornerRadius(15)
                            .zIndex(1)
                    }
                }
                Spacer()
                ZStack {
                    if userSettingsViewModel.monitorMicrophones {
                        createInputs(viewModel.microhphoneInfos)
                            .cornerRadius(15)
                            .zIndex(0)
                            .opacity(userSettingsViewModel.monitorMicrophones ? 1.0 : 0.0)
                        
                    } else {
                        List {}
                            .zIndex(0)
                            .cornerRadius(15)
                        Text("Microphone monitoring is disabled")
                            .zIndex(1)
                            .padding()
                            .cornerRadius(15)
                            .background(Color(Color(NSColor.controlBackgroundColor)))
                    }
                    if userSettingsViewModel.guideCount != 2 && userSettingsViewModel.guideCount != -1 {
                        Rectangle()
                            .foregroundColor(.black.opacity(guideOpacity))
                            .edgesIgnoringSafeArea(.all)
                            .cornerRadius(15)
                            .zIndex(5)
                    } else if userSettingsViewModel.guideCount == 2 {
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.blue, lineWidth: 3)
                            .foregroundColor(.white.opacity(0.0))
                            .zIndex(5)
                    }
                    if !viewModel.receivedMicrophoneConfigs && userSettingsViewModel.monitorMicrophones {
                        Text("Waiting on device service")
                            .zIndex(2)
                                                
                        Rectangle()
                            .foregroundColor(.black.opacity(0.9))
                            .edgesIgnoringSafeArea(.all)
                            .cornerRadius(15)
                            .zIndex(1)
                    }
                }
            }
            .frame(width: userSettingsViewModel.monitorCpu ? tabWidth / 2 : tabWidth / 1.5)
            .zIndex(0)
            
            if userSettingsViewModel.monitorCpu {
                Spacer()
                ZStack {
                    VStack(alignment: .center) {
                        List(cpuViewModel.cpuCoresInfos, id: \.name) { info in
                            HStack {
                                Text(info.name)
                                Spacer()
                                Text("\(String(format: "%.2f%%", info.percent))")
                            }
                        }
                    }
                    .frame(width: tabWidth / 6)
                    .cornerRadius(15)
                    if userSettingsViewModel.guideCount != 3 && userSettingsViewModel.guideCount != -1 {
                        Rectangle()
                            .frame(width: tabWidth / 6)
                            .foregroundColor(.black.opacity(guideOpacity))
                            .edgesIgnoringSafeArea(.all)
                            .cornerRadius(15)
                            .zIndex(5)
                    } else if userSettingsViewModel.guideCount == 3 {
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.blue, lineWidth: 3)
                            .frame(width: tabWidth / 6)
                            .foregroundColor(.white.opacity(0.0))
                            .zIndex(5)
                    }
                }
            }
            Spacer()
            ZStack {
                VStack {
                    Spacer()
                    systemStatsStack()
                    Spacer()
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(15)
                if userSettingsViewModel.guideCount != 4 && userSettingsViewModel.guideCount != -1 {
                    Rectangle()
                        .foregroundColor(.black.opacity(guideOpacity))
                        .edgesIgnoringSafeArea(.all)
                        .cornerRadius(15)
                        .zIndex(5)
                } else if userSettingsViewModel.guideCount == 4 {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.blue, lineWidth: 3)
                        .foregroundColor(.white.opacity(0.0))
                        .zIndex(5)
                }
            }
        }
    }

    func systemStatsStack() -> some View {
        VStack {
            VStack {
                Text("OS: \(systemViewModel.osVersion)")
                Text("System Up Time: \(systemViewModel.systemUpTimeString)")
                Text("Host Name: \(systemViewModel.hostName)")
                Text("App Version: \(userSettingsViewModel.appVersion)")
            }
            Spacer()
            Divider()
            Spacer()
            VStack {
                Text("Total Storage (GB): \(systemViewModel.totalCapacity)")
                Text("Available Storage (GB): \(systemViewModel.availableCapacity)")
                Text("Used Storage (GB): \(systemViewModel.usedCapacity)")
            }
            Spacer()
            Divider()
            Spacer()
            VStack {
                Text("CPU Cores: \(systemViewModel.processorCount)")
                if userSettingsViewModel.monitorCpu {
                    Text("System: \(String(format: "%.2f%%", cpuViewModel.systemCpuInfo!.percent))")
                    Text("User: \(String(format: "%.2f%%", cpuViewModel.userCpuInfo!.percent))")
                    Text("Idle: \(String(format: "%.2f%%", cpuViewModel.idleCpuInfo!.percent))")
                } else {
                    Spacer()
                    Text("CPU Monitoring is disabled")
                    Spacer()
                }
            }
            Spacer()
            Divider()
            Spacer()
            VStack {
                Text("Total RAM: \(systemViewModel.physicalMemory)")
                if userSettingsViewModel.monitorRam {
                    Text("Total Used: \(String(format: "%.2f GB", memoryViewModel.totalMemory.percent))")
                    Text("App Used \(String(format: "%.2f GB", memoryViewModel.appMemory.percent))")
                    Text("Compressed \(String(format: "%.2f GB", memoryViewModel.compressedRam.percent))")
                    Text("Active \(String(format: "%.2f GB", memoryViewModel.activeRam.percent))")
                    Text("Wired \(String(format: "%.2f GB", memoryViewModel.wiredRam.percent))")
                } else {
                    Spacer()
                    Text("RAM Monitoring is disabled")
                    Spacer()
                }
            }
        }
    }
    
//    func createSystemInfo() -> some View {
//        VStack {
//            Text("# CPU Cores: \(systemViewModel.processorCount)")
//            Text("Total RAM: \(systemViewModel.physicalMemory) GB")
//            Text("OS Version: \(systemViewModel.osVersion)")
//           
//            Text("System Up Time: \(systemViewModel.systemUpTimeString)")
//            Text("Host Name: \(systemViewModel.hostName)")
//            Text("Total Storage (GB): \(systemViewModel.totalCapacity)")
//            Text("Available Storage (GB): \(systemViewModel.availableCapacity)")
//            Text("Used Storage (GB): \(systemViewModel.usedCapacity)")
//        }
//    }
   
    func createRamStack() -> some View {
        VStack {
            HStack {
                Text("RAM Stats")
                    .frame(width: colWidth, alignment: .center)
                    .font(customFont)
            }
            .frame(width: 300)
            .padding(.bottom, 20)
                                    
            HStack {
                Text("\(memoryViewModel.totalMemory.name) \(String(format: "%.2f GB", memoryViewModel.totalMemory.percent))")
                    //                                .frame(width: colWidth, alignment: .center)
                    .font(customFont)
                                        
            }.frame(width: 300)
            HStack {
                Text("\(memoryViewModel.appMemory.name) \(String(format: "%.2f GB", memoryViewModel.appMemory.percent))")
                    //                                .frame(width: colWidth, alignment: .center)
                    .font(customFont)
                                        
            }.frame(width: 300)
            HStack {
                Text("\(memoryViewModel.compressedRam.name) \(String(format: "%.2f GB", memoryViewModel.compressedRam.percent))")
                    //                                .frame(width: colWidth, alignment: .center)
                    .font(customFont)
                                        
            }.frame(width: 300)
            HStack {
                Text("\(memoryViewModel.activeRam.name) \(String(format: "%.2f GB", memoryViewModel.activeRam.percent))")
                    //                                .frame(width: colWidth, alignment: .center)
                    .font(customFont)
                                        
            }.frame(width: 300)
            HStack {
                Text("\(memoryViewModel.wiredRam.name) \(String(format: "%.2f GB", memoryViewModel.wiredRam.percent))")
                    //                                .frame(width: colWidth, alignment: .center)
                    .font(customFont)
                                        
            }.frame(width: 300)
            Spacer()
                                    
        }.frame(alignment: .top)
    }
    
    func createSetupCpuCores() -> some View {
        return VStack {
            HStack {
                Text("CPU Stats")
                    .frame(width: colWidth, alignment: .center)
                    .font(customFont)
                
            }.frame(width: 300)
                .padding(.bottom, 20)
            HStack {
                Text("\(cpuViewModel.idleCpuInfo!.name) \(String(format: "%.2f%%", cpuViewModel.idleCpuInfo!.percent))")
                    .frame(width: colWidth, alignment: .center)
                    .font(customFont)
                
            }.frame(width: 300)
            
            HStack {
                Text("\(cpuViewModel.userCpuInfo!.name) \(String(format: "%.2f%%", cpuViewModel.userCpuInfo!.percent))")
                    .frame(width: colWidth, alignment: .leading)
                    .font(customFont)
                Spacer()
                
                Text("\(cpuViewModel.systemCpuInfo!.name) \(String(format: "%.2f%%", cpuViewModel.systemCpuInfo!.percent))")
                    //                        .frame(width: 150, alignment: .leading)
                    .frame(width: colWidth, alignment: .trailing)
                    .font(customFont)
            }
            .frame(width: colWidth * 2)
        }
    }
    // enables the drop down for the app settings in monitor list
    func updateFocusState(appName: String) {
        focusStates[appName] = appViewModel.quitList.keys.contains(appName)
        textFieldsData[appName] = "\(appViewModel.quitList[appName] ?? 0)"
        autoOpenOnQuit[appName] = appViewModel.reopenList.keys.contains(appName)
        autoOpenOnQuitData[appName] = "\(appViewModel.reopenList[appName] ?? "")"
    }

    func createApps() -> some View {
        HStack {
            VStack {
                Text("Opened Apps")
                if userSettingsViewModel.monitorOpenApps {
                    ZStack {
                        List(appViewModel.openApps, id: \.self) { app in
                            HStack {
                                Text(app)
                                    .id("appView")
                                Spacer()
                                    
                                Button {
                                    logger.info("Add To Monitor List: \(app)")
                                    appViewModel.addToMonitorList(with: app)
                                        
                                } label: {
                                    Image(systemName: "plus.square")
                                        .imageScale(.large)
                                }
                                .disabled(appViewModel.monitorList.contains(app))
                                .foregroundStyle(appViewModel.monitorList.contains(app) ? Color.white : Color.green)
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .cornerRadius(15)
                        if userSettingsViewModel.guideCount != 8 && userSettingsViewModel.guideCount != -1 {
                            Rectangle()
                                .foregroundColor(.black.opacity(guideOpacity))
                                .edgesIgnoringSafeArea(.all)
                                .cornerRadius(15)
                                //
                                        
                                .zIndex(5)
                        } else if userSettingsViewModel.guideCount == 8 {
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.blue, lineWidth: 3)
                                .foregroundColor(.white.opacity(0.0))
                                .zIndex(5)
                        }
                    }
                } else {
                    ZStack {
                        List {}
                            .cornerRadius(15)
                            .zIndex(0)
                        Text("Open app monitoring is disabled")
                            .zIndex(1)
                            .padding()
                    }
                }
            }
            .padding()
            .zIndex(0)
                
            VStack {
                Text("Monitored Apps")
                ZStack {
                    List(appViewModel.monitorList.sorted(by: { $0 < $1 }), id: \.self) { appName in
                        
                        ZStack(alignment: .topTrailing) {
                            HStack {
                                Text(appName)
                                
                                Spacer()
                                
                                let info = appViewModel.monitoredInfos[appName]
                                if info != nil && userSettingsViewModel.monitorOpenApps {
                                    let appUnknown = info?.startTime == nil
                                    let appOpen = !appUnknown && info?.startTime! == appViewModel.lastMonitoredCheck
                                    let isOpenString = appUnknown ? "Unknown" : appOpen ? "Open" : "Closed"
#if NON_SANDBOXED
                                    let ramUsage = !appOpen || info?.ramUsage == nil ? "" : info!.ramUsage >= 1024 ? String(format: "%.2f GB", info!.ramUsage / 1024) : String(format: "%.0f MB", info!.ramUsage)
                                    Text(ramUsage)
#endif
                                    
                                    Text(isOpenString)
                                }
#if NON_SANDBOXED
                                Image(systemName: "q.square")
                                    .foregroundStyle(appViewModel.quitAppList.contains(appName) ? Color.green : Color.white)
                                    .imageScale(.large)
                                Image(systemName: "r.square")
                                    .foregroundStyle(appViewModel.reopenList.keys.contains(appName) ? Color.green : Color.white)
                                    .imageScale(.large)
#endif
                                Button {
                                    logger.debug("Opened Settings for: \(appName)")
                                    if showAppSettingsDropdown && appNameDropDown == appName {
                                        showAppSettingsDropdown = false
                                        return
                                    }
                                    showAppSettingsDropdown = false
                                    if self.textFieldsData[appNameDropDown] == "" {
                                        self.textFieldsData[appNameDropDown] = "0"
                                    }
                                    appNameDropDown = ""
                                    
                                    appNameDropDown = appName
                                    showAppSettingsDropdown.toggle()
                                    
                                } label: {
                                    Image(systemName: "gear")
                                        .imageScale(.large)
                                    
                                }.buttonStyle(PlainButtonStyle())
                            }
                            .foregroundColor(showAppSettingsDropdown && appNameDropDown == appName ? Color.blue : Color.white)
                            .onAppear {
                                updateFocusState(appName: appName)
                            }
                            VStack {
                                if showAppSettingsDropdown && appNameDropDown == appName {
                      
                                    
                                    HStack {
#if NON_SANDBOXED
                                        Toggle("Automatically quit when at/above: ", isOn: Binding(
                                            get: { self.focusStates[appName, default: false] },
                                            set: { self.focusStates[appName] = $0 }
                                        ))
                                        .toggleStyle(.checkbox)
                                        .onChange(of: self.focusStates[appName]) {
                                            logger.debug("\(self.focusStates[appName] as Any)")
                                        }
                                        
                                        TextField("", text: Binding(
                                            get: { self.textFieldsData[appName, default: ""] },
                                            set: { self.textFieldsData[appName] = String($0.filter { "0123456789".contains($0) }) }
                                        ))
                                        
                                        .focused($focusedField, equals: appName)
                                        .frame(width: 75)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        Text("MB")
#endif
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    .transition(.opacity)
                                    .padding(.top, 35)
#if NON_SANDBOXED
                                    HStack {
                                        Toggle("Automatically open after quit?", isOn: Binding(
                                            get: { self.autoOpenOnQuit[appName, default: false] },
                                            set: { self.autoOpenOnQuit[appName] = $0 }
                                        ))
                                        .toggleStyle(.checkbox)
                                        .onChange(of: self.autoOpenOnQuit[appName]) {
                                            logger.debug("\(self.focusStates[appName] as Any)")
                                        }
                                    }.frame(maxWidth: .infinity, alignment: .leading)
                                    
                                        .transition(.opacity)
                                    
                                    HStack {
                                        Text("App Path:")
                                        TextField("", text: Binding(
                                            get: { self.autoOpenOnQuitData[appName, default: ""] },
                                            set: { self.autoOpenOnQuitData[appName] = $0 }
                                        ))
                                        
                                        .focused($focusedField, equals: appName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    .transition(.opacity)
#endif
                                    HStack {
                                        Spacer()
                                        Button {
                                            self.appViewModel.removeFromQuitList(appName: appName)
                                            self.appViewModel.removeFromReopenList(appName: appName)
                                            self.appViewModel.removeFromMonitorList(with: appName)
                                            showAppSettingsDropdown = false
                                            appNameDropDown = ""
                                            
                                        } label: {
                                            Text("Remove from list")
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .foregroundStyle(Color.red)
#if NON_SANDBOXED
                                        Button {
                                            let invalidMB = self.textFieldsData[appName] == nil || Double(self.textFieldsData[appName]!) ?? 0.0 < 1
                                            
                                            if self.focusStates[appName] == nil { return }
                                            if self.focusStates[appName]!, invalidMB { return }
                                            
                                            let quitMB = Int(self.textFieldsData[appName] ?? "0") ?? 0
                                            
                                            self.userSettingsViewModel.updateQuitInfo(appName: appName, quitAutomatically: self.focusStates[appName] ?? false, quitMB: quitMB)
                                            logger.debug("Value is: \(self.focusStates[appName]!) for \(appName)")
                                            if self.focusStates[appName]! {
                                                self.appViewModel.addToQuitList(appName: appName, quitMB: quitMB)
                                            } else {
                                                self.appViewModel.removeFromQuitList(appName: appName)
                                            }
                                            
                                            let path = self.autoOpenOnQuitData[appName] ?? ""
                                            if path != "", self.autoOpenOnQuit[appName] != nil {
                                                self.userSettingsViewModel.updateReopenAutomatically(appName: appName, reopenAutomatically: self.autoOpenOnQuit[appName] ?? false, path: path)
                                                
                                                if self.autoOpenOnQuit[appName]! {
                                                    self.appViewModel.addToReopenList(appName: appName, path: path)
                                                } else {
                                                    self.appViewModel.removeFromReopenList(appName: appName)
                                                }
                                            }
                                            if self.textFieldsData[appName] == "" {
                                                self.textFieldsData[appName] = "0"
                                            }
                                            showAppSettingsDropdown = false
                                            appNameDropDown = ""
                                            
                                        } label: {
                                            HStack {
                                                Text("Save settings")
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .foregroundStyle(Color.green)
#endif
                                    }.frame(maxWidth: .infinity, alignment: .leading)
                                        .transition(.opacity)
                                }
                            }
                        }
                    }
                    .cornerRadius(15)
                    .zIndex(0)
                    
                    if userSettingsViewModel.guideCount != 9 && userSettingsViewModel.guideCount != -1 {
                        Rectangle()
                            .foregroundColor(.black.opacity(guideOpacity))
                            .edgesIgnoringSafeArea(.all)
                            .cornerRadius(15)
                            //
                                                            
                            .zIndex(5)
                    } else if userSettingsViewModel.guideCount == 9 {
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.blue, lineWidth: 3)
                            .foregroundColor(.white.opacity(0.0))
                            .zIndex(5)
                    }
                }
                            
            }.padding()
        }
    }
        
    func createInputs(_ deviceInfos: [DeviceInfo]) -> some View {
        List(deviceInfos, id: \.name) { deviceInfo in
            
            HStack {
                let deviceNameColor = deviceInfo.connected ? Color.white : Color(NSColor.gray)
                Text(deviceInfo.name)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(deviceNameColor)
                Spacer()
                let inUseColor = deviceInfo.connected ? (deviceInfo.inUse ? Color.red : Color.white) : Color(NSColor.gray)
                Text(deviceInfo.inUse ? "In Use" : "Standby")
                    .strikethrough(!deviceInfo.connected)
                    .frame(width: 100)
                    .foregroundColor(inUseColor)
                Spacer()
                let connectedColor = deviceInfo.connected ? Color.green : Color(NSColor.gray)
                Text(deviceInfo.connected ? "Connected" : "Disconnected")
                    .frame(width: 100)
                    .foregroundColor(connectedColor)
            }
        }
    }

    func createInfoImage(message: String, id: String) -> some View {
        return Button {
            self.infoShowingPopoverDict[id] = true
        } label: {
            Image(systemName: "info.circle")
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: Binding(
            get: { self.infoShowingPopoverDict[id, default: false] },
            set: { self.infoShowingPopoverDict[id] = $0 }
        )) {
            Text(message)
                .font(.headline)
                .padding()
        }
    }

    func validatePorts(startPort: Int?, endPort: Int?) -> Bool {
        if startPort == nil { return false }
        if endPort == nil { return false }
        if startPort! > endPort! { return false }
        
        return true
    }
    
    func createSettings() -> some View {
        ZStack {
            VStack {
                Spacer()
                HStack {
                    Toggle("Developer Mode", isOn: $userSettingsViewModel.devModeEnabled)
                        .toggleStyle(.checkbox)
                        .onChange(of: userSettingsViewModel.devModeEnabled) {
                            logger.debug("\(userSettingsViewModel.devModeEnabled)")
                            
                            SettingsService.settingsService.enableDevLogger()
                        }
                        .id("settingsView")
                    createInfoImage(message: StringConstants.devModeInfo, id: "devMode")
                }
                Spacer()
                
                HStack {
                    Toggle("Monitor Battery", isOn: $userSettingsViewModel.monitorBattery)
                        .toggleStyle(.checkbox)
                        .onChange(of: userSettingsViewModel.monitorBattery) {
                            logger.debug("\(userSettingsViewModel.monitorBattery)")
                        }
                }
                Spacer()
                HStack {
                    Toggle("Monitor Cameras", isOn: $userSettingsViewModel.monitorCameras)
                        .toggleStyle(.checkbox)
                        .onChange(of: userSettingsViewModel.monitorCameras) {
                            logger.debug("\(userSettingsViewModel.monitorCameras)")
                            if !userSettingsViewModel.monitorCameras {
                                viewModel.updateRecievedCameraConfigs(config: false)
                            }
                        }
                }
                Spacer()
                HStack {
                    Toggle("Monitor CPU", isOn: $userSettingsViewModel.monitorCpu)
                        .toggleStyle(.checkbox)
                        .onChange(of: userSettingsViewModel.monitorCpu) {
                            logger.debug("\(userSettingsViewModel.monitorCpu)")
                            if !userSettingsViewModel.monitorCpu && cpuViewModel.mainProcess != nil && cpuViewModel.mainProcess!.isRunning {
                                cpuViewModel.mainProcess?.terminate()
                            }
                        }
                    //                createInfoImage(message: "", id: "monitorCPU")
                }
                Spacer()
                HStack {
                    Toggle("Monitor Microphones", isOn: $userSettingsViewModel.monitorMicrophones)
                        .toggleStyle(.checkbox)
                        .onChange(of: userSettingsViewModel.monitorMicrophones) {
                            logger.debug("\(userSettingsViewModel.monitorMicrophones)")
                            if !userSettingsViewModel.monitorMicrophones {
                                viewModel.updateRecievedMicrophoneConfigs(config: false)
                            }
                        }
                    //                createInfoImage(me /ssage: "", id: "monitorMicrophone")
                }
                Spacer()
                HStack {
                    Toggle("Monitor Opened Apps", isOn: $userSettingsViewModel.monitorOpenApps)
                        .toggleStyle(.checkbox)
                        .onChange(of: userSettingsViewModel.monitorOpenApps) {
                            logger.debug("\(userSettingsViewModel.monitorOpenApps)")
                        }
                    //                createInfoImage(message: "", id: "monitorApps")
                }
                Spacer()
                HStack {
                    Toggle("Monitor RAM", isOn: $userSettingsViewModel.monitorRam)
                        .toggleStyle(.checkbox)
                        .onChange(of: userSettingsViewModel.monitorRam) {
                            logger.debug("\(userSettingsViewModel.monitorRam)")
                        }
                    //                createInfoImage(message: "", id: "monitorRam")
                }
                Spacer()
                HStack {
                    Toggle("Notifications", isOn: $userSettingsViewModel.notifications)
                        .toggleStyle(.checkbox)
                        .onChange(of: userSettingsViewModel.notifications) {
                            logger.debug("\(userSettingsViewModel.notifications)")
                        }
                    //                createInfoImage(message: "", id: "notifications")
                }
                Spacer()
                HStack {
                    Toggle("Start API on App Startup", isOn: $userSettingsViewModel.startApiOnStartup)
                        .toggleStyle(.checkbox)
                        .onChange(of: userSettingsViewModel.startApiOnStartup) {
                            logger.debug("\(userSettingsViewModel.startApiOnStartup)")
                        }
                    createInfoImage(message: StringConstants.startApiOnStartupInfo, id: "startApi")
                }
                Spacer()
                HStack {
                    Toggle("Launch on Startup", isOn: $userSettingsViewModel.openAppOnSystemStartup)
                        .toggleStyle(.checkbox)
                        .onChange(of: userSettingsViewModel.openAppOnSystemStartup) {
                            logger.debug("\(userSettingsViewModel.openAppOnSystemStartup)")
                        }
                    //                createInfoImage(message: StringConstants., id: "startMOSOnStartup")
                }
                Spacer()
                
                HStack {
                    //                Spacer()
                    Text("Start Port:")
                    //                    .frame(width: 100)
                    Spacer()
                    
                    TextField("", text: Binding(
                        get: { self.userSettingsViewModel.startPortString },
                        set: { self.userSettingsViewModel.startPortString = String($0.filter { "0123456789".contains($0) }) }
                        
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
                    createInfoImage(message: StringConstants.startPortInfo, id: "startPort")
                    
                }.frame(width: 200)
                Spacer()
                HStack {
                    //                Spacer()
                    Text("End Port:")
                    //                    .frame(width: 100)
                    Spacer()
                    TextField("", text: Binding(
                        get: { self.userSettingsViewModel.endPortString },
                        set: { self.userSettingsViewModel.endPortString = String($0.filter { "0123456789".contains($0) }) }
                        
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
                    createInfoImage(message: StringConstants.endPortInfo, id: "endPort")
                    //                Spacer()
                    
                }.frame(width: 200)
                Spacer()
                HStack {
                    Button {
                        if !validatePorts(startPort: Int(userSettingsViewModel.startPortString), endPort: Int(userSettingsViewModel.endPortString)) {
                            errorText = "Check start and end ports. Start Port cannot be after end port and they have to be numbers."
                            
                            userSettingsViewModel.sendStatusSignal(status: false, message: errorText)
                            
                            return
                        }
                        userSettingsViewModel.startPort = Int(userSettingsViewModel.startPortString) ?? userSettingsViewModel.startPort
                        userSettingsViewModel.endPort = Int(userSettingsViewModel.endPortString) ?? userSettingsViewModel.endPort
                        
                        userSettingsViewModel.saveSettings()
                        
                    } label: {
                        Text("Save")
                    }
                }
                
                Spacer()
            }
            .padding([.leading, .trailing])
            .background(Color(Color(NSColor.controlBackgroundColor)))
            .cornerRadius(15)
            .frame(height: tabHeight)
            .zIndex(0)
            .frame(width: tabWidth / 3.49)
            
            if userSettingsViewModel.guideCount != 11 && userSettingsViewModel.guideCount != -1 {
                Rectangle()
                    .foregroundColor(.black.opacity(guideOpacity))
                    .frame(width: tabWidth / 3.49)
                    .cornerRadius(15)
                    //
                                                                        
                    .zIndex(5)
            } else if userSettingsViewModel.guideCount == 11 {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: tabWidth / 3.49)
                    .foregroundColor(.white.opacity(0.0))
                    .zIndex(5)
            }
        }
    }
    // create dev settings if dev mode is enabled
    func createDevSettings() -> some View {
        VStack {
            ScrollView {
                ForEach(loggerViewModel.loggerValDict.keys.sorted(), id: \.self) { name in
                    HStack {
                        Text(name)
                        Spacer()
                        TextField("Logger level", text: Binding(
                            get: { self.loggerViewModel.loggerValDict[name, default: "info"] },
                            set: { newValue in
                                self.loggerViewModel.loggerValDict[name] = newValue
    
                                if levelList.contains(newValue) {
                                    classLogLevelValid[name] = true
                                    invalidLevelSet.remove(name)
                                } else {
                                    classLogLevelValid[name] = false
                                    invalidLevelSet.insert(name)
                                }
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 75)
                        .foregroundStyle(classLogLevelValid[name, default: true] ? Color.white : Color.red)
                    }
                }
            }
            .padding(.top, 10)
            HStack {
                Button {
                    if invalidLevelSet.isEmpty {
                        userSettingsViewModel.saveDevSettings()
                    } else {
                        logger.error("One or more log levels is invalid. Look for red text in the text boxes.")
                    }
                   
                } label: {
                    Text("Save")
                }
            }
        }
        //        .padding
        .padding([.leading, .trailing])
        .background(Color(Color(NSColor.controlBackgroundColor)))
        .cornerRadius(15)
        .frame(maxHeight: tabHeight)
        .frame(maxWidth: tabWidth / 3)
    }

    func validateLevels() -> Bool {
        return true
    }
    
    func createLog() -> some View {
        ZStack {
            VStack {
                Spacer()
                Text("Log Messages")
                    .font(.headline)
                ScrollViewReader { scrollView in
                    List(loggerViewModel.logMessages, id: \.self) { message in
                        Text(message)
                    }
                    .onChange(of: loggerViewModel.logMessages) { _, _ in
    
                        if let lastId = loggerViewModel.logMessages.last {
                            if autoScroll { scrollView.scrollTo(lastId, anchor: .bottom) }
                        }
                    }
                }
                
                //                            .padding()
            }
            
            //                            .frame(width: tabWidth / 2)
            .background(Color(Color(NSColor.controlBackgroundColor)))
            .cornerRadius(15)
            .frame(height: tabHeight)
            .frame(width: tabWidth / 1.5)
            .zIndex(0)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        loggerViewModel.clearLogMessages()
                    } label: {
                        Image(systemName: "c.circle")
                            .imageScale(.large)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button {
                        logger.debug("auto toggle")
                        autoScroll = !autoScroll
                    } label: {
                        Image(systemName: "a.circle")
                            .foregroundStyle(autoScroll ? Color.blue : Color.white)
                            .imageScale(.large)
                    }
                    .foregroundStyle(autoScroll ? Color.blue : Color.white)
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 10)
                .padding(.trailing, 25)
                Spacer()
            }
            .zIndex(1)
            if userSettingsViewModel.guideCount < 12 && userSettingsViewModel.guideCount != -1 {
                Rectangle()
                    .foregroundColor(.black.opacity(guideOpacity))
                    //                    .edgesIgnoringSafeArea(.all)
                    .frame(width: tabWidth / 1.5)
                    .cornerRadius(15)
                    //
                                                                                    
                    .zIndex(5)
            } else if userSettingsViewModel.guideCount >= 12 {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: tabWidth / 1.5)
                    .foregroundColor(.white.opacity(0.0))
                    .zIndex(5)
            }
        }
    }

    func createDevLog() -> some View {
        // TODO: add filter
        ZStack {
            VStack {
                Spacer()
                Text("Dev Log Messages")
                    .font(.headline)
                ScrollViewReader { scrollView in
                    List(loggerViewModel.devLogMessages, id: \.self) { message in
                        Text(message)
                    }
                    //                .scrollPosition(id: $scrolledID)
                    .onChange(of: loggerViewModel.devLogMessages) { _, _ in
                        // scrolls to the newest log message
                        if let lastId = loggerViewModel.devLogMessages.last {
                            if autoScroll { scrollView.scrollTo(lastId, anchor: .bottom) }
                        }
                    }
                }
                
            }
            .background(Color(Color(NSColor.controlBackgroundColor)))
            .cornerRadius(15)
            .frame(height: tabHeight)
            .frame(width: tabWidth / 1.5)
            .zIndex(0)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        loggerViewModel.clearDevLogMessages()
                    } label: {
                        Image(systemName: "c.circle")
                            .imageScale(.large)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button {
                        logger.debug("auto toggle")
                        autoScroll = !autoScroll
                    } label: {
                        Image(systemName: "a.circle")
                            .foregroundStyle(autoScroll ? Color.blue : Color.white)
                            .imageScale(.large)
                    }
                    .foregroundStyle(autoScroll ? Color.blue : Color.white)
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 10)
                .padding(.trailing, 10)
                Spacer()
            }
            .zIndex(1)
        }
    }

    func parseTime(time: Int) -> String {
        var timeLeft = time
        var hours = 0
        var minutes = 0
    
        if timeLeft > 59 {
            hours = timeLeft / 60
            timeLeft -= hours * 60
        }
        minutes = timeLeft
        return String(format: "%02d:%02d", hours, minutes)
    }
}
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        // this is all mock data so preview will work
        let deviceViewModel = DeviceViewModel()
        
        let cpuViewModel = CPUViewModel()
        let memoryViewModel = MemoryViewModel()
        let batteryViewModel = BatteryViewModel()
        let appViewModel = AppViewModel(monitorList: Set<String>(), quitList: [String: Int](), reopenList: [String: String]())
        let apiViewModel = ApiViewModel()
        let userSettingsViewModel = UserSettingsViewModel(appVersion: "1.0.0", darkMode: true, devModeEnabled: true, endPort: 5005, monitorBattery: true, monitorCameras: true, monitorCpu: true, monitorMicrophones: true, monitorOpenApps: true, monitorRam: true, monitoredApps: [], notifications: true, openAppOnSystemStartup: false, startApiOnStartup: true, startPort: 5000, quitList: [String: Int](), reopenList: [String: String]())
        let systemViewModel = SystemViewModel()

        PreferencesView(viewModel: deviceViewModel, cpuViewModel: cpuViewModel, memoryViewModel: memoryViewModel, batteryViewModel: batteryViewModel, appViewModel: appViewModel, apiViewModel: apiViewModel, userSettingsViewModel: userSettingsViewModel, systemViewModel: systemViewModel)
            .onAppear {
                deviceViewModel.updateRecievedCameraConfigs(config: true)
                deviceViewModel.updateRecievedMicrophoneConfigs(config: true)
                let testCam = TestDevice(localName: "test 1 cam", uniqueId: "asdfasfasdf", isConnected: true)
                deviceViewModel.updateCameraInfos(with: ["Camera 1": CameraDevice(device: testCam, deviceType: "Cam")])
                let testMic = MicrophoneDevice(device: TestDevice(localName: "test 1 mic", uniqueId: "asdfasfasadffasdasdfsdf", isConnected: true), deviceType: "Mic")
                testMic.inUse = true
                let testMic2 = MicrophoneDevice(device: TestDevice(localName: "test 2 mic", uniqueId: "asdfasfasadffasdasdfsdf", isConnected: true), deviceType: "Mic")
                let testMic3 = MicrophoneDevice(device: TestDevice(localName: "test 3 mic", uniqueId: "asdfasfasadffasdasdfsdf", isConnected: false), deviceType: "Mic")
                let testMic4 = MicrophoneDevice(device: TestDevice(localName: "test 4 mic", uniqueId: "asdfasfasadffasdasdfsdf", isConnected: true), deviceType: "Mic")
                let testMic5 = MicrophoneDevice(device: TestDevice(localName: "test 5 mic", uniqueId: "asdfasfasadffasdasdfsdf", isConnected: false), deviceType: "Mic")
                let testMic6 = MicrophoneDevice(device: TestDevice(localName: "test 6 mic", uniqueId: "asdfasfasadffasdasdfsdf", isConnected: true), deviceType: "Mic")
                testMic6.inUse = true
                let testMic7 = MicrophoneDevice(device: TestDevice(localName: "test 7 mic", uniqueId: "asdfasfasadffasdasdfsdf", isConnected: true), deviceType: "Mic")
                
                let micDict = [testMic.captureDevice.localizedName: testMic,
                               testMic2.captureDevice.localizedName: testMic2,
                               testMic3.captureDevice.localizedName: testMic3,
                               testMic4.captureDevice.localizedName: testMic4,
                               testMic5.captureDevice.localizedName: testMic5,
                               testMic6.captureDevice.localizedName: testMic6,
                               testMic7.captureDevice.localizedName: testMic7]
                deviceViewModel.updateMicrophoneInfos(with: micDict)
            }
    }
}

//struct SizingPreferenceKey: PreferenceKey {
//    static var defaultValue: CGPoint { .zero }
//    
//    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
// 
//    }
//}
