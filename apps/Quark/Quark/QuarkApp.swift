//
//  QuarkApp.swift
//  Quark
//
//  Entry point. Two shared stores are injected here and nowhere else, and the
//  on-device model is prewarmed on launch so the first hint of a session does
//  not pay the cold-start cost.
//

import SwiftUI

@main
@MainActor
struct QuarkApp: App {
    @StateObject private var store = ProgressStore.shared
    @StateObject private var settings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(settings)
                .tint(QuarkTheme.primary)
                .task {
                    guard settings.coachEnabled else { return }
                    ReasonerFactory.make().prewarm()
                }
        }
    }
}
