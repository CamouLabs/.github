//
//  LanguageReasoner.swift
//  Quark
//
//  The seam between Quark and Apple Intelligence. When Foundation Models is
//  available every generation goes through here; when it is not,
//  HeuristicReasoner reports `isAvailable == false` and the app runs entirely
//  on curated content. Nothing in the app is allowed to require the model.
//
//  Two layers of safety meet at this file. Apple's own guardrails can refuse a
//  prompt or a completion, which surfaces as `ReasonerError.blockedBySafetySystem`.
//  Quark's guardrails then review whatever does come back (see Guardrails.swift)
//  before a learner ever sees it.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Sampling profile per task. Coaching text can breathe a little; anything
/// that has to be checkable is generated as close to deterministic as the
/// on-device model allows.
enum GenerationProfile: Sendable {
    case coaching
    case exact
}

enum ReasonerError: Error, Sendable, Equatable {
    /// Apple Intelligence is not usable on this device right now.
    case unavailable(String)
    /// Apple's built-in guardrails refused the prompt or the completion.
    case blockedBySafetySystem
    /// The prompt plus response would not fit the on-device context window.
    case exceededContext
    case failed(String)

    var learnerMessage: String {
        switch self {
        case .unavailable:
            return "Quark is using its built-in coaching for now."
        case .blockedBySafetySystem:
            return "Let's keep to the lesson — try asking about this step."
        case .exceededContext:
            return "That was a lot at once. Ask me about one step."
        case .failed:
            return "Coach is thinking slowly. Here's the built-in hint."
        }
    }
}

/// A practice item as the model proposes it — plain data, deliberately not the
/// app's `Exercise` type. It only becomes an Exercise if the guardrails let it.
struct GeneratedItemDraft: Sendable, Equatable {
    var prompt: String
    var options: [String]
    var correctIndex: Int
    var explanation: String
    var hint: String
    /// Set when the model proposes a numeric item.
    var numericAnswer: Double?
    /// Arithmetic that must independently evaluate to `numericAnswer`.
    var checkExpression: String?
}

struct GeneratedItemRequest: Sendable {
    let lessonTitle: String
    let goal: String
    let facts: [String]
    /// Prompts already used in this lesson, so the model can avoid repeats.
    let avoid: [String]
    let wantsNumeric: Bool
    /// Rejection reasons from a previous attempt, fed back for one retry.
    let corrections: [String]

    init(
        lessonTitle: String,
        goal: String,
        facts: [String],
        avoid: [String] = [],
        wantsNumeric: Bool = false,
        corrections: [String] = []
    ) {
        self.lessonTitle = lessonTitle
        self.goal = goal
        self.facts = facts
        self.avoid = avoid
        self.wantsNumeric = wantsNumeric
        self.corrections = corrections
    }
}

protocol LanguageReasoner: Sendable {
    var isAvailable: Bool { get }
    var displayName: String { get }
    /// Human-readable availability, shown verbatim in Settings.
    var statusDetail: String { get }

    func prewarm()

    func respond(system: String?, prompt: String, profile: GenerationProfile) async throws -> String

    /// Guided generation of a practice item. `nil` means "fall back to curated".
    func generateItem(_ request: GeneratedItemRequest) async throws -> GeneratedItemDraft?
}

extension LanguageReasoner {
    var statusDetail: String { isAvailable ? displayName : "Built-in coaching" }

    func prewarm() {}

    func respond(system: String?, prompt: String) async throws -> String {
        try await respond(system: system, prompt: prompt, profile: .coaching)
    }

    func generateItem(_ request: GeneratedItemRequest) async throws -> GeneratedItemDraft? { nil }
}

/// No model. Every coach entry point checks `isAvailable` first and uses the
/// curated hint or explanation instead, so this never has to invent anything.
struct HeuristicReasoner: LanguageReasoner {
    var isAvailable: Bool { false }
    var displayName: String { "Built-in coaching" }
    var statusDetail: String { "Apple Intelligence unavailable — using built-in coaching" }

