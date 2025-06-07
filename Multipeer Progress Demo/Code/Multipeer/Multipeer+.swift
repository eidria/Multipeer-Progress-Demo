//    MCPeerID+.swift
//    Multipeer Progress Demo
//
//    Created by Dan Galbraith on 11/16/24.
//
//    Copyright © 2024 Eidria Inc. All rights reserved.

import Foundation
//import MultipeerConnectivity
import PF3DPeerToPeer

extension MCSession {
    public var name: String {
        myPeerID.displayName
    }
}

extension MCSessionState {
    public var displayName: String {
        switch self {
        case .connected: return "Connected"
        case .connecting: return "Connecting"
        case .notConnected: return "Not Connected"
        @unknown default:
            return "Unknown"
        }
    }
}

extension MCPeerID {
    public static let peerIdDataKey = "peerID"

    public static func getPeerID() -> MCPeerID {
        let name = ProcessInfo.hostDisplayName()
        var peerID: MCPeerID?

        if let data = UserDefaults.standard.data(forKey: peerIdDataKey) {
            do {
                peerID = try JSONDecoder().decode(MCPeerID.self, from: data)
            } catch {
                peerID = nil
                print("\(error)")
            }
        }

        return peerID ?? makePeerID()
    }

    public static func makePeerID() -> MCPeerID {
        let name = ProcessInfo.hostDisplayName()
        let peerID = MCPeerID(displayName: name)

        do {
            let data = try JSONEncoder().encode(peerID)
            UserDefaults.standard.setValue(data, forKey: peerIdDataKey)
            UserDefaults.standard.synchronize()
        } catch {
            print("\(error)")
        }

        return peerID
    }
}
