//
//  UnitTests.swift
//  Quark
//
//  A small runner rather than XCTest, so the whole engine can be compiled and
//  exercised with one swiftc invocation on any platform — including Linux CI,
//  where SwiftUI and FoundationModels do not exist but every rule in this app
//  still does.
//
//  Run with .tooling/run_unit_tests.sh
//

import Foundation

enum UnitTests {
    struct Failure: Error, CustomStringConvertible {
        let message: String
        var description: String { message }
    }

    static func runAll() async -> Int {
        var failed = 0

        section("Arithmetic evaluator")
        failed += run("evaluates the four operations", testEvaluatorBasics)
        failed += run("respects precedence and parentheses", testEvaluatorPrecedence)
        failed += run("treats exponentiation as right-associative", testEvaluatorPower)
        failed += run("handles unary signs, percent, and sqrt", testEvaluatorUnaryAndFunctions)
        failed += run("returns nil rather than guessing", testEvaluatorRejects)

        section("Answer checking")
        failed += run("accepts decimals, fractions, and percentages", testNumericForms)
        failed += run("accepts scientific notation and mixed numbers", testNumericExoticForms)
        failed += run("applies tolerance and names a sign slip", testNumericTolerance)
        failed += run("forgives a single typo in a typed answer", testTypoTolerance)
        failed += run("normalises articles, case, and punctuation", testNormalisation)
        failed += run("gives partial credit for ordering", testOrderingCredit)
        failed += run("gives partial credit for matching", testMatchingCredit)
        failed += run("rejects a mismatched answer kind", testMismatchedAnswer)

        section("Spaced repetition")
        failed += run("a fresh lesson is due immediately", testFreshRecall)
        failed += run("recall decays with elapsed time", testRecallDecay)
        failed += run("correct answers lengthen the half-life", testHalfLifeGrowth)
        failed += run("misses shorten the half-life", testHalfLifeShrink)
        failed += run("due lessons come back weakest first", testDueOrdering)

        section("Progress and rewards")
        failed += run("combo bonus is capped", testComboCap)
        failed += run("level thresholds rise monotonically", testLevelCurve)
        failed += run("a correct answer awards XP once", testApplyingJudgement)
        failed += run("perfect and first-clear bonuses stack", testSessionBonuses)
        failed += run("a lesson is not cleared below 60%", testClearThreshold)
        failed += run("consecutive days extend the streak", testStreakExtends)
        failed += run("a gap resets the streak to one", testStreakResets)
        failed += run("practising twice in a day changes nothing", testStreakSameDay)
        failed += run("a lapsed streak reads as zero", testLiveStreak)

        section("Mastery and unlocking")
        failed += run("mastery climbs from ready to mastered", testMasteryProgression)
        failed += run("lessons unlock in order within a unit", testUnlocking)

        section("Session building")
        failed += run("sessions are clamped in length", testSessionLength)
        failed += run("sessions open with a warm-up", testSessionRamp)
        failed += run("question kinds are interleaved", testInterleaving)
        failed += run("the same seed builds the same session", testSessionDeterminism)
        failed += run("review is nil until something is due", testReviewEmpty)
        failed += run("review pulls from the weakest lessons", testReviewSession)

        section("Curriculum integrity")
        failed += run("lesson and exercise ids are unique", testUniqueIDs)
        failed += run("every exercise points at its own lesson", testLessonBackReferences)
        failed += run("every numeric answer is reproduced by its own arithmetic", testNumericSelfCheck)
        failed += run("multiple-choice items are well formed", testChoiceShape)
        failed += run("ordering and matching items have enough parts", testOrderingShape)
        failed += run("no curated hint gives away its answer", testCuratedHintsDoNotLeak)
        failed += run("every lesson has facts and enough exercises", testLessonCompleteness)

        section("Guardrails: generated items")
        failed += run("a good draft is accepted", testDraftAccepted)
        failed += run("the wrong number of options is rejected", testDraftSchema)
        failed += run("duplicate options are rejected", testDraftDuplicateOptions)
        failed += run("'all of the above' is rejected", testDraftAllOfTheAbove)
        failed += run("a question containing its own answer is rejected", testDraftSelfAnswering)
        failed += run("arithmetic that does not check out is rejected", testDraftBadArithmetic)
        failed += run("a numeric draft without arithmetic is rejected", testDraftMissingCheck)
        failed += run("correct arithmetic is accepted", testDraftGoodArithmetic)
        failed += run("off-syllabus drafts are rejected", testDraftOffTopic)
        failed += run("unsafe drafts are rejected", testDraftUnsafe)
        failed += run("a near-duplicate draft is rejected", testDraftDuplicatePrompt)
        failed += run("an overlong question is rejected", testDraftTooLong)
        failed += run("a leaking hint is repaired, not shown", testDraftHintRepaired)

        section("Guardrails: coach text")
        failed += run("a clean hint passes untouched", testHintAccepted)
        failed += run("a hint that states the answer is stopped", testHintLeakBlocked)
        failed += run("'not false' counts as leaking a true/false answer", testHintNegationLeak)
        failed += run("invented numbers are filtered out", testUngroundedNumbers)
        failed += run("links and emails are scrubbed", testContactScrubbing)
        failed += run("long replies are trimmed", testReplyTrimming)
        failed += run("an unsafe learner message is declined", testLearnerMessageDeclined)
        failed += run("an on-topic learner message is allowed", testLearnerMessageAllowed)
        failed += run("'one' inside another word is not a leak", testNoSubstringFalsePositive)

        section("Coach service")
        failed += await runAsync("a leaking hint falls back to the curated one", testCoachHintFallback)
        failed += await runAsync("a clean hint is passed through", testCoachHintPassthrough)
        failed += await runAsync("no model means curated coaching", testCoachWithoutModel)
        failed += await runAsync("Apple Intelligence refusals are handled", testCoachSafetyRefusal)
        failed += await runAsync("the generator retries once, then gives up", testGeneratorRetry)
        failed += await runAsync("the generator surfaces a system-guardrail block", testGeneratorBlocked)

        print("")
        if failed == 0 {
            print("All unit tests passed.")
        } else {
            print("\(failed) unit test(s) failed.")
        }
        return failed
    }

    // MARK: - Runner

    private static func section(_ name: String) {
        print("\n\(name)")
    }

    private static func run(_ name: String, _ body: () throws -> Void) -> Int {
        do {
            try body()
            print("  ✓ \(name)")
            return 0
        } catch {
            print("  ✗ \(name): \(error)")
            return 1
        }
    }

