//
//  CoachGuardrails.swift
//  Quark
//
//  Review board for coach text: hints, explanations, and replies in the Ask
//  Quark sheet. Each has a different contract. A hint must not contain the
//  answer; an explanation must contain it; a reply must stay on the lesson and
//  answer the learner's question without answering the exercise.
//
//  Repair before rejection, wherever repair is honest: dropping a sentence
//  that leaked, or one that carried an invented number, usually leaves a hint
//  that still helps. When it does not, the curated text takes over and the
//  learner sees a hint rather than an apology.
//

import Foundation

enum CoachGuardrails {
    static let maxHintCharacters = 220
    static let maxExplanationCharacters = 420
    static let maxReplyCharacters = 340
    static let maxHintSentences = 2
    static let maxReplySentences = 3

    // MARK: - Hints

    static func reviewHint(
        _ raw: String,
        exercise: Exercise,
        facts: [String]
    ) -> GuardrailOutcome<String> {
        var findings: [GuardrailFinding] = []

        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 8 else {
            return .rejected([GuardrailFinding(guardrail: .schema, detail: "hint is empty")])
        }

        let unsafe = SafetyScreen.review(text).filter { $0.guardrail == .safety }
        guard unsafe.isEmpty else { return .rejected(unsafe) }

        var working = text
        let scrub = SafetyScreen.scrubbed(working)
        if !scrub.findings.isEmpty {
            working = scrub.text
            findings.append(contentsOf: scrub.findings)
        }

        let sources = facts + [exercise.prompt, exercise.explanation]
        let ungrounded = GroundingCheck.findings(for: working, sources: sources)
        if !ungrounded.isEmpty {
            guard let grounded = GroundingCheck.filteredToGrounded(working, sources: sources) else {
                return .rejected(ungrounded)
            }
            working = grounded
            findings.append(contentsOf: ungrounded)
        }

        let leaks = AnswerLeakDetector.findings(in: working, exercise: exercise)
        if !leaks.isEmpty {
            guard let clean = AnswerLeakDetector.withoutLeaks(working, exercise: exercise) else {
                return .rejected(leaks)
            }
            working = clean
            findings.append(contentsOf: leaks)
        }

        let (trimmed, lengthFindings) = capped(
            working,
            characters: maxHintCharacters,
            sentences: maxHintSentences
        )
        working = trimmed
        findings.append(contentsOf: lengthFindings)

        // A trimmed hint can still leak: re-check what actually survived.
        if !AnswerLeakDetector.findings(in: working, exercise: exercise).isEmpty {
            return .rejected(findings + [GuardrailFinding(
                guardrail: .answerLeak,
                detail: "still contains the answer after repair"
            )])
        }

        return findings.isEmpty ? .accepted(working) : .repaired(working, findings)
    }

    // MARK: - Explanations

    /// An explanation is allowed to state the answer — that is its job — so
    /// only safety, grounding, and length apply.
    static func reviewExplanation(
        _ raw: String,
        exercise: Exercise,
        facts: [String]
    ) -> GuardrailOutcome<String> {
        var findings: [GuardrailFinding] = []
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 8 else {
            return .rejected([GuardrailFinding(guardrail: .schema, detail: "explanation is empty")])
        }

        let unsafe = SafetyScreen.review(text).filter { $0.guardrail == .safety }
        guard unsafe.isEmpty else { return .rejected(unsafe) }

        var working = text
        let scrub = SafetyScreen.scrubbed(working)
        if !scrub.findings.isEmpty {
            working = scrub.text
            findings.append(contentsOf: scrub.findings)
        }

        let sources = facts + [exercise.prompt, exercise.explanation] + exercise.content.answerStrings
        let ungrounded = GroundingCheck.findings(for: working, sources: sources)
        if !ungrounded.isEmpty {
            guard let grounded = GroundingCheck.filteredToGrounded(working, sources: sources) else {
                return .rejected(ungrounded)
            }
            working = grounded
            findings.append(contentsOf: ungrounded)
        }

        let (trimmed, lengthFindings) = capped(working, characters: maxExplanationCharacters, sentences: 4)
        working = trimmed
        findings.append(contentsOf: lengthFindings)

        return findings.isEmpty ? .accepted(working) : .repaired(working, findings)
    }

