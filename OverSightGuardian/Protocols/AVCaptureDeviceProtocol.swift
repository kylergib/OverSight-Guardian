//
//  AVCaptureDeviceProtocol.swift
//  MacOverSight
//
//  Created by kyle on 12/20/23.
//
import AVFoundation

protocol AVCaptureDeviceProtocol {
    var localizedName: String { get }
    var uniqueID: String { get }
    var isConnected: Bool { get }
    func getConnectionID() -> Int?
}

extension AVCaptureDevice: AVCaptureDeviceProtocol {
    func getConnectionID() -> Int? {
        if let connID = value(forKey: "_connectionID") as? Int {
            return connID
        }
        return nil
    }
}

class TestDevice: AVCaptureDeviceProtocol {
    var localizedName: String
    var uniqueID: String
    var isConnected: Bool

    init(localName: String, uniqueId: String, isConnected: Bool) {
        localizedName = localName
        uniqueID = uniqueId
        self.isConnected = isConnected
    }

    func getConnectionID() -> Int? {
        return -1
    }
}