    private static func runAsync(_ name: String, _ body: () async throws -> Void) async -> Int {
        do {
            try await body()
            print("  ✓ \(name)")
            return 0
        } catch {
            print("  ✗ \(name): \(error)")
            return 1
        }
    }

    private static func expect(_ condition: Bool, _ message: String) throws {
        if !condition { throw Failure(message: message) }
    }

    private static func expectEqual<T: Equatable>(_ lhs: T, _ rhs: T, _ message: String) throws {
        if lhs != rhs { throw Failure(message: "\(message) (got \(lhs), expected \(rhs))") }
    }

    private static func expectClose(_ lhs: Double, _ rhs: Double, _ tolerance: Double, _ message: String) throws {
        if abs(lhs - rhs) > tolerance {
            throw Failure(message: "\(message) (got \(lhs), expected \(rhs))")
        }
    }

    // MARK: - Fixtures

    private static let lesson = MathCourse.fractions
    private static let choiceExercise = MathCourse.fractions.exercises[0]
    private static let numericExercise = MathCourse.percentages.exercises[0]
    private static let trueFalseExercise = MathCourse.fractions.exercises[1]

    private static func profileWithHistory(
        lessonID: String,
        correct: Int,
        incorrect: Int = 0,
        practiced: Date
    ) -> LearnerProfile {
        var profile = LearnerProfile()
        profile.skills[lessonID] = SkillRecord(
            correct: correct,
            incorrect: incorrect,
            consecutiveCorrect: correct,
            halfLifeDays: SpacedRepetition.fitHalfLife(
                correct: correct,
                incorrect: incorrect,
                consecutiveCorrect: correct
            ),
            lastPracticed: practiced,
            completed: correct > 0
        )
        return profile
    }

    // MARK: - Arithmetic evaluator

    private static func testEvaluatorBasics() throws {
        try expectEqual(MathEvaluator.evaluate("2 + 3"), 5, "addition")
        try expectEqual(MathEvaluator.evaluate("9 - 4"), 5, "subtraction")
        try expectEqual(MathEvaluator.evaluate("6 * 7"), 42, "multiplication")
        try expectEqual(MathEvaluator.evaluate("40 / 8"), 5, "division")
        try expectEqual(MathEvaluator.evaluate("12 × 2 ÷ 4"), 6, "unicode operators")
    }

    private static func testEvaluatorPrecedence() throws {
        try expectEqual(MathEvaluator.evaluate("2 + 3 * 4"), 14, "times before plus")
        try expectEqual(MathEvaluator.evaluate("(2 + 3) * 4"), 20, "parentheses first")
        try expectEqual(MathEvaluator.evaluate("100 - 20 - 30"), 50, "left-associative minus")
        try expectEqual(MathEvaluator.evaluate("(22 - 7) / 3"), 5, "curriculum-style expression")
    }

    private static func testEvaluatorPower() throws {
        try expectEqual(MathEvaluator.evaluate("2^8"), 256, "power")
        try expectEqual(MathEvaluator.evaluate("2^3^2"), 512, "right-associative power")
        try expectEqual(MathEvaluator.evaluate("2^3 - 1"), 7, "power before minus")
        try expectEqual(MathEvaluator.evaluate("3 * 10^9 / (3 * 10^8)"), 10, "scientific-style ratio")
    }

    private static func testEvaluatorUnaryAndFunctions() throws {
        try expectEqual(MathEvaluator.evaluate("-2 * 3 + 5"), -1, "unary minus")
        try expectEqual(MathEvaluator.evaluate("50%"), 0.5, "percent")
        try expectEqual(MathEvaluator.evaluate("sqrt(81)"), 9, "sqrt")
        try expectEqual(MathEvaluator.evaluate("abs(0 - 7)"), 7, "abs")
        try expect(MathEvaluator.confirms("40 * 0.75", equals: 30), "confirms helper")
    }

    private static func testEvaluatorRejects() throws {
        try expect(MathEvaluator.evaluate("1 / 0") == nil, "division by zero")
        try expect(MathEvaluator.evaluate("2 +") == nil, "trailing operator")
        try expect(MathEvaluator.evaluate("(2 + 3") == nil, "unbalanced parenthesis")
        try expect(MathEvaluator.evaluate("velocity times mass") == nil, "prose")
        try expect(MathEvaluator.evaluate("") == nil, "empty string")
        try expect(!MathEvaluator.confirms("2 + 2", equals: 5), "false arithmetic is not confirmed")
    }

    // MARK: - Answer checking

    private static func testNumericForms() throws {
        let content = Exercise.Content.numeric(answer: 0.875, tolerance: 0.001, unit: nil, check: nil)
        for form in ["0.875", "7/8", "3/4 + 1/8", "87.5%"] {
            let judgement = AnswerChecker.check(.text(form), against: content)
            try expect(judgement.isCorrect, "\(form) should be accepted")
        }
    }

    private static func testNumericExoticForms() throws {
        try expectClose(AnswerChecker.parseNumber("1.2e3") ?? 0, 1200, 0.001, "scientific notation")
        try expectClose(AnswerChecker.parseNumber("3 1/2") ?? 0, 3.5, 0.001, "mixed number")
        try expectClose(AnswerChecker.parseNumber("1,024") ?? 0, 1024, 0.001, "thousands separator")
        try expect(AnswerChecker.parseNumber("about nine") == nil, "prose is not a number")
    }

    private static func testNumericTolerance() throws {
        let content = Exercise.Content.numeric(answer: 29.4, tolerance: 0.2, unit: "J", check: nil)
        try expect(AnswerChecker.check(.text("29.4 J"), against: content).isCorrect, "unit suffix accepted")
        try expect(AnswerChecker.check(.text("29.5"), against: content).isCorrect, "inside tolerance")
        try expect(!AnswerChecker.check(.text("31"), against: content).isCorrect, "outside tolerance")

        let signSlip = AnswerChecker.checkNumeric("1", expected: -1, tolerance: 0, unit: nil)
        try expect(signSlip.note?.contains("sign") == true, "sign slip is named")
    }

    private static func testTypoTolerance() throws {
        let content = Exercise.Content.shortText(accepted: ["denominator"])
        try expect(AnswerChecker.check(.text("denominater"), against: content).isCorrect, "one-letter typo")
        try expect(!AnswerChecker.check(.text("numerator"), against: content).isCorrect, "different word")

        let short = Exercise.Content.shortText(accepted: ["Na"])
        try expect(AnswerChecker.check(.text("na"), against: short).isCorrect, "case-insensitive symbol")
        try expect(!AnswerChecker.check(.text("K"), against: short).isCorrect, "short answers get no typo budget")
    }

