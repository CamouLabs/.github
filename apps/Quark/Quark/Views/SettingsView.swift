//
//  SettingsView.swift
//  Quark
//
//  Preferences, plus the part of the app that shows its work: what Apple
//  Intelligence is doing, the coach's principles verbatim, and all eleven
//  guardrails with the reason each one exists.
//
//  Guardrails are not on this screen as switches. They are not optional.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: ProgressStore

    @State private var reasonerStatus = ReasonerFactory.make().statusDetail
    @State private var isResetConfirmationPresented = false

    var body: some View {
        NavigationStack {
            Form {
                sessionSection
                intelligenceSection
                trustSection
                trackSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(QuarkTheme.background)
            .navigationTitle("Settings")
        }
    }

    // MARK: - Session

    private var sessionSection: some View {
        Section {
            Stepper(value: $settings.sessionLength, in: SessionBuilder.minLength...SessionBuilder.maxLength) {
                LabeledContent("Questions per session", value: "\(settings.sessionLength)")
            }

            Picker("Daily goal", selection: dailyGoalBinding) {
                Text("Casual · 20 XP").tag(20)
                Text("Steady · 50 XP").tag(50)
                Text("Serious · 100 XP").tag(100)
                Text("Intense · 200 XP").tag(200)
            }

            Toggle("Sparks", isOn: $settings.sparksEnabled)
            Toggle("Haptics", isOn: $settings.hapticsEnabled)
        } header: {
            Text("Practice")
        } footer: {
            Text("Sparks end a session after five wrong answers. Turning them off removes the only time pressure in the app — some learners do better without it.")
        }
    }

    private var dailyGoalBinding: Binding<Int> {
        Binding(
            get: { store.profile.dailyGoalXP },
            set: { store.setDailyGoal($0) }
        )
    }

    // MARK: - Apple Intelligence

    private var intelligenceSection: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(QuarkTheme.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Intelligence")
                        .font(.system(size: 15, weight: .semibold))
                    Text(reasonerStatus)
                        .font(.system(size: 12))
                        .foregroundStyle(QuarkTheme.textSecondary)
                }
            }

            Toggle("Coach writes hints and explanations", isOn: $settings.coachEnabled)
            Toggle("Bonus questions written on device", isOn: $settings.generatedPracticeEnabled)
        } header: {
            Text("Intelligence")
        } footer: {
            Text("Everything runs on this device through Apple's on-device model. With both switches off, Quark uses only the hints and explanations that ship with each lesson — nothing breaks.")
        }
    }

    // MARK: - Trust

    private var trustSection: some View {
        Section {
            NavigationLink {
                GuardrailListView()
            } label: {
                Label("Guardrails", systemImage: "checkmark.shield.fill")
            }

            NavigationLink {
                ConstitutionView()
            } label: {
                Label("How the coach behaves", systemImage: "text.book.closed.fill")
            }

            NavigationLink {
                PrivacyView()
            } label: {
                Label("Privacy", systemImage: "lock.fill")
            }
        } header: {
            Text("Trust")
        }
    }

    // MARK: - Tracks

    private var trackSection: some View {
        Section {
            ForEach(TrackID.allCases) { track in
                Button {
                    toggle(track)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: track.symbol)
                            .foregroundStyle(QuarkTheme.color(for: track))
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(track.title)
                                .foregroundStyle(QuarkTheme.textPrimary)
                            Text("\(Curriculum.course(for: track).lessons.count) lessons")
                                .font(.system(size: 12))
                                .foregroundStyle(QuarkTheme.textSecondary)
                        }
                        Spacer()
                        if store.profile.tracks.contains(track) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(QuarkTheme.primary)
                        }
                    }
                }
            }
        } header: {
            Text("Tracks")
        } footer: {
            Text("Only the tracks you pick appear on the path. Progress in a track you remove is kept.")
        }
    }

    private func toggle(_ track: TrackID) {
        var tracks = store.profile.tracks
        if let index = tracks.firstIndex(of: track) {
            guard tracks.count > 1 else { return }
            tracks.remove(at: index)
        } else {
            tracks.append(track)
        }
        store.setTracks(tracks)
        Haptics.tap()
    }

    // MARK: - Data

    private var dataSection: some View {
        Section {
            Button("Reset all progress", role: .destructive) {
                isResetConfirmationPresented = true
            }
            .confirmationDialog(
                "Reset all progress?",
                isPresented: $isResetConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("Reset everything", role: .destructive) { store.resetEverything() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("XP, streak, and every skill record are deleted from this device. There is no copy anywhere else, so this cannot be undone.")
            }
        } header: {
            Text("Data")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            LabeledContent("Lessons", value: "\(Curriculum.allLessons.count)")
            LabeledContent("Questions", value: "\(Curriculum.allExercises.count)")
            LabeledContent("Version", value: Bundle.main.shortVersion)
        } header: {
            Text("About Quark")
        } footer: {
            Text("Quark is a Camou Labs app. Built for iOS 26, on-device only.")
        }
    }
}

