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
public class MPSessionManager: NSObject {
    let session: MCSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)

    var incomingFile = CurrentValueSubject<FileTransfer?, Never>(nil)
    var outgoingFile = CurrentValueSubject<FileTransfer?, Never>(nil)

    var connectionState = CurrentValueSubject<MCSessionState, Never>(.notConnected)

    // service has to match Bonjour udp and tcp entries in info.plist
    static let service = "mpd"

    var advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: service)

    var browser: MCNearbyServiceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: service)

    override init() {
        super.init()
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self

        startServices()
    }

    func sendResource(url: URL, withName name: String) {
        if let peer = session.connectedPeers.first {
            let progress = session.sendResource(at: url, withName: name, toPeer: peer, withCompletionHandler: handleFileSent)
            Task {
                await MainActor.run {
                    print("\(MPSessionManager.peerID.displayName) started sending \(name)")
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
                    print("\(MPSessionManager.peerID.displayName) finished sending \(transfer.fileName)")
                    outgoingFile.value = nil
                }
            }
        }
    }

    var connectionName: String = "No Connection"
}

extension MPSessionManager: MCSessionDelegate {
    /*
     * keeps track of connection states
     */
    func startServices() {
        print("starting advertising services")
        advertiser.startAdvertisingPeer()

        print("starting browsing services")
        browser.startBrowsingForPeers()
    }

    func stopServices() {
        print("stopping advertising services")
        advertiser.stopAdvertisingPeer()

        print("stopping browsing services")
        browser.stopBrowsingForPeers()
    }

    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("Session state changed to \(state)")
        if let connectedPeer = session.connectedPeers.first {
            connectionName = connectedPeer.displayName
            stopServices()
        } else {
            connectionName = "No Connection"
            startServices()
        }

        Task {
            await MainActor.run {
                connectionState.value = state
            }
        }
    }

    // Both Advertiser and Browser can receive Data
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    }

    // Empty methods for protocol conformance
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }

    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("started receiving file \(resourceName) from \(peerID.displayName)")
        Task {
            await MainActor.run {
                incomingFile.value = FileTransfer(fileName: resourceName, progress: progress)
            }
        }
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
        print("finished receiving file \(resourceName) from \(peerID.displayName)")
        if let transfer = incomingFile.value, let error {
            print("Error receiving file \(transfer.fileName) : \(error)")
        }
        if let localURL {
            try? FileManager.default.removeItem(at: localURL)
        }
        Task {
            await MainActor.run {
                incomingFile.value = nil
            }
        }
    }
}

extension MPSessionManager: MCNearbyServiceBrowserDelegate {
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        if !session.connectedPeers.contains(where: { $0 == peerID }) {
            print("Found peer \(peerID.displayName), \(MPSessionManager.peerID.displayName) is issuing invite")
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 0)
        } else {
            print("\(MPSessionManager.peerID.displayName) is already connected to \(peerID.displayName)")
        }
    }

    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("\(MPSessionManager.peerID.displayName) lost peer \(peerID.displayName)")
    }
}

extension MPSessionManager: MCNearbyServiceAdvertiserDelegate {
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("ServiceAdvertiser didNotStartAdvertisingPeer: \(String(describing: error))")
    }

    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("\(MPSessionManager.peerID.displayName) is accepting invitation from \(peerID.displayName)")
        invitationHandler(true, session)
    }
}

extension MPSessionManager {
    public static func displayName() -> String {
        String(ProcessInfo.processInfo.hostName.split(separator: ".")[0]) // UIDevice.current.name
    }

    public static var peerID: MCPeerID = getPeerID()
    public static var peerDisplayNameKey = "peerDisplayName"
    public static var peerIdDataKey = "peerID"

    public static func getPeerID() -> MCPeerID {
        let name = displayName()
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

    public static func makePeerID() -> MCPeerID {
        let name = displayName()
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
