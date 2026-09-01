//
//  ItemGuardrails.swift
//  Quark
//
//  Review board for a model-written practice question. A draft has to clear
//  every check here before it becomes an Exercise; there is no path from the
//  model to the screen that skips this file.
//
//  Order matters. Cheap structural checks run first so an obviously broken
//  draft never reaches the arithmetic verifier, and the arithmetic verifier
//  runs before grounding so a wrong sum is reported as a wrong sum.
//

import Foundation

enum ItemGuardrails {
    static let requiredOptionCount = 4
    static let maxPromptCharacters = 180
    static let maxOptionCharacters = 64
    static let maxExplanationCharacters = 320
    static let maxSentenceWords = 30
    /// Token overlap above which a draft counts as a repeat.
    static let noveltyLimit = 0.6

    private static let ambiguityPhrases = [
        "all of the above", "none of the above", "both a and b",
        "all of these", "none of these", "any of the above"
    ]

    private static let fallbackHint = "Work from the lesson facts and take the first step only."

    static func review(
        _ draft: GeneratedItemDraft,
        lesson: Lesson,
        existingPrompts: [String]
    ) -> GuardrailOutcome<Exercise> {
        var findings: [GuardrailFinding] = []

        // 1. Shape.
        findings.append(contentsOf: schemaFindings(draft))
        guard findings.isEmpty else { return .rejected(findings) }

        let prompt = draft.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let options = draft.options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let explanation = draft.explanation.trimmingCharacters(in: .whitespacesAndNewlines)
        let correctOption = options[draft.correctIndex]

        // 2. Readable at a glance.
        findings.append(contentsOf: readabilityFindings(prompt: prompt, options: options, explanation: explanation))

        // 3. Safe, and free of personal data.
        let everything = ([prompt, explanation, draft.hint] + options).joined(separator: " ")
        findings.append(contentsOf: SafetyScreen.review(everything))

        // 4. Actually about this lesson.
        findings.append(contentsOf: SafetyScreen.topicalFindings(for: "\(prompt) \(explanation)", lesson: lesson))

        // 5. Exactly one defensible answer.
        findings.append(contentsOf: ambiguityFindings(prompt: prompt, options: options, correct: correctOption))

        // 6. Arithmetic re-derived rather than trusted.
        findings.append(contentsOf: arithmeticFindings(draft, options: options, correctOption: correctOption))

        // 7. Numbers traceable to the lesson.
        let sources = [lesson.title, lesson.goal] + lesson.facts + [prompt] + options
        findings.append(contentsOf: GroundingCheck.findings(for: explanation, sources: sources))

        // 8. Not something the learner just answered.
        if let repeated = nearDuplicate(of: prompt, in: existingPrompts) {
            findings.append(GuardrailFinding(
                guardrail: .novelty,
                detail: "repeats an existing question ('\(repeated.prefix(48))…')"
            ))
        }

        guard findings.isEmpty else { return .rejected(findings) }

        // 9. The hint must not solve it. This one is repairable.
        let candidate = exercise(from: draft, lesson: lesson, prompt: prompt, options: options, explanation: explanation, hint: draft.hint)
        let leaks = AnswerLeakDetector.findings(in: draft.hint, exercise: candidate)
        guard !leaks.isEmpty else { return .accepted(candidate) }

        let salvaged = AnswerLeakDetector.withoutLeaks(draft.hint, exercise: candidate) ?? fallbackHint
        let repaired = exercise(from: draft, lesson: lesson, prompt: prompt, options: options, explanation: explanation, hint: salvaged)
        return .repaired(repaired, leaks)
    }

    // MARK: - Checks

    private static func schemaFindings(_ draft: GeneratedItemDraft) -> [GuardrailFinding] {
        var findings: [GuardrailFinding] = []
        let prompt = draft.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let options = draft.options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        if prompt.count < 8 {
            findings.append(GuardrailFinding(guardrail: .schema, detail: "question is empty or too short"))
        }
        if options.count != requiredOptionCount {
            findings.append(GuardrailFinding(
                guardrail: .schema,
                detail: "needs exactly \(requiredOptionCount) options, got \(options.count)"
            ))
        }
        if options.contains(where: \.isEmpty) {
            findings.append(GuardrailFinding(guardrail: .schema, detail: "an option is blank"))
        }
        if !options.indices.contains(draft.correctIndex) {
            findings.append(GuardrailFinding(
                guardrail: .schema,
                detail: "correct index \(draft.correctIndex) is outside the options"
            ))
        }
        if draft.explanation.trimmingCharacters(in: .whitespacesAndNewlines).count < 8 {
            findings.append(GuardrailFinding(guardrail: .schema, detail: "explanation is missing"))
        }
        return findings
    }

    private static func readabilityFindings(
        prompt: String,
        options: [String],
        explanation: String
    ) -> [GuardrailFinding] {
        var findings: [GuardrailFinding] = []
        if prompt.count > maxPromptCharacters {
            findings.append(GuardrailFinding(
                guardrail: .readability,
                detail: "question is \(prompt.count) characters, limit \(maxPromptCharacters)"
            ))
        }
        if let long = options.first(where: { $0.count > maxOptionCharacters }) {
            findings.append(GuardrailFinding(
                guardrail: .readability,
                detail: "option too long ('\(long.prefix(24))…')"
            ))
        }
        if explanation.count > maxExplanationCharacters {
            findings.append(GuardrailFinding(
                guardrail: .length,
                detail: "explanation is \(explanation.count) characters, limit \(maxExplanationCharacters)"
            ))
        }
        let sentences = Sentences.split("\(prompt) \(explanation)")
        if let sprawling = sentences.first(where: { $0.split(separator: " ").count > maxSentenceWords }) {
            findings.append(GuardrailFinding(
                guardrail: .readability,
                detail: "sentence runs over \(maxSentenceWords) words ('\(sprawling.prefix(28))…')"
            ))
        }
        return findings
    }

