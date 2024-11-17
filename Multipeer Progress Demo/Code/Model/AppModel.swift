//    AppModel.swift
//    Multipeer Progress Demo
//
//    Created by Dan Galbraith on 8/24/24.
//
//    Copyright © 2024 Eidria Inc. All rights reserved.

import Foundation
import Combine
import MultipeerConnectivity

@Observable
@MainActor
class AppModel {
    var sessionManager: MPCoordinator
    var isSendingFiles = false {
        didSet {
            if !isSendingFiles {
                fileSendIndex = 0
            } else {
                sendFile()
            }
        }
    }
    
    var fileSentCancellable: AnyCancellable?
    
    var fileSendIndex = 0
    
    var sendFileURL = Bundle.main.url(forResource: "image", withExtension: "HEIC")!
    
    init() {
        sessionManager = MPCoordinator(peerID: MCPeerID.makePeerID())
        fileSentCancellable = sessionManager.outgoingFile.sink { maybeTransfer in
            // Outgoing transfer is set to nil when the transfer completes
            if self.isSendingFiles && maybeTransfer == nil {
                self.sendFile()
            }
        }
    }
    
    func sendFile() {
        if isSendingFiles {
            fileSendIndex += 1
            let resourceName = "File \(fileSendIndex)"
            sessionManager.sendResource(url: sendFileURL, withName: resourceName)
        }
    }
}

