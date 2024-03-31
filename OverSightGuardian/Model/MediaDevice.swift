//
//  Device.swift
//  MacOverSight
//
//  Created by kyle on 12/17/23.
//

import AVFoundation
import CoreAudio
import CoreMediaIO
import Foundation

class MediaDevice {
    var captureDevice: AVCaptureDeviceProtocol
    var connectionId: Int? // connectionId is needed to see if device is in use
    var inUse: Bool? = false
    var type: String?
    var lastConnection: Bool

    init(device: AVCaptureDeviceProtocol, deviceType: String) {
        captureDevice = device
        type = deviceType
        lastConnection = captureDevice.isConnected
    }

    func getConnectionID() {
        connectionId = captureDevice.getConnectionID()
    }

    func checkInUse() {}
    func broadcastJson() {
        var deviceDict = [String : Any]()
        
        var jsonDict = [String: Any]()
        jsonDict["deviceName"] = captureDevice.localizedName
        jsonDict["inUse"] = inUse
        
        deviceDict[type ?? "unknown"] = jsonDict
        APIService.apiService?.currentHandler?.broadcastMessage(message: deviceDict)
    }
}

class CameraDevice: MediaDevice {
    private var logger = Logger(current: CameraDevice.self)
    override func checkInUse() {
        let connectionString = captureDevice.localizedName + (captureDevice.isConnected ? " connected" : " disconnected")
        if captureDevice.isConnected != lastConnection {
            logger.debug(connectionString)
            lastConnection = captureDevice.isConnected
        }
        if connectionId == nil || !captureDevice.isConnected { return }
        // NOTE see microphone usage of prop for more notes
        var prop = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertyElement(kCMIODevicePropertyDeviceIsRunningSomewhere),
            mScope: kCMIOObjectPropertyScopeWildcard,
            mElement: kCMIOObjectPropertyElementWildcard
        )

        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        var result = CMIOObjectGetPropertyDataSize(CMIOObjectID(connectionId!), &prop, 0, nil, &dataSize)
        if result == OSStatus(kCMIOHardwareNoError) {
            let data = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(dataSize))

            result = CMIOObjectGetPropertyData(CMIOObjectID(connectionId!), &prop, 0, nil, dataSize, &dataUsed, data)
            let newVal = data.pointee != 0
            if inUse != newVal {
                logger.debug("\(captureDevice.localizedName) changed to \(newVal)")
                let title = "Camera: \(captureDevice.localizedName)"
                let subTitle = "changed to \(newVal ? "In Use" : "Not In Use")"
//                let subTitleUsing = "An application started using this microhpone"

                SettingsService.settingsService.showNotification(title: title, subTitle: subTitle, body: "", interval: 0.1)
                inUse = newVal
                broadcastJson()
            }
            data.deallocate()
        }
        
    }
}

class MicrophoneDevice: MediaDevice {
    private var logger = Logger(current: MicrophoneDevice.self)

    /// checks if the device is in use or not
    override func checkInUse() {
        let connectionString = captureDevice.localizedName + (captureDevice.isConnected ? " connected" : " disconnected")
        if captureDevice.isConnected != lastConnection {
            logger.debug(connectionString)
            lastConnection = captureDevice.isConnected
        }
        if connectionId == nil || !captureDevice.isConnected { return }

        var prop = AudioObjectPropertyAddress(
            /// NOTE: mSelector: selects which state of the audio object to get
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            /// NOTE: mScope: specifies where the property is in the audio object (input, output, global, etc)
            mScope: kAudioObjectPropertyScopeInput,
            /// NOTE: mElement: represents the element in the scope
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0

        /// NOTE:
        /// AudioObjectGetPropertyDataSize: detemerine the size in bytes, of the property data
        /// &dataSize: reference to the variable and the size of the property data will be stored in the variable after the function call
        /// 0: parameter is reserved for future use and should always be 0
        /// nil: parameter is reserved for future use and should always be nil
        var result = AudioObjectGetPropertyDataSize(AudioObjectID(connectionId!), &prop, 0, nil, &dataSize)
        /// NOTE: if there is no error then it will continue
        if result == OSStatus(kCMIOHardwareNoError) {
            
            let data = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(dataSize))
            /// NOTE:
            /// AudioObjectGetPropertyData: gets property data
            /// &dataSize: reference to the variable and the size of the property data will be stored in the variable after the function call
            /// data: a reference to the data memory buffer where the property data will be stored.
            /// 0: parameter is reserved for future use and should always be 0
            /// nil: parameter is reserved for future use and should always be nil
            result = AudioObjectGetPropertyData(AudioObjectID(connectionId!), &prop, 0, nil, &dataSize, data)
            if result == OSStatus(kCMIOHardwareNoError) {
                let newVal = data.pointee != 0
                if inUse != newVal {
                    logger.debug("\(captureDevice.localizedName) changed to \(newVal)")
                    let title = "Microphone: \(captureDevice.localizedName)"
                    let subTitle = "changed to \(newVal ? "In Use" : "Not In Use")"

                    SettingsService.settingsService.showNotification(title: title, subTitle: subTitle, body: "", interval: 0.1)
                    inUse = newVal
                    broadcastJson()
                }

            } else {
                logger.error("Error getting property data: \(result)")
            }
            // free up unsafe pointer manually
            data.deallocate()

        } else {
            logger.error("Error getting property data size: \(result)")
        }
    }
}