    private static func ambiguityFindings(
        prompt: String,
        options: [String],
        correct: String
    ) -> [GuardrailFinding] {
        var findings: [GuardrailFinding] = []
        let normalizedOptions = options.map { AnswerChecker.normalize($0) }

        if Set(normalizedOptions).count != normalizedOptions.count {
            findings.append(GuardrailFinding(guardrail: .ambiguity, detail: "two options say the same thing"))
        }
        // Numerically equal options ("0.5" and "1/2") are duplicates too.
        let values = options.compactMap { AnswerChecker.parseNumber($0) }
        if values.count == options.count, Set(values.map { ($0 * 1e6).rounded() }).count != values.count {
            findings.append(GuardrailFinding(guardrail: .ambiguity, detail: "two options have the same value"))
        }
        if let phrase = ambiguityPhrases.first(where: { phrase in
            normalizedOptions.contains { $0.contains(AnswerChecker.normalize(phrase)) }
        }) {
            findings.append(GuardrailFinding(guardrail: .ambiguity, detail: "uses '\(phrase)'"))
        }

        let normalizedPrompt = " \(AnswerChecker.normalize(prompt)) "
        let normalizedCorrect = AnswerChecker.normalize(correct)
        if normalizedCorrect.count >= 3, normalizedPrompt.contains(" \(normalizedCorrect) ") {
            findings.append(GuardrailFinding(
                guardrail: .ambiguity,
                detail: "the question already contains its own answer"
            ))
        }
        return findings
    }

    /// Words that mean the question is asking for a calculation rather than a
    /// judgement, and therefore that its answer must be re-derivable.
    private static let calculationCues = [
        "what is", "how many", "how much", "calculate", "work out", "value of",
        "plus", "minus", "times", "divided", "sum", "total", "product",
        "solve", "evaluate", "per", "average"
    ]

    /// Calculated answers must ship arithmetic that reproduces them. A
    /// comparison question with numeric options ("which fraction is largest")
    /// has nothing to re-derive, so it is exempt — but if it supplies
    /// arithmetic anyway, that arithmetic still has to be right.
    private static func arithmeticFindings(
        _ draft: GeneratedItemDraft,
        options: [String],
        correctOption: String
    ) -> [GuardrailFinding] {
        let isNumericItem = options.allSatisfy { AnswerChecker.parseNumber($0) != nil }
        guard isNumericItem else { return [] }

        let normalizedPrompt = AnswerChecker.normalize(draft.prompt)
        let isCalculation = calculationCues.contains { cue in
            normalizedPrompt.contains(AnswerChecker.normalize(cue))
        }

        guard let expression = draft.checkExpression, !expression.isEmpty else {
            guard isCalculation else { return [] }
            return [GuardrailFinding(
                guardrail: .mathCheck,
                detail: "calculated answer arrived without arithmetic to verify it"
            )]
        }
        guard let computed = MathEvaluator.evaluate(expression) else {
            return [GuardrailFinding(
                guardrail: .mathCheck,
                detail: "cannot evaluate '\(expression)'"
            )]
        }
        guard let expected = AnswerChecker.parseNumber(correctOption) else {
            return [GuardrailFinding(
                guardrail: .mathCheck,
                detail: "correct option '\(correctOption)' is not a number"
            )]
        }
        let tolerance = max(abs(expected) * 1e-4, 1e-6)
        guard abs(computed - expected) <= tolerance else {
            return [GuardrailFinding(
                guardrail: .mathCheck,
                detail: "'\(expression)' evaluates to \(Formatting.number(computed)), not \(Formatting.number(expected))"
            )]
        }
        if let claimed = draft.numericAnswer, abs(claimed - computed) > tolerance {
            return [GuardrailFinding(
                guardrail: .mathCheck,
                detail: "claimed answer \(Formatting.number(claimed)) disagrees with its own arithmetic"
            )]
        }
        return []
    }

    /// Jaccard overlap of content stems against questions already asked.
    static func nearDuplicate(of prompt: String, in existing: [String]) -> String? {
        let candidate = Curriculum.stems(prompt)
        guard !candidate.isEmpty else { return nil }
        for other in existing {
            let tokens = Curriculum.stems(other)
            guard !tokens.isEmpty else { continue }
            let union = candidate.union(tokens).count
            let intersection = candidate.intersection(tokens).count
            if union > 0, Double(intersection) / Double(union) >= noveltyLimit {
                return other
            }
        }
        return nil
    }

    // MARK: - Assembly

    private static func exercise(
        from draft: GeneratedItemDraft,
        lesson: Lesson,
        prompt: String,
        options: [String],
        explanation: String,
        hint: String
    ) -> Exercise {
        let hintText = hint.trimmingCharacters(in: .whitespacesAndNewlines)
        return Exercise(
            id: "\(lesson.id).generated.\(stableSuffix(for: prompt))",
            lessonID: lesson.id,
            prompt: prompt,
            content: .multipleChoice(options: options, correctIndex: draft.correctIndex),
            explanation: explanation,
            hint: hintText.isEmpty ? fallbackHint : hintText,
            difficulty: draft.checkExpression == nil ? .standard : .stretch,
            origin: .generated
        )
    }

    private static func stableSuffix(for prompt: String) -> String {
        var hash: UInt64 = 0xCBF29CE484222325
        for byte in prompt.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001B3
        }
        return String(hash % 100_000)
    }
}
