//
//  DeviceDiscoverySessionProtocol.swift
//  MacOverSight
//
//  Created by kyle on 12/20/23.
//
import AVFoundation
// protocol for unit testing
protocol DeviceDiscoverySessionProtocol {
    func discoverDevices() -> [AVCaptureDevice]
}

class AudioDeviceDiscoverySession: DeviceDiscoverySessionProtocol {
    func discoverDevices() -> [AVCaptureDevice] {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [.microphone, .external]
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .audio, position: .unspecified).devices
        return devices
    }
}

class CameraDeviceDiscoverySession: DeviceDiscoverySessionProtocol {
    func discoverDevices() -> [AVCaptureDevice] {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            AVCaptureDevice.DeviceType.builtInWideAngleCamera,
            AVCaptureDevice.DeviceType.continuityCamera,
            AVCaptureDevice.DeviceType.deskViewCamera,
            AVCaptureDevice.DeviceType.external
        ]
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: .unspecified).devices
        return devices
    }
}
