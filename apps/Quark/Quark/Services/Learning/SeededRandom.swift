//
//  SeededRandom.swift
//  Quark
//
//  SplitMix64. Session shuffling has to feel random to a learner but stay
//  reproducible for the harness, so every shuffle takes an explicit seed
//  instead of reaching for the system generator.
//

import Foundation

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    /// Seeds from a stable string (a lesson id, say) so the same lesson
    /// shuffles the same way within a day.
    init(seed: String) {
        var hash: UInt64 = 0xCBF29CE484222325
        for byte in seed.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001B3
        }
        self.init(seed: hash)
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
