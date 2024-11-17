//    ProcessInfo+.swift
//    Multipeer Progress Demo
//
//    Created by Dan Galbraith on 11/16/24.
//
//    Copyright © 2024 Eidria Inc. All rights reserved.

import Foundation

public extension ProcessInfo {
    static func hostDisplayName() -> String {
        String(ProcessInfo.processInfo.hostName.split(separator: ".")[0])  // UIDevice.current.name
    }
}

