//
//  LessonNode.swift
//  Quark
//
//  One stop on the path. The node carries three pieces of information at once
//  without any text: the ring shows how much mastery is banked, the glyph
//  shows the state, and the fill tells you whether it is open. Mastery decays,
//  so a node can quietly lose its crown — which is the point.
//

import SwiftUI

struct LessonNode: View {
    let lesson: Lesson
    let track: TrackID
    let level: MasteryLevel
    let progress: Double
    let isDue: Bool
    let action: () -> Void

    private var accent: Color { QuarkTheme.color(for: track) }

    private var isOpen: Bool { level != .locked }

    private var fill: Color {
        switch level {
        case .locked: return QuarkTheme.surfaceSunken
        case .ready: return accent
        case .learning: return accent.opacity(0.9)
        case .strong: return accent
        case .mastered: return QuarkTheme.spark
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                ProgressRing(
                    value: level == .locked ? 0 : progress,
                    tint: level == .mastered ? QuarkTheme.spark : accent,
                    lineWidth: 5,
                    trackColor: QuarkTheme.separator
                )
                .frame(width: QuarkTheme.nodeSize, height: QuarkTheme.nodeSize)

                Circle()
                    .fill(fill)
                    .frame(width: QuarkTheme.nodeSize - 16, height: QuarkTheme.nodeSize - 16)
                    .shadow(
                        color: isOpen ? accent.opacity(0.28) : .clear,
                        radius: 10,
                        y: 5
                    )

                Image(systemName: level.symbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(isOpen ? QuarkTheme.textInverse : QuarkTheme.textTertiary)

                if isDue, isOpen {
                    Circle()
                        .fill(QuarkTheme.flame)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().strokeBorder(QuarkTheme.background, lineWidth: 2.5))
                        .offset(x: QuarkTheme.nodeSize / 2 - 6, y: -QuarkTheme.nodeSize / 2 + 6)
                }
            }
        }
        .buttonStyle(PressableStyle())
        .disabled(!isOpen)
        .accessibilityLabel(lesson.title)
        .accessibilityValue(
            isDue && isOpen ? "\(level.label), due for review" : level.label
        )
        .accessibilityHint(isOpen ? "Starts this lesson" : "Clear the previous lesson to unlock")
    }
}

/// Row on the path: the node plus its title, alternating side to side so the
/// path reads as a path rather than as a list.
struct PathRow: View {
    let lesson: Lesson
    let track: TrackID
    let level: MasteryLevel
    let progress: Double
    let isDue: Bool
    let alignment: HorizontalAlignment
    let action: () -> Void

    private var isTrailing: Bool { alignment == .trailing }

    var body: some View {
        HStack(spacing: 14) {
            if isTrailing {
                Spacer(minLength: 0)
                label
                node
            } else {
                node
                label
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var node: some View {
        LessonNode(
            lesson: lesson,
            track: track,
            level: level,
            progress: progress,
            isDue: isDue,
            action: action
        )
    }

    private var label: some View {
        VStack(alignment: isTrailing ? .trailing : .leading, spacing: 3) {
            Text(lesson.title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(level == .locked ? QuarkTheme.textTertiary : QuarkTheme.textPrimary)
            Text(level == .locked ? "Locked" : lesson.goal)
                .font(.system(size: 13))
                .foregroundStyle(QuarkTheme.textSecondary)
                .lineLimit(2)
        }
        .multilineTextAlignment(isTrailing ? .trailing : .leading)
        .frame(maxWidth: 190, alignment: isTrailing ? .trailing : .leading)
    }
}
