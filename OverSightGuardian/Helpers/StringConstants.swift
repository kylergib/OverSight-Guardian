//
//  StringConstants.swift
//  MacOverSight
//
//  Created by kyle on 1/14/24.
//

import Foundation


struct StringConstants {
    static let devModeInfo = "Enabling developer mode will give you advanced options, but may have a performance impact."
    static let startApiOnStartupInfo = "This starts the API when the application starts."
    static let startPortInfo = "This is the first port the API attempts to use. If that port is unavailable, it will try the next one, continuing to the next port until it reaches the specified end port."
    static let endPortInfo = "The end port cannot be smaller than the start port. If the end port is equal to the start port, the API will attempt to start only on that port."
    
}
