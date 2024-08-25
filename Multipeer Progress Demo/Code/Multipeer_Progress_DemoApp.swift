////    Multipeer_Progress_DemoApp.swift
//    Multipeer Progress Demo
//
//    Created by Dan Galbraith on 8/24/24.
//
//    Copyright © 2024 Eidria Inc. All rights reserved.

import SwiftUI

@main
@MainActor
struct Multipeer_Progress_DemoApp: App {
    let windowWidth: CGFloat = 400
    let windowheight: CGFloat = 400
    @State var appModel = AppModel()
    var body: some Scene {
        #if os(macOS)
            WindowGroup {
                ContentView()
                    .environment(appModel)
                    .environment(appModel.sessionManager)
                    .frame(
                        minWidth: windowWidth, maxWidth: windowWidth,
                        minHeight: windowheight, maxHeight: windowheight)
            }
            .windowResizability(.contentSize)
        #else
            WindowGroup {
                ContentView()
                    .environment(appModel)
                    .environment(appModel.sessionManager)
            }
        #endif
    }
}
