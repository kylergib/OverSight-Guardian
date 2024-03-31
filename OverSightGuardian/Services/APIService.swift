

//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// used Swift NIO example to use this. https://github.com/apple/swift-nio/blob/main/Sources/NIOEchoServer/main.swift

import Foundation
import NIOCore
import NIOPosix

class APIService {
    static var apiService: APIService?
    var channel: Channel?
    private var host: String = "::1"
    private var port: Int = -1
    private var logger = Logger(current: APIService.self)
    var deviceManager: DeviceManager?
    var memoryManager: MemoryManager?
    var cpuManager: CpuManager?
    var batteryManager: BatteryManager?
    var appManager: AppManager?
    var viewModel: ApiViewModel
    var currentHandler: EchoHandler?

    init(viewModel: ApiViewModel) {
        self.viewModel = viewModel
        viewModel.apiService = self
        currentHandler = EchoHandler(apiService: self)
        APIService.apiService = self
    }

    func setManagers(deviceManager: DeviceManager, memoryManager: MemoryManager,
                     cpuManager: CpuManager, batteryManager: BatteryManager,
                     appManager: AppManager)
    {
        self.deviceManager = deviceManager
        self.memoryManager = memoryManager
        self.cpuManager = cpuManager
        self.batteryManager = batteryManager
        self.appManager = appManager
    }
    // finds first port within the range of [startport, endport] and returns it
    func findFirstPort(startPort: Int?, endPort: Int?) -> Int {
        var currPort = startPort
        var localEndPort = endPort
        if currPort == nil {
            logger.error("startPort is nil")
            return -1
        }
        if endPort == nil || endPort! < currPort! {
            logger.error("End port is nil or less than start port. Resetting to equal start port.")
            localEndPort = currPort!
        }
        while currPort! <= localEndPort! {
            if isPortAvailable(UInt16(currPort!)) {
                logger.debug("Found open port: \(currPort!)")
                return currPort!
            } else {
                logger.debug("Port is not open: \(currPort!)")
            }
            currPort! += 1
        }
        logger.error("Could not find a open port between \(startPort!) - \(endPort!)")
        return -1
    }
    // will return true if another instance of Mac OverSight is already running because they have the same name
    // TODO: look into above
    private func isPortAvailable(_ port: UInt16) -> Bool { // got error  when I used Int instead fo UInt16
        
        //AF_INET: ipv4 address
        // sock_stream: two way connection socket
        // 0: default protocol (TCP)
        let socket = socket(AF_INET, SOCK_STREAM, 0)
        if socket < 0 {
            // socket failed to be created
            return false
        }

        var addr = sockaddr_in()
        // sin_len: length of socket
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        // sin_family: the address family
        addr.sin_family = sa_family_t(AF_INET)
        // in_port: the port number and bigEndian is used for network transmission.
        addr.sin_port = in_port_t(port).bigEndian
        // sin_addr.s_addr: the IP address to bind to, set to INADDR_ANY, allows the socket to be bound to all IP addresses of the host
        // TODO: make an option to bind to local host only and not broadcast over LAN?
        addr.sin_addr.s_addr = INADDR_ANY.bigEndian
        
        // attempts to bind the socket
        let bindResult = withUnsafePointer(to: &addr) { // returns a pointer to sockaddr
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(socket, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        // have to manually close since it was created with unsafepointer
        close(socket)

        return bindResult == 0
    }

    func tryServer(startPort: Int? = nil, endPort: Int? = nil) {
        port = findFirstPort(startPort: startPort ?? SettingsService.settingsService.userSettingsViewModel?.startPort, endPort: endPort ?? SettingsService.settingsService.userSettingsViewModel?.endPort)
        viewModel.updatePort(with: port)
        if port == -1 {
            logger.error("Port is -1")
            return
        } // TODO: add error message?
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let bootstrap = ServerBootstrap(group: group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

            // Set the handlers that are appled to the accepted Channels
            .childChannelInitializer { channel in
                // Ensure we don't read faster than we can write by adding the BackPressureHandler into the pipeline.
                channel.pipeline.addHandler(BackPressureHandler()).flatMap { _ in
                    if self.currentHandler == nil { self.currentHandler = EchoHandler(apiService: self) }
                    return channel.pipeline.addHandler(self.currentHandler!)
                }
            }

            // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        defer {
            try! group.syncShutdownGracefully()
        }

        do {
            channel = try { () -> Channel in
                try bootstrap.bind(host: self.host, port: self.port).wait()

            }()
            logger.info("Server started and listening on \(channel!.localAddress!)")
            viewModel.updatePort(with: port)

            viewModel.updateServiceRunning(with: channel!.isActive)

            // This will never unblock as we don't close the ServerChannel
            try channel!.closeFuture.wait()
            viewModel.updateServiceRunning(with: false)

        } catch {
            logger.error("Error: \(error)")
            port += 1
            tryServer(startPort: port, endPort: endPort)
        }
    }

    func shutdownServer() -> Bool {
        logger.info("Received shutdown command for API")
        var closed = false
        channel?.close().whenComplete { result in
            switch result {
            case .success():
                self.logger.info("Server successfully closed.")
                self.viewModel.updateServiceRunning(with: self.channel!.isActive)
                closed = true
            case .failure(let error):
                self.logger.error("Error occurred while closing the server: \(error)")
                self.viewModel.updateServiceRunning(with: self.channel!.isActive)
                closed = self.channel!.isActive
            }
        }
        return closed
    }

    func returnMonitorList() -> [Any] {
        logger.debug("\(appManager!.viewModel.monitoredInfos)")
        return appManager!.apiMonitorList
    }

    func returnAppList() -> [String] {
        logger.debug("\(appManager!.appList)")
        return appManager!.appList
    }

    func getCpuStats() -> [String: Any] {
        var cpuDict = [String: Any]()
        cpuDict["user"] = cpuManager?.userCpu
        cpuDict["system"] = cpuManager?.systemCpu
        cpuDict["idle"] = cpuManager?.idleCpu
        cpuDict["coreCount"] = cpuManager?.cpuCores.count
        cpuDict["cores"] = cpuManager?.cpuCores
        return cpuDict
    }

    func getRamStats() -> [String: Any] {
        var ramDict = [String: Any]()
        ramDict["wired"] = memoryManager?.wiredRam
        ramDict["active"] = memoryManager?.activeRam
        ramDict["inactive"] = memoryManager?.inactiveRam
        ramDict["compressed"] = memoryManager?.compressedRam
        ramDict["app"] = memoryManager?.appMemory
        ramDict["used"] = memoryManager?.usedMemory

        return ramDict
    }

    func getBatteryStats() -> [String: Any]? {
        if !(batteryManager?.hasBattery ?? true) { return nil }
        var batteryDict = [String: Any]()
        batteryDict["batteryProvidesTimeRemaining"] = batteryManager?.batteryProvidesTimeRemaining
        batteryDict["batteryHealth"] = batteryManager?.batteryHealth
        batteryDict["batteryHealthCondition"] = batteryManager?.batteryHealthCondition
        batteryDict["current"] = batteryManager?.current
        batteryDict["currentCapacity"] = batteryManager?.currentCapacity
        batteryDict["designCycleCount"] = batteryManager?.designCycleCount
        batteryDict["hardwareSerialNumber"] = batteryManager?.hardwareSerialNumber
        batteryDict["isCharged"] = batteryManager?.isCharged
        batteryDict["isCharging"] = batteryManager?.isCharging
        batteryDict["isPresent"] = batteryManager?.isPresent
        batteryDict["lpmActive"] = batteryManager?.lpmActive
        batteryDict["maxCapacity"] = batteryManager?.maxCapacity
        batteryDict["name"] = batteryManager?.name
        batteryDict["optimizedBatteryChargingEngaged"] = batteryManager?.optimizedBatteryChargingEngaged
        batteryDict["powerSourceID"] = batteryManager?.powerSourceID
        batteryDict["powerSourceState"] = batteryManager?.powerSourceState
        batteryDict["timeToEmpty"] = batteryManager?.timeToEmpty
        batteryDict["timeToFullCharge"] = batteryManager?.timeToFullCharge
        batteryDict["transportType"] = batteryManager?.transportType
        batteryDict["type"] = batteryManager?.type

        return batteryDict
    }
}

// TODO: change name
final class EchoHandler: ChannelInboundHandler {
    private var apiService: APIService
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer
    private var logger = Logger(current: EchoHandler.self)
    private var broadcastChannelList = [String: ChannelHandlerContext]()
    private var connectionsDict = [String: ChannelHandlerContext]()

    init(apiService: APIService) {
        self.apiService = apiService
    }

    public func channelActive(context: ChannelHandlerContext) {
        // Log the new connection
        logger.info("Client connected: \(context.remoteAddress!)")
        connectionsDict["\(context.remoteAddress!)"] = context
        apiService.viewModel.updateNumConnections(with: connectionsDict.count)
    }

    public func channelInactive(context: ChannelHandlerContext) {
        // This method is called when the connection is closed.
        logger.info("Connection closed: \(context.remoteAddress!)")
        broadcastChannelList["\(context.remoteAddress!)"] = nil
        connectionsDict["\(context.remoteAddress!)"] = nil
        apiService.viewModel.updateNumConnections(with: connectionsDict.count)
        
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = unwrapInboundIn(data)

        // Convert ByteBuffer to String
        let messageString = buffer.getString(at: 0, length: buffer.readableBytes)
        let messageSplit = messageString?.split(separator: "\n")
        messageSplit?.forEach { message in
            let returnMessage = parseMessage(message + "", context: context)
            sendMessage(context: context, message: returnMessage + "\n")
        }
    }

    public func sendMessage(context: ChannelHandlerContext, message: String) {
        if !apiService.channel!.isActive { return }
        // Allocate a ByteBuffer and write your response message to it
        var bufferSend = context.channel.allocator.buffer(capacity: message.utf8.count)
        bufferSend.writeString(message)

        // Write the response to the channel
        context.writeAndFlush(wrapOutboundOut(bufferSend), promise: nil)
    }

    // Flush it out. This can make use of gathering writes if multiple buffers are pending
    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.error("error: \(error)")

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        context.close(promise: nil)
    }

    private func convertStringToDictionary(jsonString: String) -> [String: Any]? {
        guard let jsonData = jsonString.data(using: .utf8) else {
            logger.error("Error: Cannot create Data from JSON String")
            return nil
        }

        do {
            if let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                return jsonDict
            } else {
                logger.error("Invalid JSON format")
                return nil
            }
        } catch {
            logger.error("JSON Serialization error: \(error)")
            return nil
        }
    }

