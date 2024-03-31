//
//  PreferencesWindowController.swift
//  MacOverSight
//
//  Created by kyle on 12/20/23.
//

import AppKit
import Foundation
import SwiftUI

class PreferencesWindowController: NSWindowController {
    
    init(viewModel: DeviceViewModel, cpuViewModel: CPUViewModel, memoryViewModel: MemoryViewModel, batteryViewModel: BatteryViewModel, appViewModel: AppViewModel, apiViewModel: ApiViewModel, userSettingsViewModel: UserSettingsViewModel, systemViewModel: SystemViewModel)
    {
        // creating main controller with my Preferences view
        let hostingController = NSHostingController(rootView: PreferencesView(viewModel: viewModel, cpuViewModel: cpuViewModel, memoryViewModel: memoryViewModel, batteryViewModel: batteryViewModel, appViewModel: appViewModel, apiViewModel: apiViewModel, userSettingsViewModel: userSettingsViewModel,systemViewModel:systemViewModel))
        let window = NSWindow(contentViewController: hostingController)
        window.identifier = NSUserInterfaceItemIdentifier("MacControlPreferences")
        super.init(window: window)
        window.title = "Preferences"
        window.minSize = NSSize(width: 200, height: 200)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
