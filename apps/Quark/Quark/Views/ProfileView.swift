//
//  ProfileView.swift
//  Quark
//
//  Progress, honestly. The level ring and the streak are the fun part; below
//  them the screen reports accuracy and per-track strength without rounding
//  anything up. The heat strip is twelve weeks of practice days, which is the
//  one visualisation that reliably changes behaviour.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: ProgressStore

    private var tracks: [TrackID] {
        store.profile.tracks.isEmpty ? [.math] : store.profile.tracks
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    levelCard
                    statsRow
                    heatCard
                    trackCard
                }
                .padding(.horizontal, QuarkTheme.paddingH)
                .padding(.bottom, 28)
            }
            .background(QuarkTheme.background)
            .navigationTitle("Progress")
        }
    }

    // MARK: - Level

    private var levelCard: some View {
        Card {
            HStack(spacing: 18) {
                ZStack {
                    ProgressRing(value: store.levelProgress, tint: QuarkTheme.primary, lineWidth: 10)
                        .frame(width: 82, height: 82)
                    VStack(spacing: -2) {
                        Text("\(store.level)")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(QuarkTheme.textPrimary)
                            .monospacedDigit()
                        Text("LEVEL")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(QuarkTheme.textTertiary)
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("\(store.profile.totalXP) XP")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(QuarkTheme.textPrimary)
                        .monospacedDigit()
                    Text("\(ProgressEngine.xpToNextLevel(forXP: store.profile.totalXP)) XP to level \(store.level + 1)")
                        .font(.system(size: 13))
                        .foregroundStyle(QuarkTheme.textSecondary)

                    HStack(spacing: 8) {
                        StatPill(
                            symbol: "flame.fill",
                            value: "\(store.streak)d",
                            tint: QuarkTheme.flame,
                            isMuted: store.streak == 0
                        )
                        StatPill(
                            symbol: "trophy.fill",
                            value: "\(store.profile.bestStreakDays)d best",
                            tint: QuarkTheme.spark
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Stats

    private var statsRow: some View {
        VStack(spacing: 10) {
            SectionHeader(title: "Lifetime")
            HStack(spacing: 10) {
                MetricTile(
                    value: "\(store.profile.sessionsCompleted)",
                    label: "Sessions",
                    symbol: "checkmark.seal.fill",
                    tint: QuarkTheme.correct
                )
                MetricTile(
                    value: "\(store.profile.itemsAnswered)",
                    label: "Questions",
                    symbol: "questionmark.circle.fill",
                    tint: QuarkTheme.primary
                )
                MetricTile(
                    value: store.profile.itemsAnswered == 0
                        ? "—"
                        : "\(Int((store.profile.accuracy * 100).rounded()))%",
                    label: "Accuracy",
                    symbol: "target",
                    tint: QuarkTheme.spark
                )
            }
        }
    }

    // MARK: - Practice heat strip

    private var heatCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Last 12 weeks", detail: "One square per day you practised.")
            Card(padding: 16) {
                HeatStrip(activeDays: Set(store.profile.activeDays))
            }
        }
    }

    // MARK: - Tracks

    private var trackCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Track strength", detail: "Mastery fades, so these move down as well as up.")
            Card {
                VStack(spacing: 16) {
                    ForEach(tracks) { track in
                        let lessons = Curriculum.course(for: track).lessons
                        let strength = MasteryModel.trackProgress(
                            lessonIDs: lessons.map(\.id),
                            in: store.profile
                        )
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(spacing: 8) {
                                Image(systemName: track.symbol)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(QuarkTheme.color(for: track))
                                Text(track.title)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(QuarkTheme.textPrimary)
                                Spacer()
                                Text("\(Int((strength * 100).rounded()))%")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(QuarkTheme.textSecondary)
                                    .monospacedDigit()
                            }
                            ProgressBar(value: strength, tint: QuarkTheme.color(for: track), height: 8)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(track.title): \(Int((strength * 100).rounded())) percent")
                    }
                }
            }
        }
    }
}

private struct MetricTile: View {
    let value: String
    let label: String
    let symbol: String
    let tint: Color

    var body: some View {
        Card(padding: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint)
                Text(value)
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(QuarkTheme.textPrimary)
                    .monospacedDigit()
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(QuarkTheme.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// Twelve weeks of days, oldest column first, today in the last column.
private struct HeatStrip: View {
    let activeDays: Set<LearningDay>

    private static let weeks = 12

    private var columns: [[LearningDay]] {
        let today = LearningDay(date: Date())
        // Fill backwards so the final square is always today.
        let total = Self.weeks * 7
        let days = (0..<total).reversed().map { today.adding(days: -$0) }
        return stride(from: 0, to: days.count, by: 7).map { start in
            Array(days[start..<min(start + 7, days.count)])
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(columns.enumerated()), id: \.offset) { _, week in
                VStack(spacing: 4) {
                    ForEach(week, id: \.value) { day in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(activeDays.contains(day) ? QuarkTheme.flame : QuarkTheme.surfaceSunken)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(activeDays.count) practice days in the last twelve weeks")
    }
}