    private static func testNormalisation() throws {
        try expectEqual(AnswerChecker.normalize("The Denominator!"), "denominator", "article and punctuation")
        try expectEqual(AnswerChecker.normalize("  carbon   DIOXIDE "), "carbon dioxide", "whitespace and case")
        try expectEqual(AnswerChecker.normalize("café"), "cafe", "diacritics")
    }

    private static func testOrderingCredit() throws {
        let content = Exercise.Content.ordering(steps: ["a", "b", "c", "d"])
        let perfect = AnswerChecker.check(.sequence(["a", "b", "c", "d"]), against: content)
        try expect(perfect.isCorrect, "exact order")

        let swapped = AnswerChecker.check(.sequence(["a", "b", "d", "c"]), against: content)
        try expect(!swapped.isCorrect, "swapped pair is wrong")
        try expectClose(swapped.credit, 0.5, 0.001, "half credit for two in place")
        try expect(swapped.note != nil, "partial credit is explained")
    }

    private static func testMatchingCredit() throws {
        let pairs = [MatchPair(left: "Array", right: "Index"), MatchPair(left: "Stack", right: "LIFO")]
        let content = Exercise.Content.matching(pairs: pairs)
        try expect(AnswerChecker.check(.pairs(pairs), against: content).isCorrect, "all pairs matched")

        let half = AnswerChecker.check(
            .pairs([MatchPair(left: "Array", right: "Index"), MatchPair(left: "Stack", right: "Index")]),
            against: content
        )
        try expect(!half.isCorrect, "one wrong pair fails")
        try expectClose(half.credit, 0.5, 0.001, "half credit")
    }

    private static func testMismatchedAnswer() throws {
        let content = Exercise.Content.trueFalse(answer: true)
        try expectEqual(AnswerChecker.check(.sequence(["a"]), against: content), .missing, "kind mismatch")
        try expectEqual(AnswerChecker.check(.skipped, against: content), .missing, "skipped")
    }

    // MARK: - Spaced repetition

    private static func testFreshRecall() throws {
        let record = SkillRecord()
        try expectEqual(SpacedRepetition.recallProbability(record), 0, "never practised")
        try expect(!SpacedRepetition.isDue(record), "an unattempted lesson is new, not due for review")
    }

    private static func testRecallDecay() throws {
        let now = Date()
        var record = SkillRecord()
        record.lastPracticed = now
        record.halfLifeDays = 2

        let immediate = SpacedRepetition.recallProbability(record, now: now)
        let afterTwoDays = SpacedRepetition.recallProbability(record, now: now.addingTimeInterval(2 * 86_400))
        let afterFourDays = SpacedRepetition.recallProbability(record, now: now.addingTimeInterval(4 * 86_400))

        try expectClose(immediate, 1, 0.001, "no decay at zero elapsed")
        try expectClose(afterTwoDays, 0.5, 0.001, "one half-life halves recall")
        try expectClose(afterFourDays, 0.25, 0.001, "two half-lives quarter it")
    }

    private static func testHalfLifeGrowth() throws {
        var record = SkillRecord()
        var previous = record.halfLifeDays
        for _ in 0..<5 {
            record = SpacedRepetition.updated(record, correct: true)
            try expect(record.halfLifeDays > previous, "half-life grows with each success")
            previous = record.halfLifeDays
        }
        try expectEqual(record.correct, 5, "correct count")
        try expectEqual(record.consecutiveCorrect, 5, "streak count")
    }

    private static func testHalfLifeShrink() throws {
        var record = SkillRecord()
        for _ in 0..<4 { record = SpacedRepetition.updated(record, correct: true) }
        let strong = record.halfLifeDays
        record = SpacedRepetition.updated(record, correct: false)
        try expect(record.halfLifeDays < strong, "a miss shortens the half-life")
        try expectEqual(record.consecutiveCorrect, 0, "streak resets")
    }

    private static func testDueOrdering() throws {
        let now = Date()
        var profile = LearnerProfile()
        profile.skills["weak"] = SkillRecord(
            correct: 1, incorrect: 3, consecutiveCorrect: 0,
            halfLifeDays: 0.2, lastPracticed: now.addingTimeInterval(-3 * 86_400)
        )
        profile.skills["ok"] = SkillRecord(
            correct: 4, incorrect: 0, consecutiveCorrect: 4,
            halfLifeDays: 4, lastPracticed: now.addingTimeInterval(-3 * 86_400)
        )
        profile.skills["fresh"] = SkillRecord(
            correct: 3, incorrect: 0, consecutiveCorrect: 3,
            halfLifeDays: 5, lastPracticed: now
        )

        let due = SpacedRepetition.dueLessons(in: profile, among: ["fresh", "ok", "weak"], now: now)
        try expect(due.first == "weak", "weakest first, got \(due)")
        try expect(!due.contains("fresh"), "a lesson practised just now is not due")
    }

    // MARK: - Progress

    private static func testComboCap() throws {
        try expectEqual(ProgressEngine.xpForCorrect(combo: 1), 10, "no bonus on the first")
        try expectEqual(ProgressEngine.xpForCorrect(combo: 3), 14, "combo of three")
        try expectEqual(ProgressEngine.xpForCorrect(combo: 50), 20, "bonus is capped")
    }

    private static func testLevelCurve() throws {
        try expectEqual(ProgressEngine.level(forXP: 0), 1, "start at level one")
        try expectEqual(ProgressEngine.level(forXP: 99), 1, "just short of level two")
        try expectEqual(ProgressEngine.level(forXP: 100), 2, "level two")
        var previous = -1
        for level in 1...12 {
            let threshold = ProgressEngine.xpThreshold(forLevel: level)
            try expect(threshold > previous, "thresholds increase")
            previous = threshold
        }
        let progress = ProgressEngine.levelProgress(forXP: 150)
        try expect(progress > 0 && progress < 1, "mid-level progress is fractional")
    }

