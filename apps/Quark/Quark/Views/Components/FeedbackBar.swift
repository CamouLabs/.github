//
//  FeedbackBar.swift
//  Quark
//
//  The panel that slides up after an answer. It is the most-read surface in
//  the app, so it stays in one place, keeps the Continue button under the
//  thumb, and never reflows: when the coach's explanation arrives it replaces
//  the curated one in place, below everything the learner is already reading.
//

import SwiftUI

struct FeedbackBar: View {
    let feedback: SessionViewModel.Feedback
    let award: Int
    let combo: Int
    let accent: Color
    let onContinue: () -> Void

    private var tint: Color { feedback.isCorrect ? QuarkTheme.correct : QuarkTheme.wrong }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: feedback.isCorrect ? "checkmark.circle.fill" : "lightbulb.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(tint)

                Text(feedback.headline)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(QuarkTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if feedback.isCorrect, award > 0 {
                    Text("+\(award)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(QuarkTheme.spark)
                        .monospacedDigit()
                        .pop(on: award)
                }
            }

            if !feedback.isCorrect {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Answer")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(QuarkTheme.textTertiary)
                    Text(feedback.correctAnswer)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(QuarkTheme.textPrimary)
                }
            }

            if let note = feedback.note {
                Text(note)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(QuarkTheme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(feedback.explanation)
                    .font(.system(size: 15))
                    .foregroundStyle(QuarkTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if feedback.explanationSource != .curated {
                    IntelligenceBadge(source: feedback.explanationSource)
                }
            }
            .animation(QuarkTheme.settle, value: feedback.explanation)

            if feedback.isCorrect, combo >= 3 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                    Text("\(combo) in a row")
                }
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(QuarkTheme.flame)
            }

            PrimaryButton(
                title: "Continue",
                tint: feedback.isCorrect ? QuarkTheme.correct : accent,
                action: onContinue
            )
        }
        .padding(20)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 28,
                style: .continuous
            )
            .fill(feedback.isCorrect ? QuarkTheme.correctSoft : QuarkTheme.wrongSoft)
            .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            Rectangle().fill(tint.opacity(0.35)).frame(height: 1)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
