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
    @State var appModel = AppModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .environment(appModel.sessionManager)
        }
    }
}
