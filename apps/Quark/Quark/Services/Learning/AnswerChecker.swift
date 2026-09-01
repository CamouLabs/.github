//
//  AnswerChecker.swift
//  Quark
//
//  Grading, deliberately generous about form and strict about substance.
//  A learner who knows that the answer is three quarters should not lose a
//  spark for typing "3/4", "0.75", or "75 %", and a one-letter typo in
//  "photosynthesis" is a spelling slip, not a wrong answer.
//

import Foundation

enum LearnerAnswer: Sendable, Equatable {
    case option(Int)
    case boolean(Bool)
    case text(String)
    case sequence([String])
    case pairs([MatchPair])
    case skipped
}

struct Judgement: Sendable, Equatable {
    let isCorrect: Bool
    /// Credit in 0...1. Ordering and matching report how much was right so the
    /// summary can say "5 of 6 pairs" instead of a flat miss.
    let credit: Double
    /// One short line shown with the feedback banner, when there is something
    /// specific worth saying.
    let note: String?

    static let missing = Judgement(isCorrect: false, credit: 0, note: nil)
}

enum AnswerChecker {
    /// Accepts a typo of this edit distance in typed answers of 5+ characters.
    private static let typoTolerance = 1

    static func check(_ answer: LearnerAnswer, against content: Exercise.Content) -> Judgement {
        switch (answer, content) {
        case (.skipped, _):
            return .missing

        case (.option(let picked), .multipleChoice(let options, let correctIndex)):
            guard options.indices.contains(picked) else { return .missing }
            return Judgement(isCorrect: picked == correctIndex, credit: picked == correctIndex ? 1 : 0, note: nil)

        case (.boolean(let picked), .trueFalse(let expected)):
            return Judgement(isCorrect: picked == expected, credit: picked == expected ? 1 : 0, note: nil)

        case (.text(let raw), .numeric(let expected, let tolerance, let unit, _)):
            return checkNumeric(raw, expected: expected, tolerance: tolerance, unit: unit)

        case (.text(let raw), .shortText(let accepted)):
            return checkText(raw, accepted: accepted)

        case (.text(let raw), .multipleChoice(let options, let correctIndex)):
            // Voice or keyboard input against a choice item.
            guard options.indices.contains(correctIndex) else { return .missing }
            return checkText(raw, accepted: [options[correctIndex]])

        case (.sequence(let ordered), .ordering(let steps)):
            return checkOrdering(ordered, expected: steps)

        case (.pairs(let matched), .matching(let expected)):
            return checkMatching(matched, expected: expected)

        default:
            return .missing
        }
    }

    // MARK: - Numeric

    static func checkNumeric(
        _ raw: String,
        expected: Double,
        tolerance: Double,
        unit: String?
    ) -> Judgement {
        let stripped = stripUnit(raw, unit: unit)
        guard let value = parseNumber(stripped) else {
            return Judgement(isCorrect: false, credit: 0, note: "That is not a number Quark can read.")
        }
        let allowed = max(abs(tolerance), 1e-9)
        if abs(value - expected) <= allowed {
            return Judgement(isCorrect: true, credit: 1, note: nil)
        }
        // A sign slip is the most common near-miss worth naming.
        if abs(value + expected) <= allowed {
            return Judgement(isCorrect: false, credit: 0, note: "Right size, wrong sign.")
        }
        if expected != 0, abs(value - expected) <= abs(expected) * 0.02 + allowed {
            return Judgement(isCorrect: false, credit: 0, note: "Very close — check your rounding.")
        }
        return Judgement(isCorrect: false, credit: 0, note: nil)
    }

    /// Reads plain decimals, fractions, percentages, scientific notation, and
    /// any arithmetic the learner leaves unsimplified.
    static func parseNumber(_ raw: String) -> Double? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        text = text.replacingOccurrences(of: ",", with: "")

