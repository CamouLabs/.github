//
//  GroundingCheck.swift
//  Quark
//
//  Keeps coach text tied to the lesson. A 3B-parameter model that is asked to
//  explain a physics answer will occasionally produce a confident number that
//  came from nowhere, and a learner has no way to tell. So every number in
//  generated text has to be traceable to the lesson facts, the question, or
//  the curated explanation.
//
//  The trade-off is explicit: small integers up to ten are allowed through
//  ungrounded, because "the first two steps" is language, not data. Anything
//  larger has to be present in the source material.
//

import Foundation

enum Sentences {
    /// Splits on sentence-ending punctuation, keeping the terminator.
    static func split(_ text: String) -> [String] {
        var sentences: [String] = []
        var current = ""
        for character in text {
            current.append(character)
            if character == "." || character == "!" || character == "?" || character == "\n" {
                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { sentences.append(trimmed) }
                current = ""
            }
        }
        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { sentences.append(trimmed) }
        return sentences
    }

    static func join(_ sentences: [String]) -> String {
        sentences.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum GroundingCheck {
    /// Ungrounded integers at or below this value are tolerated as prose.
    static let smallNumberAllowance = 10.0

    static func numbers(in text: String) -> [String] {
        var found: [String] = []
        var current = ""
        for character in text {
            if character.isNumber || (character == "." && !current.isEmpty) {
                current.append(character)
            } else {
                if !current.isEmpty { found.append(current) }
                current = ""
            }
        }
        if !current.isEmpty { found.append(current) }
        return found.map { value in
            var trimmed = value
            while trimmed.hasSuffix(".") { trimmed.removeLast() }
            return trimmed
        }
        .filter { !$0.isEmpty }
    }

    /// Values the sources state outright, plus values they imply: a source
    /// containing "2/5" grounds 0.4, because that is the same number said two
    /// ways and a learner reading an explanation cannot tell the difference.
    static func groundedValues(in sources: [String]) -> Set<Double> {
        var values = Set(sources.flatMap { numbers(in: $0) }.compactMap(Double.init))
        for source in sources {
            for token in source.split(whereSeparator: { $0 == " " || $0 == "," || $0 == "(" || $0 == ")" }) {
                let candidate = String(token).trimmingCharacters(in: CharacterSet(charactersIn: ".:;?!"))
                guard candidate.contains("/") || candidate.contains("^") || candidate.contains("%") else { continue }
                if let value = AnswerChecker.parseNumber(candidate) {
                    values.insert(value)
                }
            }
        }
        return values
    }

    /// Numbers in `text` that do not appear anywhere in `sources`.
    static func ungroundedNumbers(in text: String, sources: [String]) -> [String] {
        let allowed = Set(sources.flatMap { numbers(in: $0) })
        let allowedValues = groundedValues(in: sources)

        var ungrounded: [String] = []
        for candidate in numbers(in: text) {
            if allowed.contains(candidate) { continue }
            guard let value = Double(candidate) else { continue }
            if allowedValues.contains(where: { abs($0 - value) <= max(abs(value) * 1e-6, 1e-9) }) { continue }
            if value <= smallNumberAllowance, value == value.rounded() { continue }
            ungrounded.append(candidate)
        }
        return ungrounded
    }

    static func findings(for text: String, sources: [String]) -> [GuardrailFinding] {
        let ungrounded = ungroundedNumbers(in: text, sources: sources)
        guard !ungrounded.isEmpty else { return [] }
        return [GuardrailFinding(
            guardrail: .grounding,
            detail: "uses \(ungrounded.joined(separator: ", ")), which the lesson never states"
        )]
    }

    /// Drops the sentences that carry ungrounded numbers and keeps the rest.
    /// Returns nil when nothing usable survives.
    static func filteredToGrounded(_ text: String, sources: [String]) -> String? {
        let kept = Sentences.split(text).filter { sentence in
            ungroundedNumbers(in: sentence, sources: sources).isEmpty
        }
        let result = Sentences.join(kept)
        return result.isEmpty ? nil : result
    }
}
