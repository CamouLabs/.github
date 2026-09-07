import Foundation
import SwiftData

struct MemorySearchResult {
    let nodeId: String
    let content: String
    let score: Double
    let tier: String
    let entityType: String
}

@MainActor
final class MemoryGraphService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func allNodes() -> [MemoryNodeRecord] {
        let descriptor = FetchDescriptor<MemoryNodeRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func allEdges() -> [MemoryEdgeRecord] {
        let descriptor = FetchDescriptor<MemoryEdgeRecord>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func search(query: String, topK: Int = 5) -> [MemorySearchResult] {
        let queryKeywords = Set(MemoryNodeRecord.extractKeywords(query))
        guard !queryKeywords.isEmpty else { return [] }

        let nodes = allNodes()
        var results: [MemorySearchResult] = []

        for node in nodes {
            let nodeKeywords = Set(node.keywords)
            let intersection = queryKeywords.intersection(nodeKeywords)
            let union = queryKeywords.union(nodeKeywords)
            let score = union.isEmpty ? 0 : Double(intersection.count) / Double(union.count)

            if score > 0.1 {
                touch(node)
                results.append(MemorySearchResult(
                    nodeId: node.id.uuidString,
                    content: node.content,
                    score: score,
                    tier: node.tier,
                    entityType: node.entityType
                ))
            }
        }

        return results.sorted { $0.score > $1.score }.prefix(topK).map { $0 }
    }

    func addNode(
        content: String,
        tier: MemoryTier,
        entityType: EntityType,
        sourceEntryId: String?,
        salience: Double,
        stickyScore: Double
    ) -> MemoryNodeRecord {
        let node = MemoryNodeRecord(
            content: content,
            tier: tier,
            entityType: entityType,
            sourceEntryId: sourceEntryId,
            salience: salience,
            stickyScore: stickyScore
        )
        modelContext.insert(node)
        return node
    }

    func addEdge(sourceId: String, targetId: String, relationship: String, weight: Double) {
        let edge = MemoryEdgeRecord(
            sourceId: sourceId,
            targetId: targetId,
            relationship: relationship,
            weight: weight
        )
        modelContext.insert(edge)
    }

    func touch(_ node: MemoryNodeRecord) {
        node.accessCount += 1
        node.lastAccessed = Date()
        node.stickyScore = min(1.0, node.stickyScore + 0.1 * (1 - node.stickyScore))
    }

    func consolidate() {
        let perceptual = allNodes().filter { $0.tier == MemoryTier.perceptual.rawValue }
        var mergedIds: Set<String> = []

        for node in perceptual {
            if mergedIds.contains(node.id.uuidString) { continue }
            let similar = search(query: node.content, topK: 5)
                .filter { $0.nodeId != node.id.uuidString && $0.score >= 0.5 }

            for sim in similar {
                if let target = allNodes().first(where: { $0.id.uuidString == sim.nodeId }),
                   target.tier == MemoryTier.perceptual.rawValue,
                   !mergedIds.contains(target.id.uuidString) {
                    node.content = "\(node.content) | \(target.content)"
                    node.salience = max(node.salience, target.salience)
                    node.stickyScore = max(node.stickyScore, target.stickyScore)
                    node.keywords = MemoryNodeRecord.extractKeywords(node.content)
                    mergedIds.insert(target.id.uuidString)
                    modelContext.delete(target)
                }
            }
        }

        for node in allNodes() {
            if node.tier == MemoryTier.perceptual.rawValue && node.stickyScore > 0.6 {
                node.tier = MemoryTier.reflective.rawValue
                node.salience = min(1.0, node.salience + 0.2)
            }
        }
    }
}
