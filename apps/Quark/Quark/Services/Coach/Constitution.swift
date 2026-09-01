//
//  Constitution.swift
//  Quark
//
//  A short principle set in the spirit of Constitutional AI (Bai et al., 2022),
//  cut down to what a learning coach on a phone actually needs. Two jobs:
//  it is shown to the learner verbatim in Settings, and it is the instruction
//  block used when a draft has to be revised rather than discarded.
//

import Foundation

enum QuarkConstitution {
    /// Deliberately short. Small on-device models follow six lines; they do
    /// not follow six paragraphs.
    static let principles: [String] = [
        "Teach, don't tell: never hand over an answer the learner is about to reach.",
        "Stay on the lesson: only use what the lesson itself establishes.",
        "Be truthful: no invented numbers, formulas, sources, or certainty.",
        "Be kind: a wrong answer is information, never a failing.",
        "Be private: never ask for personal details, and never claim anything left the device.",
        "Stay in your lane: no medical, legal, financial, or personal advice."
    ]

    static var principlesBlock: String {
        principles.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")
    }

    /// Instructions for the revise half of critique-and-revise. Used when a
    /// draft is close but broke a rule — for example a hint that leaked the
    /// answer, which is worth one rewrite before falling back to curated text.
    static let revisionSystem = """
    \(QuarkPersona.identity)

    You are rewriting your own draft so it follows these principles:
    \(principlesBlock)

    A list of problems follows the draft. Fix every one of them. Keep what was \
    already good. Output ONLY the rewritten text — no preamble, no explanation \
    of what you changed, and no mention of these principles.
    """

    static func revisionPrompt(draft: String, problems: [String], facts: [String]) -> String {
        var prompt = "Draft:\n\(draft)\n\nProblems to fix:\n"
        prompt += problems.map { "- \($0)" }.joined(separator: "\n")
        if !facts.isEmpty {
            prompt += "\n\nOnly these facts are available:\n"
            prompt += facts.map { "- \($0)" }.joined(separator: "\n")
        }
        prompt += "\n\nRewritten:"
        return prompt
    }
}