    func broadcastMessage(message: Any) {
        logger.debug("Broadcast Message: \(message)")
        let broadcastJson = jsonUpdate(message)
        broadcastChannelList.forEach { (_: String, value: ChannelHandlerContext) in
            value.eventLoop.execute {
                self.sendMessage(context: value, message: broadcastJson)
            }
        }
    }
    private func parseMessage(_ message: String, context: ChannelHandlerContext?) -> String {
        logger.debug("Received: \(message)")
        guard let jsonDict = convertStringToDictionary(jsonString: message.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return "\(errorJson(errorCode: JSONErrorCodes.parseError, message: message))"
        }

        if jsonDict.keys.contains("method") {
            let method = APIMethod(rawValue: jsonDict["method"] as! String)
            let id = jsonDict["id"]
            let params = jsonDict.keys.contains("params") ? (jsonDict["params"] as! [Any]) : nil
            return parseMethod(method: method, id: id as? Int, params: params ?? nil, context: context)
        }

        return errorJson(errorCode: JSONErrorCodes.internalError)
    }

    private func parseMethod(method: APIMethod?, id: Int?, params: [Any]? = [], context: ChannelHandlerContext? = nil) -> String {
        // TODO: put everything in different functions for ease of reading
        switch method {
        case .getAppInfo:
            if params == nil || params!.isEmpty {
                let appName = "OverSight Guardian"
                let version = "1.0.0"
                #if NON_SANDBOXED
                let sandBox = false
                #else
                let sandBox = true
                #endif

                let result: [String: Any] = ["version": version, "appName": appName, "sandbox": sandBox]
                return jsonCreate(result, id)
            }
            return errorJson(errorCode: JSONErrorCodes.invalidParams)
        case .subscribe:
            if context == nil {
                return errorJson(errorCode: JSONErrorCodes.internalError)
            }
            if params == nil || params!.isEmpty {
                broadcastChannelList["\(context!.remoteAddress!)"] = context
                return jsonCreate("Successfully subscribed", id)
            }
            return errorJson(errorCode: JSONErrorCodes.invalidParams)

        case .getOpenedApps:
            if params == nil || params!.isEmpty {
                return SettingsService.settingsService.userSettingsViewModel!.monitorOpenApps ?
                    jsonCreate(apiService.returnAppList(), id) :
                    jsonCreate("Monitoring Apps is disabled", id) // works 1/23/24: Kyle Gibson

            } else {
                return errorJson(errorCode: JSONErrorCodes.invalidParams)
            }
        case .getStatus:

            if params == nil || params!.isEmpty {
                let isActive = apiService.channel?.isActive ?? false
                let address = apiService.channel?.localAddress?.description ?? "Unknown"
                let result: [String: Any] = ["Active": isActive, "Address": address]
                return jsonCreate(result, id) // works 1/23/24: Kyle Gibson
            } else {
                return errorJson(errorCode: JSONErrorCodes.invalidParams)
            }
        case .shutdown:
            if params == nil || params!.isEmpty {
                return apiService.shutdownServer() ? "" : errorJson(errorCode: JSONErrorCodes.internalError)
            } else {
                return errorJson(errorCode: JSONErrorCodes.invalidParams)
            }

        case .getSystem:
            if params == nil || params!.isEmpty {
                var systemDict = [String: Any]()
                if SettingsService.settingsService.userSettingsViewModel!.monitorCpu {
                    systemDict["cpu"] = apiService.getCpuStats()
                } else {
                    systemDict["cpu"] = "CPU monitoring is disabled"
                }
                if SettingsService.settingsService.userSettingsViewModel!.monitorRam {
                    systemDict["memory"] = apiService.getRamStats()
                } else {
                    systemDict["memory"] = "Memory monitoring is disabled"
                }
                if SettingsService.settingsService.userSettingsViewModel!.monitorBattery {
                    let batteryStats = apiService.getBatteryStats()
                    systemDict["battery"] = batteryStats == nil ? NSNull() : batteryStats
                } else {
                    systemDict["battery"] = "Battery monitoring is disabled"
                }

                return jsonCreate(systemDict, id) // works 1/23/24: Kyle Gibson
            } else {
                return errorJson(errorCode: JSONErrorCodes.invalidParams)
            }
        case .getDevices:
            if params == nil || params!.isEmpty {
                var deviceDict = [String: Any]()
                if SettingsService.settingsService.userSettingsViewModel!.monitorCameras {
                    let cams = apiService.deviceManager?.getCameraData()
                    if cams == nil { return errorJson(errorCode: JSONErrorCodes.internalError) }
                    var camsList = [Any]()
                    for info in cams! {
                        let infoString = encodeInfo(info: info)
                        if infoString != nil { camsList.append(encodeInfo(info: info)!) }
                    }
                    deviceDict["cameras"] = camsList
                } else {
                    deviceDict["cameras"] = "disabled"
                }
                if SettingsService.settingsService.userSettingsViewModel!.monitorMicrophones {
                    let mics = apiService.deviceManager?.getMicrophoneData()
                    if mics == nil { return errorJson(errorCode: JSONErrorCodes.internalError) }
                    var micsList = [Any]()
                    for info in mics! {
                        let infoString = encodeInfo(info: info)
                        if infoString != nil { micsList.append(encodeInfo(info: info)!) }
                    }

                    deviceDict["microphones"] = micsList
                } else {
                    deviceDict["microphones"] = "disabled"
                }

                return jsonCreate(deviceDict, id) // works 1/23/24: Kyle Gibson
            } else {
                return errorJson(errorCode: JSONErrorCodes.invalidParams)
            }
        case .getMonitoredApps:
            if params == nil || params!.isEmpty {
                return jsonCreate(apiService.returnMonitorList(), id)
            } else {
                return errorJson(errorCode: JSONErrorCodes.invalidParams)
            } // TODO: should I remove?
        case .openApp:
            if params == nil || params!.isEmpty {
                return errorJson(errorCode: JSONErrorCodes.invalidParams)
            }
            var openedApps = [String: Any]()
            var openAppResult = [String: Bool]()
            params?.forEach { path in
                logger.debug("\(path)")
                if let pathString = path as? String {
                    logger.debug("\(pathString)")
                    openAppResult[pathString] = apiService.appManager?.openApp(path: pathString)
                }
            }
            openedApps["openAppsResult"] = openAppResult
            return jsonCreate(openedApps, id)
        case .closeApp:

            #if NON_SANDBOXED
            if params == nil || params!.isEmpty {
                return errorJson(errorCode: JSONErrorCodes.invalidParams)
            }

            params?.forEach { name in
                logger.debug("\(name)")
                if let pathString = name as? String {
                    logger.debug("\(pathString)")
                    apiService.appManager?.apiQuitList.insert(pathString)
                }
            }
            sleep(5) // TODO: change this to timer + 1 to get updated list
            return jsonCreate("Attempting to quit", id)
            #else
            return errorJson(errorCode: .sandboxError)
            #endif
        case .changeTimer: // TODO: update
            return ""
        case .getTimer:
            if params == nil || params!.isEmpty {
                return ""
            } else {
                return errorJson(errorCode: JSONErrorCodes.invalidParams)
            }
        case nil:
            return errorJson(errorCode: JSONErrorCodes.methodNotFound)
        }
    }