    private static func testApplyingJudgement() throws {
        let profile = LearnerProfile()
        let correct = Judgement(isCorrect: true, credit: 1, note: nil)
        let (afterCorrect, xp) = ProgressEngine.applying(
            judgement: correct, lessonID: "math.fractions", combo: 1, to: profile
        )
        try expectEqual(xp, 10, "XP awarded")
        try expectEqual(afterCorrect.totalXP, 10, "total XP")
        try expectEqual(afterCorrect.xpToday, 10, "today's XP")
        try expectEqual(afterCorrect.itemsCorrect, 1, "correct tally")
        try expectEqual(afterCorrect.record(for: "math.fractions").correct, 1, "skill record")

        let (afterWrong, noXP) = ProgressEngine.applying(
            judgement: .missing, lessonID: "math.fractions", combo: 4, to: afterCorrect
        )
        try expectEqual(noXP, 0, "no XP for a miss")
        try expectEqual(afterWrong.itemsAnswered, 2, "answered tally")
        try expectEqual(afterWrong.totalXP, 10, "XP unchanged")
    }

    private static func testSessionBonuses() throws {
        let profile = LearnerProfile()
        let (updated, bonus) = ProgressEngine.completing(
            lessonID: "math.fractions", correct: 8, total: 8, isReview: false, to: profile
        )
        try expectEqual(
            bonus,
            ProgressEngine.firstClearBonus + ProgressEngine.perfectSessionBonus,
            "first clear plus perfect"
        )
        try expect(updated.isCompleted("math.fractions"), "lesson marked complete")
        try expectEqual(updated.sessionsCompleted, 1, "session counted")

        let (again, secondBonus) = ProgressEngine.completing(
            lessonID: "math.fractions", correct: 8, total: 8, isReview: false, to: updated
        )
        try expectEqual(secondBonus, ProgressEngine.perfectSessionBonus, "first-clear bonus is once only")
        try expectEqual(again.sessionsCompleted, 2, "second session counted")
    }

    private static func testClearThreshold() throws {
        let (updated, bonus) = ProgressEngine.completing(
            lessonID: "math.slope", correct: 4, total: 8, isReview: false, to: LearnerProfile()
        )
        try expectEqual(bonus, 0, "half marks earns no bonus")
        try expect(!updated.isCompleted("math.slope"), "lesson not cleared at 50%")
    }

    private static func testStreakExtends() throws {
        var profile = LearnerProfile()
        profile = ProgressEngine.registering(day: LearningDay(value: "2026-03-01"), in: profile)
        try expectEqual(profile.streakDays, 1, "first day")
        profile = ProgressEngine.registering(day: LearningDay(value: "2026-03-02"), in: profile)
        try expectEqual(profile.streakDays, 2, "second consecutive day")
        profile = ProgressEngine.registering(day: LearningDay(value: "2026-03-03"), in: profile)
        try expectEqual(profile.streakDays, 3, "third consecutive day")
        try expectEqual(profile.bestStreakDays, 3, "best streak tracked")
        try expectEqual(profile.activeDays.count, 3, "active days recorded")
    }

    private static func testStreakResets() throws {
        var profile = LearnerProfile()
        profile = ProgressEngine.registering(day: LearningDay(value: "2026-03-01"), in: profile)
        profile = ProgressEngine.registering(day: LearningDay(value: "2026-03-02"), in: profile)
        profile = ProgressEngine.registering(day: LearningDay(value: "2026-03-06"), in: profile)
        try expectEqual(profile.streakDays, 1, "gap resets to one")
        try expectEqual(profile.bestStreakDays, 2, "best streak is remembered")
    }

    private static func testStreakSameDay() throws {
        var profile = LearnerProfile()
        profile = ProgressEngine.registering(day: LearningDay(value: "2026-03-01"), in: profile)
        profile.xpToday = 40
        let unchanged = ProgressEngine.registering(day: LearningDay(value: "2026-03-01"), in: profile)
        try expectEqual(unchanged.xpToday, 40, "today's XP survives a second session")
        try expectEqual(unchanged.streakDays, 1, "streak unchanged")
        try expectEqual(unchanged.activeDays.count, 1, "day recorded once")
    }

    private static func testLiveStreak() throws {
        var profile = LearnerProfile()
        profile = ProgressEngine.registering(day: LearningDay(value: "2026-03-01"), in: profile)
        profile = ProgressEngine.registering(day: LearningDay(value: "2026-03-02"), in: profile)

        try expectEqual(
            ProgressEngine.liveStreak(in: profile, today: LearningDay(value: "2026-03-02")),
            2,
            "streak on the day itself"
        )
        try expectEqual(
            ProgressEngine.liveStreak(in: profile, today: LearningDay(value: "2026-03-03")),
            2,
            "streak still alive the next day"
        )
        try expectEqual(
            ProgressEngine.liveStreak(in: profile, today: LearningDay(value: "2026-03-05")),
            0,
            "streak has lapsed"
        )
        try expectEqual(
            ProgressEngine.xpToday(in: profile, today: LearningDay(value: "2026-03-05")),
            0,
            "yesterday's XP does not count today"
        )
    }

    // MARK: - Mastery

    private static func testMasteryProgression() throws {
        let now = Date()
        let empty = LearnerProfile()
        try expectEqual(
            MasteryModel.level(for: "math.fractions", in: empty, unlocked: false, now: now),
            .locked,
            "locked without unlock"
        )
        try expectEqual(
            MasteryModel.level(for: "math.fractions", in: empty, unlocked: true, now: now),
            .ready,
            "ready once unlocked"
        )

        let learning = profileWithHistory(lessonID: "math.fractions", correct: 1, practiced: now)
        try expectEqual(
            MasteryModel.level(for: "math.fractions", in: learning, unlocked: true, now: now),
            .learning,
            "one attempt is still learning"
        )

        let mastered = profileWithHistory(lessonID: "math.fractions", correct: 8, practiced: now)
        try expectEqual(
            MasteryModel.level(for: "math.fractions", in: mastered, unlocked: true, now: now),
            .mastered,
            "eight clean attempts is mastery"
        )

        let lapsed = profileWithHistory(
            lessonID: "math.fractions",
            correct: 8,
            practiced: now.addingTimeInterval(-200 * 86_400)
        )
        try expect(
            MasteryModel.level(for: "math.fractions", in: lapsed, unlocked: true, now: now) != .mastered,
            "mastery decays when it is never revisited"
        )
        try expect(
            MasteryModel.progress(for: "math.fractions", in: mastered, now: now) > 0.9,
            "progress ring is nearly full at mastery"
        )
    }

    private static func testUnlocking() throws {
        let course = MathCourse.course
        let fresh = MasteryModel.unlockedLessonIDs(for: course, in: LearnerProfile())
        try expect(fresh.contains("math.fractions"), "first lesson of a unit is open")
        try expect(!fresh.contains("math.percentages"), "second lesson is gated")
        try expect(fresh.contains("math.solving"), "each unit opens independently")

        var profile = LearnerProfile()
        var record = SkillRecord()
        record.completed = true
        profile.skills["math.fractions"] = record
        let after = MasteryModel.unlockedLessonIDs(for: course, in: profile)
        try expect(after.contains("math.percentages"), "clearing a lesson opens the next")
    }

