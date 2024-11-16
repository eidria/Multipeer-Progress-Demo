////    CustomProgressView.swift
//    Multipeer Progress Demo
//
//    Created by Dan Galbraith on 11/15/24.
//
//    Copyright © 2024 Eidria Inc. All rights reserved.

import AppKit
import SwiftUI

struct CustomProgressView: NSViewRepresentable {
    @State public private(set) var progress: Progress

    public init(_ progress: Progress) {
        self.progress = progress
    }

    func makeNSView(context: Self.Context) -> NSProgressIndicator {
        let view = NSProgressIndicator()
        view.observedProgress = progress
        return view
    }

    func updateNSView(_ uiView: Self.NSViewType, context: Self.Context) {

    }
}

//#Preview {
//    CustomProgressView()
//}
