//
//  ResourceManager.swift
//  MacOverSight
//
//  Created by kyle on 12/21/23.
//

import Foundation
import MachO
import System


class MemoryManager {
    private var logger = Logger(current: MemoryManager.self)
    var wiredRam: Double?
    var activeRam: Double?
    var inactiveRam: Double?
    var compressedRam: Double?
    var appMemory: Double?
    var usedMemory: Double?
    private let gigabyteNum = Double(1000 * 1000 * 1000)
    private var viewModel: MemoryViewModel

    

    init(viewModel: MemoryViewModel) {
        self.viewModel = viewModel
    }

    func getMemory() {
        // NOTE:vm_statistics64() will hold the stats retrieved
        var stats = vm_statistics64()
        // NOTE: calculates the size of stats object
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        // NOTE: creates mutable pointer which is needed for the host_statistics64()
        let currentStats = withUnsafeMutablePointer(to: &stats) {
            // NOTE: converts mutables pointers to interger_t (int 32 of obj c) for host_statistics64
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                // NOTE: mach_host_self() - provides a eference to the host
                // NOTE: HOST_VM_INFO64 - specifies virtual memory stats
                // NOTE: $0 - pointer to vm_statistics64
                // NOTE: &count - pointer to count for size
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        // kern_success is the result for the obj c of getting the stats
        if currentStats == KERN_SUCCESS {
            let pageSize = vm_page_size
            wiredRam = Double(Int64(stats.wire_count) * Int64(pageSize))
            activeRam = Double(Int64(stats.active_count) * Int64(pageSize))
            inactiveRam = Double(Int64(stats.inactive_count) * Int64(pageSize))
            compressedRam = Double(Int64(stats.compressor_page_count) * Int64(pageSize))
            appMemory = Double(Int64(stats.internal_page_count) * Int64(pageSize))

            usedMemory = Double(appMemory! + wiredRam! + compressedRam!)

            logger.debug("Wired Ram: \(wiredRam! / gigabyteNum) GB")
            logger.debug("Active Ram: \(activeRam! / gigabyteNum) GB")
            logger.debug("Inactive Ram: \(inactiveRam! / gigabyteNum) GB")
            logger.debug("Compressed Ram: \(compressedRam! / gigabyteNum) GB")
            logger.debug("App Memory: \(appMemory! / gigabyteNum) GB")
            logger.debug("Total Ram Used: \(usedMemory! / gigabyteNum) GB")
            viewModel.updateMemoryTotals(wiredRamPercent: wiredRam! / gigabyteNum, activeRamPercent: activeRam! / gigabyteNum, inactiveRamPercent: inactiveRam! / gigabyteNum, compressedRamPercent: compressedRam! / gigabyteNum, appMemoryPercent: appMemory! / gigabyteNum, totalMemoryPercent: usedMemory! / gigabyteNum)

        } else {
            logger.error("Error: \(String(cString: mach_error_string(currentStats)))")
        }
    }
}

struct MemoryInfo {
    var name: String
    var percent: Double
}

class MemoryViewModel: ObservableObject {
    private var logger = Logger(current: MemoryViewModel.self)
    @Published var wiredRam: MemoryInfo
    @Published var activeRam: MemoryInfo
    @Published var inactiveRam: MemoryInfo
    @Published var compressedRam: MemoryInfo
    @Published var appMemory: MemoryInfo
    @Published var totalMemory: MemoryInfo

    init() {
        wiredRam = MemoryInfo(name: "Wired", percent: -1)
        activeRam = MemoryInfo(name: "Active", percent: -1)
        inactiveRam = MemoryInfo(name: "Inactive", percent: -1)
        compressedRam = MemoryInfo(name: "Compressed", percent: -1)
        appMemory = MemoryInfo(name: "App", percent: -1)
        totalMemory = MemoryInfo(name: "Total", percent: -1)
    }

    func updateMemoryTotals(wiredRamPercent: Double, activeRamPercent: Double,
                            inactiveRamPercent: Double, compressedRamPercent: Double,
                            appMemoryPercent: Double, totalMemoryPercent: Double) {
        DispatchQueue.main.async {
            self.wiredRam.percent = wiredRamPercent
            self.activeRam.percent = activeRamPercent
            self.inactiveRam.percent = inactiveRamPercent
            self.compressedRam.percent = compressedRamPercent
            self.appMemory.percent = appMemoryPercent
            self.totalMemory.percent = totalMemoryPercent
        }
    }
}
