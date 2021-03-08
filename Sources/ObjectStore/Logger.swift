//
//  Logger.swift
//  
//
//  Created by Maddie Schipper on 2/27/21.
//

import Foundation
import OSLog

internal let LoggerSubsystemName: String = {
    if let identifier = Bundle.main.bundleIdentifier {
        return identifier
    }
    return "dev.schipper.ObjectStore-Subsystem"
}()

internal let OMLog = Logger(subsystem: LoggerSubsystemName, category: "obj-manager")
