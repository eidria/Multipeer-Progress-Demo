//    MCPeerID+.swift
//    Multipeer Progress Demo
//
//    Created by Dan Galbraith on 11/16/24.
//
//    Copyright © 2024 Eidria Inc. All rights reserved.

import Foundation
import MultipeerConnectivity

public extension MCSession {
    var name: String {
        myPeerID.displayName
    }
}

public extension MCSessionState {
    var displayName: String {
        switch self {
        case .connected: return "Connected"
        case .connecting: return "Connecting"
        case .notConnected: return "Not Connected"
        @unknown default:
            return "Unknown"
        }
    }
}

public extension MCPeerID {
    static var peerDisplayNameKey = "peerDisplayName"
    static var peerIdDataKey = "peerID"
    
    static func getPeerID() -> MCPeerID {
        let name = ProcessInfo.hostDisplayName()
        var peerID: MCPeerID?
        
        if let oldName = UserDefaults.standard.string(forKey: peerDisplayNameKey) {
            if oldName == name {
                if let data = UserDefaults.standard.data(forKey: peerIdDataKey) {
                    do {
                        peerID = try NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data)
                    } catch {
                        peerID = nil
                        print("\(error)")
                    }
                }
            }
        }
        
        return peerID ?? makePeerID()
    }
    
    static func makePeerID() -> MCPeerID {
        let name = ProcessInfo.hostDisplayName()
        let peerID = MCPeerID(displayName: name)
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: peerID, requiringSecureCoding: false)
            UserDefaults.standard.setValue(data, forKey: peerIdDataKey)
            UserDefaults.standard.setValue(name, forKey: peerDisplayNameKey)
            UserDefaults.standard.synchronize()
        } catch {
            print("\(error)")
        }
        
        return peerID
    }
}

