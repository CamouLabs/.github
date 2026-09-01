//
//  Guardrail.swift
//  Quark
//
//  Vocabulary for the guardrail layer.
//
//  Apple Intelligence has its own safety guardrails, and they run first. These
//  are the app's: eleven narrow, deterministic checks that decide whether
//  model output is fit to put in front of someone who is trying to learn. They
//  are separate from the model, they are testable without it, and every one of
//  them can be read in a minute.
//

import Foundation

enum GuardrailID: String, Sendable, CaseIterable, Identifiable {
    case schema
    case safety
    case privacy
    case topical
    case mathCheck
    case ambiguity
    case readability
    case grounding
    case novelty
    case answerLeak
    case length

    var id: String { rawValue }

    var title: String {
        switch self {
        case .schema: return "Shape"
        case .safety: return "Safety"
        case .privacy: return "No personal data"
        case .topical: return "On syllabus"
        case .mathCheck: return "Arithmetic re-checked"
        case .ambiguity: return "One right answer"
        case .readability: return "Readable"
        case .grounding: return "Grounded in the lesson"
        case .novelty: return "Not a repeat"
        case .answerLeak: return "No spoilers"
        case .length: return "Short enough"
        }
    }

    /// Shown in Settings, one line each, so the list of guardrails is
    /// something a learner or a parent can actually read.
    var rationale: String {
        switch self {
        case .schema:
            return "A generated question must have four distinct options and exactly one marked correct."
        case .safety:
            return "Anything violent, sexual, self-harm related, or otherwise unsuitable is dropped, not softened."
        case .privacy:
            return "Names, emails, phone numbers, and links are stripped; the coach never asks for personal details."
        case .topical:
            return "Generated material has to use the vocabulary of the lesson it claims to belong to."
        case .mathCheck:
            return "Numeric answers are re-derived from arithmetic before the question is shown."
        case .ambiguity:
            return "Duplicate options, 'all of the above', and questions with two defensible answers are rejected."
        case .readability:
            return "Long sentences and jargon the lesson never introduced are rejected."
        case .grounding:
            return "Every number in coach text must appear in the lesson or the question itself."
        case .novelty:
            return "A generated question that repeats one already asked is discarded."
        case .answerLeak:
            return "A hint that contains the answer is rewritten once, then replaced with the built-in hint."
        case .length:
            return "Coach replies are capped so a hint stays a hint."
        }
    }
}

struct GuardrailFinding: Sendable, Equatable, Identifiable {
    let guardrail: GuardrailID
    let detail: String

    var id: String { "\(guardrail.rawValue):\(detail)" }

    /// Phrasing fed back to the model for its single retry.
    var correction: String { "\(guardrail.title): \(detail)" }
}

enum GuardrailOutcome<Value: Sendable>: Sendable {
    case accepted(Value)
    /// Passed, but only after the app repaired it (a redaction, a rewrite).
    case repaired(Value, [GuardrailFinding])
    case rejected([GuardrailFinding])

    var value: Value? {
        switch self {
        case .accepted(let value): return value
        case .repaired(let value, _): return value
        case .rejected: return nil
        }
    }

    var findings: [GuardrailFinding] {
        switch self {
        case .accepted: return []
        case .repaired(_, let findings): return findings
        case .rejected(let findings): return findings
        }
    }

    var wasRejected: Bool {
        if case .rejected = self { return true }
        return false
    }
}

/// Running tally of what the guardrails did, so the app can show its work
/// instead of asking to be trusted. Lives in memory only.
struct GuardrailLedger: Sendable, Equatable {
    var reviewed = 0
    var accepted = 0
    var repaired = 0
    var rejected = 0
    var blockedBySystemGuardrail = 0
    var rejectionsByGuardrail: [String: Int] = [:]

    mutating func record<Value: Sendable>(_ outcome: GuardrailOutcome<Value>) {
        reviewed += 1
        switch outcome {
        case .accepted:
            accepted += 1
        case .repaired:
            repaired += 1
        case .rejected(let findings):
            rejected += 1
            for finding in findings {
                rejectionsByGuardrail[finding.guardrail.rawValue, default: 0] += 1
            }
        }
    }

    mutating func recordSystemGuardrailBlock() {
        blockedBySystemGuardrail += 1
    }

    var topRejections: [GuardrailTally] {
        rejectionsByGuardrail
            .compactMap { key, count in
                GuardrailID(rawValue: key).map { GuardrailTally(guardrail: $0, count: count) }
            }
            .sorted { $0.count > $1.count }
    }
}

/// One guardrail and how often it fired. A named type rather than a tuple
/// because the summary screen enumerates these, and `ForEach` needs identity.
struct GuardrailTally: Sendable, Equatable, Identifiable {
    let guardrail: GuardrailID
    let count: Int

    var id: String { guardrail.rawValue }
}
