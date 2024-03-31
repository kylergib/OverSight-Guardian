//
//  Logger.swift
//  MacOverSight
//
//  Created by kyle on 12/18/23.
//

import Foundation
// simple logger class, created a library at: https://github.com/kylergib/LoggerSwift for other projects, repo does not work with different dev mode logger like i have here
class Logger {
    private var levelDict = ["info": 0, "debug": 1, "warning": 0, "error": 0, "critical": 0, "fatal": 0, "fine": 2, "finer": 3, "finest": 4]
    var currentLevel: String = "info"
    var currentClassName: String
    let formatter = DateFormatter()
    var customOutput: LoggerOutput?
    static var loggerViewModel = LoggerViewModel()
    static var loggerValDict = [String: String]()
    static var isDevMode = false
//    var classDict: [String : AnyObject]

    init<T>(current: T, output: LoggerOutput? = nil) {
        currentClassName = String(describing: current.self)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        customOutput = output
    }

    func info(_ message: String, function: String = #function, line: Int = #line) {
        let isDev = Logger.isDevMode
        log("ℹ️", message, function: function, line: line, dev: isDev)
    }

    func debug(_ message: String, function: String = #function, line: Int = #line) {
        let devLogLevel = Logger.loggerValDict[currentClassName] ?? "info"
        let isDev = Logger.isDevMode && levelDict[devLogLevel]! >= 1
        if levelDict[currentLevel]! >= 1 || isDev {
            log("🐞", message, function: function, line: line, dev: isDev)
        }
    }

    func warning(_ message: String, function: String = #function, line: Int = #line) {
        let isDev = Logger.isDevMode
        log("⚠️", message, function: function, line: line, dev: isDev)
    }

    func error(_ message: String, function: String = #function, line: Int = #line) {
        let isDev = Logger.isDevMode
        log("❌", message, function: function, line: line, dev: isDev)
    }

    func critical(_ message: String, function: String = #function, line: Int = #line) {
        let isDev = Logger.isDevMode
        log("❗", message, function: function, line: line, dev: isDev)
    }

    func fatal(_ message: String, function: String = #function, line: Int = #line) {
        let isDev = Logger.isDevMode
        log("☠️", message, function: function, line: line, dev: isDev)
    }

    func fine(_ message: String, function: String = #function, line: Int = #line) {
        let devLogLevel = Logger.loggerValDict[currentClassName] ?? "info"
        let isDev = Logger.isDevMode && levelDict[devLogLevel]! >= 2
        if levelDict[currentLevel]! >= 2 || isDev {
            log("👍", message, function: function, line: line, dev: isDev)
        }
    }

    func finer(_ message: String, function: String = #function, line: Int = #line) {
        let devLogLevel = Logger.loggerValDict[currentClassName] ?? "info"
        let isDev = Logger.isDevMode && levelDict[devLogLevel]! >= 3
        if levelDict[currentLevel]! >= 3 || isDev {
            log("👌", message, function: function, line: line, dev: isDev)
        }
    }

    func finest(_ message: String, function: String = #function, line: Int = #line) {
        let devLogLevel = Logger.loggerValDict[currentClassName] ?? "info"
        let isDev = Logger.isDevMode && levelDict[devLogLevel]! >= 4
        if levelDict[currentLevel]! >= 4 || isDev {
            log("🌟", message, function: function, line: line, dev: isDev)
        }
    }

    private func log(_ emoji: String, _ message: String, function: String = #function, line: Int = #line, dev: Bool) {
        let currentDate = Date()
        let customFormattedDate = formatter.string(from: currentDate)
        let printString = "\(emoji) [\(customFormattedDate) - \(currentClassName) - \(function) - line \(line)]: \(message)"
        let loggedMessage = "\(emoji) [\(customFormattedDate) - \(currentClassName)]: \(message)"
        print(printString)
        if customOutput != nil {
            customOutput!.write(message: printString)
        }
        if dev {
            Logger.loggerViewModel.addDevLogMessage(message: loggedMessage)
        } else {
            Logger.loggerViewModel.addLogMessage(message: loggedMessage)
        }
    }

    func setLevel(level: String) {
        currentLevel = levelDict.contains(where: { $0.key == level }) ? level : currentLevel
    }

    func getLevel() -> String {
        return currentLevel
    }
}

protocol LoggerOutput {
    func write(message: String)
}

class LoggerViewModel: ObservableObject {
    private var logger = Logger(current: LoggerViewModel.self)
    @Published var logMessages = [String]()
    @Published var devLogMessages = [String]()
    @Published var loggerValDict = [String: String]()
    init() {}

    func updateLoggerValDict(classDict: [String: String]) {
        DispatchQueue.main.async {
            self.loggerValDict = classDict
        }
    }

    func updateLoggerValDict(className: String, level: String) {
        DispatchQueue.main.async {
            self.loggerValDict[className] = level
        }
    }

    func removeFromLoggerValDict(className: String) {
        DispatchQueue.main.async {
            self.loggerValDict[className] = nil
        }
    }

    func removeAllLoggerValDict(className: String, level: String) {
        DispatchQueue.main.async {
            self.loggerValDict.removeAll()
        }
    }

    func addLogMessage(message: String) {
        DispatchQueue.main.async {
            self.logMessages.append(message)
        }
    }

    func clearLogMessages() {
        DispatchQueue.main.async {
            self.logMessages.removeAll()
        }
    }

    func addDevLogMessage(message: String) {
        DispatchQueue.main.async {
            self.devLogMessages.append(message)
        }
    }

    func clearDevLogMessages() {
        DispatchQueue.main.async {
            self.devLogMessages.removeAll()
        }
    }
}
