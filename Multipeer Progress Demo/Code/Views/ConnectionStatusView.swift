////    ConnectionStatusView.swift
//    Multipeer Progress Demo
//
//    Created by Dan Galbraith on 8/24/24.
//
//    Copyright © 2024 Eidria Inc. All rights reserved.


import SwiftUI
import MultipeerConnectivity

struct ConnectionStatusView: View {
    @Environment(MPSessionManager.self) var sessionManager
    @Environment(AppModel.self) var appModel
    
    @State var connectionName:String = ""
    @State var connectionState:MCSessionState = .notConnected
    
    var body: some View {
        GroupBox("Connection") {
            VStack {
                Text(verbatim: connectionName)
                    .padding()
                
                Button {
                    appModel.isSendingFiles.toggle()
                } label: {
                    Text(verbatim: appModel.isSendingFiles ? "Stop File Send" : "Start File Send")
                }
                .buttonStyle(.bordered)
                .disabled(connectionState != .connected)
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onReceive(sessionManager.connectionState) { state in
            connectionState = state
            connectionName = sessionManager.connectionName
        }
    }
}

#Preview {
    ConnectionStatusView()
}