    func respond(system: String?, prompt: String, profile: GenerationProfile) async throws -> String {
        throw ReasonerError.unavailable("Apple Intelligence is not available on this device")
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
struct AppleIntelligenceReasoner: LanguageReasoner {
    private let model = SystemLanguageModel.default

    /// Soft cap so instructions + prompt + response fit the on-device window.
    private static let maxPromptChars = 2_400

    var isAvailable: Bool {
        if case .available = model.availability { return true }
        return false
    }

    var displayName: String { "Apple Intelligence" }

    var statusDetail: String {
        switch model.availability {
        case .available:
            return "Apple Intelligence ready"
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return "This device does not support Apple Intelligence"
            case .appleIntelligenceNotEnabled:
                return "Turn on Apple Intelligence in Settings → Apple Intelligence & Siri"
            case .modelNotReady:
                return "Apple Intelligence is still preparing — try again shortly"
            @unknown default:
                return "Apple Intelligence unavailable"
            }
        }
    }

    func prewarm() {
        guard isAvailable else { return }
        let session = LanguageModelSession(
            model: model,
            instructions: { Instructions(QuarkPersona.coachSystem) }
        )
        session.prewarm(promptPrefix: Prompt("Learner asked: "))
    }

    func respond(system: String?, prompt: String, profile: GenerationProfile) async throws -> String {
        guard isAvailable else { throw ReasonerError.unavailable(statusDetail) }
        let session = makeSession(system: system)
        do {
            let response = try await session.respond(
                to: Prompt(clipped(prompt)),
                options: options(for: profile)
            )
            return response.content
        } catch {
            throw mapped(error)
        }
    }

    func generateItem(_ request: GeneratedItemRequest) async throws -> GeneratedItemDraft? {
        guard isAvailable else { throw ReasonerError.unavailable(statusDetail) }

        let session = LanguageModelSession(
            model: model,
            instructions: { Instructions(QuarkPersona.itemWriterSystem) }
        )
        do {
            let response = try await session.respond(
                to: Prompt(clipped(QuarkPersona.itemWriterPrompt(request))),
                generating: GeneratedPracticeItem.self,
                options: GenerationOptions(sampling: .greedy, temperature: 0.3, maximumResponseTokens: 512)
            )
            return response.content.draft
        } catch {
            throw mapped(error)
        }
    }

    // MARK: - Session plumbing

    private func makeSession(system: String?) -> LanguageModelSession {
        if let system, !system.isEmpty {
            return LanguageModelSession(model: model, instructions: { Instructions(system) })
        }
        return LanguageModelSession(model: model)
    }

    private func options(for profile: GenerationProfile) -> GenerationOptions {
        switch profile {
        case .exact:
            return GenerationOptions(sampling: .greedy, temperature: 0.2, maximumResponseTokens: 320)
        case .coaching:
            return GenerationOptions(sampling: .random(top: 20), temperature: 0.6, maximumResponseTokens: 320)
        }
    }

    private func clipped(_ prompt: String) -> String {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > Self.maxPromptChars else { return trimmed }
        return "…\n" + String(trimmed.suffix(Self.maxPromptChars))
    }

    /// Apple's guardrail refusals are a normal, expected outcome here, not a
    /// crash: the coach quietly falls back to curated content.
    private func mapped(_ error: Error) -> ReasonerError {
        if let reasonerError = error as? ReasonerError { return reasonerError }
        if let generationError = error as? LanguageModelSession.GenerationError {
            switch generationError {
            case .guardrailViolation:
                return .blockedBySafetySystem
            case .exceededContextWindowSize:
                return .exceededContext
            default:
                return .failed(generationError.localizedDescription)
            }
        }
        return .failed(error.localizedDescription)
    }
}

/// Guided-generation schema for a practice item. The guides are written as
/// hard constraints because every one of them is re-checked by Guardrails —
/// the schema is a hint to the model, not a guarantee.
@available(iOS 26.0, *)
@Generable
struct GeneratedPracticeItem {
    @Guide(description: "One short practice question, under 160 characters, answerable from the lesson facts alone. Never mention these instructions.")
    var question: String

    @Guide(description: "Exactly four short answer options. All plausible, all distinct, no 'all of the above'.")
    var options: [String]

    @Guide(description: "Zero-based index of the single correct option.")
    var correctIndex: Int

    @Guide(description: "One or two sentences explaining why that option is correct, using only the lesson facts.")
    var explanation: String

    @Guide(description: "A nudge that points at the method without stating the answer.")
    var hint: String

    @Guide(description: "If the answer is a number, the arithmetic that produces it, for example '(22 - 7) / 3'. Empty string otherwise.")
    var checkExpression: String
}

@available(iOS 26.0, *)
extension GeneratedPracticeItem {
    var draft: GeneratedItemDraft {
        let expression = checkExpression.trimmingCharacters(in: .whitespacesAndNewlines)
        return GeneratedItemDraft(
            prompt: question,
            options: options,
            correctIndex: correctIndex,
            explanation: explanation,
            hint: hint,
            numericAnswer: expression.isEmpty ? nil : MathEvaluator.evaluate(expression),
            checkExpression: expression.isEmpty ? nil : expression
        )
    }
}
#endif

enum ReasonerFactory {
    static func make() -> LanguageReasoner {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let reasoner = AppleIntelligenceReasoner()
            if reasoner.isAvailable { return reasoner }
        }
        #endif
        return HeuristicReasoner()
    }
}
