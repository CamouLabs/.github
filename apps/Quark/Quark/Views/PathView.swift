//
//  PathView.swift
//  Quark
//
//  Home. A vertical path of lesson nodes per unit, one track at a time, with
//  the daily goal and the streak pinned to the top.
//
//  The path deliberately does not show a percentage for the whole track.
//  Mastery here decays, so a single headline number would be either wrong or
//  demoralising; the per-node rings tell the truth without needing a caption.
//

import SwiftUI

struct PathView: View {
    @EnvironmentObject private var store: ProgressStore
    @EnvironmentObject private var settings: AppSettings

    @State private var selectedTrack: TrackID = .math
    @State private var activeSession: ActiveSession?

    private struct ActiveSession: Identifiable {
        let plan: SessionPlan
        let track: TrackID
        var id: String { "\(track.rawValue)-\(plan.lessonID)-\(plan.mode.rawValue)-\(plan.items.count)" }
    }

    private var tracks: [TrackID] {
        store.profile.tracks.isEmpty ? [.math] : store.profile.tracks
    }

    private var course: Course { Curriculum.course(for: selectedTrack) }

    private var accent: Color { QuarkTheme.color(for: selectedTrack) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    DailyGoalCard(store: store, accent: accent)

                    if tracks.count > 1 {
                        TrackStrip(tracks: tracks, selection: $selectedTrack)
                    }

                    reviewCard

                    ForEach(Array(course.units.enumerated()), id: \.element.id) { unitIndex, unit in
                        UnitSection(
                            unit: unit,
                            unitIndex: unitIndex,
                            track: selectedTrack,
                            store: store,
                            onStart: start(lesson:)
                        )
                    }

                    Text("All \(Curriculum.allExercises.count) questions ship with the app. Nothing about your practice leaves this device.")
                        .font(.system(size: 12))
                        .foregroundStyle(QuarkTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }
                .padding(.horizontal, QuarkTheme.paddingH)
                .padding(.bottom, 28)
            }
            .background(QuarkTheme.background)
            .navigationTitle(selectedTrack.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    StatPill(
                        symbol: "flame.fill",
                        value: "\(store.streak)",
                        tint: QuarkTheme.flame,
                        isMuted: store.streak == 0
                    )
                    .accessibilityLabel("\(store.streak) day streak")
                }
            }
        }
        .onAppear {
            if !tracks.contains(selectedTrack) { selectedTrack = tracks[0] }
        }
        .fullScreenCover(item: $activeSession) { session in
            SessionView(plan: session.plan, track: session.track)
        }
    }

    // MARK: - Review

    private var reviewPlan: SessionPlan? {
        SessionBuilder.reviewSession(
            lessons: Curriculum.lessons(in: tracks),
            profile: store.profile,
            length: settings.sessionLength
        )
    }

    @ViewBuilder
    private var reviewCard: some View {
        if let plan = reviewPlan {
            Card {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(QuarkTheme.flame.opacity(0.14)).frame(width: 46, height: 46)
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(QuarkTheme.flame)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Review is due")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(QuarkTheme.textPrimary)
                        Text(plan.subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(QuarkTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        activeSession = ActiveSession(
                            plan: plan,
                            track: Curriculum.track(containing: plan.lessonID) ?? selectedTrack
                        )
                    } label: {
                        Text("Start")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(QuarkTheme.textInverse)
                            .padding(.vertical, 9)
                            .padding(.horizontal, 16)
                            .background(Capsule().fill(QuarkTheme.flame))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
    }

    // MARK: - Starting a lesson

    private func start(lesson: Lesson) {
        let plan = SessionBuilder.lessonSession(
            for: lesson,
            profile: store.profile,
            length: settings.sessionLength
        )
        guard !plan.isEmpty else { return }
        Haptics.tap()
        activeSession = ActiveSession(
            plan: plan,
            track: Curriculum.track(containing: lesson.id) ?? selectedTrack
        )
    }
}

// MARK: - Daily goal

private struct DailyGoalCard: View {
    @ObservedObject var store: ProgressStore
    let accent: Color

    var body: some View {
        Card {
            HStack(spacing: 16) {
                ZStack {
                    ProgressRing(value: store.dailyGoalProgress, tint: QuarkTheme.spark, lineWidth: 9)
                        .frame(width: 62, height: 62)
                    if store.metDailyGoal {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(QuarkTheme.spark)
                    } else {
                        Text("\(store.xpToday)")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(QuarkTheme.textPrimary)
                            .monospacedDigit()
                    }
                }
                .pop(on: store.xpToday)

                VStack(alignment: .leading, spacing: 5) {
                    Text(store.metDailyGoal ? "Daily goal met" : "Today's goal")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(QuarkTheme.textPrimary)
                    Text(store.metDailyGoal
                        ? "Streak safe. Anything more is a bonus."
                        : "\(max(store.profile.dailyGoalXP - store.xpToday, 0)) XP to go — about one lesson.")
                        .font(.system(size: 13))
                        .foregroundStyle(QuarkTheme.textSecondary)

                    HStack(spacing: 8) {
                        StatPill(symbol: "star.fill", value: "Level \(store.level)", tint: QuarkTheme.primary)
                        StatPill(symbol: "bolt.fill", value: "\(store.profile.totalXP)", tint: QuarkTheme.spark)
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Track strip

private struct TrackStrip: View {
    let tracks: [TrackID]
    @Binding var selection: TrackID

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(tracks) { track in
                    let isSelected = track == selection
                    Button {
                        withAnimation(QuarkTheme.bounce) { selection = track }
                        Haptics.tap()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: track.symbol)
                                .font(.system(size: 13, weight: .bold))
                            Text(track.title)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(isSelected ? QuarkTheme.textInverse : QuarkTheme.color(for: track))
                        .padding(.vertical, 9)
                        .padding(.horizontal, 14)
                        .background(
                            Capsule().fill(
                                isSelected
                                    ? QuarkTheme.color(for: track)
                                    : QuarkTheme.color(for: track).opacity(0.12)
                            )
                        )
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 2)
        }
        .scrollClipDisabled()
    }
}

// MARK: - Unit

private struct UnitSection: View {
    let unit: Unit
    let unitIndex: Int
    let track: TrackID
    @ObservedObject var store: ProgressStore
    let onStart: (Lesson) -> Void

    private var unlocked: Set<String> {
        store.unlockedLessons(in: Curriculum.course(for: track))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            unitBanner

            VStack(spacing: 16) {
                ForEach(Array(unit.lessons.enumerated()), id: \.element.id) { index, lesson in
                    let isUnlocked = unlocked.contains(lesson.id)
                    PathRow(
                        lesson: lesson,
                        track: track,
                        level: store.mastery(for: lesson.id, unlocked: isUnlocked),
                        progress: store.progress(for: lesson.id),
                        isDue: SpacedRepetition.isDue(store.profile.record(for: lesson.id))
                            && store.profile.record(for: lesson.id).attempts > 0,
                        alignment: (unitIndex + index).isMultiple(of: 2) ? .leading : .trailing
                    ) {
                        onStart(lesson)
                    }
                }
            }
        }
    }

    private var unitBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Unit \(unitIndex + 1)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundStyle(QuarkTheme.textInverse.opacity(0.8))
            Text(unit.title)
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .foregroundStyle(QuarkTheme.textInverse)
            Text(unit.blurb)
                .font(.system(size: 13))
                .foregroundStyle(QuarkTheme.textInverse.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: QuarkTheme.cardRadius, style: .continuous)
                .fill(QuarkTheme.gradient(for: track))
        )
        .accessibilityElement(children: .combine)
    }
}
