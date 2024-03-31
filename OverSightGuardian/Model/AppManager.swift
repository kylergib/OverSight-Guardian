//
//  AppManager.swift
//  MacOverSight
//
//  Created by kyle on 12/28/23.
//
import Cocoa
import Foundation

class AppManager {
    private var logger = Logger(current: AppManager.self)

    var appList: [String]
    var updateTimer: Timer?
    var viewModel: AppViewModel
    private var reopenQueue = Queue<String>()
    var apiQuitList = Set<String>()
    var apiMonitorList = [Any]()
    var quittingDict = [String: NSRunningApplication]()
    var forceQuittingDict = [String: NSRunningApplication]()

    init(viewModel: AppViewModel) {
        appList = [String]()

        self.viewModel = viewModel
        parseToApiMonitorList(monitorList: self.viewModel.monitorList)
    }

    func parseToApiMonitorList(monitorList: Set<String>) {
        monitorList.forEach { (name: String) in
            let info = AppMonitorInfo(name: name, cpuUsage: -1, ramUsage: -1, startTime: "", quitAutomatically: false, quitMB: 0.0, open: false)
            viewModel.updateMonitoredAppInfo(with: name, info: info)
//            if info == nil { return }
            do {
                let jsonData = try JSONEncoder().encode(info)
                let jsonString = String(data: jsonData, encoding: .utf8)
                if jsonString != nil {
                    apiMonitorList.append(jsonString!)
                }
            } catch {
                print("Error encoding JSON: \(error)")
            }
        }
    }

