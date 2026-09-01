//
//  ProgressStore.swift
//  Quark
//
//  Persistence for the learner profile: one JSON file in the app's own
//  container, written atomically. No account, no sync, no server — so the
//  store's whole job is to load a value, hand it to ProgressEngine, and write
//  the result back.
//

import Foundation

@MainActor
final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    @Published private(set) var profile: LearnerProfile

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileURL: URL? = nil) {
        let resolved = fileURL ?? Self.defaultFileURL()
        self.fileURL = resolved
        self.profile = Self.load(from: resolved, using: JSONDecoder()) ?? LearnerProfile()
    }

    // MARK: - Reading

    var today: LearningDay { LearningDay(date: Date()) }

    var streak: Int { ProgressEngine.liveStreak(in: profile, today: today) }

    var xpToday: Int { ProgressEngine.xpToday(in: profile, today: today) }

    var level: Int { ProgressEngine.level(forXP: profile.totalXP) }

    var levelProgress: Double { ProgressEngine.levelProgress(forXP: profile.totalXP) }

    var dailyGoalProgress: Double {
        guard profile.dailyGoalXP > 0 else { return 1 }
        return min(Double(xpToday) / Double(profile.dailyGoalXP), 1)
    }

    var metDailyGoal: Bool { xpToday >= profile.dailyGoalXP }

    func mastery(for lessonID: String, unlocked: Bool) -> MasteryLevel {
        MasteryModel.level(for: lessonID, in: profile, unlocked: unlocked)
    }

    func progress(for lessonID: String) -> Double {
        MasteryModel.progress(for: lessonID, in: profile)
    }

    func unlockedLessons(in course: Course) -> Set<String> {
        MasteryModel.unlockedLessonIDs(for: course, in: profile)
    }

    func dueCount(in tracks: [TrackID]) -> Int {
        SpacedRepetition.dueLessons(
            in: profile,
            among: Curriculum.lessons(in: tracks).map(\.id)
        ).count
    }

    // MARK: - Writing

    func startSession() {
        profile = ProgressEngine.registering(day: today, in: profile)
        persist()
    }

    func record(judgement: Judgement, lessonID: String, combo: Int) -> Int {
        let (updated, xp) = ProgressEngine.applying(
            judgement: judgement,
            lessonID: lessonID,
            combo: combo,
            to: profile
        )
        profile = updated
        persist()
        return xp
    }

    func completeSession(lessonID: String, correct: Int, total: Int, isReview: Bool) -> Int {
        let (updated, bonus) = ProgressEngine.completing(
            lessonID: lessonID,
            correct: correct,
            total: total,
            isReview: isReview,
            to: profile
        )
        profile = updated
        persist()
        return bonus
    }

    func setTracks(_ tracks: [TrackID]) {
        profile.tracks = tracks.isEmpty ? [.math] : tracks
        persist()
    }

    func setDailyGoal(_ xp: Int) {
        profile.dailyGoalXP = max(10, xp)
        persist()
    }

    func completeOnboarding() {
        profile.hasCompletedOnboarding = true
        persist()
    }

    /// Wipes everything. There is nowhere else a copy could be.
    func resetEverything() {
        profile = LearnerProfile()
        profile.hasCompletedOnboarding = true
        persist()
    }

    // MARK: - Storage

    private static func defaultFileURL() -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("QuarkProgress.json")
    }

    private static func load(from url: URL, using decoder: JSONDecoder) -> LearnerProfile? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(LearnerProfile.self, from: data)
    }

    private func persist() {
        guard let data = try? encoder.encode(profile) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
