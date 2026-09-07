import SwiftUI

struct EntryListView: View {
    let entries: [JournalEntry]
    @Binding var searchText: String
    let onNewEntry: () -> Void

    var groupedEntries: [(String, [JournalEntry])] {
        let grouped = Dictionary(grouping: entries) { entry -> String in
            DateFormatters.sectionLabel(for: entry.createdAt)
        }
        return grouped.sorted { lhs, rhs in
            guard let l = lhs.1.first?.createdAt, let r = rhs.1.first?.createdAt else { return false }
            return l > r
        }
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView {
                    Label("No Entries", systemImage: "book.pages")
                } description: {
                    Text("Tap + to start journaling")
                } actions: {
                    Button("New Entry", action: onNewEntry)
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(groupedEntries, id: \.0) { section, sectionEntries in
                        Section(section) {
                            ForEach(sectionEntries) { entry in
                                NavigationLink(value: entry.id) {
                                    EntryRowView(entry: entry)
                                }
                            }
                            .onDelete { offsets in
                                // SwiftData deletion would need modelContext — handled in parent if needed
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .searchable(text: $searchText, prompt: "Search entries")
    }
}

struct EntryRowView: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if let mood = entry.moodEnum {
                    Text(mood.emoji)
                        .font(.caption)
                }
                Text(entry.title.isEmpty ? "Untitled" : entry.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Spacer()
                if entry.mediaTypeEnum != .text {
                    Image(systemName: entry.mediaTypeEnum == .video ? "video" : "mic")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(entry.displayText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}

enum DateFormatters {
    static func sectionLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days < 7 { return "\(days) days ago" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
