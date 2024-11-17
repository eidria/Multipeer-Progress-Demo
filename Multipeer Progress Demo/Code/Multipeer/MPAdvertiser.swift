//    MPBrowserDelegate.swift
//    Multipeer Progress Demo
//
//    Created by Dan Galbraith on 11/16/24.
//
//    Copyright © 2024 Eidria Inc. All rights reserved.

import Foundation
import MultipeerConnectivity

public class MPAdvertiser: NSObject, MCNearbyServiceAdvertiserDelegate {
    var session: MCSession
    var advertiser: MCNearbyServiceAdvertiser

    public init(session: MCSession, serviceType: String) {
        self.session = session
        advertiser = MCNearbyServiceAdvertiser(peer: session.myPeerID, discoveryInfo: nil, serviceType: serviceType)
        super.init()
        advertiser.delegate = self
    }

    public func startAdvertising() {
        advertiser.startAdvertisingPeer()
    }

    public func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
    }

    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: any Error) {
        print("Error advertising: \(error)")
    }

    public func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        if session.connectedPeers.isEmpty {
            print("\(session.name) is accepting invitation from: \(peerID.displayName)")
            invitationHandler(true, session)
        } else {
            print("\(session.name) is declining invitation from: \(peerID.displayName)")
            invitationHandler(false, nil)
        }
    }
}
