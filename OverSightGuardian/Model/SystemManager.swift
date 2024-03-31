//
//  SystemManager.swift
//  MacOverSight
//
//  Created by kyle on 1/12/24.
//

import Foundation

class SystemManager {
    private var logger = Logger(current: SystemManager.self)
    var processorCount: Int = -1
    var physicalMemory: Int = -1 // in bytes
    var osVersion: String = ""
    var systemUpTime: Double = 0.0 // in seconds
    var hostName: String = ""
    var totalCapacity: Int = -1
    var availableCapacity: Int = -1
    var usedCapacity: Int = -1
    var systemViewModel: SystemViewModel

    init(systemViewModel: SystemViewModel) {
        self.systemViewModel = systemViewModel
        updateSystem()
        getVolumeData()
    }

    func updateSystem() {
        
        let processInfo = ProcessInfo.processInfo

        
        processorCount = processInfo.activeProcessorCount
        logger.fine("Active Processor Count: \(processorCount)")

        physicalMemory = Int(processInfo.physicalMemory) / (1024 * 1024 * 1024)
        logger.fine("Physical Memory (bytes): \(physicalMemory)")
        systemUpTime = processInfo.systemUptime
        logger.fine("System Uptime (seconds): \(systemUpTime)")

    
        osVersion = processInfo.operatingSystemVersionString
        logger.fine("OS Version: \(osVersion)")

        hostName = processInfo.hostName
        logger.fine("Process Arguments: \(hostName)")
        systemViewModel.updateProcessCount(count: processorCount)
        systemViewModel.updatePhysicalMemory(memory: physicalMemory)
        systemViewModel.updateSystemUpTime(upTime: systemUpTime)
        systemViewModel.updateOsVersion(version: osVersion)
        systemViewModel.updateHostName(name: hostName)
    }

    func getVolumeData() {
        let fileManager = FileManager.default

        do {
            // get url of volumes mounted
            let volumeURLs = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: [])
            if let volumeURL = volumeURLs?.first { // first should be main
                let values = try volumeURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])

                if let totalCapacity = values.volumeTotalCapacity,
                   let availableCapacity = values.volumeAvailableCapacity
                {
                    logger.fine("Total capacity: \(totalCapacity / 1_000_000_000) GB")
                    logger.fine("Available capacity: \(availableCapacity / 1_000_000_000) GB")

                    let usedCapacity = totalCapacity - availableCapacity
                    logger.fine("Used capacity: \(usedCapacity / 1_000_000_000) GB")
                    self.totalCapacity = totalCapacity / 1_000_000_000
                    self.availableCapacity = availableCapacity / 1_000_000_000
                    self.usedCapacity = usedCapacity / 1_000_000_000
                    systemViewModel.updateTotalCapacity(count: self.totalCapacity)
                    systemViewModel.updateAvailableCapacity(count: self.availableCapacity)
                    systemViewModel.updateUsedCapacity(count: self.usedCapacity)
                }
            }
        } catch {
            logger.error("Error retrieving volume information: \(error)")
        }
    }
}

class SystemViewModel: ObservableObject {
    private var logger = Logger(current: SystemViewModel.self)
    @Published var processorCount: Int = -1
    @Published var physicalMemory: Int = -1 // in bytes
    @Published var osVersion: String = ""
    @Published var systemUpTime: Double = 0.0 // in seconds
    @Published var hostName: String = ""
    @Published var totalCapacity: Int = -1
    @Published var availableCapacity: Int = -1
    @Published var usedCapacity: Int = -1
    @Published var systemUpTimeString: String = ""
    private let secondsInDay = 86400
    private let secondsInHour = 3600
    private let secondsInMinute = 60

    func updateProcessCount(count: Int) {
        DispatchQueue.main.async {
            self.processorCount = count
        }
    }

    func updatePhysicalMemory(memory: Int) {
        DispatchQueue.main.async {
            self.physicalMemory = memory
        }
    }

    func updateOsVersion(version: String) {
        DispatchQueue.main.async {
            self.osVersion = version
        }
    }

    func updateSystemUpTime(upTime: Double) {
        var tempDay = 0
        var tempHour = 0
        var tempMin = 0
        var tempSec = 0

        var tempTime = Int(upTime)
        if tempTime >= secondsInDay {
            tempDay = tempTime / secondsInDay
            tempTime = tempTime - (tempDay * secondsInDay)
        }
        if tempTime >= secondsInHour {
            tempHour = tempTime / secondsInHour
            tempTime = tempTime - (tempHour * secondsInHour)
        }
        if tempTime >= secondsInMinute {
            tempMin = tempTime / secondsInMinute
            tempSec = tempTime - (tempMin * secondsInMinute)
        }
        DispatchQueue.main.async {
            self.systemUpTime = upTime
            self.systemUpTimeString = String(format: "%02d:%02d:%02d:%02d", tempDay,tempHour,tempMin,tempSec)
        }
    }

    func updateHostName(name: String) {
        DispatchQueue.main.async {
            self.hostName = name
        }
    }

    func updateTotalCapacity(count: Int) {
        DispatchQueue.main.async {
            self.totalCapacity = count
        }
    }

    func updateAvailableCapacity(count: Int) {
        DispatchQueue.main.async {
            self.availableCapacity = count
        }
    }

    func updateUsedCapacity(count: Int) {
        DispatchQueue.main.async {
            self.usedCapacity = count
        }
    }
}
