//
//  ProgressEngine.swift
//  Quark
//
//  The game rules: XP, combos, levels, daily goal, and the streak. Pure
//  functions over LearnerProfile, so the whole reward loop can be tested
//  without a device and audited by reading one file.
//

import Foundation

enum ProgressEngine {
    static let xpPerCorrect = 10
    /// Extra XP per answer once a combo is running, capped so a long streak
    /// never dwarfs the value of attempting something hard.
    static let comboBonusStep = 2
    static let maxComboBonus = 10
    static let perfectSessionBonus = 20
    static let firstClearBonus = 15
    static let reviewSessionBonus = 10
    /// Wrong answers a learner can afford in one session.
    static let sparksPerSession = 5

    // MARK: - XP and levels

    static func xpForCorrect(combo: Int) -> Int {
        let bonus = min(max(combo - 1, 0) * comboBonusStep, maxComboBonus)
        return xpPerCorrect + bonus
    }

    /// Cumulative XP required to reach a level. Quadratic, so early levels
    /// arrive quickly and later ones stay meaningful.
    static func xpThreshold(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        let steps = level - 1
        return 100 * steps + 25 * steps * (steps - 1)
    }

    static func level(forXP xp: Int) -> Int {
        var level = 1
        while xpThreshold(forLevel: level + 1) <= xp { level += 1 }
        return level
    }

    /// Fraction of the way through the current level, for the profile ring.
    static func levelProgress(forXP xp: Int) -> Double {
        let current = level(forXP: xp)
        let floorXP = xpThreshold(forLevel: current)
        let ceilingXP = xpThreshold(forLevel: current + 1)
        guard ceilingXP > floorXP else { return 1 }
        return Double(xp - floorXP) / Double(ceilingXP - floorXP)
    }

    static func xpToNextLevel(forXP xp: Int) -> Int {
        max(xpThreshold(forLevel: level(forXP: xp) + 1) - xp, 0)
    }

    // MARK: - Answers

    /// Fold one graded answer into the profile: skill record, XP, tallies.
    static func applying(
        judgement: Judgement,
        lessonID: String,
        combo: Int,
        to profile: LearnerProfile,
        now: Date = Date()
    ) -> (profile: LearnerProfile, xpEarned: Int) {
        var updated = profile
        updated.skills[lessonID] = SpacedRepetition.updated(
            profile.record(for: lessonID),
            correct: judgement.isCorrect,
            now: now
        )
        updated.itemsAnswered += 1

        guard judgement.isCorrect else { return (updated, 0) }

        let xp = xpForCorrect(combo: combo)
        updated.itemsCorrect += 1
        updated.totalXP += xp
        updated.xpToday += xp
        return (updated, xp)
    }

    // MARK: - Sessions

    /// Award end-of-session bonuses and mark the lesson cleared.
    static func completing(
        lessonID: String,
        correct: Int,
        total: Int,
        isReview: Bool,
        to profile: LearnerProfile
    ) -> (profile: LearnerProfile, bonusXP: Int) {
        var updated = profile
        var bonus = 0

        let cleared = total > 0 && Double(correct) / Double(total) >= 0.6
        if cleared, !profile.isCompleted(lessonID) {
            bonus += firstClearBonus
        }
        if total > 0, correct == total {
            bonus += perfectSessionBonus
        }
        if isReview {
            bonus += reviewSessionBonus
        }

        if cleared {
            var record = updated.record(for: lessonID)
            record.completed = true
            updated.skills[lessonID] = record
        }

        updated.sessionsCompleted += 1
        updated.totalXP += bonus
        updated.xpToday += bonus
        return (updated, bonus)
    }

    // MARK: - Streak

    /// Called whenever the learner practises. Consecutive calendar days extend
    /// the streak; a gap resets it to today.
    static func registering(
        day: LearningDay,
        in profile: LearnerProfile
    ) -> LearnerProfile {
        var updated = profile

        if let last = profile.lastActiveDay {
            if last == day {
                return profile
            }
            // A new day starts a fresh daily-goal tally.
            updated.xpToday = 0
            updated.streakDays = (last.adding(days: 1) == day) ? profile.streakDays + 1 : 1
        } else {
            updated.xpToday = 0
            updated.streakDays = 1
        }

        updated.lastActiveDay = day
        updated.bestStreakDays = max(updated.bestStreakDays, updated.streakDays)
        updated.activeDays.append(day)
        if updated.activeDays.count > LearnerProfile.maxActiveDays {
            updated.activeDays.removeFirst(updated.activeDays.count - LearnerProfile.maxActiveDays)
        }
        return updated
    }

    /// The streak the learner would see right now: a streak that was last
    /// extended before yesterday has already lapsed.
    static func liveStreak(in profile: LearnerProfile, today: LearningDay) -> Int {
        guard let last = profile.lastActiveDay else { return 0 }
        if last == today || last.adding(days: 1) == today { return profile.streakDays }
        return 0
    }

    /// Whether today's tally still counts, or belongs to an earlier day.
    static func xpToday(in profile: LearnerProfile, today: LearningDay) -> Int {
        profile.lastActiveDay == today ? profile.xpToday : 0
    }
}
