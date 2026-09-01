//
//  Exercise.swift
//  Quark
//
//  One question a learner answers. Six content kinds cover the drills that
//  actually build STEM fluency: recall, numeric work, ordering a procedure,
//  and connecting a term to its meaning.
//
//  `Content.numeric` carries an optional `check` expression (for example
//  "6 * 7") so a generated item's answer can be re-derived arithmetically by
//  the guardrail layer instead of being trusted.
//

import Foundation

struct MatchPair: Codable, Sendable, Equatable, Identifiable {
    let left: String
    let right: String

    var id: String { left }
}

enum ExerciseKind: String, Codable, Sendable, CaseIterable {
    case multipleChoice
    case trueFalse
    case numeric
    case shortText
    case ordering
    case matching
}

enum ExerciseDifficulty: Int, Codable, Sendable, Comparable, CaseIterable {
    case gentle = 1
    case standard = 2
    case stretch = 3

    static func < (lhs: ExerciseDifficulty, rhs: ExerciseDifficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .gentle: return "Warm-up"
        case .standard: return "Core"
        case .stretch: return "Stretch"
        }
    }
}

/// Where an item came from. Generated items are always guardrail-reviewed
/// before they reach a learner, and are labelled as such in the UI.
enum ExerciseOrigin: String, Codable, Sendable {
    case curated
    case generated
}

struct Exercise: Identifiable, Codable, Sendable, Equatable {
    enum Content: Codable, Sendable, Equatable {
        case multipleChoice(options: [String], correctIndex: Int)
        case trueFalse(answer: Bool)
        case numeric(answer: Double, tolerance: Double, unit: String?, check: String?)
        case shortText(accepted: [String])
        case ordering(steps: [String])
        case matching(pairs: [MatchPair])
    }

    let id: String
    let lessonID: String
    let prompt: String
    let content: Content
    /// Shown after answering. Also the grounding text for a generated hint.
    let explanation: String
    /// Curated nudge used when Apple Intelligence is unavailable — or when a
    /// generated hint fails the answer-leak check.
    let hint: String
    let difficulty: ExerciseDifficulty
    let origin: ExerciseOrigin

    init(
        id: String,
        lessonID: String,
        prompt: String,
        content: Content,
        explanation: String,
        hint: String,
        difficulty: ExerciseDifficulty = .standard,
        origin: ExerciseOrigin = .curated
    ) {
        self.id = id
        self.lessonID = lessonID
        self.prompt = prompt
        self.content = content
        self.explanation = explanation
        self.hint = hint
        self.difficulty = difficulty
        self.origin = origin
    }
}

extension Exercise.Content {
    var kind: ExerciseKind {
        switch self {
        case .multipleChoice: return .multipleChoice
        case .trueFalse: return .trueFalse
        case .numeric: return .numeric
        case .shortText: return .shortText
        case .ordering: return .ordering
        case .matching: return .matching
        }
    }

    /// Every phrasing of the correct answer. The answer-leak guardrail uses
    /// this to keep a hint from quietly solving the exercise.
    var answerStrings: [String] {
        switch self {
        case .multipleChoice(let options, let index):
            guard options.indices.contains(index) else { return [] }
            return [options[index]]
        case .trueFalse(let answer):
            return [answer ? "true" : "false"]
        case .numeric(let answer, _, let unit, _):
            var forms = [Formatting.number(answer)]
            if let unit, !unit.isEmpty { forms.append("\(Formatting.number(answer)) \(unit)") }
            return forms
        case .shortText(let accepted):
            return accepted
        case .ordering(let steps):
            return [steps.joined(separator: " → ")]
        case .matching(let pairs):
            return pairs.map { "\($0.left) → \($0.right)" }
        }
    }
}

extension Exercise {
    var kind: ExerciseKind { content.kind }

    /// Learner-facing instruction above the answer controls.
    var instruction: String {
        switch content {
        case .multipleChoice: return "Pick the right answer"
        case .trueFalse: return "True or false?"
        case .numeric: return "Type the number"
        case .shortText: return "Type your answer"
        case .ordering: return "Put the steps in order"
        case .matching: return "Match each pair"
        }
    }
}

/// Number formatting shared by answer checking, hints, and the UI so the same
/// value never appears two different ways in one session.
enum Formatting {
    static func number(_ value: Double) -> String {
        if value.isNaN || value.isInfinite { return "—" }
        if abs(value.rounded() - value) < 1e-9, abs(value) < 1e15 {
            return String(Int(value.rounded()))
        }
        var text = String(format: "%.4f", value)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text
    }
}
