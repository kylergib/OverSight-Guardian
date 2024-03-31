//
//  CpuManager.swift
//  MacOverSight
//
//  Created by kyle on 12/27/23.
//

import Foundation

class CpuManager {
    private var logger = Logger(current: CpuManager.self)
    private var viewModel: CPUViewModel
    var cpuInfo: processor_info_array_t!
    var prevCpuInfo: processor_info_array_t?
    var numCpuInfo: mach_msg_type_number_t = 0
    var numPrevCpuInfo: mach_msg_type_number_t = 0
    var numCPUs: uint = 0
    var updateTimer: Timer!
    let CPUUsageLock: NSLock = .init()
    var cpuCores = [String: Double]()
    var userCpu: Double?
    var systemCpu: Double?
    var idleCpu: Double?

    init(viewModel: CPUViewModel) {
        self.viewModel = viewModel
        let mibKeys: [Int32] = [CTL_HW, HW_NCPU]
        // sysctl Swift usage credit Matt Gallagher: https://github.com/mattgallagher/CwlUtils/blob/master/Sources/CwlUtils/CwlSysctl.swift
        mibKeys.withUnsafeBufferPointer { mib in
            var sizeOfNumCPUs: size_t = MemoryLayout<uint>.size
            let status = sysctl(processor_info_array_t(mutating: mib.baseAddress), 2, &numCPUs, &sizeOfNumCPUs, nil, 0)
            if status != 0 {
                self.numCPUs = 1
            }
        }
    }
    // CPU usage credit VenoMKO: https://stackoverflow.com/a/6795612/1033581
    @objc func getCpuInfo() {
        var numCPUsU: natural_t = 0
        // mach system call that returns cpu usage info
        // mach_host_self(): reference to host machine
        // PROCESSOR_CPU_LOAD_INFO: type of info to receive
        // &numCPUsU pointer to variable that stores num cpus
        // &cpuInfo: a poiinter to array variable -> will store cpu info data
        // &numCpuInfo: stores number of elements in info array.
        let err: kern_return_t = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &cpuInfo, &numCpuInfo)
        if err == KERN_SUCCESS {
            var cpuInfos: [CPUInfo] = []
            var totalSystemTime: Int32 = 0
            var totalUserTime: Int32 = 0
            var allTime: Int32 = 0
            for i in 0 ..< Int32(numCPUs) {
                var systemTime: Int32
                var userTime: Int32
                var totalTime: Int32
                var inUse: Int32
                var total: Int32
                // TODO: i think this can be simplified
                // want to do more research as i do not think that prevcpuinfo is needed at all if i deallocate cpuinfo after i set all the states?
                if let prevCpuInfo = prevCpuInfo {
                    userTime = cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_USER)]
                        - prevCpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_USER)]
                    systemTime = cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_SYSTEM)]
                        - prevCpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_SYSTEM)]
                    totalTime = userTime + systemTime + (cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_IDLE)]
                        - prevCpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_IDLE)])

                    inUse = userTime + systemTime
                        + cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_NICE)]
                        - prevCpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_NICE)]
                    total = inUse + (cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_IDLE)]
                        - prevCpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_IDLE)])
                } else {
                    userTime = cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_USER)]
                    systemTime = cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_SYSTEM)]
                    totalTime = userTime + systemTime + cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_IDLE)]

                    inUse = userTime + systemTime + cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_NICE)]
                    total = inUse + cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_IDLE)]
                }

                totalSystemTime += systemTime
                totalUserTime += userTime
                allTime += totalTime
                logger.debug(String(format: "Core: %u Usage: %f", i, Float(inUse) / Float(total)))            
                self.cpuCores["\(i)"] = (Double(inUse) / Double(total)) * 100
                cpuInfos.append(CPUInfo(name: "Core\(i):", coreNum: Int(i), percent: (Double(inUse) / Double(total)) * 100 ))
                
            }

            
            self.systemCpu = (Double(totalSystemTime) / Double(allTime)) * 100
            self.userCpu = (Double(totalUserTime) / Double(allTime)) * 100
            self.idleCpu = (Double(allTime - totalSystemTime - totalUserTime) / Double(allTime)) * 100
            logger.debug("System: \(Float(totalSystemTime) / Float(allTime))")
            logger.debug("User: \(Float(totalUserTime) / Float(allTime))")
            logger.debug("Idle: \(Float(allTime - totalSystemTime - totalUserTime) / Float(allTime))")
            
            viewModel.updateAllCpu(userCPU: self.userCpu!, systemCPU: self.systemCpu!, idleCPU: self.idleCpu!, cpuInfos: cpuInfos)


            if let prevCpuInfo = prevCpuInfo {
                // vm_deallocate Swift usage credit rsfinn: https://stackoverflow.com/a/48630296/1033581
                let prevCpuInfoSize: size_t = MemoryLayout<integer_t>.stride * Int(numPrevCpuInfo)
                vm_deallocate(mach_task_self_, vm_address_t(bitPattern: prevCpuInfo), vm_size_t(prevCpuInfoSize))
            }

            prevCpuInfo = cpuInfo
            numPrevCpuInfo = numCpuInfo

            cpuInfo = nil
            numCpuInfo = 0
        } else {
            logger.error("Error!")
        }
    }


}

struct CPUInfo {
    var name: String
    var coreNum: Int?
    var percent: Double
}

class CPUViewModel: ObservableObject {
    private var logger = Logger(current: CPUViewModel.self)
    @Published var cpuCoresInfos: [CPUInfo] = []
    @Published var userCpuInfo: CPUInfo?
    @Published var systemCpuInfo: CPUInfo?
    @Published var idleCpuInfo: CPUInfo?
    @Published var mainProcess: Process?

    init() {
        self.userCpuInfo = CPUInfo(name: "User", coreNum: nil, percent: -1)
        self.systemCpuInfo = CPUInfo(name: "System", coreNum: nil, percent: -1)
        self.idleCpuInfo = CPUInfo(name: "Idle", coreNum: nil, percent: -1)
    }

    func updateMainProcess(process: Process?) {
        DispatchQueue.main.async {
            self.mainProcess = process
        }
    }
    

    func updateCPUCores(with cpuInfos: [CPUInfo]) {
        DispatchQueue.main.async {
            self.cpuCoresInfos = cpuInfos

        }
    }

    func updateAllCpu(userCPU: Double, systemCPU: Double, idleCPU: Double, cpuInfos: [CPUInfo]) {
        DispatchQueue.main.async {
            self.userCpuInfo?.percent = userCPU
            self.systemCpuInfo?.percent = systemCPU
            self.idleCpuInfo?.percent = idleCPU
            self.cpuCoresInfos = cpuInfos
        }
    }
}