    // MARK: - Sessions

    private static func testSessionLength() throws {
        let short = SessionBuilder.lessonSession(for: lesson, profile: LearnerProfile(), length: 2)
        try expect(short.items.count >= min(SessionBuilder.minLength, lesson.exercises.count), "clamped up")

        let long = SessionBuilder.lessonSession(for: lesson, profile: LearnerProfile(), length: 99)
        try expect(long.items.count <= lesson.exercises.count, "cannot exceed the lesson")

        let exact = SessionBuilder.lessonSession(for: lesson, profile: LearnerProfile(), length: 4)
        try expectEqual(exact.items.count, 4, "asked for four, got four")
        try expectEqual(Set(exact.items.map(\.id)).count, exact.items.count, "no repeats in a session")
    }

    private static func testSessionRamp() throws {
        var generator = SeededGenerator(seed: 7)
        let ramped = SessionBuilder.ramped(lesson.exercises, length: 5, using: &generator)
        try expect(ramped.first?.difficulty == .gentle, "opens on a warm-up")

        let plan = SessionBuilder.lessonSession(for: MathCourse.percentages, profile: LearnerProfile(), length: 5)
        try expect(plan.items.first?.difficulty != .stretch, "does not open on the hardest item")
        try expectEqual(plan.facts.count, MathCourse.percentages.facts.count, "grounding facts travel with the plan")
    }

    private static func testInterleaving() throws {
        let items = [
            Exercise.truth("a", lesson: "l", "one", answer: true, why: "w", hint: "h"),
            Exercise.truth("b", lesson: "l", "two", answer: true, why: "w", hint: "h"),
            Exercise.choice("c", lesson: "l", "three", options: ["1", "2"], correct: 0, why: "w", hint: "h"),
            Exercise.choice("d", lesson: "l", "four", options: ["1", "2"], correct: 0, why: "w", hint: "h")
        ]
        let mixed = SessionBuilder.interleaved(items)
        try expectEqual(mixed.count, items.count, "nothing is lost")
        var adjacentRepeats = 0
        for index in 1..<mixed.count where mixed[index].kind == mixed[index - 1].kind {
            adjacentRepeats += 1
        }
        try expectEqual(adjacentRepeats, 0, "no two neighbours share a kind")
    }

    private static func testSessionDeterminism() throws {
        let first = SessionBuilder.lessonSession(for: lesson, profile: LearnerProfile(), length: 5, seed: "fixed")
        let second = SessionBuilder.lessonSession(for: lesson, profile: LearnerProfile(), length: 5, seed: "fixed")
        try expectEqual(first.items.map(\.id), second.items.map(\.id), "same seed, same session")

        let other = SessionBuilder.lessonSession(for: lesson, profile: LearnerProfile(), length: 5, seed: "different")
        try expect(
            other.items.count == first.items.count,
            "a different seed still builds a full session"
        )
    }

    private static func testReviewEmpty() throws {
        let plan = SessionBuilder.reviewSession(lessons: Curriculum.allLessons, profile: LearnerProfile())
        try expect(plan == nil, "nothing to review on a fresh profile")
    }

    private static func testReviewSession() throws {
        let now = Date()
        var profile = LearnerProfile()
        profile.skills["math.fractions"] = SkillRecord(
            correct: 1, incorrect: 2, consecutiveCorrect: 0,
            halfLifeDays: 0.3, lastPracticed: now.addingTimeInterval(-5 * 86_400), completed: true
        )
        profile.skills["physics.forces"] = SkillRecord(
            correct: 2, incorrect: 1, consecutiveCorrect: 1,
            halfLifeDays: 0.8, lastPracticed: now.addingTimeInterval(-6 * 86_400), completed: true
        )

        guard let plan = SessionBuilder.reviewSession(
            lessons: Curriculum.allLessons,
            profile: profile,
            length: 6,
            now: now
        ) else {
            throw Failure(message: "expected a review session")
        }
        try expectEqual(plan.mode, .review, "review mode")
        try expect(plan.items.count >= 2, "pulled items from the weak lessons")
        try expect(
            plan.items.allSatisfy { ["math.fractions", "physics.forces"].contains($0.lessonID) },
            "only weak lessons are reviewed"
        )
        try expectEqual(Set(plan.items.map(\.id)).count, plan.items.count, "no repeated items")
        try expect(!plan.facts.isEmpty, "review carries grounding facts")
    }

    // MARK: - Curriculum integrity

    private static func testUniqueIDs() throws {
        let lessonIDs = Curriculum.allLessons.map(\.id)
        try expectEqual(Set(lessonIDs).count, lessonIDs.count, "duplicate lesson id")

        let exerciseIDs = Curriculum.allExercises.map(\.id)
        try expectEqual(Set(exerciseIDs).count, exerciseIDs.count, "duplicate exercise id")

        let unitIDs = Curriculum.courses.flatMap { $0.units.map(\.id) }
        try expectEqual(Set(unitIDs).count, unitIDs.count, "duplicate unit id")
        try expectEqual(Curriculum.courses.count, TrackID.allCases.count, "every track has a course")
    }

    private static func testLessonBackReferences() throws {
        for lesson in Curriculum.allLessons {
            for exercise in lesson.exercises {
                try expectEqual(exercise.lessonID, lesson.id, "\(exercise.id) points at the wrong lesson")
            }
            try expect(Curriculum.lesson(id: lesson.id) != nil, "\(lesson.id) is not indexed")
            try expect(Curriculum.track(containing: lesson.id) != nil, "\(lesson.id) has no track")
            try expect(Curriculum.unit(containing: lesson.id) != nil, "\(lesson.id) has no unit")
        }
    }

    private static func testNumericSelfCheck() throws {
        var checked = 0
        for exercise in Curriculum.allExercises {
            guard case .numeric(let answer, let tolerance, _, let check) = exercise.content else { continue }
            guard let check else {
                throw Failure(message: "\(exercise.id) has no check expression")
            }
            guard let computed = MathEvaluator.evaluate(check) else {
                throw Failure(message: "\(exercise.id): cannot evaluate '\(check)'")
            }
            let allowed = max(tolerance, 1e-6)
            guard abs(computed - answer) <= allowed else {
                throw Failure(
                    message: "\(exercise.id): '\(check)' = \(computed), stated answer \(answer)"
                )
            }
            checked += 1
        }
        try expect(checked >= 25, "expected a substantial numeric curriculum, checked \(checked)")
    }

