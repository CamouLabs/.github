//
//  SessionBuilder.swift
//  Quark
//
//  Picks what a learner actually sees in the next few minutes.
//
//  Two research results shape the ordering. Items ramp from warm-up to
//  stretch, because a session that opens with the hardest question mostly
//  teaches people to quit. And question kinds are interleaved rather than
//  blocked (Rohrer & Taylor, 2007): mixing recall, numeric work, and ordering
//  hurts practice accuracy slightly and helps retention a lot.
//

import Foundation

enum SessionMode: String, Codable, Sendable {
    case lesson
    case practice
    case review

    var title: String {
        switch self {
        case .lesson: return "Lesson"
        case .practice: return "Practice"
        case .review: return "Review"
        }
    }

    var isReview: Bool { self == .review }
}

struct SessionPlan: Sendable, Equatable {
    let mode: SessionMode
    /// Lesson the session is credited to. Review sessions credit each answer
    /// to the lesson the item came from instead.
    let lessonID: String
    let title: String
    let subtitle: String
    let items: [Exercise]
    /// Union of the grounding facts behind these items — the only material the
    /// coach may draw on during this session.
    let facts: [String]

    var isEmpty: Bool { items.isEmpty }
}

struct SessionSummary: Sendable, Equatable {
    let mode: SessionMode
    let lessonTitle: String
    let correct: Int
    let total: Int
    let xpEarned: Int
    let bestCombo: Int
    let sparksLeft: Int
    let generatedItemsServed: Int
    let elapsed: TimeInterval

    var isPerfect: Bool { total > 0 && correct == total }

    var accuracy: Double { total == 0 ? 0 : Double(correct) / Double(total) }
}

enum SessionBuilder {
    static let defaultLength = 8
    static let minLength = 4
    static let maxLength = 15

    // MARK: - Lesson

    static func lessonSession(
        for lesson: Lesson,
        profile: LearnerProfile,
        length: Int = defaultLength,
        seed: String? = nil
    ) -> SessionPlan {
        var generator = SeededGenerator(seed: seed ?? lesson.id)
        let ordered = ramped(lesson.exercises, length: clamp(length), using: &generator)
        let record = profile.record(for: lesson.id)
        return SessionPlan(
            mode: record.completed ? .practice : .lesson,
            lessonID: lesson.id,
            title: lesson.title,
            subtitle: lesson.goal,
            items: interleaved(ordered),
            facts: lesson.facts
        )
    }

    // MARK: - Review

    /// A mixed session drawn from the lessons whose recall has decayed most.
    /// Returns nil when nothing is due, so the UI can hide the review button
    /// rather than offer busywork.
    static func reviewSession(
        lessons: [Lesson],
        profile: LearnerProfile,
        length: Int = defaultLength,
        now: Date = Date(),
        seed: String? = nil
    ) -> SessionPlan? {
        let byID = Dictionary(uniqueKeysWithValues: lessons.map { ($0.id, $0) })
        let due = SpacedRepetition.dueLessons(in: profile, among: lessons.map(\.id), now: now)
        guard !due.isEmpty else { return nil }

        var generator = SeededGenerator(seed: seed ?? "review-\(LearningDay(date: now).value)")
        let target = clamp(length)
        var picked: [Exercise] = []
        var facts: [String] = []

        // Two items per weak lesson, cycling until the session is full.
        for round in 0..<3 where picked.count < target {
            for lessonID in due {
                guard picked.count < target, let lesson = byID[lessonID] else { continue }
                let pool = lesson.exercises.filter { candidate in
                    !picked.contains { $0.id == candidate.id }
                }
                guard !pool.isEmpty else { continue }
                let index = Int(generator.next() % UInt64(pool.count))
                picked.append(pool[index])
                if round == 0 { facts.append(contentsOf: lesson.facts) }
            }
        }

        guard !picked.isEmpty else { return nil }
        return SessionPlan(
            mode: .review,
            lessonID: due[0],
            title: "Review",
            subtitle: due.count == 1
                ? "One lesson is going quiet."
                : "\(due.count) lessons are going quiet.",
            items: interleaved(picked),
            facts: Array(facts.prefix(12))
        )
    }

    // MARK: - Ordering

    static func clamp(_ length: Int) -> Int {
        min(max(length, minLength), maxLength)
    }

    /// Warm-up → core → stretch, shuffled inside each tier.
    static func ramped(
        _ exercises: [Exercise],
        length: Int,
        using generator: inout SeededGenerator
    ) -> [Exercise] {
        var result: [Exercise] = []
        for tier in ExerciseDifficulty.allCases {
            let tierItems = exercises.filter { $0.difficulty == tier }
            result.append(contentsOf: tierItems.shuffled(using: &generator))
        }
        if result.count > length {
            // Keep the ramp but thin the middle, never dropping the opener.
            var trimmed = [result[0]]
            let stride = Double(result.count - 1) / Double(length - 1)
            for step in 1..<length {
                let index = min(Int((Double(step) * stride).rounded()), result.count - 1)
                let candidate = result[index]
                if !trimmed.contains(where: { $0.id == candidate.id }) {
                    trimmed.append(candidate)
                }
            }
            // Backfill if rounding collided.
            for candidate in result where trimmed.count < length {
                if !trimmed.contains(where: { $0.id == candidate.id }) {
                    trimmed.append(candidate)
                }
            }
            return trimmed
        }
        return result
    }

    /// Greedy reorder so two items of the same kind are not adjacent when an
    /// alternative exists. Preserves the difficulty ramp as much as possible.
    static func interleaved(_ items: [Exercise]) -> [Exercise] {
        guard items.count > 2 else { return items }
        var remaining = items
        var result: [Exercise] = [remaining.removeFirst()]

        while !remaining.isEmpty {
            let lastKind = result[result.count - 1].kind
            let index = remaining.firstIndex { $0.kind != lastKind } ?? 0
            result.append(remaining.remove(at: index))
        }
        return result
    }
}
