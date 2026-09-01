//
//  Track.swift
//  Quark
//
//  The six STEM tracks a learner can pick. Tracks are pure data so the whole
//  learning engine stays Foundation-only (and unit-testable off-device);
//  colors and symbols are resolved in the theme layer.
//

import Foundation

enum TrackID: String, Codable, CaseIterable, Identifiable, Sendable {
    case math
    case physics
    case chemistry
    case biology
    case computing
    case data

    var id: String { rawValue }

    var title: String {
        switch self {
        case .math: return "Mathematics"
        case .physics: return "Physics"
        case .chemistry: return "Chemistry"
        case .biology: return "Biology"
        case .computing: return "Computing"
        case .data: return "Data & Stats"
        }
    }

    /// Short, playful promise shown on the track card.
    var blurb: String {
        switch self {
        case .math: return "Numbers you can feel."
        case .physics: return "Why things move."
        case .chemistry: return "What stuff is made of."
        case .biology: return "How life works."
        case .computing: return "Think like a machine."
        case .data: return "Read the world's numbers."
        }
    }

    var symbol: String {
        switch self {
        case .math: return "function"
        case .physics: return "atom"
        case .chemistry: return "flask"
        case .biology: return "leaf"
        case .computing: return "curlybraces"
        case .data: return "chart.bar.xaxis"
        }
    }

    /// Emoji used in celebration copy — the one place the app gets loud.
    var badge: String {
        switch self {
        case .math: return "➗"
        case .physics: return "🪐"
        case .chemistry: return "⚗️"
        case .biology: return "🌱"
        case .computing: return "⌨️"
        case .data: return "📊"
        }
    }
}
