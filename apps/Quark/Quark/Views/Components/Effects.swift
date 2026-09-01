//
//  Effects.swift
//  Quark
//
//  The three motions that carry the game feel: a shake for a wrong answer, a
//  pop for anything that just changed, and a spark shower for a finished
//  session. All three respect Reduce Motion, because a learning app that makes
//  someone queasy has failed at its actual job.
//

import SwiftUI

/// Horizontal wobble driven by an integer tick, so the caller animates it by
/// incrementing a counter rather than by managing a phase.
struct Shake: GeometryEffect {
    var travel: CGFloat = 8
    var shakes: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = travel * sin(animatableData * .pi * shakes)
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

extension View {
    /// Shakes once whenever `tick` changes.
    func shake(on tick: Int) -> some View {
        modifier(ShakeOnChange(tick: tick))
    }

    /// Scales up briefly whenever `value` changes. Used on the XP counter and
    /// the combo badge so a number that changed never changes silently.
    func pop<Value: Equatable>(on value: Value, scale: CGFloat = 1.18) -> some View {
        modifier(PopOnChange(value: value, scale: scale))
    }
}

private struct ShakeOnChange: ViewModifier {
    let tick: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(Shake(animatableData: phase))
            .onChange(of: tick) { _, _ in
                guard !reduceMotion else { return }
                phase = 0
                withAnimation(.easeInOut(duration: 0.4)) { phase = 1 }
            }
    }
}

private struct PopOnChange<Value: Equatable>: ViewModifier {
    let value: Value
    let scale: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPopped = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPopped ? scale : 1)
            .onChange(of: value) { _, _ in
                guard !reduceMotion else { return }
                withAnimation(QuarkTheme.bounce) { isPopped = true }
                withAnimation(QuarkTheme.bounce.delay(0.12)) { isPopped = false }
            }
    }
}

/// One-shot shower of small marks, used on the summary screen. Positions are
/// drawn from a seeded generator so the same summary always looks the same —
/// screenshots and UI tests stay stable, and nothing regenerates on redraw.
struct SparkShower: View {
    let seed: String
    var count = 26
    var colors: [Color] = [QuarkTheme.spark, QuarkTheme.primary, QuarkTheme.correct, QuarkTheme.flame]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFalling = false

    private struct Mark: Identifiable {
        let id: Int
        let x: CGFloat
        let delay: Double
        let size: CGFloat
        let spin: Double
        let color: Color
    }

    private var marks: [Mark] {
        var generator = SeededGenerator(seed: seed)
        return (0..<count).map { index in
            Mark(
                id: index,
                x: CGFloat(generator.next() % 1000) / 1000,
                delay: Double(generator.next() % 700) / 1000,
                size: 6 + CGFloat(generator.next() % 7),
                spin: Double(generator.next() % 360),
                color: colors[Int(generator.next() % UInt64(colors.count))]
            )
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                ForEach(marks) { mark in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(mark.color)
                        .frame(width: mark.size, height: mark.size * 1.6)
                        .rotationEffect(.degrees(mark.spin))
                        .position(
                            x: mark.x * geometry.size.width,
                            y: isFalling ? geometry.size.height + 40 : -40
                        )
                        .opacity(isFalling ? 0 : 1)
                        .animation(
                            .easeIn(duration: 1.9).delay(mark.delay),
                            value: isFalling
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            isFalling = true
        }
    }
}
