//
//  SpacedRepetition.swift
//  Quark
//
//  Review scheduling by half-life regression (Settles & Meeder, ACL 2016) —
//  the model Duolingo published for exactly this problem. Recall decays
//  exponentially, p = 2^(-Δ/h), and the half-life h is refit from the
//  learner's own hit/miss history for that lesson.
//
//  Everything here is deterministic and closed-form: no training, no server,
//  no telemetry. The only inputs are counts and timestamps already stored in
//  the learner's own profile.
//

import Foundation

enum SpacedRepetition {
    /// Half-life of a lesson nobody has practised yet, in days.
    static let initialHalfLifeDays = 0.66
    static let minHalfLifeDays = 0.02
    static let maxHalfLifeDays = 180.0
    /// Below this recall probability a lesson is worth reviewing today.
    static let reviewThreshold = 0.7

    /// Fitted weights over sqrt-transformed practice counts, as in the paper.
    private enum Weights {
        static let bias = -1.2
        static let correct = 1.6
        static let incorrect = 1.0
        static let streak = 0.15
        static let maxStreakCredit = 6.0
    }

    static func fitHalfLife(correct: Int, incorrect: Int, consecutiveCorrect: Int) -> Double {
        let exponent = Weights.bias
            + Weights.correct * Double(max(correct, 0) + 1).squareRoot()
            - Weights.incorrect * Double(max(incorrect, 0) + 1).squareRoot()
            + Weights.streak * min(Double(max(consecutiveCorrect, 0)), Weights.maxStreakCredit)
        return min(max(pow(2, exponent), minHalfLifeDays), maxHalfLifeDays)
    }

    /// p = 2^(-Δ/h). Never practised → 0, so new lessons sort as "due".
    static func recallProbability(_ record: SkillRecord, now: Date = Date()) -> Double {
        guard let last = record.lastPracticed else { return 0 }
        let elapsedDays = max(now.timeIntervalSince(last), 0) / 86_400
        let halfLife = max(record.halfLifeDays, minHalfLifeDays)
        return min(max(pow(2, -elapsedDays / halfLife), 0), 1)
    }

    static func isDue(_ record: SkillRecord, now: Date = Date()) -> Bool {
        guard record.attempts > 0 else { return false }
        return recallProbability(record, now: now) < reviewThreshold
    }

    static func nextReview(_ record: SkillRecord) -> Date? {
        guard let last = record.lastPracticed, record.attempts > 0 else { return nil }
        // Solve 2^(-Δ/h) = threshold for Δ.
        let days = -record.halfLifeDays * log2(reviewThreshold)
        return last.addingTimeInterval(days * 86_400)
    }

    /// Fold one graded attempt into a lesson's record.
    static func updated(
        _ record: SkillRecord,
        correct: Bool,
        now: Date = Date()
    ) -> SkillRecord {
        var updated = record
        if correct {
            updated.correct += 1
            updated.consecutiveCorrect += 1
        } else {
            updated.incorrect += 1
            updated.consecutiveCorrect = 0
        }
        updated.lastPracticed = now
        updated.halfLifeDays = fitHalfLife(
            correct: updated.correct,
            incorrect: updated.incorrect,
            consecutiveCorrect: updated.consecutiveCorrect
        )
        return updated
    }

    /// Lessons whose recall has decayed below the threshold, weakest first.
    static func dueLessons(
        in profile: LearnerProfile,
        among lessonIDs: [String],
        now: Date = Date()
    ) -> [String] {
        lessonIDs
            .map { ($0, profile.record(for: $0)) }
            .filter { isDue($0.1, now: now) }
            .sorted { recallProbability($0.1, now: now) < recallProbability($1.1, now: now) }
            .map(\.0)
    }
}
