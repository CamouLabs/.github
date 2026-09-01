//
//  Haptics.swift
//  Quark
//
//  Small, specific taps. A learning app earns its feel from the difference
//  between "yes" and "not yet", so those two get distinct haptics and nothing
//  else gets any.
//

import UIKit

@MainActor
enum Haptics {
    static func correct() {
        guard AppSettings.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func incorrect() {
        guard AppSettings.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func tap() {
        guard AppSettings.shared.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func celebrate() {
        guard AppSettings.shared.hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
}
