//
//  LearnerProfile.swift
//  Quark
//
//  Everything Quark knows about a learner — and all of it lives in a single
//  Codable value written to the app's own container. There is no account, no
//  sync, and no server that could read this.
//

import Foundation

/// A calendar day as `yyyy-MM-dd`, so streaks compare cleanly across time
/// zones and survive encoding without date-math surprises.
struct LearningDay: Codable, Sendable, Equatable, Hashable, Comparable {
    let value: String

    init(value: String) { self.value = value }

    init(date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.value = String(
            format: "%04d-%02d-%02d",
            parts.year ?? 0, parts.month ?? 0, parts.day ?? 0
        )
    }

    static func < (lhs: LearningDay, rhs: LearningDay) -> Bool { lhs.value < rhs.value }

    func adding(days: Int, calendar: Calendar = .current) -> LearningDay {
        guard let date = calendar.date(from: components()),
              let moved = calendar.date(byAdding: .day, value: days, to: date)
        else { return self }
        return LearningDay(date: moved, calendar: calendar)
    }

    private func components() -> DateComponents {
        let parts = value.split(separator: "-").compactMap { Int($0) }
        var components = DateComponents()
        if parts.count == 3 {
            components.year = parts[0]
            components.month = parts[1]
            components.day = parts[2]
        }
        return components
    }
}

/// Per-lesson memory strength. `halfLifeDays` is the fitted forgetting
/// half-life used by SpacedRepetition to schedule reviews.
struct SkillRecord: Codable, Sendable, Equatable {
    var correct: Int = 0
    var incorrect: Int = 0
    var consecutiveCorrect: Int = 0
    var halfLifeDays: Double = SpacedRepetition.initialHalfLifeDays
    var lastPracticed: Date?
    var completed: Bool = false

    var attempts: Int { correct + incorrect }

    var accuracy: Double {
        attempts == 0 ? 0 : Double(correct) / Double(attempts)
    }
}

struct LearnerProfile: Codable, Sendable, Equatable {
    /// Tracks the learner opted into during onboarding, in display order.
    var tracks: [TrackID] = [.math, .physics]
    var totalXP: Int = 0
    var dailyGoalXP: Int = 50
    var xpToday: Int = 0
    var streakDays: Int = 0
    var bestStreakDays: Int = 0
    var lastActiveDay: LearningDay?
    /// Recent practice days, newest last, capped by `maxActiveDays`.
    var activeDays: [LearningDay] = []
    var skills: [String: SkillRecord] = [:]
    var sessionsCompleted: Int = 0
    var itemsAnswered: Int = 0
    var itemsCorrect: Int = 0
    var hasCompletedOnboarding: Bool = false

    static let maxActiveDays = 120

    var accuracy: Double {
        itemsAnswered == 0 ? 0 : Double(itemsCorrect) / Double(itemsAnswered)
    }

    var metDailyGoal: Bool { xpToday >= dailyGoalXP }

    func record(for lessonID: String) -> SkillRecord {
        skills[lessonID] ?? SkillRecord()
    }

    func isCompleted(_ lessonID: String) -> Bool {
        skills[lessonID]?.completed ?? false
    }

    func practiced(on day: LearningDay) -> Bool {
        activeDays.contains(day)
    }
}
