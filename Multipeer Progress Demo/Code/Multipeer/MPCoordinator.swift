import Foundation
import Combine
import PF3DPeerToPeer

public struct FileTransfer {
    var fileName: String
    var progress: Progress?
}

public enum PeerMode: String, CaseIterable, Identifiable {
    public var id: String { self.rawValue }
    
    case client = "Browser"
    case server = "Advertiser"
    case disabled = "Disabled"
}

@Observable
@MainActor
public class MPCoordinator: NSObject {
    let session: MCSession
    let sessionManager: MPSessionManager
    let myName: String
    let incomingFile = CurrentValueSubject<FileTransfer?, Never>(nil)
    let outgoingFile = CurrentValueSubject<FileTransfer?, Never>(nil)
    
    var connectionState = CurrentValueSubject<MCSessionState, Never>(.notConnected)
    var peerMode: PeerMode = .disabled {
        didSet {
            peerModeChanged(oldvalue: oldValue, newvalue: peerMode)
        }
    }
    
    // service has to match Bonjour udp and tcp entries in info.plist
    static let service = "mpd"
    
    var mpAdvertiser: MPAdvertiser?
    var mpBrowser: MPBrowser?
    
    init(peerID: MCPeerID) {
        myName = peerID.displayName
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        sessionManager = MPSessionManager(session: session)
        
        super.init()
        
        Task {
            for await message in sessionManager.sessionActivity.stream {
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
        if let peer = session.connectedPeers.first {
            Task {
                do {
                    let progress = try await session.sendResource(
                        at: url, withName: name, toPeer: peer, withCompletionHandler: handleFileSent)
                    await MainActor.run {
                        print("\(myName) started sending \(name)")
                        outgoingFile.value = FileTransfer(fileName: name, progress: progress)
                    }
                } catch {
                    print("Error sending resource: \(error)")
                    handleFileSent(error)
                }
            }
        }
    }
    
    func peerModeChanged(oldvalue: PeerMode, newvalue: PeerMode) {
        guard oldvalue != newvalue else { return }
        
        stopServices()
        
        mpBrowser = nil
        mpAdvertiser = nil
        
        switch peerMode {
            case .client:
                mpBrowser = MPBrowser(session: session, serviceType: MPCoordinator.service)
            case .server:
                mpAdvertiser = MPAdvertiser(session: session, serviceType: MPCoordinator.service)
            case .disabled:
                ()
        }
        
        startServices()
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
        print("\(session.myPeerID.displayName) state changed to \(state.displayName) for \(peerID.displayName)")
        
        switch state {
            case .notConnected:
                connectionName = "No Connection"
            case .connecting:
                stopServices()
            case .connected:
                connectionName = peerID.displayName
            @unknown default: ()
        }
        
        connectionState.value = state
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