    private func encodeInfo(info: Codable) -> String? {
        do {
            let jsonData = try JSONEncoder().encode(info)
            let jsonString = String(data: jsonData, encoding: .utf8)
            return jsonString
        } catch {
            logger.error("Error encoding JSON: \(error)")
        }
        return nil
    }

    private func errorJson(errorCode: JSONErrorCodes, message: String? = nil) -> String {
        if message != nil { logger.error(message!) }
        var jsonDict = [String: Any]()
        jsonDict["jsonrpc"] = "2.0"
        jsonDict["id"] = NSNull()
        var errorDict = [String: Any]()
        errorDict["code"] = errorCode.rawValue
        switch errorCode {
        case .parseError:
            errorDict["message"] = "Parse error"
        case .invalidRequest:
            errorDict["message"] = "Invalid Request"
        case .methodNotFound:
            errorDict["message"] = "Method not found"
        case .invalidParams:
            errorDict["message"] = "Invalid params"
        case .internalError:
            errorDict["message"] = "Internal error"
        case .sandboxError:
            errorDict["message"] = "Method does not work in OverSight Guardian from Mac App Store. Download the non sandboxed version to use this method"
        }
        jsonDict["error"] = errorDict

        return dictionaryToJson(jsonDict: jsonDict)
    }

