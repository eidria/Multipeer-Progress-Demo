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
    let mySession: MCSession

    var myName: String { mySession.myPeerID.displayName }

    var incomingFile = CurrentValueSubject<FileTransfer?, Never>(nil)
    var outgoingFile = CurrentValueSubject<FileTransfer?, Never>(nil)

    var connectionState = CurrentValueSubject<MCSessionState, Never>(.notConnected)

    // service has to match Bonjour udp and tcp entries in info.plist
    static let service = "mpd"

    let myAdvertiser: MCNearbyServiceAdvertiser
    let myBrowser: MCNearbyServiceBrowser

    init(peerID: MCPeerID) {
        mySession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        myAdvertiser = MCNearbyServiceAdvertiser(
            peer: peerID, discoveryInfo: nil, serviceType: MPSessionManager.service)
        myBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: MPSessionManager.service)

        super.init()

        mySession.delegate = self
        myAdvertiser.delegate = self
        myBrowser.delegate = self

        startServices()
    }

    func sendResource(url: URL, withName name: String) {
        if let peer = mySession.connectedPeers.first {
            let progress = mySession.sendResource(
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
}

extension MPSessionManager: MCSessionDelegate {
    /*
     * keeps track of connection states
     */
    func startServices() {
        #if os(macOS)
            print("\(myName) starting advertising services")
            myAdvertiser.startAdvertisingPeer()
        #else
            print("\(myName) starting browsing services")
            myBrowser.startBrowsingForPeers()
        #endif
    }

    func stopServices() {
        #if os(macOS)
            print("\(myName) stopping advertising services")
            myAdvertiser.stopAdvertisingPeer()
        #else
            print("\(myName) stopping browsing services")
            myBrowser.stopBrowsingForPeers()
        #endif
    }

    func canConnect(to peer: MCPeerID) -> Bool {
        if mySession.connectedPeers.isEmpty && connectionState.value == .notConnected {
            if peer != mySession.myPeerID {
                print("\(myName) can connect to \(peer.displayName)")
                return true
            } else {
                print("\(myName) is trying to connect to itself")
            }
        } else {
            print("\(myName) CANNOT connect to \(peer.displayName)")
        }

        return false
    }

    nonisolated public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task {
            await MainActor.run {
                guard peerID == mySession.myPeerID else {
                    print("\(myName) received state change for \(peerID.displayName): \(state.name)")
                    return
                }

                guard session == mySession else {
                    print("State change received for somebody elses session")
                    return
                }

                connectionState.value = state

                switch state {
                case .notConnected:
                    print("\(myName) Session state changed to .notConnected")
                    connectionName = "No Connection"
                //                   startServices()
                case .connecting:
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
        }
    }

    // Both Advertiser and Browser can receive Data
    nonisolated public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    }

    // Empty methods for protocol conformance
    nonisolated public func session(
        _ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID
    ) {
    }

    nonisolated public func session(
        _ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        Task {
            await MainActor.run {
                print("\(myName) started receiving file \(resourceName) from \(peerID.displayName)")
                incomingFile.value = FileTransfer(fileName: resourceName, progress: progress)
            }
        }
    }

    nonisolated public func session(
        _ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID,
        at localURL: URL?, withError error: (any Error)?
    ) {
        Task {
            await MainActor.run {
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
    }
}

extension MPSessionManager: MCNearbyServiceBrowserDelegate {
    nonisolated public func browser(
        _ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?
    ) {
        Task {
            await MainActor.run {
                if canConnect(to: peerID) {
                    print(
                        "\(myName) found peer \(peerID.displayName), \(myName) is issuing invite"
                    )
                    browser.invitePeer(peerID, to: mySession, withContext: nil, timeout: 0)
                } else {
                    print("\(myName) is already connected to \(peerID.displayName)")
                }
            }
        }
    }

    nonisolated public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task {
            await MainActor.run {
                print("\(myName) lost peer \(peerID.displayName)")
            }
        }
    }
}

extension MPSessionManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error)
    {
        print("ServiceAdvertiser didNotStartAdvertisingPeer: \(String(describing: error))")
    }

    nonisolated public func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Task {
            await MainActor.run {
                print("\(myName) received invitation from \(peerID.displayName)")
                let connect = canConnect(to: peerID)
                invitationHandler(connect, mySession)
                if connect {
                    print("\(myName) accepted invitation from \(peerID.displayName)")
                } else {
                    print("\(myName) declined invitation from \(peerID.displayName)")
                }
            }
        }
    }
}

extension MPSessionManager {
    public static func displayName() -> String {
        String(ProcessInfo.processInfo.hostName.split(separator: ".")[0])  // UIDevice.current.name
    }

    //    public static var peerID: MCPeerID = getPeerID()
    //    public static var peerDisplayName: String = "N/A"
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

extension MCSession {
    public var name: String {
        myPeerID.displayName
    }
}

extension MCSessionState {
    public var name: String {
        switch self {
        case .connected: return "Connected"
        case .connecting: return "Connecting"
        case .notConnected: return "Not Connected"
        @unknown default:
            return "Unknown"
        }
    }
}