    private static func testChoiceShape() throws {
        for exercise in Curriculum.allExercises {
            switch exercise.content {
            case .multipleChoice(let options, let index):
                try expect(options.count >= 3, "\(exercise.id) needs at least three options")
                try expect(options.indices.contains(index), "\(exercise.id) correct index out of range")
                let normalized = options.map { AnswerChecker.normalize($0) }
                try expectEqual(Set(normalized).count, normalized.count, "\(exercise.id) has duplicate options")
                try expect(!options.contains { $0.isEmpty }, "\(exercise.id) has a blank option")
            case .shortText(let accepted):
                try expect(!accepted.isEmpty, "\(exercise.id) accepts nothing")
            default:
                break
            }
            try expect(exercise.explanation.count > 12, "\(exercise.id) needs a real explanation")
            try expect(exercise.hint.count > 8, "\(exercise.id) needs a real hint")
            try expect(exercise.prompt.count > 8, "\(exercise.id) needs a real prompt")
        }
    }

    private static func testOrderingShape() throws {
        for exercise in Curriculum.allExercises {
            switch exercise.content {
            case .ordering(let steps):
                try expect(steps.count >= 3, "\(exercise.id) needs at least three steps")
                try expectEqual(Set(steps).count, steps.count, "\(exercise.id) has duplicate steps")
            case .matching(let pairs):
                try expect(pairs.count >= 3, "\(exercise.id) needs at least three pairs")
                try expectEqual(Set(pairs.map(\.left)).count, pairs.count, "\(exercise.id) has duplicate keys")
                try expectEqual(Set(pairs.map(\.right)).count, pairs.count, "\(exercise.id) has duplicate values")
            default:
                break
            }
        }
    }

    private static func testCuratedHintsDoNotLeak() throws {
        for exercise in Curriculum.allExercises {
            let findings = AnswerLeakDetector.findings(in: exercise.hint, exercise: exercise)
            try expect(
                findings.isEmpty,
                "\(exercise.id) hint leaks its answer: \(findings.map(\.detail).joined(separator: "; "))"
            )
        }
    }

    private static func testLessonCompleteness() throws {
        for lesson in Curriculum.allLessons {
            try expect(lesson.facts.count >= 3, "\(lesson.id) needs at least three grounding facts")
            try expect(lesson.exercises.count >= 4, "\(lesson.id) needs at least four exercises")
            try expect(!lesson.goal.isEmpty, "\(lesson.id) needs a goal")
            try expect(lesson.groundingBlock.contains(lesson.goal), "\(lesson.id) grounding omits its goal")

            let kinds = Set(lesson.exercises.map(\.kind))
            try expect(kinds.count >= 3, "\(lesson.id) should mix at least three question kinds")
            try expect(
                lesson.exercises.contains { $0.difficulty == .gentle },
                "\(lesson.id) needs a warm-up item"
            )
        }
        try expect(Curriculum.allExercises.count >= 100, "expected a full curriculum")
        try expect(Curriculum.vocabulary.count > 400, "vocabulary looks too small for the topical guardrail")
    }

    // MARK: - Guardrails: items

    private static func reviewDraft(
        _ draft: GeneratedItemDraft,
        lesson target: Lesson = MathCourse.fractions,
        existing: [String] = []
    ) -> GuardrailOutcome<Exercise> {
        ItemGuardrails.review(draft, lesson: target, existingPrompts: existing)
    }

    private static func expectRejection(
        _ outcome: GuardrailOutcome<Exercise>,
        _ guardrail: GuardrailID,
        _ message: String
    ) throws {
        try expect(outcome.wasRejected, "\(message): expected rejection, got acceptance")
        try expect(
            outcome.findings.contains { $0.guardrail == guardrail },
            "\(message): expected \(guardrail.rawValue), got \(outcome.findings.map(\.guardrail.rawValue))"
        )
    }

    private static func testDraftAccepted() throws {
        let outcome = reviewDraft(.sample())
        guard let exercise = outcome.value else {
            throw Failure(message: "clean draft rejected: \(outcome.findings.map(\.detail))")
        }
        try expectEqual(exercise.origin, .generated, "marked as generated")
        try expectEqual(exercise.lessonID, MathCourse.fractions.id, "attributed to the lesson")
        try expectEqual(exercise.kind, .multipleChoice, "generated items are multiple choice")
    }

    private static func testDraftSchema() throws {
        try expectRejection(
            reviewDraft(.sample(options: ["1/8", "2/5", "1/5"])),
            .schema,
            "three options"
        )
        try expectRejection(
            reviewDraft(.sample(correctIndex: 9)),
            .schema,
            "index out of range"
        )
        try expectRejection(
            reviewDraft(.sample(prompt: "?")),
            .schema,
            "empty prompt"
        )
    }

    private static func testDraftDuplicateOptions() throws {
        try expectRejection(
            reviewDraft(.sample(options: ["2/5", "2/5", "1/5", "1/10"])),
            .ambiguity,
            "identical options"
        )
        try expectRejection(
            reviewDraft(.sample(
                prompt: "Which decimal equals one half?",
                options: ["0.5", "1/2", "0.25", "0.75"],
                correctIndex: 0,
                explanation: "A half is 0.5 as a decimal.",
                checkExpression: "1/2"
            )),
            .ambiguity,
            "numerically equal options"
        )
    }

    private static func testDraftAllOfTheAbove() throws {
        try expectRejection(
            reviewDraft(.sample(options: ["1/8", "2/5", "1/5", "All of the above"])),
            .ambiguity,
            "all of the above"
        )
    }

    private static func testDraftSelfAnswering() throws {
        try expectRejection(
            reviewDraft(.sample(
                prompt: "Is 2/5 the fraction closest to one half among these?",
                options: ["1/8", "2/5", "1/5", "1/10"]
            )),
            .ambiguity,
            "prompt contains the answer"
        )
    }

    private static func testDraftBadArithmetic() throws {
        try expectRejection(
            reviewDraft(.sample(
                prompt: "What is 3/4 plus 1/8 as a decimal?",
                options: ["0.75", "0.875", "0.925", "1.125"],
                correctIndex: 2,
                explanation: "Rewrite 3/4 as 6/8 and add one eighth.",
                numericAnswer: 0.925,
                checkExpression: "3/4 + 1/8"
            )),
            .mathCheck,
            "arithmetic disagrees with the marked option"
        )
    }

