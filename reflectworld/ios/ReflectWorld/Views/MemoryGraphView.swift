import SwiftUI
import SwiftData

struct MemoryGraphView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var nodes: [MemoryNodeRecord]
    @Query private var edges: [MemoryEdgeRecord]

    var reflectiveNodes: [MemoryNodeRecord] {
        nodes.filter { $0.tier == MemoryTier.reflective.rawValue }
    }

    var perceptualNodes: [MemoryNodeRecord] {
        nodes.filter { $0.tier == MemoryTier.perceptual.rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    summaryHeader

                    if !reflectiveNodes.isEmpty {
                        memorySection(title: "Reflective Memories", nodes: reflectiveNodes, tint: .purple)
                    }

                    if !perceptualNodes.isEmpty {
                        memorySection(title: "Perceptual Memories", nodes: perceptualNodes.prefix(20).map { $0 }, tint: .blue)
                    }

                    if nodes.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "brain.head.profile")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Your memory graph grows as you journal.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Memory Graph")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var summaryHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(nodes.count) memories")
                    .font(.headline)
                Text("\(edges.count) connections")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func memorySection(title: String, nodes: [MemoryNodeRecord], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(nodes) { node in
                let linkCount = edges.filter { $0.sourceId == node.id.uuidString || $0.targetId == node.id.uuidString }.count
                VStack(alignment: .leading, spacing: 6) {
                    Text(node.content)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 12) {
                        Text("Salience \(Int(node.salience * 100))%")
                        Text("Sticky \(Int(node.stickyScore * 100))%")
                        if linkCount > 0 {
                            Text("\(linkCount) links")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(tint.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
