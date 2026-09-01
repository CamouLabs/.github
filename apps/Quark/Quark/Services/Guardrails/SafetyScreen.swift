//
//  SafetyScreen.swift
//  Quark
//
//  Content safety, privacy scrubbing, and the on-syllabus check.
//
//  This is a deliberately blunt instrument. It runs after Apple Intelligence's
//  own guardrails and it is allowed to be over-cautious, because the cost of a
//  false positive is one discarded practice question and the cost of a false
//  negative is a child reading something they should not.
//
//  Matching is on whole normalised tokens and on explicit phrases, never on
//  substrings — a chemistry lesson has every right to the word "acid", and
//  "assess" must not trip a check for a shorter word inside it.
//

import Foundation

enum SafetyScreen {
    // MARK: - Blocked content

    /// Single words that have no place in a STEM practice question regardless
    /// of context. Kept short on purpose; the phrase list does the real work.
    private static let blockedTokens: Set<String> = [
        "suicide", "selfharm", "cocaine", "heroin", "meth", "methamphetamine",
        "porn", "pornography", "rape", "slur", "nazi", "genocide", "torture",
        "overdose", "gore", "molest"
    ]

    /// Harmful intent usually shows up as a phrase, not a word.
    private static let blockedPhrases: [String] = [
        "kill yourself", "kill myself", "end my life", "hurt yourself",
        "how to make a bomb", "make a bomb", "build a bomb", "build a weapon",
        "synthesize explosive", "make explosives", "make poison", "poison someone",
        "how to hurt", "how to kill", "buy drugs", "get high", "sexual",
        "hate crime", "ethnic cleansing", "self harm"
    ]

    /// Domains the coach must decline rather than attempt.
    private static let outOfScopePhrases: [String] = [
        "should i take", "what medication", "diagnose", "my symptoms",
        "is it legal", "sue", "invest in", "buy stock", "my prescription",
        "which doctor", "is my rash"
    ]

    // MARK: - Personal data

    private static let personalDataPhrases: [String] = [
        "your full name", "your address", "your phone number", "your email",
        "which school do you", "how old are you", "where do you live",
        "your parents name", "your password", "credit card"
    ]

    /// Reviews model output for unsafe or out-of-scope content.
    static func review(_ text: String) -> [GuardrailFinding] {
        var findings: [GuardrailFinding] = []
        let normalized = AnswerChecker.normalize(text)
        let tokens = Set(normalized.split(separator: " ").map(String.init))

        if let hit = blockedTokens.first(where: { tokens.contains($0) }) {
            findings.append(GuardrailFinding(
                guardrail: .safety,
                detail: "contains blocked term '\(hit)'"
            ))
        }
        if let hit = blockedPhrases.first(where: { normalized.contains($0) }) {
            findings.append(GuardrailFinding(
                guardrail: .safety,
                detail: "contains blocked phrase '\(hit)'"
            ))
        }
        if let hit = outOfScopePhrases.first(where: { normalized.contains($0) }) {
            findings.append(GuardrailFinding(
                guardrail: .safety,
                detail: "asks for advice outside STEM practice ('\(hit)')"
            ))
        }
        if let hit = personalDataPhrases.first(where: { normalized.contains($0) }) {
            findings.append(GuardrailFinding(
                guardrail: .privacy,
                detail: "solicits personal information ('\(hit)')"
            ))
        }
        findings.append(contentsOf: contactDetailFindings(in: text))
        return findings
    }

    /// True when a learner's own message should be answered at all. The same
    /// screen runs on input, so an unsafe question is declined before it is
    /// ever handed to the model.
    static func allowsLearnerMessage(_ text: String) -> Bool {
        review(text).allSatisfy { $0.guardrail != .safety && $0.guardrail != .privacy }
    }

    // MARK: - Contact details and links

    private static let emailPattern = #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#
    private static let urlPattern = #"(https?://|www\.)[^\s]+"#
    private static let phonePattern = #"(\+?\d[\d\s()-]{7,}\d)"#

