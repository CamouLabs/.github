//
//  QuarkControls.swift
//  Quark
//
//  The shared controls: one primary button, one quiet button, one stat pill,
//  one card. Keeping them here is what stops six screens from each inventing
//  their own idea of a rounded rectangle.
//

import SwiftUI

/// The single loud button in the app. Full width, springy on press, and it
/// dims rather than disappears when it is not usable yet — a button that
/// vanishes mid-question is disorienting.
struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var tint: Color = QuarkTheme.primary
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(QuarkTheme.textInverse)
            .background(
                RoundedRectangle(cornerRadius: QuarkTheme.controlRadius, style: .continuous)
                    .fill(tint.opacity(isEnabled ? 1 : 0.38))
            )
        }
        .buttonStyle(PressableStyle())
        .disabled(!isEnabled)
    }
}

/// Secondary action: same shape, no fill.
struct QuietButton: View {
    let title: String
    var systemImage: String?
    var tint: Color = QuarkTheme.textSecondary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 14, weight: .semibold))
                }
                Text(title).font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(tint)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: QuarkTheme.chipRadius, style: .continuous)
                    .fill(QuarkTheme.surfaceSunken)
            )
        }
        .buttonStyle(PressableStyle())
    }
}

/// Scale-down-on-press. Applied to everything tappable so the whole app
/// answers to touch the same way.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .animation(QuarkTheme.bounce, value: configuration.isPressed)
    }
}

/// Compact number-with-icon used in the top bars: streak, XP, sparks.
struct StatPill: View {
    let symbol: String
    let value: String
    var tint: Color = QuarkTheme.primary
    var isMuted = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(isMuted ? QuarkTheme.textTertiary : tint)
        .padding(.vertical, 7)
        .padding(.horizontal, 11)
        .background(
            Capsule(style: .continuous)
                .fill((isMuted ? QuarkTheme.textTertiary : tint).opacity(0.12))
        )
    }
}

/// The app's one card surface.
struct Card<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: QuarkTheme.cardRadius, style: .continuous)
                    .fill(QuarkTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: QuarkTheme.cardRadius, style: .continuous)
                    .strokeBorder(QuarkTheme.separator, lineWidth: 1)
            )
    }
}

/// Section heading used across Profile and Settings.
struct SectionHeader: View {
    let title: String
    var detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(QuarkTheme.textTertiary)
            if let detail {
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(QuarkTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Thin horizontal bar used for session progress and track completion.
struct ProgressBar: View {
    let value: Double
    var tint: Color = QuarkTheme.primary
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(QuarkTheme.surfaceSunken)
                Capsule()
                    .fill(tint)
                    .frame(width: max(geometry.size.width * min(max(value, 0), 1), value > 0 ? height : 0))
            }
        }
        .frame(height: height)
        .animation(QuarkTheme.settle, value: value)
    }
}

/// Ring used for the daily goal and the level badge.
struct ProgressRing: View {
    let value: Double
    var tint: Color = QuarkTheme.spark
    var lineWidth: CGFloat = 8
    var trackColor: Color = QuarkTheme.surfaceSunken

    var body: some View {
        ZStack {
            Circle().strokeBorder(trackColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(value, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(QuarkTheme.settle, value: value)
    }
}

/// The label that appears on anything Apple Intelligence wrote. It is small,
/// but it is never optional: a learner should always be able to tell curated
/// content from generated content.
struct IntelligenceBadge: View {
    let source: CoachResponse.Source
    var compact = false

    private var symbol: String {
        switch source {
        case .appleIntelligence: return "sparkles"
        case .repaired: return "checkmark.shield.fill"
        case .curated: return "book.closed.fill"
        case .declined: return "hand.raised.fill"
        }
    }

    private var tint: Color {
        switch source {
        case .appleIntelligence: return QuarkTheme.primary
        case .repaired: return QuarkTheme.correct
        case .curated: return QuarkTheme.textTertiary
        case .declined: return QuarkTheme.flame
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
            if !compact {
                Text(source.label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
        }
        .foregroundStyle(tint)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Capsule().fill(tint.opacity(0.12)))
        .accessibilityLabel("Source: \(source.label)")
    }
}
