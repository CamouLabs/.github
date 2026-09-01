//
//  CoachService.swift
//  Quark
//
//  The coach. Three jobs — hint, explain, answer a question — and one rule
//  running through all of them: whatever comes back from the model is a draft
//  until the guardrails have signed it off.
//
//  When a draft fails a repairable check, the coach gets exactly one rewrite
//  against the constitution (critique-and-revise, Bai et al. 2022). If the
//  rewrite also fails, the curated text ships instead. A learner is never left
//  staring at an error where a hint should be.
//

import Foundation

struct CoachResponse: Sendable, Equatable {
    enum Source: String, Sendable {
        /// Straight from Apple Intelligence, unmodified.
        case appleIntelligence
        /// From Apple Intelligence, after the app repaired it.
        case repaired
        /// The curated text that ships with the lesson.
        case curated
        /// Declined on purpose.
        case declined

        var label: String {
            switch self {
            case .appleIntelligence: return "Apple Intelligence"
            case .repaired: return "Apple Intelligence, edited by guardrails"
            case .curated: return "Built-in"
            case .declined: return "Declined"
            }
        }
    }

    let text: String
    let source: Source
    let findings: [GuardrailFinding]

    static func curated(_ text: String) -> CoachResponse {
        CoachResponse(text: text, source: .curated, findings: [])
    }
}

struct CoachService: Sendable {
    let reasoner: LanguageReasoner

    init(reasoner: LanguageReasoner) {
        self.reasoner = reasoner
    }

    // MARK: - Hint

    func hint(for exercise: Exercise, facts: [String], attempts: Int = 1) async -> CoachResponse {
        guard reasoner.isAvailable else { return .curated(exercise.hint) }

        let prompt = QuarkPersona.hintPrompt(exercise: exercise, facts: facts, attempts: attempts)
        guard let draft = await text(system: QuarkPersona.hintSystem, prompt: prompt, profile: .coaching) else {
            return .curated(exercise.hint)
        }

        switch CoachGuardrails.reviewHint(draft, exercise: exercise, facts: facts) {
        case .accepted(let hint):
            return CoachResponse(text: hint, source: .appleIntelligence, findings: [])
        case .repaired(let hint, let findings):
            return CoachResponse(text: hint, source: .repaired, findings: findings)
        case .rejected(let findings):
            return await revisedHint(draft: draft, exercise: exercise, facts: facts, problems: findings)
        }
    }

    /// One constitutional rewrite, then the curated hint.
    private func revisedHint(
        draft: String,
        exercise: Exercise,
        facts: [String],
        problems: [GuardrailFinding]
    ) async -> CoachResponse {
        let prompt = QuarkConstitution.revisionPrompt(
            draft: draft,
            problems: problems.map(\.correction),
            facts: facts
        )
        guard let revised = await text(
            system: QuarkConstitution.revisionSystem,
            prompt: prompt,
            profile: .exact
        ) else {
            return CoachResponse(text: exercise.hint, source: .curated, findings: problems)
        }

        switch CoachGuardrails.reviewHint(revised, exercise: exercise, facts: facts) {
        case .accepted(let hint), .repaired(let hint, _):
            return CoachResponse(text: hint, source: .repaired, findings: problems)
        case .rejected(let findings):
            return CoachResponse(text: exercise.hint, source: .curated, findings: problems + findings)
        }
    }

    // MARK: - Explanation

    func explanation(
        for exercise: Exercise,
        learnerAnswer: String?,
        wasCorrect: Bool,
        facts: [String]
    ) async -> CoachResponse {
        guard reasoner.isAvailable else { return .curated(exercise.explanation) }

        let prompt = QuarkPersona.explainPrompt(
            exercise: exercise,
            learnerAnswer: learnerAnswer,
            wasCorrect: wasCorrect,
            facts: facts
        )
        guard let draft = await text(system: QuarkPersona.explainSystem, prompt: prompt, profile: .exact) else {
            return .curated(exercise.explanation)
        }

        switch CoachGuardrails.reviewExplanation(draft, exercise: exercise, facts: facts) {
        case .accepted(let explanation):
            return CoachResponse(text: explanation, source: .appleIntelligence, findings: [])
        case .repaired(let explanation, let findings):
            return CoachResponse(text: explanation, source: .repaired, findings: findings)
        case .rejected(let findings):
            return CoachResponse(text: exercise.explanation, source: .curated, findings: findings)
        }
    }

    // MARK: - Ask Quark

    func reply(
        to message: String,
        exercise: Exercise?,
        lesson: Lesson,
        facts: [String]
    ) async -> CoachResponse {
        // The learner's own message is screened first, by the app, on-device.
        let screened = CoachGuardrails.reviewLearnerMessage(message)
        if case .rejected(let findings) = screened {
            return CoachResponse(
                text: CoachGuardrails.declineMessage(for: findings),
                source: .declined,
                findings: findings
            )
        }

        guard reasoner.isAvailable else {
            return .curated(fallbackReply(for: exercise, lesson: lesson))
        }

        let prompt = QuarkPersona.chatPrompt(question: message, exercise: exercise, facts: facts)
        do {
            let draft = try await reasoner.respond(
                system: QuarkPersona.coachSystem,
                prompt: prompt,
                profile: .coaching
            )
            switch CoachGuardrails.reviewReply(draft, exercise: exercise, lesson: lesson, facts: facts) {
            case .accepted(let reply):
                return CoachResponse(text: reply, source: .appleIntelligence, findings: [])
            case .repaired(let reply, let findings):
                return CoachResponse(text: reply, source: .repaired, findings: findings)
            case .rejected(let findings):
                return CoachResponse(
                    text: fallbackReply(for: exercise, lesson: lesson),
                    source: .curated,
                    findings: findings
                )
            }
        } catch let error as ReasonerError {
            return CoachResponse(
                text: error == .blockedBySafetySystem
                    ? error.learnerMessage
                    : fallbackReply(for: exercise, lesson: lesson),
                source: error == .blockedBySafetySystem ? .declined : .curated,
                findings: error == .blockedBySafetySystem
                    ? [GuardrailFinding(guardrail: .safety, detail: "blocked by Apple Intelligence guardrails")]
                    : []
            )
        } catch {
            return .curated(fallbackReply(for: exercise, lesson: lesson))
        }
    }

    private func fallbackReply(for exercise: Exercise?, lesson: Lesson) -> String {
        if let exercise {
            return "Here's the nudge that ships with this question: \(exercise.hint)"
        }
        return "This lesson is about \(lesson.goal.lowercased()) Try the first question and I'll help from there."
    }

    // MARK: - Model call

    private func text(system: String, prompt: String, profile: GenerationProfile) async -> String? {
        do {
            let response = try await reasoner.respond(system: system, prompt: prompt, profile: profile)
            let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        } catch {
            return nil
        }
    }
}
