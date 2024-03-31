//
//  BatteryManager.swift
//  MacOverSight
//
//  Created by kyle on 12/27/23.
//

import Foundation
import IOKit.ps

class BatteryManager {
    private var logger = Logger(current: BatteryManager.self)
    private var viewModel: BatteryViewModel
    
    var batteryProvidesTimeRemaining: Bool?
    var batteryHealth: String?
    var batteryHealthCondition: String?
    var current: Int?
    var currentCapacity: Int?
    var designCycleCount: Int?
    var hardwareSerialNumber: String?
    var isCharged: Bool?
    var isCharging: Bool?
    var isPresent: Bool?
    var lpmActive: Bool? // Note: low power mode
    var maxCapacity: Int?
    var name: String?
    var optimizedBatteryChargingEngaged: Bool?
    var powerSourceID: Int?
    var powerSourceState: String?
    var timeToEmpty: Int? // Note: in minutes
    var timeToFullCharge: Int? // Note: in minutes
    var transportType: String?
    var type: String?
    var hasBattery: Bool?
    

    init(viewModel: BatteryViewModel) {
        self.viewModel = viewModel
    }

    func getBatteryDetails() {
        hasBattery = false
        // gets info of power sources
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()

        // gets all batteries connected
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

        if sources.count == 0 { return }
        
        // 0 index is built in battery
        // this apparently may work with a UPS on a mac mini, but cannot test currently.
        let ps = sources[0]
        hasBattery = true
        batteryProvidesTimeRemaining = (ps["Battery Provides Time Remaining"] as? Int == 1)
        batteryHealth = ps["BatteryHealth"] as? String
        batteryHealthCondition = ps["batteryHealthCondition"] as? String ?? ""
        current = ps["Current"] as? Int
        currentCapacity = ps["Current Capacity"] as? Int
        designCycleCount = ps["DesignCycleCount"] as? Int
        hardwareSerialNumber = ps["Hardware Serial Number"] as? String
        isCharged = (ps["Is Charged"] as? Int == 1)
        isCharging = (ps["Is Charging"] as? Int == 1)
        isPresent = (ps["Is Present"] as? Int == 1)
        lpmActive = (ps["LPM Active"] as? Int == 1)
        maxCapacity = ps["Max Capacity"] as? Int
        name = ps["Name"] as? String
        optimizedBatteryChargingEngaged = (ps["Optimized Battery Charging Engaged"] as? Int == 1)
        powerSourceID = ps["Power Source ID"] as? Int
        powerSourceState = ps["Power Source State"] as? String
        timeToEmpty = ps["Time to Empty"] as? Int
        timeToFullCharge = ps["Time to Full Charge"] as? Int
        transportType = ps["Transport Type"] as? String
        type = ps["Type"] as? String

        logger.debug("\(batteryProvidesTimeRemaining!)")
        logger.debug("\(batteryHealth!)")
        logger.debug("\(batteryHealthCondition!)")
        logger.debug("\(current!)")
        logger.debug("\(currentCapacity!)")
        logger.debug("\(designCycleCount!)")
        logger.debug("\(hardwareSerialNumber!)")
        logger.debug("\(isCharged!)")
        logger.debug("\(isCharging!)")
        logger.debug("\(isPresent!)")
        logger.debug("\(lpmActive!)")
        logger.debug("\(maxCapacity!)")
        logger.debug("\(name!)")
        logger.debug("\(optimizedBatteryChargingEngaged!)")
        logger.debug("\(powerSourceID!)")
        logger.debug("\(powerSourceState!)")
        logger.debug("\(timeToEmpty!)")
        logger.debug("\(timeToFullCharge!)")
        logger.debug("\(transportType!)")
        logger.debug("\(type!)")
        viewModel.updateInfo(batteryHealth: batteryHealth!, current: current!, currentCapacity: currentCapacity!, isCharged: isCharged!, isCharging: isCharging!, lpmActive: lpmActive!, powerSourceState: powerSourceState!, timeToEmpty: timeToEmpty!, timeToFullCharge: timeToFullCharge!)
    }
}

// struct BatteryInfo {
//
// }

class BatteryViewModel: ObservableObject {
    @Published var batteryHealth: String?
    @Published var current: Int?
    @Published var currentCapacity: Int?
    @Published var isCharged: Bool?
    @Published var isCharging: Bool?
    @Published var lpmActive: Bool?
    @Published var powerSourceState: String?
    @Published var timeToEmpty: Int?
    @Published var timeToFullCharge: Int?
    @Published var hasBattery: Bool

    init() {
        hasBattery = false
    }
    func updateInfo(batteryHealth: String, current: Int, currentCapacity: Int,
                    isCharged: Bool, isCharging: Bool, lpmActive: Bool,
                    powerSourceState: String, timeToEmpty: Int, timeToFullCharge: Int) {
        
        DispatchQueue.main.async {
            self.hasBattery = true
            self.batteryHealth = batteryHealth
            self.current = current
            self.currentCapacity = currentCapacity
            self.isCharged = isCharged
            self.isCharging = isCharging
            self.lpmActive = lpmActive
            self.powerSourceState = powerSourceState
            self.timeToEmpty = timeToEmpty // if -1 is calculating
            self.timeToFullCharge = timeToFullCharge // if -1 is calculating
        }
        
    }
}
