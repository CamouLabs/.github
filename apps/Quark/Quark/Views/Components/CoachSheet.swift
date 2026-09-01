//
//  CoachSheet.swift
//  Quark
//
//  Ask Quark. A hint at the top, then a short conversation about the question
//  on screen.
//
//  Every reply here is labelled with where it came from, and the label is not
//  decoration: "edited by guardrails" means the app changed the model's words
//  before showing them, and a learner is entitled to know that.
//

import SwiftUI

struct CoachSheet: View {
    @ObservedObject var model: SessionViewModel
    let accent: Color
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @FocusState private var isComposerFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        hintCard

                        if !model.coachMessages.isEmpty {
                            ForEach(model.coachMessages) { message in
                                MessageBubble(message: message, accent: accent)
                                    .id(message.id)
                            }
                        } else {
                            starters
                        }

                        if model.isCoachBusy {
                            ThinkingRow()
                        }
                    }
                    .padding(.horizontal, QuarkTheme.paddingH)
                    .padding(.vertical, 16)
                }
                .onChange(of: model.coachMessages.count) { _, _ in
                    guard let last = model.coachMessages.last else { return }
                    withAnimation(QuarkTheme.settle) { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .background(QuarkTheme.background)
            .safeAreaInset(edge: .bottom) { composer }
            .navigationTitle("Ask Quark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
            }
        }
    }

    // MARK: - Hint

    private var hintCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.max.fill")
                        .foregroundStyle(QuarkTheme.spark)
                    Text("Hint")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(QuarkTheme.textPrimary)
                    Spacer()
                    if let hint = model.hint {
                        IntelligenceBadge(source: hint.source)
                    }
                }

                if let hint = model.hint {
                    Text(hint.text)
                        .font(.system(size: 15))
                        .foregroundStyle(QuarkTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    QuietButton(title: "Another nudge", systemImage: "arrow.clockwise", tint: accent) {
                        model.requestHint()
                    }
                } else {
                    Text("A nudge toward the method — never the answer.")
                        .font(.system(size: 15))
                        .foregroundStyle(QuarkTheme.textSecondary)

                    PrimaryButton(
                        title: model.isCoachBusy ? "Thinking…" : "Give me a hint",
                        systemImage: "lightbulb.fill",
                        tint: accent,
                        isEnabled: !model.isCoachBusy
                    ) {
                        model.requestHint()
                    }
                }
            }
        }
    }

    // MARK: - Starters

    private var starters: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Try asking")
            ForEach(Self.starterQuestions, id: \.self) { question in
                Button {
                    model.ask(question)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 12))
                            .foregroundStyle(accent)
                        Text(question)
                            .font(.system(size: 15))
                            .foregroundStyle(QuarkTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: QuarkTheme.chipRadius, style: .continuous)
                            .fill(QuarkTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: QuarkTheme.chipRadius, style: .continuous)
                            .strokeBorder(QuarkTheme.separator, lineWidth: 1)
                    )
                }
                .buttonStyle(PressableStyle())
                .disabled(model.isCoachBusy)
            }
        }
    }

    private static let starterQuestions = [
        "Where do I start?",
        "Why does that step work?",
        "Can you say it another way?"
    ]

    // MARK: - Composer

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Ask about this question", text: $draft, axis: .vertical)
                .font(.system(size: 16))
                .lineLimit(1...4)
                .focused($isComposerFocused)
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
                .background(Capsule().fill(QuarkTheme.surface))
                .overlay(Capsule().strokeBorder(QuarkTheme.separator, lineWidth: 1))

            Button {
                let question = draft
                draft = ""
                isComposerFocused = false
                model.ask(question)
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(QuarkTheme.textInverse)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(canSend ? accent : QuarkTheme.textTertiary.opacity(0.4)))
            }
            .buttonStyle(PressableStyle())
            .disabled(!canSend)
        }
        .padding(.horizontal, QuarkTheme.paddingH)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !model.isCoachBusy
    }
}

private struct MessageBubble: View {
    let message: SessionViewModel.CoachMessage
    let accent: Color

    var body: some View {
        VStack(alignment: message.isFromLearner ? .trailing : .leading, spacing: 5) {
            Text(message.text)
                .font(.system(size: 15))
                .foregroundStyle(message.isFromLearner ? QuarkTheme.textInverse : QuarkTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(message.isFromLearner ? accent : QuarkTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            message.isFromLearner ? .clear : QuarkTheme.separator,
                            lineWidth: 1
                        )
                )

            if let source = message.source, source != .curated {
                IntelligenceBadge(source: source)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: message.isFromLearner ? .trailing : .leading
        )
    }
}

private struct ThinkingRow: View {
    @State private var isBreathing = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(QuarkTheme.textTertiary)
                    .frame(width: 7, height: 7)
                    .scaleEffect(isBreathing ? 1 : 0.55)
                    .opacity(isBreathing ? 1 : 0.35)
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: isBreathing
                    )
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(QuarkTheme.surface)
        )
        .accessibilityLabel("Quark is thinking")
        .onAppear { isBreathing = true }
    }
}
