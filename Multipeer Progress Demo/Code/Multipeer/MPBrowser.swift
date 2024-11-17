//    MPBrowserDelegate.swift
//    Multipeer Progress Demo
//
//    Created by Dan Galbraith on 11/16/24.
//
//    Copyright © 2024 Eidria Inc. All rights reserved.

import Foundation
import MultipeerConnectivity

public class MPBrowser: NSObject, MCNearbyServiceBrowserDelegate {
    var browser: MCNearbyServiceBrowser
    var session: MCSession
    var invitedPeers: Set<MCPeerID> = []

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

    public func browser(
        _ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?
    ) {
        if invitedPeers.isEmpty {
            invitedPeers.insert(peerID)
            print("browser for \(session.name) invited \(peerID.displayName)")
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 60)  // zero timeout == default == 30 seconds
        }
    }

    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("browser for \(session.name) lost \(peerID.displayName)")
        invitedPeers.remove(peerID)
    }
}
