import SwiftUI

struct InsightsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let insights: [Insight]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if insights.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Insights will appear as you journal and reflect.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(insights) { insight in
                            InsightCard(insight: insight) {
                                insight.read = true
                                try? modelContext.save()
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct InsightCard: View {
    let insight: Insight
    let onRead: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(insight.typeEnum.label, systemImage: insight.typeEnum.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentColor)
                Spacer()
                if !insight.read {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                }
            }

            Text(insight.content)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(insight.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .opacity(insight.read ? 0.7 : 1)
        .onTapGesture {
            if !insight.read { onRead() }
        }
    }

    private var accentColor: Color {
        switch insight.typeEnum {
        case .reminder: return .purple
        case .pattern: return .blue
        case .encouragement: return .orange
        case .reflectionQuestion: return .green
        }
    }
}