    private static func testDraftMissingCheck() throws {
        try expectRejection(
            reviewDraft(.sample(
                prompt: "What is 3/4 plus 1/8 as a decimal?",
                options: ["0.75", "0.875", "0.925", "1.125"],
                correctIndex: 1,
                explanation: "Rewrite 3/4 as 6/8 and add one eighth."
            )),
            .mathCheck,
            "numeric item with no arithmetic"
        )
    }

    private static func testDraftGoodArithmetic() throws {
        let outcome = reviewDraft(.sample(
            prompt: "What is 3/4 plus 1/8 as a decimal?",
            options: ["0.75", "0.875", "0.925", "1.125"],
            correctIndex: 1,
            explanation: "Rewrite 3/4 as 6/8, then add one eighth to get 7/8.",
            hint: "Put both fractions over the same denominator first.",
            numericAnswer: 0.875,
            checkExpression: "3/4 + 1/8"
        ))
        try expect(!outcome.wasRejected, "verified arithmetic should pass: \(outcome.findings.map(\.detail))")
    }

    private static func testDraftOffTopic() throws {
        try expectRejection(
            reviewDraft(.sample(
                prompt: "Which footballer has scored the most league goals overall?",
                options: ["Alan Shearer", "Harry Kane", "Wayne Rooney", "Thierry Henry"],
                correctIndex: 0,
                explanation: "Alan Shearer holds the record with 260 goals.",
                hint: "Think about the 1990s."
            )),
            .topical,
            "off-syllabus draft"
        )
    }

    private static func testDraftUnsafe() throws {
        try expectRejection(
            reviewDraft(.sample(
                prompt: "Which fraction of a lethal overdose is 2/5 of a dose?",
                options: ["1/8", "2/5", "1/5", "1/10"],
                correctIndex: 1
            )),
            .safety,
            "unsafe framing"
        )
    }

    private static func testDraftDuplicatePrompt() throws {
        try expectRejection(
            reviewDraft(
                .sample(),
                existing: ["Which fraction is the closest to one half?"]
            ),
            .novelty,
            "near-duplicate prompt"
        )
    }

    private static func testDraftTooLong() throws {
        let sprawling = String(repeating: "Which of these fractions, considered carefully, ", count: 6)
        try expectRejection(
            reviewDraft(.sample(prompt: sprawling + "is closest to a half?")),
            .readability,
            "overlong prompt"
        )
    }

    private static func testDraftHintRepaired() throws {
        let outcome = reviewDraft(.sample(hint: "The answer is 2/5, since it is 0.4."))
        guard case .repaired(let exercise, let findings) = outcome else {
            throw Failure(message: "expected repair, got \(outcome.findings.map(\.detail))")
        }
        try expect(findings.contains { $0.guardrail == .answerLeak }, "leak recorded")
        try expect(
            AnswerLeakDetector.findings(in: exercise.hint, exercise: exercise).isEmpty,
            "repaired hint still leaks: \(exercise.hint)"
        )
    }

    // MARK: - Guardrails: coach text

    private static func testHintAccepted() throws {
        let outcome = CoachGuardrails.reviewHint(
            "Turn each fraction into a decimal and compare the sizes.",
            exercise: choiceExercise,
            facts: lesson.facts
        )
        guard case .accepted(let hint) = outcome else {
            throw Failure(message: "clean hint not accepted: \(outcome.findings.map(\.detail))")
        }
        try expect(hint.contains("decimal"), "hint preserved")
    }

    private static func testHintLeakBlocked() throws {
        let outcome = CoachGuardrails.reviewHint(
            "The answer is 1/2.",
            exercise: choiceExercise,
            facts: lesson.facts
        )
        try expect(outcome.wasRejected, "a hint that is only the answer must be rejected")
        try expect(outcome.findings.contains { $0.guardrail == .answerLeak }, "leak flagged")

        let mixed = CoachGuardrails.reviewHint(
            "Convert each option to a decimal. The answer is 1/2.",
            exercise: choiceExercise,
            facts: lesson.facts
        )
        guard let salvaged = mixed.value else {
            throw Failure(message: "the usable half of the hint should survive")
        }
        try expect(!salvaged.contains("1/2"), "leaking sentence removed, got: \(salvaged)")
    }

    private static func testHintNegationLeak() throws {
        let outcome = CoachGuardrails.reviewHint(
            "This statement is not false, so look at the third decimal place.",
            exercise: trueFalseExercise,
            facts: lesson.facts
        )
        try expect(
            outcome.findings.contains { $0.guardrail == .answerLeak },
            "double negative should count as a leak"
        )
    }

    private static func testUngroundedNumbers() throws {
        let outcome = CoachGuardrails.reviewExplanation(
            "A quarter off leaves 75% of the price. Prices rose 47.3% last year.",
            exercise: numericExercise,
            facts: MathCourse.percentages.facts
        )
        guard let text = outcome.value else {
            throw Failure(message: "expected the grounded half to survive")
        }
        try expect(!text.contains("47.3"), "invented figure removed, got: \(text)")
        try expect(outcome.findings.contains { $0.guardrail == .grounding }, "grounding flagged")

        try expectEqual(
            GroundingCheck.ungroundedNumbers(in: "There are 3 steps", sources: []),
            [],
            "small integers are prose, not data"
        )
        try expectEqual(
            GroundingCheck.ungroundedNumbers(in: "The value is 4096", sources: ["nothing here"]),
            ["4096"],
            "a large invented number is caught"
        )
    }

    private static func testContactScrubbing() throws {
        let outcome = CoachGuardrails.reviewReply(
            "Read more at https://example.com/fractions or write to tutor@example.com.",
            exercise: nil,
            lesson: lesson,
            facts: lesson.facts
        )
        guard let text = outcome.value else {
            throw Failure(message: "expected scrubbing rather than rejection")
        }
        try expect(!text.contains("http"), "link removed, got: \(text)")
        try expect(!text.contains("@"), "email removed, got: \(text)")
        try expect(outcome.findings.contains { $0.guardrail == .privacy }, "privacy flagged")
    }

    private static func testReplyTrimming() throws {
        let long = "One. Two. Three. Four. Five. Six."
        let outcome = CoachGuardrails.reviewReply(
            long,
            exercise: nil,
            lesson: lesson,
            facts: lesson.facts
        )
        guard let text = outcome.value else { throw Failure(message: "expected a trimmed reply") }
        try expect(
            Sentences.split(text).count <= CoachGuardrails.maxReplySentences,
            "reply not trimmed: \(text)"
        )
        try expect(outcome.findings.contains { $0.guardrail == .length }, "length flagged")
    }

