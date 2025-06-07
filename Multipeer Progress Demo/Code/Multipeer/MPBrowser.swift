//    MPBrowserDelegate.swift
//    Multipeer Progress Demo
//
//    Created by Dan Galbraith on 11/16/24.
//
//    Copyright © 2024 Eidria Inc. All rights reserved.

import Foundation
//import MultipeerConnectivity
import PF3DPeerToPeer

@Observable
@MainActor
public class MPBrowser: NSObject {
    var browser: MCNearbyServiceBrowser
    var session: MCSession
    public var invitedPeers: Set<MCPeerID> = []

    public init(session: MCSession, serviceType: String) {
        self.session = session
        browser = MCNearbyServiceBrowser(peer: session.myPeerID, serviceType: serviceType)
        super.init()
        browser.delegate = self
    }

    public func startBrowsing() {
        browser.startBrowsingForPeers()
    }

    public func stopBrowsing() {
        browser.stopBrowsingForPeers()
    }
}

@MainActor
extension MPBrowser {
    public func handlePeerFound(
        foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?
    ) {
        if !invitedPeers.contains(peerID) {
            print("ServiceBrowser.browser() found: \(peerID.displayName)")
            invitedPeers.insert(peerID)
        }
    }
    
    public func handleLostPeer(lostPeer peerID: MCPeerID) {
        print("ServiceBrowser.browser() near by peer has been lost: \(peerID.displayName)")
        invitedPeers.remove(peerID)
    }
}

extension MPBrowser: MCNearbyServiceBrowserDelegate {
    nonisolated public func browser(_ browser: PF3DPeerToPeer.MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: any Error) {
        // Handle the error
    }
    

    
    nonisolated public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
//        if invitedPeers.isEmpty && peerID.displayName != "localhost" {
//            invitedPeers.insert(peerID)
//            print("browser for \(session.name) invited \(peerID.displayName)")
//            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30.0)  // zero timeout == default == 30 seconds
//        }
        
        Task {
            await MainActor.run {
                self.handlePeerFound(foundPeer: peerID, withDiscoveryInfo: info)
            }
        }
    }
    
    nonisolated public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        //print("browser for \(session.name) lost \(peerID.displayName)")
        //invitedPeers.remove(peerID)
        
        Task {
            await MainActor.run {
                self.handleLostPeer(lostPeer: peerID)
            }
        }
    }
}