    // MARK: - Replies

    static func reviewReply(
        _ raw: String,
        exercise: Exercise?,
        lesson: Lesson,
        facts: [String]
    ) -> GuardrailOutcome<String> {
        var findings: [GuardrailFinding] = []
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 4 else {
            return .rejected([GuardrailFinding(guardrail: .schema, detail: "reply is empty")])
        }

        let screened = SafetyScreen.review(text)
        let blocking = screened.filter { $0.guardrail == .safety }
        guard blocking.isEmpty else { return .rejected(blocking) }

        var working = text
        let scrub = SafetyScreen.scrubbed(working)
        if !scrub.findings.isEmpty {
            working = scrub.text
            findings.append(contentsOf: scrub.findings)
        }

        let sources = facts + [lesson.title, lesson.goal] + (exercise.map { [$0.prompt, $0.explanation] } ?? [])
        let ungrounded = GroundingCheck.findings(for: working, sources: sources)
        if !ungrounded.isEmpty {
            guard let grounded = GroundingCheck.filteredToGrounded(working, sources: sources) else {
                return .rejected(ungrounded)
            }
            working = grounded
            findings.append(contentsOf: ungrounded)
        }

        if let exercise {
            let leaks = AnswerLeakDetector.findings(in: working, exercise: exercise)
            if !leaks.isEmpty {
                guard let clean = AnswerLeakDetector.withoutLeaks(working, exercise: exercise) else {
                    return .rejected(leaks)
                }
                working = clean
                findings.append(contentsOf: leaks)
            }
        }

        let (trimmed, lengthFindings) = capped(
            working,
            characters: maxReplyCharacters,
            sentences: maxReplySentences
        )
        working = trimmed
        findings.append(contentsOf: lengthFindings)

        return findings.isEmpty ? .accepted(working) : .repaired(working, findings)
    }

    // MARK: - Learner input

    /// Screens what the learner types before it is handed to the model. An
    /// unsafe or out-of-scope question is answered by the app, not the model.
    static func reviewLearnerMessage(_ raw: String) -> GuardrailOutcome<String> {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return .rejected([GuardrailFinding(guardrail: .schema, detail: "message is empty")])
        }
        let findings = SafetyScreen.review(text)
        let blocking = findings.filter { $0.guardrail == .safety || $0.guardrail == .privacy }
        guard blocking.isEmpty else { return .rejected(blocking) }
        return .accepted(text)
    }

    /// What the coach says when it declines. Friendly, brief, no lecture.
    static func declineMessage(for findings: [GuardrailFinding]) -> String {
        if findings.contains(where: { $0.guardrail == .privacy }) {
            return "Let's leave personal details out of it. Ask me about the lesson instead."
        }
        return "That one's outside what I can help with. Ask me about this lesson and I'm all yours."
    }

    // MARK: - Length

    private static func capped(
        _ text: String,
        characters: Int,
        sentences limit: Int
    ) -> (String, [GuardrailFinding]) {
        var findings: [GuardrailFinding] = []
        var working = text

        let parts = Sentences.split(working)
        if parts.count > limit {
            working = Sentences.join(Array(parts.prefix(limit)))
            findings.append(GuardrailFinding(
                guardrail: .length,
                detail: "trimmed \(parts.count) sentences to \(limit)"
            ))
        }
        if working.count > characters {
            let cut = String(working.prefix(characters))
            // Prefer to end on a sentence boundary rather than mid-word.
            if let lastStop = cut.lastIndex(where: { $0 == "." || $0 == "!" || $0 == "?" }) {
                working = String(cut[...lastStop])
            } else if let lastSpace = cut.lastIndex(of: " ") {
                working = String(cut[..<lastSpace]) + "…"
            } else {
                working = cut
            }
            findings.append(GuardrailFinding(
                guardrail: .length,
                detail: "over \(characters) characters, shortened"
            ))
        }
        return (working, findings)
    }
}
