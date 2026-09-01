//
//  SummaryView.swift
//  Quark
//
//  The payoff screen. It celebrates, but it also reports: accuracy, best
//  combo, and — when Apple Intelligence contributed anything — exactly what
//  the guardrails did with it. The transparency panel is collapsed by default,
//  because it should be available without being homework.
//

import SwiftUI

struct SummaryView: View {
    let summary: SessionSummary
    let track: TrackID
    let ledger: GuardrailLedger
    let onDone: () -> Void

    @State private var hasAppeared = false

    private var accent: Color { QuarkTheme.color(for: track) }

    private var headline: String {
        if summary.isPerfect { return "Flawless \(track.badge)" }
        if summary.accuracy >= 0.8 { return "Strong finish" }
        if summary.accuracy >= 0.5 { return "Good work" }
        return "That's the hard part done"
    }

    private var subhead: String {
        if summary.isPerfect { return "Every answer, first time." }
        if summary.accuracy >= 0.8 { return "The shape of it is there." }
        return "Missed questions come back tomorrow, on purpose."
    }

    var body: some View {
        ZStack {
            QuarkTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    medal
                        .padding(.top, 24)

                    VStack(spacing: 6) {
                        Text(headline)
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(QuarkTheme.textPrimary)
                        Text(subhead)
                            .font(.system(size: 15))
                            .foregroundStyle(QuarkTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    statGrid

                    if ledger.reviewed > 0 {
                        GuardrailLedgerCard(ledger: ledger)
                    }
                }
                .padding(.horizontal, QuarkTheme.paddingH)
                .padding(.bottom, 24)
            }

            if summary.accuracy >= 0.8 {
                SparkShower(seed: "\(summary.lessonTitle)-\(summary.correct)-\(summary.total)")
                    .ignoresSafeArea()
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Done", tint: accent, action: onDone)
                .padding(.horizontal, QuarkTheme.paddingH)
                .padding(.vertical, 12)
                .background(QuarkTheme.background)
        }
    }

    // MARK: - Medal

    private var medal: some View {
        ZStack {
            Circle()
                .fill(QuarkTheme.gradient(for: track))
                .frame(width: 132, height: 132)
                .shadow(color: accent.opacity(0.35), radius: 22, y: 10)

            VStack(spacing: 2) {
                Text("\(Int((summary.accuracy * 100).rounded()))%")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                Text(summary.mode.title.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .opacity(0.85)
            }
            .foregroundStyle(QuarkTheme.textInverse)
        }
        .scaleEffect(hasAppeared ? 1 : 0.7)
        .opacity(hasAppeared ? 1 : 0)
        .onAppear {
            withAnimation(QuarkTheme.bounce.delay(0.05)) { hasAppeared = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(summary.correct) of \(summary.total) correct in this \(summary.mode.title.lowercased())"
        )
    }

    // MARK: - Stats

    private var statGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                SummaryStat(
                    symbol: "bolt.fill",
                    value: "+\(summary.xpEarned)",
                    label: "XP earned",
                    tint: QuarkTheme.spark
                )
                SummaryStat(
                    symbol: "target",
                    value: "\(summary.correct)/\(summary.total)",
                    label: "Correct",
                    tint: QuarkTheme.correct
                )
            }
            HStack(spacing: 10) {
                SummaryStat(
                    symbol: "flame.fill",
                    value: "\(summary.bestCombo)",
                    label: "Best combo",
                    tint: QuarkTheme.flame
                )
                SummaryStat(
                    symbol: "clock",
                    value: durationText,
                    label: "Time",
                    tint: QuarkTheme.primary
                )
            }
        }
    }

    private var durationText: String {
        let seconds = Int(summary.elapsed.rounded())
        if seconds < 60 { return "\(seconds)s" }
        return "\(seconds / 60)m \(seconds % 60)s"
    }
}

private struct SummaryStat: View {
    let symbol: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        Card(padding: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tint)
                Text(value)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(QuarkTheme.textPrimary)
                    .monospacedDigit()
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(QuarkTheme.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// What the guardrails did during this session. Shown only when Apple
/// Intelligence was actually used, so it never appears as an empty promise.
struct GuardrailLedgerCard: View {
    let ledger: GuardrailLedger
    @State private var isExpanded = false

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    withAnimation(QuarkTheme.settle) { isExpanded.toggle() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(QuarkTheme.correct)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Guardrails, this session")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(QuarkTheme.textPrimary)
                            Text(oneLiner)
                                .font(.system(size: 13))
                                .foregroundStyle(QuarkTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(QuarkTheme.textTertiary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    VStack(spacing: 8) {
                        LedgerRow(label: "Reviewed", value: ledger.reviewed, tint: QuarkTheme.textSecondary)
                        LedgerRow(label: "Passed as written", value: ledger.accepted, tint: QuarkTheme.correct)
                        LedgerRow(label: "Edited before you saw it", value: ledger.repaired, tint: QuarkTheme.spark)
                        LedgerRow(label: "Replaced with built-in text", value: ledger.rejected, tint: QuarkTheme.wrong)
                        if ledger.blockedBySystemGuardrail > 0 {
                            LedgerRow(
                                label: "Declined by Apple Intelligence",
                                value: ledger.blockedBySystemGuardrail,
                                tint: QuarkTheme.primary
                            )
                        }
                    }

                    if !ledger.topRejections.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Caught by")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(QuarkTheme.textTertiary)
                            ForEach(Array(ledger.topRejections.prefix(4))) { entry in
                                Text("• \(entry.guardrail.title) × \(entry.count)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(QuarkTheme.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var oneLiner: String {
        if ledger.rejected == 0 && ledger.repaired == 0 {
            return "\(ledger.reviewed) pieces of coach text checked, all clean."
        }
        var parts: [String] = []
        if ledger.repaired > 0 { parts.append("\(ledger.repaired) edited") }
        if ledger.rejected > 0 { parts.append("\(ledger.rejected) replaced") }
        return "\(ledger.reviewed) checked · " + parts.joined(separator: " · ")
    }
}

private struct LedgerRow: View {
    let label: String
    let value: Int
    let tint: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(QuarkTheme.textSecondary)
            Spacer()
            Text("\(value)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
    }
}