    static func contactDetailFindings(in text: String) -> [GuardrailFinding] {
        var findings: [GuardrailFinding] = []
        if matches(emailPattern, in: text) {
            findings.append(GuardrailFinding(guardrail: .privacy, detail: "contains an email address"))
        }
        if matches(urlPattern, in: text) {
            findings.append(GuardrailFinding(guardrail: .privacy, detail: "contains a link"))
        }
        if looksLikePhoneNumber(text) {
            findings.append(GuardrailFinding(guardrail: .privacy, detail: "contains what looks like a phone number"))
        }
        return findings
    }

    /// A list of numeric answer options is a run of digits and spaces, and so
    /// is a phone number, so a regex alone produces constant false positives on
    /// a maths app. A run only counts as a phone number when it carries phone
    /// punctuation, or is a long unbroken string of digits.
    static func looksLikePhoneNumber(_ text: String) -> Bool {
        let runCharacters: Set<Character> = ["+", "(", ")", "-", " "]
        var run = ""

        func isPhone(_ candidate: String) -> Bool {
            let digits = candidate.filter(\.isNumber).count
            guard digits >= 9 else { return false }
            let hasPhonePunctuation = candidate.contains("+")
                || candidate.contains("(")
                || candidate.contains("-")
            let separators = candidate.filter { $0 == " " }.count
            if hasPhonePunctuation, separators <= 3 { return true }
            return separators == 0 && digits >= 10
        }

        for character in text {
            if character.isNumber || runCharacters.contains(character) {
                run.append(character)
            } else {
                if isPhone(run) { return true }
                run = ""
            }
        }
        return isPhone(run)
    }

    /// Removes links and contact details rather than discarding otherwise good
    /// coaching text.
    static func scrubbed(_ text: String) -> (text: String, findings: [GuardrailFinding]) {
        let findings = contactDetailFindings(in: text)
        guard !findings.isEmpty else { return (text, []) }

        var cleaned = text
        for pattern in [emailPattern, urlPattern, phonePattern] {
            cleaned = replacing(pattern, in: cleaned, with: "")
        }
        cleaned = cleaned
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (cleaned, findings)
    }

    // MARK: - On syllabus

    /// Fraction of a text's content words that the curriculum itself uses.
    /// Compared on stems, so a plural is not treated as a new subject.
    static func topicality(of text: String, lesson: Lesson) -> Double {
        let words = Curriculum.stems(text)
        guard !words.isEmpty else { return 0 }
        let vocabulary = Curriculum.vocabularyStems.union(lessonStems(lesson))
        let known = words.filter { vocabulary.contains($0) }.count
        return Double(known) / Double(words.count)
    }

    /// Terms shared with this specific lesson, not merely with the app's
    /// overall vocabulary. Stops a physics question wandering into biology.
    static func lessonOverlap(of text: String, lesson: Lesson) -> Int {
        Curriculum.stems(text).intersection(lessonStems(lesson)).count
    }

    private static func lessonStems(_ lesson: Lesson) -> Set<String> {
        var stems = Curriculum.stems(lesson.title)
        stems.formUnion(Curriculum.stems(lesson.goal))
        for fact in lesson.facts {
            stems.formUnion(Curriculum.stems(fact))
        }
        return stems
    }

    static let minTopicality = 0.5
    static let minLessonOverlap = 2

    static func topicalFindings(for text: String, lesson: Lesson) -> [GuardrailFinding] {
        var findings: [GuardrailFinding] = []
        let score = topicality(of: text, lesson: lesson)
        if score < minTopicality {
            findings.append(GuardrailFinding(
                guardrail: .topical,
                detail: String(format: "only %.0f%% of the wording comes from the curriculum", score * 100)
            ))
        }
        let overlap = lessonOverlap(of: text, lesson: lesson)
        if overlap < minLessonOverlap {
            findings.append(GuardrailFinding(
                guardrail: .topical,
                detail: "shares \(overlap) term(s) with '\(lesson.title)'; needs at least \(minLessonOverlap)"
            ))
        }
        return findings
    }

    // MARK: - Regex helpers

    private static func matches(_ pattern: String, in text: String) -> Bool {
        text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    private static func replacing(_ pattern: String, in text: String, with replacement: String) -> String {
        var result = text
        while let range = result.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
            result.replaceSubrange(range, with: replacement)
        }
        return result
    }
}
