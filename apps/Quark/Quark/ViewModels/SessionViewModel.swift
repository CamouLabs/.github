//
//  SessionViewModel.swift
//  Quark
//
//  Runs one session: holds the answer in progress, grades it, feeds the
//  reward loop, and talks to the coach. All UI state lives on the main actor;
//  everything it calls into is a pure function or an async model call.
//
//  Two mechanics are worth naming. A missed question is requeued once at the
//  end of the session, because the point is to leave knowing it. And a
//  generated bonus question is fetched in the background mid-session, so a
//  slow model never makes the learner wait — if it is not ready, the session
//  simply does not have one.
//

import Foundation
import SwiftUI

@MainActor
final class SessionViewModel: ObservableObject {
    struct Feedback: Equatable {
        let isCorrect: Bool
        let headline: String
        let correctAnswer: String
        var explanation: String
        var explanationSource: CoachResponse.Source
        var note: String?
    }

    enum Phase: Equatable {
        case answering
        case feedback(Feedback)
        case finished(SessionSummary)
    }

    struct CoachMessage: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let isFromLearner: Bool
        let source: CoachResponse.Source?
    }

    // MARK: - Published state

    @Published private(set) var items: [Exercise]
    @Published private(set) var index = 0
    @Published private(set) var phase: Phase = .answering

    @Published var selectedOption: Int?
    @Published var booleanAnswer: Bool?
    @Published var typedAnswer = ""
    @Published private(set) var orderedSteps: [String] = []
    @Published private(set) var remainingSteps: [String] = []
    @Published private(set) var matchedPairs: [MatchPair] = []
    @Published private(set) var matchOptions: [String] = []
    @Published var pendingLeft: String?

    @Published private(set) var sparks: Int
    @Published private(set) var xpEarned = 0
    @Published private(set) var lastAward = 0
    @Published private(set) var combo = 0
    @Published private(set) var bestCombo = 0
    @Published private(set) var correctCount = 0

    @Published private(set) var hint: CoachResponse?
    @Published private(set) var isCoachBusy = false
    @Published private(set) var coachMessages: [CoachMessage] = []
    @Published private(set) var generatedServed = 0
    @Published private(set) var ledger = GuardrailLedger()
    /// Bumped to trigger the wrong-answer shake.
    @Published private(set) var shakeTick = 0

    // MARK: - Dependencies

    let plan: SessionPlan
    private let store: ProgressStore
    private let settings: AppSettings
    private let coach: CoachService
    private let generator: PracticeGenerator
    private let startedAt = Date()

    private var requeued: Set<String> = []
    private var hintsThisItem = 0
    private var bonusTask: Task<Void, Never>?

    init(
        plan: SessionPlan,
        store: ProgressStore = .shared,
        settings: AppSettings = .shared,
        reasoner: LanguageReasoner = ReasonerFactory.make()
    ) {
        self.plan = plan
        self.store = store
        self.settings = settings
        self.coach = CoachService(reasoner: settings.coachEnabled ? reasoner : HeuristicReasoner())
        self.generator = PracticeGenerator(
            reasoner: settings.generatedPracticeEnabled ? reasoner : HeuristicReasoner()
        )
        self.items = plan.items
        self.sparks = settings.sparksEnabled ? ProgressEngine.sparksPerSession : Int.max
        store.startSession()
        prepareCurrentItem()
    }

    deinit {
        bonusTask?.cancel()
    }

    // MARK: - Derived state

    var current: Exercise? {
        items.indices.contains(index) ? items[index] : nil
    }

    var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(index) / Double(items.count)
    }

    var sparksAreLimited: Bool { sparks != Int.max }

    /// True once the answer has been graded, which is what locks the controls.
    var isShowingFeedback: Bool {
        if case .feedback = phase { return true }
        return false
    }

    var facts: [String] {
        guard let current, let lesson = Curriculum.lesson(id: current.lessonID) else { return plan.facts }
        return lesson.facts
    }

    var lesson: Lesson? {
        guard let current else { return Curriculum.lesson(id: plan.lessonID) }
        return Curriculum.lesson(id: current.lessonID)
    }

    var canCheck: Bool {
        guard let current else { return false }
        switch current.content {
        case .multipleChoice: return selectedOption != nil
        case .trueFalse: return booleanAnswer != nil
        case .numeric, .shortText: return !typedAnswer.trimmingCharacters(in: .whitespaces).isEmpty
        case .ordering(let steps): return orderedSteps.count == steps.count
        case .matching(let pairs): return matchedPairs.count == pairs.count
        }
    }

    // MARK: - Answering

    func check() {
        guard let current, case .answering = phase else { return }

        let judgement = AnswerChecker.check(assembledAnswer(for: current), against: current.content)
        if judgement.isCorrect {
            combo += 1
            bestCombo = max(bestCombo, combo)
            correctCount += 1
            let award = store.record(judgement: judgement, lessonID: current.lessonID, combo: combo)
            xpEarned += award
            lastAward = award
            Haptics.correct()
        } else {
            combo = 0
            lastAward = 0
            _ = store.record(judgement: judgement, lessonID: current.lessonID, combo: 0)
            if sparksAreLimited { sparks = max(sparks - 1, 0) }
            shakeTick += 1
            Haptics.incorrect()
            requeueIfNeeded(current)
        }

        let feedback = Feedback(
            isCorrect: judgement.isCorrect,
            headline: judgement.isCorrect
                ? QuarkPersona.correctLine(combo: combo, seed: seed(for: current))
                : QuarkPersona.incorrectLine(seed: seed(for: current)),
            correctAnswer: current.content.answerStrings.first ?? "—",
            explanation: current.explanation,
            explanationSource: .curated,
            note: judgement.note
        )
        phase = .feedback(feedback)

        upgradeExplanation(for: current, judgement: judgement)
        scheduleBonusItemIfDue()
    }

    /// Answer without answering: costs the item, shows the explanation.
    func skip() {
        guard let current, case .answering = phase else { return }
        combo = 0
        _ = store.record(judgement: .missing, lessonID: current.lessonID, combo: 0)
        requeueIfNeeded(current)
        phase = .feedback(Feedback(
            isCorrect: false,
            headline: "Skipped — here's how it works.",
            correctAnswer: current.content.answerStrings.first ?? "—",
            explanation: current.explanation,
            explanationSource: .curated,
            note: nil
        ))
        upgradeExplanation(for: current, judgement: .missing)
    }

    func advance() {
        guard case .feedback = phase else { return }

        if sparksAreLimited, sparks == 0 {
            finish()
            return
        }
        index += 1
        if index >= items.count {
            finish()
            return
        }
        prepareCurrentItem()
        phase = .answering
    }

    private func finish() {
        bonusTask?.cancel()
        let bonus = store.completeSession(
            lessonID: plan.lessonID,
            correct: correctCount,
            total: max(items.count, 1),
            isReview: plan.mode.isReview
        )
        xpEarned += bonus
        phase = .finished(SessionSummary(
            mode: plan.mode,
            lessonTitle: plan.title,
            correct: correctCount,
            total: items.count,
            xpEarned: xpEarned,
            bestCombo: bestCombo,
            sparksLeft: sparksAreLimited ? sparks : ProgressEngine.sparksPerSession,
            generatedItemsServed: generatedServed,
            elapsed: Date().timeIntervalSince(startedAt)
        ))
        Haptics.celebrate()
    }

    // MARK: - Answer assembly

    private func assembledAnswer(for exercise: Exercise) -> LearnerAnswer {
        switch exercise.content {
        case .multipleChoice:
            return selectedOption.map { LearnerAnswer.option($0) } ?? .skipped
        case .trueFalse:
            return booleanAnswer.map { LearnerAnswer.boolean($0) } ?? .skipped
        case .numeric, .shortText:
            return .text(typedAnswer)
        case .ordering:
            return .sequence(orderedSteps)
        case .matching:
            return .pairs(matchedPairs)
        }
    }

    private func prepareCurrentItem() {
        selectedOption = nil
        booleanAnswer = nil
        typedAnswer = ""
        orderedSteps = []
        matchedPairs = []
        pendingLeft = nil
        hint = nil
        hintsThisItem = 0

        guard let current else { return }
        var generator = SeededGenerator(seed: current.id)
        switch current.content {
        case .ordering(let steps):
            remainingSteps = steps.shuffled(using: &generator)
        case .matching(let pairs):
            matchOptions = pairs.map(\.right).shuffled(using: &generator)
        default:
            remainingSteps = []
            matchOptions = []
        }
    }

    // MARK: - Ordering and matching interaction

    func chooseStep(_ step: String) {
        guard let position = remainingSteps.firstIndex(of: step) else { return }
        withAnimation(QuarkTheme.bounce) {
            remainingSteps.remove(at: position)
            orderedSteps.append(step)
        }
        Haptics.tap()
    }

    func removeStep(_ step: String) {
        guard let position = orderedSteps.firstIndex(of: step) else { return }
        withAnimation(QuarkTheme.bounce) {
            orderedSteps.remove(at: position)
            remainingSteps.append(step)
        }
    }

    func selectLeft(_ left: String) {
        guard !matchedPairs.contains(where: { $0.left == left }) else { return }
        pendingLeft = pendingLeft == left ? nil : left
        Haptics.tap()
    }

    func selectRight(_ right: String) {
        guard let left = pendingLeft, !matchedPairs.contains(where: { $0.right == right }) else { return }
        withAnimation(QuarkTheme.bounce) {
            matchedPairs.append(MatchPair(left: left, right: right))
            pendingLeft = nil
        }
        Haptics.tap()
    }

    func unmatch(_ pair: MatchPair) {
        withAnimation(QuarkTheme.bounce) {
            matchedPairs.removeAll { $0 == pair }
        }
    }

    func matchedRight(for left: String) -> String? {
        matchedPairs.first { $0.left == left }?.right
    }

    func isMatched(right: String) -> Bool {
        matchedPairs.contains { $0.right == right }
    }

    // MARK: - Coach

    func requestHint() {
        guard let current, !isCoachBusy else { return }
        hintsThisItem += 1
        isCoachBusy = true
        let attempts = hintsThisItem
        let facts = facts

        Task { [coach] in
            let response = await coach.hint(for: current, facts: facts, attempts: attempts)
            self.hint = response
            self.isCoachBusy = false
            self.ledger.record(
                response.findings.isEmpty
                    ? GuardrailOutcome<String>.accepted(response.text)
                    : (response.source == .curated
                        ? GuardrailOutcome<String>.rejected(response.findings)
                        : GuardrailOutcome<String>.repaired(response.text, response.findings))
            )
        }
    }

    func ask(_ question: String) {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isCoachBusy, let lesson else { return }

        coachMessages.append(CoachMessage(text: trimmed, isFromLearner: true, source: nil))
        isCoachBusy = true
        let exercise = current
        let facts = facts

        Task { [coach] in
            let response = await coach.reply(
                to: trimmed,
                exercise: exercise,
                lesson: lesson,
                facts: facts
            )
            self.coachMessages.append(
                CoachMessage(text: response.text, isFromLearner: false, source: response.source)
            )
            self.isCoachBusy = false
            if !response.findings.isEmpty {
                self.ledger.record(GuardrailOutcome<String>.repaired(response.text, response.findings))
            } else {
                self.ledger.record(GuardrailOutcome<String>.accepted(response.text))
            }
        }
    }

    /// Replaces the curated explanation in place once the coach has one that
    /// passed review. The learner is reading by then, so it must not reflow
    /// anything above it.
    private func upgradeExplanation(for exercise: Exercise, judgement: Judgement) {
        guard settings.coachEnabled else { return }
        let facts = facts
        let answered = judgement.isCorrect
            ? exercise.content.answerStrings.first
            : typedAnswerDescription(for: exercise)

        Task { [coach] in
            let response = await coach.explanation(
                for: exercise,
                learnerAnswer: answered,
                wasCorrect: judgement.isCorrect,
                facts: facts
            )
            guard case .feedback(var feedback) = self.phase,
                  response.source != .curated,
                  self.current?.id == exercise.id
            else { return }
            feedback.explanation = response.text
            feedback.explanationSource = response.source
            self.phase = .feedback(feedback)
        }
    }

    private func typedAnswerDescription(for exercise: Exercise) -> String? {
        switch exercise.content {
        case .multipleChoice(let options, _):
            guard let selectedOption, options.indices.contains(selectedOption) else { return nil }
            return options[selectedOption]
        case .trueFalse:
            return booleanAnswer.map { $0 ? "true" : "false" }
        case .numeric, .shortText:
            return typedAnswer.isEmpty ? nil : typedAnswer
        case .ordering:
            return orderedSteps.isEmpty ? nil : orderedSteps.joined(separator: " → ")
        case .matching:
            return matchedPairs.isEmpty ? nil : matchedPairs.map { "\($0.left) → \($0.right)" }.joined(separator: ", ")
        }
    }

    // MARK: - Generated practice

    /// Fetch one bonus question in the background, once, around the middle of
    /// the session, and slot it in before the final item.
    private func scheduleBonusItemIfDue() {
        guard settings.generatedPracticeEnabled,
              generator.isAvailable,
              generatedServed < PracticeGenerator.maxPerSession,
              bonusTask == nil,
              index == 1,
              let lesson
        else { return }

        let existing = items.map(\.prompt)
        bonusTask = Task { [generator] in
            let result = await generator.bonusItem(for: lesson, existingPrompts: existing)
            self.ledger.record(
                result.exercise.map { GuardrailOutcome<Exercise>.accepted($0) }
                    ?? GuardrailOutcome<Exercise>.rejected(result.findings)
            )
            if result.blockedBySafetySystem {
                self.ledger.recordSystemGuardrailBlock()
            }
            guard let exercise = result.exercise, !Task.isCancelled else { return }
            let insertion = max(self.items.count - 1, self.index + 1)
            self.items.insert(exercise, at: min(insertion, self.items.count))
            self.generatedServed += 1
        }
    }

    // MARK: - Helpers

    private func requeueIfNeeded(_ exercise: Exercise) {
        guard !requeued.contains(exercise.id) else { return }
        requeued.insert(exercise.id)
        items.append(exercise)
    }

    private func seed(for exercise: Exercise) -> UInt64 {
        var generator = SeededGenerator(seed: "\(exercise.id)-\(index)-\(correctCount)")
        return generator.next()
    }
}
