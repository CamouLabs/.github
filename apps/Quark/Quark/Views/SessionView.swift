//
//  SessionView.swift
//  Quark
//
//  The screen a learner spends almost all their time on. Layout is fixed on
//  purpose: progress and sparks at the top, question in the middle, one action
//  at the bottom. Nothing moves between questions except the content, so
//  answering becomes muscle memory.
//

import SwiftUI

struct SessionView: View {
    @StateObject private var model: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isCoachPresented = false
    @State private var isQuitConfirmationPresented = false

    private let track: TrackID

    @MainActor
    init(plan: SessionPlan, track: TrackID) {
        _model = StateObject(wrappedValue: SessionViewModel(plan: plan))
        self.track = track
    }

    private var accent: Color { QuarkTheme.color(for: track) }

    var body: some View {
        ZStack {
            QuarkTheme.background.ignoresSafeArea()

            switch model.phase {
            case .finished(let summary):
                SummaryView(summary: summary, track: track, ledger: model.ledger) {
                    dismiss()
                }
            case .answering, .feedback:
                questionFlow
            }
        }
        .animation(QuarkTheme.settle, value: model.phase)
        .sheet(isPresented: $isCoachPresented) {
            CoachSheet(model: model, accent: accent)
        }
        .confirmationDialog(
            "Leave this session?",
            isPresented: $isQuitConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Leave", role: .destructive) { dismiss() }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("The XP you've already earned is kept.")
        }
    }

    // MARK: - Question flow

    private var questionFlow: some View {
        VStack(spacing: 0) {
            topBar

            if let exercise = model.current {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        QuestionHeader(exercise: exercise, accent: accent)

                        AnswerControls(
                            model: model,
                            exercise: exercise,
                            accent: accent,
                            isLocked: model.isShowingFeedback
                        )
                        .shake(on: model.shakeTick)
                    }
                    .padding(.horizontal, QuarkTheme.paddingH)
                    .padding(.top, 18)
                    .padding(.bottom, 24)
                    .id(exercise.id)
                }
                .scrollDismissesKeyboard(.interactively)
            }

            Spacer(minLength: 0)

            if case .feedback(let feedback) = model.phase {
                FeedbackBar(
                    feedback: feedback,
                    award: model.lastAward,
                    combo: model.combo,
                    accent: accent,
                    onContinue: { model.advance() }
                )
            } else {
                actionBar
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    isQuitConfirmationPresented = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(QuarkTheme.textTertiary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(QuarkTheme.surfaceSunken))
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("Leave session")

                ProgressBar(value: model.progress, tint: accent)

                if model.sparksAreLimited {
                    StatPill(
                        symbol: "bolt.fill",
                        value: "\(model.sparks)",
                        tint: QuarkTheme.spark,
                        isMuted: model.sparks == 0
                    )
                    .pop(on: model.sparks)
                    .accessibilityLabel("\(model.sparks) sparks left")
                }
            }

            HStack(spacing: 8) {
                Text("\(min(model.index + 1, model.items.count)) of \(model.items.count)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(QuarkTheme.textTertiary)
                    .monospacedDigit()

                if model.combo >= 2 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                        Text("\(model.combo)")
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(QuarkTheme.flame)
                    .pop(on: model.combo)
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer()

                if model.xpEarned > 0 {
                    Text("+\(model.xpEarned) XP")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(QuarkTheme.spark)
                        .monospacedDigit()
                        .pop(on: model.xpEarned)
                }
            }
        }
        .padding(.horizontal, QuarkTheme.paddingH)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Action bar

    private var actionBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                QuietButton(title: "Hint", systemImage: "lightbulb", tint: accent) {
                    if model.hint == nil { model.requestHint() }
                    isCoachPresented = true
                }
                QuietButton(title: "Ask Quark", systemImage: "bubble.left.and.text.bubble.right") {
                    isCoachPresented = true
                }
                Spacer()
                Button("Skip") { model.skip() }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(QuarkTheme.textTertiary)
            }

            PrimaryButton(
                title: "Check",
                tint: accent,
                isEnabled: model.canCheck
            ) {
                model.check()
            }
        }
        .padding(.horizontal, QuarkTheme.paddingH)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(QuarkTheme.background)
    }
}

// MARK: - Question header

private struct QuestionHeader: View {
    let exercise: Exercise
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Label(exercise.instruction, systemImage: symbol)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(Capsule().fill(accent.opacity(0.12)))

                if exercise.origin == .generated {
                    // A generated question is always labelled. It also passed
                    // eleven guardrails to get here.
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("Bonus, written on device")
                    }
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(QuarkTheme.primary)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 9)
                    .background(Capsule().fill(QuarkTheme.primary.opacity(0.12)))
                }

                Spacer()
            }

            Text(exercise.prompt)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(QuarkTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var symbol: String {
        switch exercise.kind {
        case .multipleChoice: return "list.bullet"
        case .trueFalse: return "arrow.left.arrow.right"
        case .numeric: return "number"
        case .shortText: return "textformat"
        case .ordering: return "arrow.up.arrow.down"
        case .matching: return "link"
        }
    }
}
