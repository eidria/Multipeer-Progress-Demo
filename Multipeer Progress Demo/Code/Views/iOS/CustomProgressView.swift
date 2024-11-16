////    CustomProgressView.swift
//    Multipeer Progress Demo
//
//    Created by Dan Galbraith on 11/15/24.
//
//    Copyright © 2024 Eidria Inc. All rights reserved.

import SwiftUI
import UIKit

struct CustomProgressView: UIViewRepresentable {
    @State public private(set) var progress: Progress

    public init(_ progress: Progress) {
        self.progress = progress
    }

    func makeUIView(context: Self.Context) -> UIProgressView {
        let view = UIProgressView()
        view.observedProgress = progress
        return view
    }

    func updateUIView(_ uiView: Self.UIViewType, context: Self.Context) {

    }
}

//#Preview {
//    CustomProgressView()
//}
