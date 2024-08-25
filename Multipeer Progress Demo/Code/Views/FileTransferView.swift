////    FileTransferView.swift
//    Multipeer Progress Demo
//
//    Created by Dan Galbraith on 8/24/24.
//
//    Copyright © 2024 Eidria Inc. All rights reserved.

import SwiftUI

struct FileTransferView: View {
    @State var viewTitle: String
    @Binding var fileTransfer: FileTransfer?

    var body: some View {
        GroupBox(viewTitle) {
            VStack {
                if let transfer = fileTransfer, let progress = fileTransfer?.progress {
                    Text(verbatim: transfer.fileName)
                    ProgressView(progress)
                } else {
                    Text(verbatim: fileTransfer?.fileName ?? "No activity")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// #Preview {
//    FileTransferView()
// }