        if text.hasSuffix("%"), let value = MathEvaluator.evaluate(String(text.dropLast())) {
            return value / 100
        }
        // 1.2e3 / 4E-2 — normalise the exponent into an explicit power.
        if let exponentIndex = text.firstIndex(where: { $0 == "e" || $0 == "E" }),
           exponentIndex != text.startIndex,
           text.dropFirst(text.distance(from: text.startIndex, to: exponentIndex) + 1)
               .allSatisfy({ $0.isNumber || $0 == "-" || $0 == "+" }),
           let mantissa = Double(text[text.startIndex..<exponentIndex]),
           let exponent = Int(text[text.index(after: exponentIndex)...]) {
            return mantissa * pow(10, Double(exponent))
        }
        // Mixed number: "3 1/2".
        let parts = text.split(separator: " ").map(String.init)
        if parts.count == 2,
           let whole = Double(parts[0]),
           let fraction = MathEvaluator.evaluate(parts[1]),
           parts[1].contains("/") {
            return whole < 0 ? whole - fraction : whole + fraction
        }
        return MathEvaluator.evaluate(text)
    }

    private static func stripUnit(_ raw: String, unit: String?) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let unit, !unit.isEmpty else { return text }
        let lowered = text.lowercased()
        let suffix = unit.lowercased()
        if lowered.hasSuffix(suffix) {
            text = String(text.dropLast(suffix.count))
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Text

    static func checkText(_ raw: String, accepted: [String]) -> Judgement {
        let candidate = normalize(raw)
        guard !candidate.isEmpty else { return .missing }
        for option in accepted {
            let target = normalize(option)
            if candidate == target {
                return Judgement(isCorrect: true, credit: 1, note: nil)
            }
            if target.count >= 5, editDistance(candidate, target) <= typoTolerance {
                return Judgement(isCorrect: true, credit: 1, note: "Spelling: \(option).")
            }
        }
        return Judgement(isCorrect: false, credit: 0, note: nil)
    }

    /// Lowercase, unaccent, drop punctuation and leading articles, collapse space.
    static func normalize(_ raw: String) -> String {
        let folded = raw.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let cleaned = folded.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) { return Character(scalar) }
            return " "
        }
        var words = String(cleaned).split(whereSeparator: { $0 == " " }).map(String.init)
        if words.count > 1, ["the", "a", "an"].contains(words[0]) {
            words.removeFirst()
        }
        return words.joined(separator: " ")
    }

    static func editDistance(_ lhs: String, _ rhs: String) -> Int {
        let left = Array(lhs)
        let right = Array(rhs)
        if left.isEmpty { return right.count }
        if right.isEmpty { return left.count }

        var previous = Array(0...right.count)
        var current = [Int](repeating: 0, count: right.count + 1)

        for i in 1...left.count {
            current[0] = i
            for j in 1...right.count {
                let substitution = previous[j - 1] + (left[i - 1] == right[j - 1] ? 0 : 1)
                current[j] = min(previous[j] + 1, current[j - 1] + 1, substitution)
            }
            previous = current
        }
        return previous[right.count]
    }

    // MARK: - Ordering and matching

    private static func checkOrdering(_ ordered: [String], expected: [String]) -> Judgement {
        guard ordered.count == expected.count, !expected.isEmpty else { return .missing }
        if ordered == expected {
            return Judgement(isCorrect: true, credit: 1, note: nil)
        }
        let inPlace = zip(ordered, expected).filter { $0 == $1 }.count
        let credit = Double(inPlace) / Double(expected.count)
        let note = inPlace == expected.count - 2
            ? "So close — two steps are swapped."
            : "\(inPlace) of \(expected.count) steps in the right place."
        return Judgement(isCorrect: false, credit: credit, note: note)
    }

    private static func checkMatching(_ matched: [MatchPair], expected: [MatchPair]) -> Judgement {
        guard !expected.isEmpty else { return .missing }
        let truth = Dictionary(expected.map { (normalize($0.left), normalize($0.right)) },
                               uniquingKeysWith: { first, _ in first })
        var correct = 0
        for pair in matched where truth[normalize(pair.left)] == normalize(pair.right) {
            correct += 1
        }
        if correct == expected.count, matched.count == expected.count {
            return Judgement(isCorrect: true, credit: 1, note: nil)
        }
        return Judgement(
            isCorrect: false,
            credit: Double(correct) / Double(expected.count),
            note: "\(correct) of \(expected.count) pairs matched."
        )
    }
}
