//
//  MasteryModel.swift
//  Quark
//
//  Turns a SkillRecord into the five states the path draws: locked, ready,
//  learning, strong, and — once recall has held up over spaced attempts —
//  mastered. Mastery here is not "finished the lesson once"; it decays, which
//  is why the path can send you back.
//

import Foundation

enum MasteryLevel: String, Codable, Sendable, CaseIterable {
    case locked
    case ready
    case learning
    case strong
    case mastered

    var label: String {
        switch self {
        case .locked: return "Locked"
        case .ready: return "Ready"
        case .learning: return "Learning"
        case .strong: return "Strong"
        case .mastered: return "Mastered"
        }
    }

    var symbol: String {
        switch self {
        case .locked: return "lock.fill"
        case .ready: return "play.fill"
        case .learning: return "circle.dotted"
        case .strong: return "star.fill"
        case .mastered: return "crown.fill"
        }
    }
}

enum MasteryModel {
    /// Correct attempts needed before a lesson can be called mastered.
    static let masteryAttempts = 6
    static let strongAttempts = 3

    static func level(
        for lessonID: String,
        in profile: LearnerProfile,
        unlocked: Bool,
        now: Date = Date()
    ) -> MasteryLevel {
        guard unlocked else { return .locked }
        let record = profile.record(for: lessonID)
        guard record.attempts > 0 else { return .ready }

        let recall = SpacedRepetition.recallProbability(record, now: now)
        if record.correct >= masteryAttempts, record.accuracy >= 0.8, recall >= 0.8 {
            return .mastered
        }
        if record.correct >= strongAttempts, record.accuracy >= 0.65, recall >= SpacedRepetition.reviewThreshold {
            return .strong
        }
        return .learning
    }

    /// 0...1 ring fill for a lesson node: how much of mastery is banked.
    static func progress(
        for lessonID: String,
        in profile: LearnerProfile,
        now: Date = Date()
    ) -> Double {
        let record = profile.record(for: lessonID)
        guard record.attempts > 0 else { return 0 }
        let banked = min(Double(record.correct) / Double(masteryAttempts), 1)
        let retention = SpacedRepetition.recallProbability(record, now: now)
        return min(max(0.65 * banked + 0.35 * retention, 0), 1)
    }

    /// Mean progress across a track, for the profile screen's track bars.
    static func trackProgress(
        lessonIDs: [String],
        in profile: LearnerProfile,
        now: Date = Date()
    ) -> Double {
        guard !lessonIDs.isEmpty else { return 0 }
        let total = lessonIDs.reduce(0.0) { $0 + progress(for: $1, in: profile, now: now) }
        return total / Double(lessonIDs.count)
    }

    /// A lesson unlocks when the previous lesson in its unit has been cleared
    /// once. The first lesson of every unit is always open, so nobody is
    /// stranded behind a single hard question.
    static func unlockedLessonIDs(for course: Course, in profile: LearnerProfile) -> Set<String> {
        var unlocked: Set<String> = []
        for unit in course.units {
            var previousCleared = true
            for lesson in unit.lessons {
                if previousCleared { unlocked.insert(lesson.id) }
                previousCleared = profile.record(for: lesson.id).completed
            }
        }
        return unlocked
    }
}
