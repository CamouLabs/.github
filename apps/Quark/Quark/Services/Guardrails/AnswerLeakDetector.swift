//
//  AnswerLeakDetector.swift
//  Quark
//
//  The guardrail the app would be worst without. A hint that hands over the
//  answer feels helpful for four seconds and removes the entire point of the
//  exercise, and a small model asked for a nudge will often just answer.
//
//  So a hint is checked against every phrasing of the correct answer before it
//  is shown. A leaking sentence is removed; if that empties the hint, the
//  curated one is used instead. The learner never sees the difference.
//

import Foundation

enum AnswerLeakDetector {
    private static let tellPhrases = [
        "the answer is", "the correct answer", "correct option is",
        "it is option", "so the answer", "which means the answer"
    ]

    /// Checked against raw text, because normalising "answer:" would leave
    /// "answer" and flag every hint that uses the word at all. An equals sign
    /// is deliberately not on this list: "put x = 0 into the equation" is a
    /// hint, and a hint that really states a value is caught below instead.
    private static let rawTells = ["answer:", "answer is:"]

    /// Findings for a hint that gives the game away.
    static func findings(
        in text: String,
        exercise: Exercise
    ) -> [GuardrailFinding] {
        var findings: [GuardrailFinding] = []
        let normalized = AnswerChecker.normalize(text)

        let lowered = text.lowercased()
        if let tell = tellPhrases.first(where: { normalized.contains(AnswerChecker.normalize($0)) })
            ?? rawTells.first(where: { lowered.contains($0) }) {
            findings.append(GuardrailFinding(
                guardrail: .answerLeak,
                detail: "announces the answer ('\(tell.trimmingCharacters(in: .whitespaces))')"
            ))
        }
        if let leaked = leakedAnswer(in: text, exercise: exercise) {
            findings.append(GuardrailFinding(
                guardrail: .answerLeak,
                detail: "states the answer ('\(leaked)')"
            ))
        }
        return findings
    }

    /// The specific answer phrasing that leaked, if any.
    static func leakedAnswer(in text: String, exercise: Exercise) -> String? {
        let normalizedText = AnswerChecker.normalize(text)
        let textTokens = Set(normalizedText.split(separator: " ").map(String.init))

        switch exercise.content {
        case .numeric(let answer, _, _, _):
            // A number only counts as leaked if the question did not already
            // contain it — "solve 3x + 7 = 22" may legitimately repeat 22.
            let formatted = Formatting.number(answer)
            let promptNumbers = Set(GroundingCheck.numbers(in: exercise.prompt))
            guard !promptNumbers.contains(formatted) else { return nil }
            return GroundingCheck.numbers(in: text).contains(formatted) ? formatted : nil

        case .trueFalse(let answer):
            let word = answer ? "true" : "false"
            let opposite = answer ? "false" : "true"
            // "not false" is as much of a giveaway as "true".
            if textTokens.contains(word) { return word }
            if normalizedText.contains("not \(opposite)") { return "not \(opposite)" }
            return nil

        case .multipleChoice(let options, let index):
            guard options.indices.contains(index) else { return nil }
            let answer = options[index]
            return containsPhrase(answer, in: normalizedText) ? answer : nil

        case .shortText(let accepted):
            return accepted.first { containsPhrase($0, in: normalizedText) }

        case .ordering(let steps):
            // Leaked only if the hint reproduces most of the sequence in order.
            let normalizedSteps = steps.map { AnswerChecker.normalize($0) }
            let present = normalizedSteps.filter { normalizedText.contains($0) }
            return present.count >= max(2, steps.count - 1) ? "the step order" : nil

        case .matching(let pairs):
            let leakedPairs = pairs.filter { pair in
                let left = AnswerChecker.normalize(pair.left)
                let right = AnswerChecker.normalize(pair.right)
                guard let leftRange = normalizedText.range(of: left),
                      let rightRange = normalizedText.range(of: right)
                else { return false }
                // Both halves of a pair, close together, is a given answer.
                let distance = abs(normalizedText.distance(from: leftRange.upperBound, to: rightRange.lowerBound))
                return distance <= 24
            }
            return leakedPairs.count >= 2 ? "matched pairs" : nil
        }
    }

    /// Whole-phrase containment on normalised text, so "one" does not match
    /// inside "money" and a two-word answer must appear as two words.
    private static func containsPhrase(_ phrase: String, in normalizedText: String) -> Bool {
        let target = AnswerChecker.normalize(phrase)
        guard target.count >= 2 else { return false }
        let padded = " \(normalizedText) "
        return padded.contains(" \(target) ")
            || padded.contains(" \(target),")
            || padded.contains(" \(target).")
    }

    /// Removes leaking sentences. Returns nil when the whole hint had to go.
    static func withoutLeaks(_ text: String, exercise: Exercise) -> String? {
        let kept = Sentences.split(text).filter { sentence in
            findings(in: sentence, exercise: exercise).isEmpty
        }
        let result = Sentences.join(kept)
        return result.count >= 12 ? result : nil
    }
}
