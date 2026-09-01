//
//  Course.swift
//  Quark
//
//  Course → Unit → Lesson → Exercise. A lesson is also the unit of mastery:
//  its `id` is the skill key used by the spaced-repetition model.
//
//  `Lesson.facts` is the lesson's syllabus in one-line form. It is the only
//  material the on-device model is allowed to build generated practice and
//  hints from, which is what keeps the coach on-topic (see GroundingGate).
//

import Foundation

struct Lesson: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    /// One learner-facing sentence: what you can do after this lesson.
    let goal: String
    let facts: [String]
    let exercises: [Exercise]

    init(
        id: String,
        title: String,
        goal: String,
        facts: [String],
        exercises: [Exercise]
    ) {
        self.id = id
        self.title = title
        self.goal = goal
        self.facts = facts
        self.exercises = exercises
    }
}

struct Unit: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let blurb: String
    let lessons: [Lesson]
}

struct Course: Identifiable, Sendable, Equatable {
    let track: TrackID
    let units: [Unit]

    var id: String { track.rawValue }
    var lessons: [Lesson] { units.flatMap(\.lessons) }
}

extension Lesson {
    /// Grounding text handed to the model: goal plus facts, nothing else.
    var groundingBlock: String {
        ([goal] + facts).map { "- \($0)" }.joined(separator: "\n")
    }

    var exerciseCount: Int { exercises.count }
}

/// Builder sugar so the curriculum files read like content, not like code.
extension Exercise {
    static func choice(
        _ id: String,
        lesson: String,
        _ prompt: String,
        options: [String],
        correct: Int,
        why: String,
        hint: String,
        difficulty: ExerciseDifficulty = .standard
    ) -> Exercise {
        Exercise(
            id: id,
            lessonID: lesson,
            prompt: prompt,
            content: .multipleChoice(options: options, correctIndex: correct),
            explanation: why,
            hint: hint,
            difficulty: difficulty
        )
    }

    static func number(
        _ id: String,
        lesson: String,
        _ prompt: String,
        answer: Double,
        tolerance: Double = 0,
        unit: String? = nil,
        check: String? = nil,
        why: String,
        hint: String,
        difficulty: ExerciseDifficulty = .standard
    ) -> Exercise {
        Exercise(
            id: id,
            lessonID: lesson,
            prompt: prompt,
            content: .numeric(answer: answer, tolerance: tolerance, unit: unit, check: check),
            explanation: why,
            hint: hint,
            difficulty: difficulty
        )
    }

    static func truth(
        _ id: String,
        lesson: String,
        _ prompt: String,
        answer: Bool,
        why: String,
        hint: String,
        difficulty: ExerciseDifficulty = .gentle
    ) -> Exercise {
        Exercise(
            id: id,
            lessonID: lesson,
            prompt: prompt,
            content: .trueFalse(answer: answer),
            explanation: why,
            hint: hint,
            difficulty: difficulty
        )
    }

    static func text(
        _ id: String,
        lesson: String,
        _ prompt: String,
        accepted: [String],
        why: String,
        hint: String,
        difficulty: ExerciseDifficulty = .standard
    ) -> Exercise {
        Exercise(
            id: id,
            lessonID: lesson,
            prompt: prompt,
            content: .shortText(accepted: accepted),
            explanation: why,
            hint: hint,
            difficulty: difficulty
        )
    }

    static func order(
        _ id: String,
        lesson: String,
        _ prompt: String,
        steps: [String],
        why: String,
        hint: String,
        difficulty: ExerciseDifficulty = .stretch
    ) -> Exercise {
        Exercise(
            id: id,
            lessonID: lesson,
            prompt: prompt,
            content: .ordering(steps: steps),
            explanation: why,
            hint: hint,
            difficulty: difficulty
        )
    }

    static func match(
        _ id: String,
        lesson: String,
        _ prompt: String,
        pairs: [(String, String)],
        why: String,
        hint: String,
        difficulty: ExerciseDifficulty = .standard
    ) -> Exercise {
        Exercise(
            id: id,
            lessonID: lesson,
            prompt: prompt,
            content: .matching(pairs: pairs.map { MatchPair(left: $0.0, right: $0.1) }),
            explanation: why,
            hint: hint,
            difficulty: difficulty
        )
    }
}