    private func jsonCreate(_ result: Any, _ id: Int?) -> String {
        var jsonDict = [String: Any]()
        jsonDict["jsonrpc"] = "2.0"
        jsonDict["id"] = id ?? NSNull()
        jsonDict["result"] = result

        logger.debug("\(jsonDict)")

        return dictionaryToJson(jsonDict: jsonDict)
    }

    private func jsonUpdate(_ result: Any) -> String {
        var jsonDict = [String: Any]()
        jsonDict["jsonrpc"] = "2.0"
//            jsonDict["id"] = id ?? NSNull()
        jsonDict["update"] = result

        logger.debug("\(jsonDict)")

        return dictionaryToJson(jsonDict: jsonDict)
    }

    private func dictionaryToJson(jsonDict: [String: Any]) -> String {
        logger.debug("\(jsonDict)")

        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonDict, options: []) else {
            logger.error("Error: jsonData could not be created")
            return ""
        }
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            logger.debug(jsonString)
        
            return jsonString
        }

        return "{\"id\": null, \"result\": \"Error processing command\", \"jsonrpc\": \"2.0\"}"
    }
}

class ApiViewModel: ObservableObject {
    private var logger = Logger(current: ApiViewModel.self)
    @Published var apiRunning: Bool = false
    @Published var port: Int?
    @Published var numConnections: Int = 0
    var apiService: APIService?
    init() {}

