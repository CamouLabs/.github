//
//  AnswerControls.swift
//  Quark
//
//  One view per question kind. They all take the view model and mutate it
//  directly, because the answer in progress is genuinely session state — a
//  half-built ordering has to survive a hint sheet opening over it.
//
//  Ordering and matching are tap-only. Drag-and-drop looks better in a demo
//  and is worse on a phone: it fights the scroll view, it is hard to hit
//  one-handed, and it is close to unusable with VoiceOver.
//

import SwiftUI

struct AnswerControls: View {
    @ObservedObject var model: SessionViewModel
    let exercise: Exercise
    let accent: Color
    /// Locked once the answer has been checked.
    let isLocked: Bool

    var body: some View {
        switch exercise.content {
        case .multipleChoice(let options, let correctIndex):
            ChoiceGrid(
                options: options,
                correctIndex: correctIndex,
                selection: $model.selectedOption,
                accent: accent,
                isLocked: isLocked
            )
        case .trueFalse(let answer):
            TrueFalseControl(
                correctAnswer: answer,
                selection: $model.booleanAnswer,
                accent: accent,
                isLocked: isLocked
            )
        case .numeric(_, _, let unit, _):
            TypedAnswerField(
                text: $model.typedAnswer,
                placeholder: unit.map { "Number in \($0)" } ?? "Your number",
                unit: unit,
                keyboard: .numbersAndPunctuation,
                accent: accent,
                isLocked: isLocked
            )
        case .shortText:
            TypedAnswerField(
                text: $model.typedAnswer,
                placeholder: "Your answer",
                unit: nil,
                keyboard: .default,
                accent: accent,
                isLocked: isLocked
            )
        case .ordering:
            OrderingControl(model: model, accent: accent, isLocked: isLocked)
        case .matching(let pairs):
            MatchingControl(model: model, pairs: pairs, accent: accent, isLocked: isLocked)
        }
    }
}

// MARK: - Multiple choice

private struct ChoiceGrid: View {
    let options: [String]
    let correctIndex: Int
    @Binding var selection: Int?
    let accent: Color
    let isLocked: Bool

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                ChoiceRow(
                    label: option,
                    marker: marker(for: index),
                    verdict: verdict(for: index),
                    accent: accent
                ) {
                    selection = index
                    Haptics.tap()
                }
                .disabled(isLocked)
            }
        }
    }

    private func marker(for index: Int) -> String {
        let letter = UnicodeScalar(UInt8(65 + min(max(index, 0), 25)))
        return String(Character(letter))
    }

    private func verdict(for index: Int) -> ChoiceRow.Verdict {
        guard isLocked else { return selection == index ? .selected : .idle }
        if index == correctIndex { return .correct }
        if selection == index { return .wrong }
        return .idle
    }
}

private struct ChoiceRow: View {
    enum Verdict { case idle, selected, correct, wrong }

    let label: String
    let marker: String
    let verdict: Verdict
    let accent: Color
    let action: () -> Void

    private var border: Color {
        switch verdict {
        case .idle: return QuarkTheme.separator
        case .selected: return accent
        case .correct: return QuarkTheme.correct
        case .wrong: return QuarkTheme.wrong
        }
    }

    private var background: Color {
        switch verdict {
        case .idle: return QuarkTheme.surface
        case .selected: return accent.opacity(0.12)
        case .correct: return QuarkTheme.correctSoft
        case .wrong: return QuarkTheme.wrongSoft
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(marker)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(verdict == .idle ? QuarkTheme.textTertiary : border)
                    .frame(width: 26, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(border.opacity(verdict == .idle ? 0.08 : 0.18))
                    )

                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(QuarkTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if verdict == .correct {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(QuarkTheme.correct)
                } else if verdict == .wrong {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(QuarkTheme.wrong)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: QuarkTheme.controlRadius, style: .continuous)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: QuarkTheme.controlRadius, style: .continuous)
                    .strokeBorder(border, lineWidth: verdict == .idle ? 1 : 2)
            )
        }
        .buttonStyle(PressableStyle())
        .animation(QuarkTheme.bounce, value: verdict)
    }
}

// MARK: - True / false

private struct TrueFalseControl: View {
    let correctAnswer: Bool
    @Binding var selection: Bool?
    let accent: Color
    let isLocked: Bool

    var body: some View {
        HStack(spacing: 12) {
            option(true, title: "True", symbol: "checkmark")
            option(false, title: "False", symbol: "xmark")
        }
    }

    private func option(_ value: Bool, title: String, symbol: String) -> some View {
        let isChosen = selection == value
        let verdictTint: Color? = isLocked
            ? (value == correctAnswer ? QuarkTheme.correct : (isChosen ? QuarkTheme.wrong : nil))
            : nil
        let tint = verdictTint ?? (isChosen ? accent : QuarkTheme.separator)

        return Button {
            selection = value
            Haptics.tap()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .bold))
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(verdictTint ?? (isChosen ? accent : QuarkTheme.textSecondary))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: QuarkTheme.controlRadius, style: .continuous)
                    .fill(tint.opacity(verdictTint == nil && !isChosen ? 0.06 : 0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: QuarkTheme.controlRadius, style: .continuous)
                    .strokeBorder(tint, lineWidth: isChosen || verdictTint != nil ? 2 : 1)
            )
        }
        .buttonStyle(PressableStyle())
        .disabled(isLocked)
        .animation(QuarkTheme.bounce, value: selection)
    }
}

