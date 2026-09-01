//
//  PracticeGenerator.swift
//  Quark
//
//  Bonus practice written on-device by Apple Intelligence. This is the one
//  place where the app shows a learner a question nobody wrote by hand, so it
//  is also the most tightly fenced: guided generation for shape, then the full
//  ItemGuardrails review, then one retry with the rejection reasons fed back,
//  then silence. A session that gets no generated item simply has curated
//  questions in its place, and the learner is never told a feature failed.
//

import Foundation

struct GeneratedItemResult: Sendable {
    let exercise: Exercise?
    let findings: [GuardrailFinding]
    let attempts: Int
    /// Apple Intelligence itself declined, before Quark's review ran.
    let blockedBySafetySystem: Bool

    var succeeded: Bool { exercise != nil }
}

struct PracticeGenerator: Sendable {
    /// Generated items per session. Low on purpose: the curated ramp is the
    /// spine of a lesson, and generated questions are seasoning.
    static let maxPerSession = 2

    let reasoner: LanguageReasoner

    init(reasoner: LanguageReasoner) {
        self.reasoner = reasoner
    }

    var isAvailable: Bool { reasoner.isAvailable }

    func bonusItem(
        for lesson: Lesson,
        existingPrompts: [String],
        wantsNumeric: Bool = false
    ) async -> GeneratedItemResult {
        guard reasoner.isAvailable else {
            return GeneratedItemResult(
                exercise: nil,
                findings: [],
                attempts: 0,
                blockedBySafetySystem: false
            )
        }

        var corrections: [String] = []
        var allFindings: [GuardrailFinding] = []

        for attempt in 1...2 {
            let request = GeneratedItemRequest(
                lessonTitle: lesson.title,
                goal: lesson.goal,
                facts: lesson.facts,
                avoid: existingPrompts,
                wantsNumeric: wantsNumeric,
                corrections: corrections
            )

            let draft: GeneratedItemDraft?
            do {
                draft = try await reasoner.generateItem(request)
            } catch ReasonerError.blockedBySafetySystem {
                return GeneratedItemResult(
                    exercise: nil,
                    findings: allFindings + [GuardrailFinding(
                        guardrail: .safety,
                        detail: "blocked by Apple Intelligence guardrails"
                    )],
                    attempts: attempt,
                    blockedBySafetySystem: true
                )
            } catch {
                return GeneratedItemResult(
                    exercise: nil,
                    findings: allFindings,
                    attempts: attempt,
                    blockedBySafetySystem: false
                )
            }

            guard let draft else {
                return GeneratedItemResult(
                    exercise: nil,
                    findings: allFindings,
                    attempts: attempt,
                    blockedBySafetySystem: false
                )
            }

            let outcome = ItemGuardrails.review(
                draft,
                lesson: lesson,
                existingPrompts: existingPrompts
            )
            allFindings.append(contentsOf: outcome.findings)

            if let exercise = outcome.value {
                // `allFindings` carries the earlier rejection too, so the
                // transparency panel can show what it took to get here.
                return GeneratedItemResult(
                    exercise: exercise,
                    findings: allFindings,
                    attempts: attempt,
                    blockedBySafetySystem: false
                )
            }
            corrections = outcome.findings.map(\.correction)
        }

        return GeneratedItemResult(
            exercise: nil,
            findings: allFindings,
            attempts: 2,
            blockedBySafetySystem: false
        )
    }
}