    private static func testLearnerMessageDeclined() throws {
        let outcome = CoachGuardrails.reviewLearnerMessage("How do I make a bomb for chemistry class?")
        try expect(outcome.wasRejected, "unsafe request must be declined")
        try expect(
            !CoachGuardrails.declineMessage(for: outcome.findings).isEmpty,
            "there is something friendly to say"
        )

        let personal = CoachGuardrails.reviewLearnerMessage("My email is me@example.com, which school do you go to?")
        try expect(personal.wasRejected, "personal data request declined")
        try expect(
            CoachGuardrails.declineMessage(for: personal.findings).contains("personal"),
            "the decline explains itself"
        )
    }

    private static func testLearnerMessageAllowed() throws {
        let outcome = CoachGuardrails.reviewLearnerMessage("Why do I need a common denominator?")
        try expect(!outcome.wasRejected, "an ordinary question must go through")
        try expect(SafetyScreen.allowsLearnerMessage("How does slope work?"), "helper agrees")
    }

    private static func testNoSubstringFalsePositive() throws {
        let exercise = Exercise.choice(
            "t.1", lesson: "l", "Pick one",
            options: ["one", "two", "three"], correct: 0,
            why: "because", hint: "h"
        )
        try expect(
            AnswerLeakDetector.leakedAnswer(in: "Think about money and moneyed words.", exercise: exercise) == nil,
            "'one' inside 'money' is not a leak"
        )
        try expect(
            AnswerLeakDetector.leakedAnswer(in: "Pick one.", exercise: exercise) != nil,
            "a standalone 'one' is a leak"
        )
    }

    // MARK: - Coach service

    private static func testCoachHintFallback() async throws {
        let reasoner = ScriptedReasoner(replies: [
            "The answer is 1/2 because it is the largest.",
            "The answer is definitely 1/2."
        ])
        let coach = CoachService(reasoner: reasoner)
        let response = await coach.hint(for: choiceExercise, facts: lesson.facts)
        try expectEqual(response.source, .curated, "a persistently leaking model falls back to curated")
        try expectEqual(response.text, choiceExercise.hint, "the curated hint is used verbatim")
        try expect(!response.findings.isEmpty, "the reason is recorded")
    }

    private static func testCoachHintPassthrough() async throws {
        let reasoner = ScriptedReasoner(replies: ["Convert each option to a decimal, then compare."])
        let coach = CoachService(reasoner: reasoner)
        let response = await coach.hint(for: choiceExercise, facts: lesson.facts)
        try expectEqual(response.source, .appleIntelligence, "a clean hint is used as generated")
        try expect(response.text.contains("decimal"), "text preserved")
    }

    private static func testCoachWithoutModel() async throws {
        let coach = CoachService(reasoner: HeuristicReasoner())
        let hint = await coach.hint(for: choiceExercise, facts: lesson.facts)
        try expectEqual(hint.source, .curated, "no model, curated hint")

        let explanation = await coach.explanation(
            for: choiceExercise,
            learnerAnswer: "3/8",
            wasCorrect: false,
            facts: lesson.facts
        )
        try expectEqual(explanation.text, choiceExercise.explanation, "curated explanation")

        let reply = await coach.reply(
            to: "Why do I need a common denominator?",
            exercise: choiceExercise,
            lesson: lesson,
            facts: lesson.facts
        )
        try expectEqual(reply.source, .curated, "curated reply")
        try expect(!reply.text.isEmpty, "the coach always says something")
    }

    private static func testCoachSafetyRefusal() async throws {
        let reasoner = ScriptedReasoner(replies: [], error: .blockedBySafetySystem)
        let coach = CoachService(reasoner: reasoner)

        let hint = await coach.hint(for: choiceExercise, facts: lesson.facts)
        try expectEqual(hint.source, .curated, "a refused hint falls back")

        let reply = await coach.reply(
            to: "Tell me about fractions",
            exercise: choiceExercise,
            lesson: lesson,
            facts: lesson.facts
        )
        try expectEqual(reply.source, .declined, "a refused reply is reported as declined")
        try expect(
            reply.findings.contains { $0.guardrail == .safety },
            "the system guardrail is recorded"
        )
    }

    private static func testGeneratorRetry() async throws {
        let reasoner = ScriptedReasoner(drafts: [
            .sample(options: ["1/8", "2/5"]),
            .sample()
        ])
        let generator = PracticeGenerator(reasoner: reasoner)
        let result = await generator.bonusItem(for: MathCourse.fractions, existingPrompts: [])
        try expect(result.succeeded, "the second attempt should be accepted")
        try expectEqual(result.attempts, 2, "one retry")
        try expect(result.findings.contains { $0.guardrail == .schema }, "the first failure is recorded")

        let hopeless = ScriptedReasoner(drafts: [.sample(options: ["1/8"])])
        let stubborn = PracticeGenerator(reasoner: hopeless)
        let failure = await stubborn.bonusItem(for: MathCourse.fractions, existingPrompts: [])
        try expect(!failure.succeeded, "two bad drafts means no generated item")
        try expectEqual(failure.attempts, 2, "gives up after one retry")

        let unavailable = PracticeGenerator(reasoner: HeuristicReasoner())
        let skipped = await unavailable.bonusItem(for: MathCourse.fractions, existingPrompts: [])
        try expectEqual(skipped.attempts, 0, "no model, no attempt")
    }

    private static func testGeneratorBlocked() async throws {
        let reasoner = ScriptedReasoner(drafts: [], error: .blockedBySafetySystem)
        let generator = PracticeGenerator(reasoner: reasoner)
        let result = await generator.bonusItem(for: MathCourse.fractions, existingPrompts: [])
        try expect(!result.succeeded, "blocked means no item")
        try expect(result.blockedBySafetySystem, "the block is reported")

        var ledger = GuardrailLedger()
        ledger.recordSystemGuardrailBlock()
        ledger.record(GuardrailOutcome<Exercise>.rejected(result.findings))
        try expectEqual(ledger.blockedBySystemGuardrail, 1, "ledger counts system blocks")
        try expectEqual(ledger.rejected, 1, "ledger counts rejections")
        try expect(!ledger.topRejections.isEmpty, "ledger summarises by guardrail")
    }
}

#if QUARK_UNIT_TESTS_MAIN
@main
struct UnitTestsMain {
    static func main() async {
        let failures = await UnitTests.runAll()
        exit(Int32(min(failures, 120)))
    }
}
#endif
