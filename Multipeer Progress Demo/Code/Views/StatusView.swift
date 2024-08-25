////    StatusView.swift
//    Multipeer Progress Demo
//
//    Created by Dan Galbraith on 8/24/24.
//
//    Copyright © 2024 Eidria Inc. All rights reserved.

import SwiftUI

@MainActor
struct StatusView: View {
    @Environment(AppModel.self) var appModel
    @Environment(MPSessionManager.self) var sessionManager
    @State var incomingFileTransfer: FileTransfer?
    @State var outgoingFileTransfer: FileTransfer?

    var body: some View {
        VStack {
            displayGrid
                .onReceive(sessionManager.incomingFile) { transfer in
                    incomingFileTransfer = transfer
                }
                .onReceive(sessionManager.outgoingFile) { transfer in
                    outgoingFileTransfer = transfer
                }
        }
    }

    var displayGrid: some View {
        Grid {
            GridRow {
                connectionStatus
            }
            GridRow {
                incomingFileStatus
            }
            GridRow {
                outgoingFileStatus
            }
        }
        .padding()
    }

    var connectionStatus: some View {
        ConnectionStatusView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var incomingFileStatus: some View {
        FileTransferView(viewTitle: "Incoming File Activity", fileTransfer: $incomingFileTransfer)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var outgoingFileStatus: some View {
        FileTransferView(viewTitle: "Outgoing File Activity", fileTransfer: $outgoingFileTransfer)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    StatusView()
}