    func updateServiceRunning(with isRunning: Bool) {
        logger.debug("Updating api active with: \(isRunning)")
        DispatchQueue.main.async {
            self.apiRunning = isRunning
        }
    }

    func updatePort(with port: Int) {
        logger.debug("Updating port with: \(port)")
        DispatchQueue.main.async {
            self.port = port
        }
    }
    func updateNumConnections(with num: Int) {
            logger.debug("Updating num connections with: \(num)")
            DispatchQueue.main.async {
                self.numConnections = num
            }
        }

    func enableApi() {
        DispatchQueue.global(qos: .background).async {
            self.apiService?.tryServer()
        }
    }

    func shutdownApi() {
        _ = apiService?.shutdownServer()
    }
}

enum JSONErrorCodes: Int {
    case parseError = -32700
    case invalidRequest = -32600
    case methodNotFound = -32601
    case invalidParams = -32602
    case internalError = -32603
    case sandboxError = -32604
    // Add other cases here if needed
}

enum APIMethod: String {
    case getAppInfo // in sandbox
    case subscribe // in sandbox
    case getOpenedApps // in sandbox
    case getStatus // in sandbox
    case shutdown // in sandbox
    case getSystem // in sandbox
    case getDevices // in sandbox
    case getMonitoredApps // TODO: should I remove? // in sandbox
    case openApp // in sandbox
    case closeApp // not in sandbox
    case changeTimer // in sandbox - not in version 1 doc
    case getTimer // in sandbox - not in version 1 doc
    // quitlist ->
}