    // add timer
    func start() {
        //polls apps
        // TODO: would prefer to have an event listener and not have to poll continusously
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.getApps()
        }
    }

    func openApp(path: String) -> Bool {
        let workspace = NSWorkspace.shared
        let appURL = URL(fileURLWithPath: path) // Note: "/Applications/Safari.app"

        if workspace.open(appURL) {
            logger.info("Application opened successfully: \(path)")
            return true
        }
        logger.error("Failed to open application: \(path)")

        return false
    }

    func getApps() {
        logger.debug("getting apps")
        DispatchQueue.global(qos: .background).async {
            let reopenCount = self.reopenQueue.count
            var tempMonitorList = [Any]()
            var localAppList = [String]()
            var localDict = [String: NSRunningApplication]()
            var localMonitoredInfo = self.viewModel.monitoredInfos
            var nonUpdatedInfos = self.viewModel.monitoredInfos
            let startTime = "\(Date())"
            var beforeQuittingDict = self.quittingDict
            self.quittingDict.removeAll()
            var beforeForceQuittingDict = self.forceQuittingDict
            self.forceQuittingDict.removeAll()

            let apps = NSWorkspace.shared.runningApplications
            for app in apps {
                if let name = app.localizedName, name != "", !localDict.keys.contains(name) {
                    let insertionIndex = localAppList.firstIndex { $0.lowercased() > name.lowercased() } ?? localAppList.endIndex

                    localAppList.insert(name, at: insertionIndex)

                    localDict[name] = app
                    var continueToMonitor = true
                    #if NON_SANDBOXED
                    if self.apiQuitList.contains(name) {
                        // this if checks if a request was sent from the api to quit the app
                        app.terminate()
                        self.quittingDict[app.localizedName!] = app
                        self.apiQuitList.remove(name)
                        continueToMonitor = false
                    }
                    #endif
                    
                    // added continueToMonitor because it is pointless to continue the rest if i quit the app.
                    if self.viewModel.monitorList.contains(name), continueToMonitor {
                        var currentInfo = localMonitoredInfo[name]
                        var appUsage = -1.0
                        #if NON_SANDBOXED
                        appUsage = self.getMemoryUsageOfProcess(pid: Int(app.processIdentifier))
                        self.logger.debug("\(name) \(appUsage)")

                        self.logger.debug("\(self.viewModel.quitAppList)")
                        
                        // this if checks if a an app should be quit from utilizing too much memory
                        if self.viewModel.quitAppList.contains(name), SettingsService.settingsService.userSettingsViewModel?.quitList[name] != nil, (SettingsService.settingsService.userSettingsViewModel?.quitList[name])! <= Int(appUsage) {
                            if !self.quittingDict.keys.contains(app.localizedName!) && !self.forceQuittingDict.keys.contains(app.localizedName!) {
                                self.logger.info("Attempting to quit: \(name)")
                                let title = "\(name) exceeded usage"
                                let subTitle = "Attempting to quit"

                                SettingsService.settingsService.showNotification(title: title, subTitle: subTitle, body: "", interval: 0.1)

                                app.terminate()
                                self.quittingDict[app.localizedName!] = app
                            }

                        }
                        #endif

                        if currentInfo == nil {
                            localMonitoredInfo[name] = AppMonitorInfo(name: name, cpuUsage: -1, ramUsage: appUsage, startTime: startTime, quitAutomatically: false, quitMB: 0.0, open: true)
                        } else {
                            currentInfo?.cpuUsage = -1
                            currentInfo?.ramUsage = appUsage
                            currentInfo?.startTime = startTime
                            currentInfo?.open = true
                            localMonitoredInfo[name] = currentInfo
                        }
                        nonUpdatedInfos[name] = nil
                        do {
                            let jsonData = try JSONEncoder().encode(currentInfo)
                            let jsonString = String(data: jsonData, encoding: .utf8)
                            if jsonString != nil {
                                tempMonitorList.append(jsonString!)
                            }
                        } catch {
                            self.logger.error("Error encoding JSON: \(error)")
                        }
                    }
                }
            }
            self.appList = localAppList
            self.viewModel.updateAppsOpen(with: localAppList)

            nonUpdatedInfos.forEach { (key: String, _) in
                var info = localMonitoredInfo[key]
                if info == nil { return }
                info!.open = startTime == info!.startTime
                localMonitoredInfo[key] = info
                do {
                    let jsonData = try JSONEncoder().encode(info)
                    let jsonString = String(data: jsonData, encoding: .utf8)
                    if jsonString != nil {
                        tempMonitorList.append(jsonString!)
                    }
                } catch {
                    print("Error encoding JSON: \(error)")
                }
            }
            self.apiMonitorList = tempMonitorList
            self.viewModel.updateAppsMonitoredInfos(with: localMonitoredInfo)
            self.viewModel.updateLastMonitorCheck(with: startTime)
            if reopenCount == 0 {
                self.logger.debug("skipping because queue is empty1")
            }
            for _ in 0 ... reopenCount {
                if reopenCount == 0 {
                    self.logger.debug("skipping because queue is empty2")
                    continue
                }
                let appName = self.reopenQueue.dequeue()
                if appName != nil {
                    let path = self.viewModel.reopenList[appName!]
                    if path != nil {
                        _ = self.openApp(path: path!)
                    }
                }
            }

            if beforeForceQuittingDict.keys.count > 0 {
                beforeForceQuittingDict.keys.forEach { key in
                    var app = beforeForceQuittingDict[key]
                    if app == nil { return }
                    if !app!.isTerminated {
                        self.logger.warning("Could not force terminate \(key), will have to terminate manually.")
                    } else {
                        if self.viewModel.reopenList.keys.contains(app!.localizedName!) {
//                            app!.activate()
                            self.reopenQueue.enqueue(app!.localizedName!)
                        }
                    }
                }
            }
            beforeForceQuittingDict.removeAll()

            if beforeQuittingDict.keys.count > 0 {
                beforeQuittingDict.keys.forEach { key in
                    var app = beforeQuittingDict[key]
                    if app == nil { return }
                    if !app!.isTerminated {
                        self.logger.warning("Could not terminate \(key), will try to force terminate")
                        app!.forceTerminate()
                        beforeForceQuittingDict[key] = app
                    } else {
                        if self.viewModel.reopenList.keys.contains(app!.localizedName!) {
//                            app!.activate()
                            self.reopenQueue.enqueue(app!.localizedName!)
                        }
                    }
                }
            }
        }
    }

    #if NON_SANDBOXED
    func getMemoryUsageOfProcess(pid: Int) -> Double {
        // NOTE: CPU DOES NOT WORK
        // NOTE: will not work in sandbox
        // TODO: try to find a sandbox alternative
//        var usage: [Double] = []
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["top", "-pid", "\(pid)", "-l", "1", "-stats", "mem,cpu"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.split(separator: "\n")
                logger.fine("\(output)")
                let lastLine = lines[lines.count - 1]
                var memoryString = lastLine.split(separator: " ")[0]
                var memoryUsage = -1.0
                if memoryString.contains("M") {
                    memoryString.removeLast()
                    memoryUsage = Double(memoryString) ?? memoryUsage
                }

                return memoryUsage
            } else {
                logger.error("Failed to decode output.")
            }
        } catch {
            logger.error("An error occurred: \(error)")
        }
        return -1
    }
    #endif
}