// MARK: - Typed answers

private struct TypedAnswerField: View {
    @Binding var text: String
    let placeholder: String
    let unit: String?
    let keyboard: UIKeyboardType
    let accent: Color
    let isLocked: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            TextField(placeholder, text: $text)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isFocused)
                .disabled(isLocked)

            if let unit, !unit.isEmpty {
                Text(unit)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(QuarkTheme.textTertiary)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: QuarkTheme.controlRadius, style: .continuous)
                .fill(QuarkTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: QuarkTheme.controlRadius, style: .continuous)
                .strokeBorder(isFocused ? accent : QuarkTheme.separator, lineWidth: isFocused ? 2 : 1)
        )
        .animation(QuarkTheme.bounce, value: isFocused)
    }
}

// MARK: - Ordering

private struct OrderingControl: View {
    @ObservedObject var model: SessionViewModel
    let accent: Color
    let isLocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(spacing: 8) {
                ForEach(Array(model.orderedSteps.enumerated()), id: \.element) { position, step in
                    Button {
                        guard !isLocked else { return }
                        model.removeStep(step)
                    } label: {
                        HStack(spacing: 12) {
                            Text("\(position + 1)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(QuarkTheme.textInverse)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(accent))
                            Text(step)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(QuarkTheme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if !isLocked {
                                Image(systemName: "minus.circle")
                                    .foregroundStyle(QuarkTheme.textTertiary)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: QuarkTheme.chipRadius, style: .continuous)
                                .fill(accent.opacity(0.1))
                        )
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("Step \(position + 1): \(step)")
                    .accessibilityHint("Removes this step from your order")
                }

                if model.orderedSteps.isEmpty {
                    Text("Tap the steps below in order.")
                        .font(.system(size: 14))
                        .foregroundStyle(QuarkTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 16)
                }
            }

            if !model.remainingSteps.isEmpty {
                Divider().overlay(QuarkTheme.separator)

                VStack(spacing: 8) {
                    ForEach(model.remainingSteps, id: \.self) { step in
                        Button {
                            model.chooseStep(step)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(accent)
                                Text(step)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(QuarkTheme.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
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
                        .disabled(isLocked)
                        .accessibilityHint("Adds this as the next step")
                    }
                }
            }
        }
    }
}

// MARK: - Matching

private struct MatchingControl: View {
    @ObservedObject var model: SessionViewModel
    let pairs: [MatchPair]
    let accent: Color
    let isLocked: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Tapping a matched term breaks the pair, so a mistake costs one
            // tap rather than a restart.
            column(
                items: pairs.map(\.left),
                isSelected: { model.pendingLeft == $0 },
                isMatched: { left in model.matchedPairs.contains { $0.left == left } },
                trailingLabel: { model.matchedRight(for: $0) },
                lockMatched: false,
                tap: { left in
                    if let pair = model.matchedPairs.first(where: { $0.left == left }) {
                        model.unmatch(pair)
                    } else {
                        model.selectLeft(left)
                    }
                }
            )

            column(
                items: model.matchOptions,
                isSelected: { _ in false },
                isMatched: { model.isMatched(right: $0) },
                trailingLabel: { _ in nil },
                lockMatched: true,
                tap: { model.selectRight($0) }
            )
        }
        .animation(QuarkTheme.bounce, value: model.matchedPairs)
    }

    private func column(
        items: [String],
        isSelected: @escaping (String) -> Bool,
        isMatched: @escaping (String) -> Bool,
        trailingLabel: @escaping (String) -> String?,
        lockMatched: Bool,
        tap: @escaping (String) -> Void
    ) -> some View {
        VStack(spacing: 8) {
            ForEach(items, id: \.self) { item in
                let matched = isMatched(item)
                let selected = isSelected(item)
                Button { tap(item) } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(matched ? QuarkTheme.textSecondary : QuarkTheme.textPrimary)
                            .multilineTextAlignment(.leading)
                        if let paired = trailingLabel(item), matched {
                            Text(paired)
                                .font(.system(size: 12))
                                .foregroundStyle(accent)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: QuarkTheme.chipRadius, style: .continuous)
                            .fill(matched ? accent.opacity(0.1) : QuarkTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: QuarkTheme.chipRadius, style: .continuous)
                            .strokeBorder(
                                selected ? accent : (matched ? accent.opacity(0.4) : QuarkTheme.separator),
                                lineWidth: selected ? 2 : 1
                            )
                    )
                    .opacity(matched ? 0.75 : 1)
                }
                .buttonStyle(PressableStyle())
                .disabled(isLocked || (matched && lockMatched))
            }
        }
    }
}
