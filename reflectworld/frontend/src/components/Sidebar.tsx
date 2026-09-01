"use client";

import { Entry } from "@/lib/api";

const MOOD_EMOJIS: Record<string, string> = {
  peaceful: "🌿",
  happy: "☀️",
  grateful: "🙏",
  contemplative: "🌙",
  anxious: "🌊",
  sad: "💧",
  hopeful: "🌱",
  tired: "😴",
};

function formatDate(dateStr: string): string {
  const d = new Date(dateStr);
  const now = new Date();
  const diff = now.getTime() - d.getTime();
  const days = Math.floor(diff / 86400000);

  if (days === 0) return "Today";
  if (days === 1) return "Yesterday";
  if (days < 7) return `${days} days ago`;
  return d.toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

function groupByDate(entries: Entry[]): Record<string, Entry[]> {
  const groups: Record<string, Entry[]> = {};
  for (const entry of entries) {
    const label = formatDate(entry.created_at);
    if (!groups[label]) groups[label] = [];
    groups[label].push(entry);
  }
  return groups;
}

interface SidebarProps {
  entries: Entry[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  onNew: () => void;
  search: string;
  onSearchChange: (s: string) => void;
}

export default function Sidebar({
  entries,
  selectedId,
  onSelect,
  onNew,
  search,
  onSearchChange,
}: SidebarProps) {
  const filtered = search
    ? entries.filter(
        (e) =>
          e.title.toLowerCase().includes(search.toLowerCase()) ||
          e.content.toLowerCase().includes(search.toLowerCase())
      )
    : entries;

  const groups = groupByDate(filtered);

  return (
    <aside className="w-64 min-w-[240px] bg-white border-r border-apple-border flex flex-col h-full">
      <div className="p-4 border-b border-apple-border">
        <div className="flex items-center justify-between mb-3">
          <h1 className="text-lg font-semibold text-apple-text">ReflectWorld</h1>
          <button
            onClick={onNew}
            className="w-8 h-8 rounded-lg bg-apple-accent text-white flex items-center justify-center hover:bg-blue-600 transition-colors text-lg leading-none"
            title="New entry"
          >
            +
          </button>
        </div>
        <input
          type="search"
          placeholder="Search entries..."
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          className="w-full px-3 py-2 text-sm bg-apple-bg rounded-lg border-none placeholder-apple-secondary"
        />
      </div>

      <div className="flex-1 overflow-y-auto scrollbar-thin p-2">
        {Object.entries(groups).map(([date, groupEntries]) => (
          <div key={date} className="mb-4">
            <p className="text-xs font-medium text-apple-secondary px-3 py-1 uppercase tracking-wide">
              {date}
            </p>
            {groupEntries.map((entry) => (
              <button
                key={entry.id}
                onClick={() => onSelect(entry.id)}
                className={`w-full text-left px-3 py-2.5 rounded-lg mb-0.5 transition-colors ${
                  selectedId === entry.id
                    ? "bg-apple-accent/10 text-apple-accent"
                    : "hover:bg-apple-hover text-apple-text"
                }`}
              >
                <div className="flex items-center gap-2">
                  {entry.mood && (
                    <span className="text-sm">{MOOD_EMOJIS[entry.mood] || "📝"}</span>
                  )}
                  <span className="text-sm font-medium truncate flex-1">
                    {entry.title || "Untitled"}
                  </span>
                  {entry.media_type !== "text" && (
                    <span className="text-xs text-apple-secondary">
                      {entry.media_type === "video" ? "🎥" : "🎙️"}
                    </span>
                  )}
                </div>
                <p className="text-xs text-apple-secondary truncate mt-0.5 pl-0">
                  {(entry.transcript || entry.content || "").slice(0, 60)}
                </p>
              </button>
            ))}
          </div>
        ))}
        {filtered.length === 0 && (
          <p className="text-sm text-apple-secondary text-center py-8">
            {search ? "No matching entries" : "Your journal awaits"}
          </p>
        )}
      </div>
    </aside>
  );
}
