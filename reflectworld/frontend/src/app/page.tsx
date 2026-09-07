"use client";

import { useCallback, useEffect, useState } from "react";
import {
  Entry,
  Insight,
  createEntry,
  generateInsights,
  getEntries,
  getHealth,
  getInsights,
  getMemoryGraph,
  MemoryEdge,
  MemoryNode,
} from "@/lib/api";
import EntryEditor from "@/components/EntryEditor";
import InsightsPanel from "@/components/InsightsPanel";
import MemoryView from "@/components/MemoryView";
import Sidebar from "@/components/Sidebar";

export default function Home() {
  const [entries, setEntries] = useState<Entry[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [insights, setInsights] = useState<Insight[]>([]);
  const [memoryNodes, setMemoryNodes] = useState<MemoryNode[]>([]);
  const [memoryEdges, setMemoryEdges] = useState<MemoryEdge[]>([]);
  const [search, setSearch] = useState("");
  const [memoryOpen, setMemoryOpen] = useState(false);
  const [generating, setGenerating] = useState(false);
  const [llmAvailable, setLlmAvailable] = useState(false);

  const selectedEntry = entries.find((e) => e.id === selectedId) || null;

  const refresh = useCallback(async () => {
    try {
      const [e, i, g, h] = await Promise.all([
        getEntries(),
        getInsights(),
        getMemoryGraph(),
        getHealth(),
      ]);
      setEntries(e);
      setInsights(i);
      setMemoryNodes(g.nodes);
      setMemoryEdges(g.edges);
      setLlmAvailable(h.llm_available);
    } catch {
      // Backend may not be ready yet
    }
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const handleNew = async () => {
    const entry = await createEntry({ title: "", content: "", media_type: "text" });
    setEntries((prev) => [entry, ...prev]);
    setSelectedId(entry.id);
  };

  const handleUpdate = (entry: Entry) => {
    setEntries((prev) => prev.map((e) => (e.id === entry.id ? entry : e)));
    if (!selectedId) setSelectedId(entry.id);
  };

  const handleProcessed = () => refresh();

  const handleGenerateInsights = async () => {
    setGenerating(true);
    try {
      await generateInsights();
      const i = await getInsights();
      setInsights(i);
    } finally {
      setGenerating(false);
    }
  };

  const handleInsightRead = (id: string) => {
    setInsights((prev) =>
      prev.map((ins) => (ins.id === id ? { ...ins, read: 1 } : ins))
    );
  };

  return (
    <div className="h-screen flex flex-col">
      <header className="h-12 bg-white/80 backdrop-blur border-b border-apple-border flex items-center justify-between px-4 shrink-0">
        <div className="flex items-center gap-2">
          <span className="text-sm text-apple-secondary hidden sm:inline">
            Your inner world model
          </span>
        </div>
        <div className="flex items-center gap-3">
          {llmAvailable && (
            <span className="text-xs text-green-600 bg-green-50 px-2 py-0.5 rounded-full">
              AI enhanced
            </span>
          )}
          <button
            onClick={() => setMemoryOpen(true)}
            className="text-sm text-apple-accent hover:underline"
          >
            Memory Graph ({memoryNodes.length})
          </button>
        </div>
      </header>

      <div className="flex-1 flex overflow-hidden">
        <Sidebar
          entries={entries}
          selectedId={selectedId}
          onSelect={setSelectedId}
          onNew={handleNew}
          search={search}
          onSearchChange={setSearch}
        />
        <EntryEditor
          entry={selectedEntry}
          onUpdate={handleUpdate}
          onProcessed={handleProcessed}
        />
        <InsightsPanel
          insights={insights}
          onRefresh={handleGenerateInsights}
          onInsightRead={handleInsightRead}
          generating={generating}
        />
      </div>

      <MemoryView
        nodes={memoryNodes}
        edges={memoryEdges}
        open={memoryOpen}
        onClose={() => setMemoryOpen(false)}
      />
    </div>
  );
}