// MARK: - Guardrails

struct GuardrailListView: View {
    var body: some View {
        List {
            Section {
                Text("Apple Intelligence has its own safety guardrails, and they run first. These are Quark's: eleven deterministic checks on anything the model writes, before a learner sees it.")
                    .font(.system(size: 14))
                    .foregroundStyle(QuarkTheme.textSecondary)
            }

            Section {
                ForEach(GuardrailID.allCases) { guardrail in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(guardrail.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(QuarkTheme.textPrimary)
                        Text(guardrail.rationale)
                            .font(.system(size: 13))
                            .foregroundStyle(QuarkTheme.textSecondary)
                    }
                    .padding(.vertical, 3)
                }
            } header: {
                Text("Every check")
            } footer: {
                Text("A failed check is repaired if it safely can be, and replaced with the lesson's built-in text if it cannot. The learner is never shown an error where a hint should be.")
            }
        }
        .navigationTitle("Guardrails")
    }
}

struct ConstitutionView: View {
    var body: some View {
        List {
            Section {
                Text("These six lines are given to the model as instructions, and they are also what the app uses to rewrite a draft that broke one of them. This is the whole set — nothing is withheld.")
                    .font(.system(size: 14))
                    .foregroundStyle(QuarkTheme.textSecondary)
            }

            Section {
                ForEach(Array(QuarkConstitution.principles.enumerated()), id: \.offset) { index, principle in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(QuarkTheme.primary)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(QuarkTheme.primary.opacity(0.12)))
                        Text(principle)
                            .font(.system(size: 15))
                            .foregroundStyle(QuarkTheme.textPrimary)
                    }
                    .padding(.vertical, 3)
                }
            } header: {
                Text("Principles")
            }
        }
        .navigationTitle("The coach")
    }
}

struct PrivacyView: View {
    private struct Promise: Identifiable {
        let symbol: String
        let title: String
        let detail: String
        var id: String { title }
    }

    private static let promises: [Promise] = [
        Promise(
            symbol: "iphone",
            title: "On device, always",
            detail: "Lessons, questions, hints, and explanations are all generated and graded on this iPhone."
        ),
        Promise(
            symbol: "wifi.slash",
            title: "No network calls",
            detail: "Quark makes none. It works in airplane mode, and there is no account to create."
        ),
        Promise(
            symbol: "folder.fill",
            title: "One local file",
            detail: "Your XP, streak, and skill records live in a single JSON file in the app's own container."
        ),
        Promise(
            symbol: "trash.fill",
            title: "Deleting is deleting",
            detail: "Removing the app removes everything. Reset in Settings does the same thing immediately."
        ),
        Promise(
            symbol: "eye.slash.fill",
            title: "Nothing to sell",
            detail: "There is no analytics SDK, no advertising identifier, and no crash reporter in this app."
        )
    ]

    var body: some View {
        List {
            ForEach(Self.promises) { promise in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: promise.symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(QuarkTheme.primary)
                        .frame(width: 26)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(promise.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(QuarkTheme.textPrimary)
                        Text(promise.detail)
                            .font(.system(size: 13))
                            .foregroundStyle(QuarkTheme.textSecondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Privacy")
    }
}

extension Bundle {
    var shortVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }
}
