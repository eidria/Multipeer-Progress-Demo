////    CustomProgressView.swift
//    Multipeer Progress Demo
//
//    Created by Dan Galbraith on 11/15/24.
//
//    Copyright © 2024 Eidria Inc. All rights reserved.

import SwiftUI

#if os(macOS)
    import AppKit
    typealias SuperClass = NSViewRepresentable
#else
    import UIKit
    typealias SuperClass = UIViewRepresentable
#endif

struct RepresentedProgressView: SuperClass {
    @State public private(set) var progress: Progress

    public init(_ progress: Progress) {
        self.progress = progress
    }

    #if os(macOS)
        func makeNSView(context: Self.Context) -> NSProgressIndicator {
            let view = NSProgressIndicator()
            view.observedProgress = progress
            return view
        }

        func updateNSView(_ uiView: Self.NSViewType, context: Self.Context) {

        }
    #else
        func makeUIView(context: Self.Context) -> UIProgressView {
            let view = UIProgressView()
            view.observedProgress = progress
            return view
        }

        func updateUIView(_ uiView: Self.UIViewType, context: Self.Context) {

        }
    #endif
}
