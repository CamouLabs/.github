import Foundation
import SwiftData

struct ExtractedEntities {
    var emotions: [String]
    var themes: [String]
    var segments: [String]
}

@MainActor
final class ProcessingPipeline {
    private let modelContext: ModelContext
    private let graph: MemoryGraphService

    private static let emotionWords: [String: Double] = [
        "happy": 0.8, "joy": 0.9, "excited": 0.7, "grateful": 0.8, "peaceful": 0.7,
        "sad": 0.7, "anxious": 0.6, "worried": 0.5, "angry": 0.6, "frustrated": 0.5,
        "overwhelmed": 0.7, "tired": 0.4, "hopeful": 0.8, "proud": 0.8, "lonely": 0.6,
        "calm": 0.7, "stressed": 0.5, "loving": 0.9, "scared": 0.6, "content": 0.7,
    ]

    private static let themePatterns: [(String, String)] = [
        ("work", "work|job|career|boss|meeting|project"),
        ("family", "family|mom|dad|parent|sibling|child|partner"),
        ("health", "health|exercise|sleep|tired|energy|walk|gym"),
        ("creativity", "create|art|write|music|design|build|idea"),
        ("relationships", "friend|relationship|love|connect|social"),
        ("growth", "learn|grow|improve|change|progress|goal|habit"),
        ("nature", "nature|outdoor|garden|tree|sky|sun|rain"),
    ]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.graph = MemoryGraphService(modelContext: modelContext)
    }

    func process(entry: JournalEntry) async -> ProcessResult {
        let text = entry.displayText
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ProcessResult(nodesCreated: 0, edgesCreated: 0, insightCreated: false)
        }

        let entities = extractEntities(from: text)
        let related = graph.search(query: String(text.prefix(200)), topK: 3)
        let condensed = condense(text: text, entities: entities, related: related)
        let emotionalWeight = entities.emotions.map { Self.emotionWords[$0] ?? 0.5 }.max() ?? 0.0

        var nodesCreated = 0
        var edgesCreated = 0

        var segmentNodeIds: [String] = []
        for segment in entities.segments.prefix(5) {
            let node = graph.addNode(
                content: segment,
                tier: .perceptual,
                entityType: .event,
                sourceEntryId: entry.id.uuidString,
                salience: 0.3,
                stickyScore: emotionalWeight * 0.5
            )
            segmentNodeIds.append(node.id.uuidString)
            nodesCreated += 1
        }

        let reflectiveNode = graph.addNode(
            content: condensed,
            tier: .reflective,
            entityType: .insight,
            sourceEntryId: entry.id.uuidString,
            salience: 0.5 + emotionalWeight * 0.3,
            stickyScore: emotionalWeight
        )
        nodesCreated += 1

        for segId in segmentNodeIds {
            graph.addEdge(sourceId: segId, targetId: reflectiveNode.id.uuidString, relationship: "evolved_from", weight: 0.7)
            edgesCreated += 1
        }

        for theme in entities.themes.prefix(5) {
            let themeNode = graph.addNode(
                content: "Theme: \(theme)",
                tier: .perceptual,
                entityType: .theme,
                sourceEntryId: entry.id.uuidString,
                salience: 0.4,
                stickyScore: 0.0
            )
            graph.addEdge(
                sourceId: reflectiveNode.id.uuidString,
                targetId: themeNode.id.uuidString,
                relationship: "related_to",
                weight: 0.6
            )
            nodesCreated += 1
            edgesCreated += 1
        }

        for rel in related where rel.score > 0.5 {
            graph.addEdge(
                sourceId: reflectiveNode.id.uuidString,
                targetId: rel.nodeId,
                relationship: "reminds_of",
                weight: rel.score
            )
            edgesCreated += 1
        }

        var insightCreated = false
        if insightsTodayCount() < 3 {
            let insight = InsightGenerator.generate(
                text: text,
                entities: entities,
                related: related,
                condensed: condensed,
                memoryId: reflectiveNode.id.uuidString
            )
            modelContext.insert(insight)
            insightCreated = true
        }

        graph.consolidate()
        entry.processed = true
        entry.updatedAt = Date()
        try? modelContext.save()

        return ProcessResult(
            nodesCreated: nodesCreated,
            edgesCreated: edgesCreated,
            insightCreated: insightCreated
        )
    }

    private func extractEntities(from text: String) -> ExtractedEntities {
        let lowered = text.lowercased()
        var emotions: [String] = []
        for (word, _) in Self.emotionWords where lowered.contains(word) {
            emotions.append(word)
        }

        var themes: [String] = []
        for (theme, pattern) in Self.themePatterns {
            if lowered.range(of: pattern, options: .regularExpression) != nil {
                themes.append(theme)
            }
        }

        let segments = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 10 }

        return ExtractedEntities(emotions: emotions, themes: themes, segments: segments)
    }

    private func condense(text: String, entities: ExtractedEntities, related: [MemorySearchResult]) -> String {
        let emotionStr = entities.emotions.prefix(3).joined(separator: ", ")
        let themeStr = entities.themes.prefix(3).joined(separator: ", ")
        let snippet = String(text.prefix(150))
        let suffix = text.count > 150 ? "..." : ""

        if !emotionStr.isEmpty && !themeStr.isEmpty {
            return "You reflected on \(themeStr), feeling \(emotionStr). \(snippet)\(suffix)"
        }
        if !related.isEmpty {
            return "This connects to something you've written before. \(snippet)\(suffix)"
        }
        return "You took a moment to reflect. \(snippet)\(suffix)"
    }

    private func insightsTodayCount() -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let descriptor = FetchDescriptor<Insight>(
            predicate: #Predicate { $0.createdAt >= startOfDay }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}

struct ProcessResult {
    let nodesCreated: Int
    let edgesCreated: Int
    let insightCreated: Bool
}

enum InsightGenerator {
    static func generate(
        text: String,
        entities: ExtractedEntities,
        related: [MemorySearchResult],
        condensed: String,
        memoryId: String
    ) -> Insight {
        if let top = related.first, top.score > 0.6 {
            return Insight(
                type: .pattern,
                content: "It seems like this connects to something you've reflected on before — "
                    + "about \(top.content.prefix(80)). Patterns like this can reveal what truly matters to you.",
                empathyScore: 0.85,
                relatedMemoryIds: [memoryId]
            )
        }

        if let emotion = entities.emotions.first {
            return Insight(
                type: .reflectionQuestion,
                content: "You mentioned feeling \(emotion). What would it feel like to sit with that feeling "
                    + "for a moment, without needing to change it?",
                empathyScore: 0.8,
                relatedMemoryIds: [memoryId]
            )
        }

        if let theme = entities.themes.first {
            return Insight(
                type: .encouragement,
                content: "Taking time to reflect on \(theme) shows real self-awareness. "
                    + "That kind of honesty with yourself is a gift.",
                empathyScore: 0.85,
                relatedMemoryIds: [memoryId]
            )
        }

        return Insight(
            type: .reflectionQuestion,
            content: "What stood out to you most as you wrote this? Sometimes the first thing we mention "
                + "holds more meaning than we realize.",
            empathyScore: 0.75,
            relatedMemoryIds: [memoryId]
        )
    }
}
