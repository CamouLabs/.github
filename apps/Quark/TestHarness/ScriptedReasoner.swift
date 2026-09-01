//
//  ScriptedReasoner.swift
//  Quark
//
//  A LanguageReasoner that says exactly what a test tells it to say —
//  including the things a real model occasionally says that must never reach a
//  learner. Used by the unit tests and by GuardrailHarness to red-team the
//  guardrail layer without a device.
//

import Foundation

struct ScriptedReasoner: LanguageReasoner {
    let isAvailable: Bool
    let displayName: String
    var statusDetail: String { displayName }

    /// Returned by `respond`, in order; the last one repeats.
    let replies: [String]
    /// Returned by `generateItem`, in order; the last one repeats.
    let drafts: [GeneratedItemDraft?]
    let error: ReasonerError?

    init(
        replies: [String] = [],
        drafts: [GeneratedItemDraft?] = [],
        error: ReasonerError? = nil,
        isAvailable: Bool = true,
        displayName: String = "Scripted model"
    ) {
        self.replies = replies
        self.drafts = drafts
        self.error = error
        self.isAvailable = isAvailable
        self.displayName = displayName
    }

    private final class Counter: @unchecked Sendable {
        private let lock = NSLock()
        private var value = 0
        func next() -> Int {
            lock.lock()
            defer { lock.unlock() }
            let current = value
            value += 1
            return current
        }
    }

    private let replyCount = Counter()
    private let draftCount = Counter()

    func respond(system: String?, prompt: String, profile: GenerationProfile) async throws -> String {
        if let error { throw error }
        guard !replies.isEmpty else { return "" }
        return replies[min(replyCount.next(), replies.count - 1)]
    }

    func generateItem(_ request: GeneratedItemRequest) async throws -> GeneratedItemDraft? {
        if let error { throw error }
        guard !drafts.isEmpty else { return nil }
        return drafts[min(draftCount.next(), drafts.count - 1)]
    }
}

extension GeneratedItemDraft {
    /// A well-formed draft about fractions, used as the base for tests that
    /// break one thing at a time.
    static func sample(
        prompt: String = "Which of these fractions is closest to a half?",
        options: [String] = ["1/8", "2/5", "1/5", "1/10"],
        correctIndex: Int = 1,
        explanation: String = "As decimals, 2/5 is 0.4 and 1/5 is 0.2, so 2/5 is nearest.",
        hint: String = "Turn each fraction into a decimal first.",
        numericAnswer: Double? = nil,
        checkExpression: String? = nil
    ) -> GeneratedItemDraft {
        GeneratedItemDraft(
            prompt: prompt,
            options: options,
            correctIndex: correctIndex,
            explanation: explanation,
            hint: hint,
            numericAnswer: numericAnswer,
            checkExpression: checkExpression
        )
    }
}
