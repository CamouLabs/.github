import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \Insight.createdAt, order: .reverse) private var insights: [Insight]

    @State private var searchText = ""
    @State private var showInsights = false
    @State private var showMemoryGraph = false
    @State private var navigationPath = NavigationPath()

    var filteredEntries: [JournalEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            ($0.transcript?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            EntryListView(
                entries: filteredEntries,
                searchText: $searchText,
                onNewEntry: createNewEntry
            )
            .navigationTitle("ReflectWorld")
            .navigationDestination(for: UUID.self) { entryId in
                if let entry = entries.first(where: { $0.id == entryId }) {
                    EntryEditorView(entry: entry)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showMemoryGraph = true
                    } label: {
                        Image(systemName: "point.3.connected.trianglepath.dotted")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showInsights = true
                        } label: {
                            Image(systemName: "sparkles")
                        }
                        Button(action: createNewEntry) {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
            }
            .sheet(isPresented: $showInsights) {
                InsightsSheet(insights: insights)
            }
            .sheet(isPresented: $showMemoryGraph) {
                MemoryGraphView()
            }
        }
    }

    private func createNewEntry() {
        let entry = JournalEntry()
        modelContext.insert(entry)
        try? modelContext.save()
        navigationPath.append(entry.id)
    }
}

struct WelcomeView: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.pages")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Welcome to ReflectWorld")
                .font(.title2.weight(.semibold))
            Text("Your compassionate inner world model")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("New Entry", action: onCreate)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