struct AppMonitorInfo: Codable {
    var name: String
    var cpuUsage: Double?
    var ramUsage: Double
    var startTime: String?
    var quitAutomatically: Bool?
    var quitMB: Double?
    var open: Bool?
}

class AppViewModel: ObservableObject {
    private var logger = Logger(current: AppViewModel.self)
    @Published var openApps: [String] = []
//    @Published var monitoredApps: [String] = []
    @Published var monitoredInfos = [String: AppMonitorInfo]()
    @Published var lastMonitoredCheck: String?
//    @Published var appsPendingMonitor: Set<String> = []
//    @Published var currentlyAdding: Set<String> = []
    @Published var monitorList: Set<String>
    @Published var quitList: [String: Int]
    @Published var quitAppList: Set<String> = []
    @Published var reopenList: [String: String]

    init(monitorList: Set<String>, quitList: [String: Int], reopenList: [String: String]) {
        self.monitorList = monitorList
        self.reopenList = reopenList
        self.quitList = quitList
        quitList.forEach { (key: String, _: Int) in
            quitAppList.insert(key)
        }
    }

    func addToMonitorList(with appName: String) {
        DispatchQueue.main.async {
            self.monitorList.insert(appName)
            SettingsService.settingsService.userSettingsViewModel?.addMonitoredApp(appName: appName)
        }
    }

    func removeFromMonitorList(with appName: String) {
        DispatchQueue.main.async {
            self.monitorList.remove(appName)
            self.monitoredInfos[appName] = nil
            SettingsService.settingsService.userSettingsViewModel?.removeMonitoredApp(appName: appName)
        }
    }

    func updateAppsOpen(with apps: [String]) {
        logger.debug("Updating open apps")
        DispatchQueue.main.async {
            self.openApps = apps
        }
    }

    func updateAppsMonitoredInfos(with apps: [String: AppMonitorInfo]) {
        logger.debug("Updating monitored apps")
        DispatchQueue.main.async {
            self.monitoredInfos = apps
        }
    }

    func updateMonitoredAppInfo(with appName: String, info: AppMonitorInfo) {
        DispatchQueue.main.async {
            self.monitoredInfos[appName] = info
        }
    }

    func removeAppToMonitor(with appName: String) {
        DispatchQueue.main.async {
            self.monitoredInfos[appName] = nil
        }
    }

    func updateLastMonitorCheck(with dateString: String) {
        DispatchQueue.main.async {
            self.lastMonitoredCheck = dateString
        }
    }

    func addToQuitList(appName: String, quitMB: Int) {
        DispatchQueue.main.async {
            self.logger.debug("Attempting to add: \(appName) to quit list")
            self.quitAppList.insert(appName)
            self.logger.debug("\(self.quitAppList)")
        }
    }

    func removeFromQuitList(appName: String) {
        DispatchQueue.main.async {
            self.quitAppList.remove(appName)
        }
    }

    func addToReopenList(appName: String, path: String) {
        DispatchQueue.main.async {
            self.reopenList[appName] = path
        }
    }

    func removeFromReopenList(appName: String) {
        DispatchQueue.main.async {
            self.reopenList[appName] = nil
        }
    }

//    func addPendingMonitored() {
//        if appsPendingMonitor.count == 0 { return }
//        DispatchQueue.main.async {
    ////            self.appsPendingMonitor
//            self.currentlyAdding = self.appsPendingMonitor
//            self.appsPendingMonitor = []
    ////            var localPending = self.currentlyAdding
//
//            for key in self.currentlyAdding {
//                self.updateMonitoredApp(with: key, info: AppMonitorInfo(name: key, cpuUsage: nil, ramUsage: nil, startTime: nil))
//                self.logger.info("Added \(key) to monitor list")
//            }
//            self.currentlyAdding = []
    ////            print()
//        }
//    }
//
//    func addToPending(with appName: String) {
//        if currentlyAdding.contains(appName) || appsPendingMonitor.contains(appName) || monitoredInfos.keys.contains(appName) {
//            logger.info("App: \(appName) is pending to be added or in list already")
//            return
//        }
//        DispatchQueue.main.async {
//            self.appsPendingMonitor.insert(appName)
//        }
//    }
}

struct Queue<T> {
    private var elements: [T] = []

    mutating func enqueue(_ value: T) {
        elements.append(value)
    }

    mutating func dequeue() -> T? {
        guard !elements.isEmpty else {
            return nil
        }
        return elements.removeFirst()
    }

    var head: T? {
        return elements.first
    }

    var tail: T? {
        return elements.last
    }

    var count: Int {
        return elements.count
    }
}
