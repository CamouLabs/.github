import Foundation
import SwiftData

enum MediaType: String, Codable, CaseIterable {
    case text, audio, video
}

enum Mood: String, Codable, CaseIterable, Identifiable {
    case peaceful, happy, grateful, contemplative, anxious, sad, hopeful, tired

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .peaceful: return "🌿"
        case .happy: return "☀️"
        case .grateful: return "🙏"
        case .contemplative: return "🌙"
        case .anxious: return "🌊"
        case .sad: return "💧"
        case .hopeful: return "🌱"
        case .tired: return "😴"
        }
    }

    var label: String {
        rawValue.capitalized
    }
}

@Model
final class JournalEntry {
    var id: UUID
    var title: String
    var content: String
    var mediaType: String
    var mediaPath: String?
    var transcript: String?
    var mood: String?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    var processed: Bool

    init(
        title: String = "",
        content: String = "",
        mediaType: MediaType = .text,
        mediaPath: String? = nil,
        transcript: String? = nil,
        mood: Mood? = nil,
        tags: [String] = []
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.mediaType = mediaType.rawValue
        self.mediaPath = mediaPath
        self.transcript = transcript
        self.mood = mood?.rawValue
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
        self.processed = false
    }

    var moodEnum: Mood? {
        guard let mood else { return nil }
        return Mood(rawValue: mood)
    }

    var mediaTypeEnum: MediaType {
        MediaType(rawValue: mediaType) ?? .text
    }

    var displayText: String {
        transcript ?? content
    }
}

enum InsightType: String, Codable, CaseIterable {
    case reminder, pattern, encouragement, reflectionQuestion

    var label: String {
        switch self {
        case .reminder: return "Reminder"
        case .pattern: return "Pattern"
        case .encouragement: return "Encouragement"
        case .reflectionQuestion: return "Reflection"
        }
    }

    var icon: String {
        switch self {
        case .reminder: return "bubble.left"
        case .pattern: return "link"
        case .encouragement: return "star"
        case .reflectionQuestion: return "sparkles"
        }
    }
}

@Model
final class Insight {
    var id: UUID
    var type: String
    var content: String
    var empathyScore: Double
    var relatedMemoryIds: [String]
    var createdAt: Date
    var read: Bool

    init(type: InsightType, content: String, empathyScore: Double = 0.8, relatedMemoryIds: [String] = []) {
        self.id = UUID()
        self.type = type.rawValue
        self.content = content
        self.empathyScore = empathyScore
        self.relatedMemoryIds = relatedMemoryIds
        self.createdAt = Date()
        self.read = false
    }

    var typeEnum: InsightType {
        InsightType(rawValue: type) ?? .reflectionQuestion
    }
}

enum MemoryTier: String, Codable {
    case perceptual, reflective
}

enum EntityType: String, Codable {
    case event, emotion, theme, insight, person
}

@Model
final class MemoryNodeRecord {
    var id: UUID
    var tier: String
    var content: String
    var salience: Double
    var stickyScore: Double
    var sourceEntryId: String?
    var entityType: String
    var createdAt: Date
    var lastAccessed: Date
    var accessCount: Int
    /// Serialized keywords for lightweight semantic matching
    var keywords: [String]

    init(
        content: String,
        tier: MemoryTier = .perceptual,
        entityType: EntityType = .theme,
        sourceEntryId: String? = nil,
        salience: Double = 0.5,
        stickyScore: Double = 0.0
    ) {
        self.id = UUID()
        self.tier = tier.rawValue
        self.content = content
        self.salience = salience
        self.stickyScore = stickyScore
        self.sourceEntryId = sourceEntryId
        self.entityType = entityType.rawValue
        self.createdAt = Date()
        self.lastAccessed = Date()
        self.accessCount = 0
        self.keywords = MemoryNodeRecord.extractKeywords(content)
    }

    static func extractKeywords(_ text: String) -> [String] {
        let lowered = text.lowercased()
        let words = lowered.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 }
        return Array(Set(words)).prefix(20).map { $0 }
    }
}

@Model
final class MemoryEdgeRecord {
    var id: UUID
    var sourceId: String
    var targetId: String
    var relationship: String
    var weight: Double

    init(sourceId: String, targetId: String, relationship: String = "related_to", weight: Double = 0.5) {
        self.id = UUID()
        self.sourceId = sourceId
        self.targetId = targetId
        self.relationship = relationship
        self.weight = weight
    }
}
