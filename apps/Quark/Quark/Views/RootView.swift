//
//  RootView.swift
//  Quark
//
//  Three tabs, because a learning app with four is a learning app you stop
//  opening. Onboarding covers the whole screen until it is done.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: ProgressStore

    var body: some View {
        Group {
            if store.profile.hasCompletedOnboarding {
                TabView {
                    Tab("Learn", systemImage: "flag.pattern.checkered") {
                        PathView()
                    }
                    Tab("Progress", systemImage: "chart.line.uptrend.xyaxis") {
                        ProfileView()
                    }
                    Tab("Settings", systemImage: "gearshape.fill") {
                        SettingsView()
                    }
                }
                .tint(QuarkTheme.primary)
            } else {
                OnboardingView()
            }
        }
        .animation(QuarkTheme.settle, value: store.profile.hasCompletedOnboarding)
    }
}
