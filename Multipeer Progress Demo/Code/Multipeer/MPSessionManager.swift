//    MPBrowserDelegate.swift
//    Multipeer Progress Demo
//
//    Created by Dan Galbraith on 11/16/24.
//
//    Copyright © 2024 Eidria Inc. All rights reserved.

import Foundation
import MultipeerConnectivity
import Synchronization

class MPSessionManager: NSObject, MCSessionDelegate {
    public enum SessionMessage {
        case sessionChange(MCSession, MCPeerID, MCSessionState)
        case data(MCSession, MCPeerID, Data)
        case startResourceReceive(MCSession, MCPeerID, String, Progress)
        case finishResourceReceive(MCSession, MCPeerID, String, URL?, (any Error)?)
    }
    
    let sessionActivity = AsyncStreamHandler<SessionMessage>()
    
    init(session: MCSession) {
        super.init()
        session.delegate = self
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        sessionActivity.add(.sessionChange(session, peerID, state))
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        sessionActivity.add(.data(session, peerID, data))
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        sessionActivity.add(.startResourceReceive(session, peerID, resourceName, progress))
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
        sessionActivity.add(.finishResourceReceive(session, peerID, resourceName, localURL, error))
    }
}

