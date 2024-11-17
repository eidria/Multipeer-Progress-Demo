//    MPSessionManager.swift
//    Multipeer Progress Demo
//
//    Created by Dan Galbraith on 8/24/24.
//
//    Copyright © 2024 Eidria Inc. All rights reserved.

import Combine
import Foundation
import MultipeerConnectivity

public struct FileTransfer {
    var fileName: String
    var progress: Progress?
}

@Observable
@MainActor
public class MPCoordinator: NSObject {
    let mcSession: MCSession
    let mpSession: MPSessionManager
    let myName: String
    let incomingFile = CurrentValueSubject<FileTransfer?, Never>(nil)
    let outgoingFile = CurrentValueSubject<FileTransfer?, Never>(nil)

    var connectionState = CurrentValueSubject<MCSessionState, Never>(.notConnected)

    // service has to match Bonjour udp and tcp entries in info.plist
    static let service = "mpd"

    let mpAdvertiser: MPAdvertiser?
    let mpBrowser: MPBrowser?

    init(peerID: MCPeerID) {
        myName = peerID.displayName
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        mpSession = MPSessionManager(session: mcSession)
        
        #if os(macOS)
        mpAdvertiser = MPAdvertiser(session: mcSession, serviceType: MPCoordinator.service)
        mpBrowser = nil
        #else
        mpBrowser = MPBrowser(session: mcSession, serviceType: MPCoordinator.service)
        mpAdvertiser = nil
        #endif
        
        super.init()

        Task {
            for await message in mpSession.sessionActivity.stream {
                switch message {
                case let .sessionChange(session, peerID, state):
                    handleSessionChange(session: session, peerID: peerID, state: state)
                case let .data(session, peerID, data):
                    handleReceivedData(session: session, peerID: peerID, data: data)
                case let .startResourceReceive(session, peerID, resourceName, progress):
                    handleStartReceivingResource(
                        session: session, peerID: peerID, resourceName: resourceName, progress: progress)
                case let .finishResourceReceive(session, peerID, resourceName, localURL, error):
                    handleFinishReceivingResource(
                        session: session, peerID: peerID, resourceName: resourceName, localURL: localURL, error: error)
                }
            }
        }
        startServices()
    }

    func sendResource(url: URL, withName name: String) {
        if let peer = mcSession.connectedPeers.first {
            let progress = mcSession.sendResource(
                at: url, withName: name, toPeer: peer, withCompletionHandler: handleFileSent)
            Task {
                await MainActor.run {
                    print("\(myName) started sending \(name)")
                    outgoingFile.value = FileTransfer(fileName: name, progress: progress)
                }
            }
        }
    }

    func handleFileSent(_ error: Error?) {
        if let transfer = outgoingFile.value {
            if let error {
                print("Error send file \(transfer.fileName) : \(error)")
            }
            Task {
                await MainActor.run {
                    print("\(myName) finished sending \(transfer.fileName)")
                    outgoingFile.value = nil
                }
            }
        }
    }

    var connectionName: String = "No Connection"

    /*
     * keeps track of connection states
     */
    func startServices() {
        if let mpAdvertiser {
            print("\(myName) starting advertising services")
            mpAdvertiser.startAdvertising()
        }
        
        if let mpBrowser {
            print("\(myName) starting browsing services")
            mpBrowser.startBrowsing()
        }
    }

    func stopServices() {
        if let mpAdvertiser {
            print("\(myName) stopping advertising services")
            mpAdvertiser.stopAdvertising()
        }
 
        if let mpBrowser {
            print("\(myName) stopping browsing services")
            mpBrowser.stopBrowsing()
        }
    }

    public func handleSessionChange(session: MCSession, peerID: MCPeerID, state: MCSessionState) {
        connectionState.value = state

        switch state {
        case .notConnected:
            print("\(myName) Session state changed to .notConnected")
            connectionName = "No Connection"
        //                   startServices()
        case .connecting:
//            session.nearbyConnectionData(forPeer: peerID) { data, error in
//                if let data {
//                    session.connectPeer(peerID, withNearbyConnectionData: data)
//                } else {
//                    print(
//                        "connecting to peer \(peerID.displayName) failed: \(error?.localizedDescription ?? "unknown error")"
//                    )
//                }
//            }
            print("\(myName) Session state changed to .connecting")
        //                   stopServices()
        case .connected:
            print("\(myName) Session state changed to .connected")
            if let connectedPeer = session.connectedPeers.first {
                connectionName = connectedPeer.displayName
            }
        @unknown default:
            print("\(myName) Session state changed to @unknown default")
        }
    }

    public func handleReceivedData(session: MCSession, peerID: MCPeerID, data: Data) {

    }

    public func handleStartReceivingResource(
        session: MCSession, peerID: MCPeerID, resourceName: String, progress: Progress
    ) {
        print("\(myName) started receiving file \(resourceName) from \(peerID.displayName)")
        incomingFile.value = FileTransfer(fileName: resourceName, progress: progress)
    }

    public func handleFinishReceivingResource(
        session: MCSession, peerID: MCPeerID, resourceName: String, localURL: URL?, error: (any Error)?
    ) {
        print("\(myName) finished receiving file \(resourceName) from \(peerID.displayName)")
        if let transfer = incomingFile.value, let error {
            print("\(myName) Error receiving file \(transfer.fileName) : \(error)")
        }
        if let localURL {
            try? FileManager.default.removeItem(at: localURL)
        }
        incomingFile.value = nil
    }
}
