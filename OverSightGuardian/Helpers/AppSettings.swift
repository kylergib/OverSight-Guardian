//
//  Settings.swift
//  MacOverSight
//
//  Created by kyle on 12/28/23.
//

import Foundation

enum AppSettings {
    static var developerSettings = getDeveloperPlist()
    static var loggerSettings = parseForLogger()

    private static func getDeveloperPlist() -> [String: AnyObject]? {
        if let path = Bundle.main.path(forResource: "DeveloperSettings", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject]
        {

            return dict
        } else {
            return nil
        }
    }

    private static func parseForLogger() -> [String: AnyObject]? {
        return AppSettings.developerSettings?["Logger"] as? [String: AnyObject]
    }
}
