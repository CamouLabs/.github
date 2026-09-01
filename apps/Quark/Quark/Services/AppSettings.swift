//
//  AppSettings.swift
//  Quark
//
//  Device preferences. Deliberately short: the only switch that touches
//  Apple Intelligence turns generated practice off, and the guardrails are
//  not on this list because they are not optional.
//

import Foundation

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    /// Questions per session.
    @Published var sessionLength: Int {
        didSet { UserDefaults.standard.set(sessionLength, forKey: Keys.sessionLength) }
    }

    /// Whether Apple Intelligence may write bonus practice questions. Hints
    /// and explanations are unaffected; curated content always works.
    @Published var generatedPracticeEnabled: Bool {
        didSet { UserDefaults.standard.set(generatedPracticeEnabled, forKey: Keys.generatedPractice) }
    }

    /// Whether the coach may rewrite hints and explanations on device.
    @Published var coachEnabled: Bool {
        didSet { UserDefaults.standard.set(coachEnabled, forKey: Keys.coach) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    /// Sparks are the app's only pressure. Some learners do better without it.
    @Published var sparksEnabled: Bool {
        didSet { UserDefaults.standard.set(sparksEnabled, forKey: Keys.sparks) }
    }

    private enum Keys {
        static let sessionLength = "Quark.settings.sessionLength"
        static let generatedPractice = "Quark.settings.generatedPractice"
        static let coach = "Quark.settings.coach"
        static let haptics = "Quark.settings.haptics"
        static let sparks = "Quark.settings.sparks"
    }

    private init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            Keys.sessionLength: SessionBuilder.defaultLength,
            Keys.generatedPractice: true,
            Keys.coach: true,
            Keys.haptics: true,
            Keys.sparks: true
        ])
        sessionLength = defaults.integer(forKey: Keys.sessionLength)
        generatedPracticeEnabled = defaults.bool(forKey: Keys.generatedPractice)
        coachEnabled = defaults.bool(forKey: Keys.coach)
        hapticsEnabled = defaults.bool(forKey: Keys.haptics)
        sparksEnabled = defaults.bool(forKey: Keys.sparks)
    }
}
