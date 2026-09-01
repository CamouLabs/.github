//
//  QuarkTheme.swift
//  Quark
//
//  Playful, but not loud. The palette is a calm indigo shell with one warm
//  accent for reward, so celebration reads as a moment rather than as the
//  app's permanent volume. Every colour is defined as a dynamic UIColor, so
//  Dark Mode is handled once, here.
//
//  Each track gets its own hue. It is the fastest way to make a subject feel
//  like a place you return to.
//

import SwiftUI
import UIKit

enum QuarkTheme {
    // Brand
    static let primary = Color.dynamic(light: "5B5BD6", dark: "9797F2")
    static let primaryDeep = Color.dynamic(light: "4141B8", dark: "7B7BE0")
    /// Reward: XP, level-ups, the daily goal ring.
    static let spark = Color.dynamic(light: "E9982A", dark: "FFC15E")
    /// Streaks.
    static let flame = Color.dynamic(light: "F0653A", dark: "FF8A5C")

    // Verdicts
    static let correct = Color.dynamic(light: "12996B", dark: "3ED598")
    static let correctSoft = Color.dynamic(light: "E4F6EE", dark: "17352A")
    static let wrong = Color.dynamic(light: "D6483E", dark: "F98078")
    static let wrongSoft = Color.dynamic(light: "FCEAE8", dark: "3A1F1D")

    // Surfaces
    static let background = Color.dynamic(light: "F6F5FB", dark: "121118")
    static let surface = Color.dynamic(light: "FFFFFF", dark: "1E1C26")
    static let surfaceSunken = Color.dynamic(light: "EFEEF7", dark: "191822")
    static let separator = Color.dynamic(light: "E3E1F0", dark: "302E3C")

    // Text
    static let textPrimary = Color.dynamic(light: "1B1A26", dark: "F3F1FA")
    static let textSecondary = Color.dynamic(light: "5C5972", dark: "B7B3C9")
    static let textTertiary = Color.dynamic(light: "918DA8", dark: "807C93")
    static let textInverse = Color.white

    // Layout
    static let cardRadius: CGFloat = 22
    static let controlRadius: CGFloat = 18
    static let chipRadius: CGFloat = 14
    static let nodeSize: CGFloat = 74
    static let paddingH: CGFloat = 20

    /// The one animation curve the whole app uses for anything that should
    /// feel physical.
    static let bounce = Animation.spring(response: 0.34, dampingFraction: 0.62)
    static let settle = Animation.spring(response: 0.45, dampingFraction: 0.85)

    static func color(for track: TrackID) -> Color {
        switch track {
        case .math: return Color.dynamic(light: "E08A2B", dark: "F5AE5C")
        case .physics: return Color.dynamic(light: "4F63D9", dark: "8496FF")
        case .chemistry: return Color.dynamic(light: "0F9C8C", dark: "3FD3C0")
        case .biology: return Color.dynamic(light: "2E9E52", dark: "58D07C")
        case .computing: return Color.dynamic(light: "7A54F0", dark: "A88DFF")
        case .data: return Color.dynamic(light: "D5455F", dark: "F97F91")
        }
    }

    static func gradient(for track: TrackID) -> LinearGradient {
        let base = color(for: track)
        return LinearGradient(
            colors: [base.opacity(0.95), base.opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func color(for level: MasteryLevel, track: TrackID) -> Color {
        switch level {
        case .locked: return separator
        case .ready, .learning: return color(for: track)
        case .strong: return color(for: track)
        case .mastered: return spark
        }
    }
}

extension Color {
    /// A colour that resolves differently in light and dark appearance.
    static func dynamic(light: String, dark: String) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let alpha, red, green, blue: UInt64
        switch hex.count {
        case 3:
            (alpha, red, green, blue) = (255, (value >> 8) * 17, (value >> 4 & 0xF) * 17, (value & 0xF) * 17)
        case 6:
            (alpha, red, green, blue) = (255, value >> 16, value >> 8 & 0xFF, value & 0xFF)
        case 8:
            (alpha, red, green, blue) = (value >> 24, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF)
        default:
            (alpha, red, green, blue) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}
