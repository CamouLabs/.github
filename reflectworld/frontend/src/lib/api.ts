const API_BASE = "/api";

export interface Entry {
  id: string;
  title: string;
  content: string;
  media_type: string;
  media_path?: string;
  transcript?: string;
  mood?: string;
  tags: string[];
  created_at: string;
  updated_at: string;
  processed: number;
}

export interface Insight {
  id: string;
  type: string;
  content: string;
  empathy_score: number;
  related_memory_ids: string[];
  created_at: string;
  delivered: number;
  read: number;
}

export interface MemoryNode {
  id: string;
  tier: string;
  content: string;
  salience: number;
  sticky_score: number;
  entity_type: string;
  created_at: string;
  access_count: number;
}

export interface MemoryEdge {
  source_id: string;
  target_id: string;
  relationship: string;
  weight: number;
}

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, options);
  if (!res.ok) {
    const err = await res.text();
    throw new Error(err || res.statusText);
  }
  return res.json();
}

export async function getEntries(): Promise<Entry[]> {
  return request("/entries");
}

export async function getEntry(id: string): Promise<Entry> {
  return request(`/entries/${id}`);
}

export async function createEntry(data: {
  title?: string;
  content?: string;
  media_type?: string;
  mood?: string;
}): Promise<Entry> {
  return request("/entries", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });
}

export async function updateEntry(
  id: string,
  data: Partial<{ title: string; content: string; mood: string }>
): Promise<Entry> {
  return request(`/entries/${id}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });
}

export async function deleteEntry(id: string): Promise<void> {
  await request(`/entries/${id}`, { method: "DELETE" });
}

export async function processEntry(id: string): Promise<unknown> {
  return request(`/entries/${id}/process`, { method: "POST" });
}

export async function uploadMediaEntry(
  file: File,
  title?: string,
  mood?: string
): Promise<Entry> {
  const form = new FormData();
  form.append("file", file);
  if (title) form.append("title", title);
  if (mood) form.append("mood", mood);
  const res = await fetch(`${API_BASE}/media/create-entry`, { method: "POST", body: form });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

export async function getInsights(): Promise<Insight[]> {
  return request("/insights");
}

export async function generateInsights(): Promise<{ created: number; insights: Insight[] }> {
  return request("/insights/generate", { method: "POST" });
}

export async function markInsightRead(id: string): Promise<Insight> {
  return request(`/insights/${id}/read`, { method: "POST" });
}

export async function getMemoryGraph(): Promise<{
  nodes: MemoryNode[];
  edges: MemoryEdge[];
}> {
  return request("/memory/graph");
}

export async function searchMemories(q: string): Promise<
  Array<{ node_id: string; content: string; score: number; tier: string; entity_type: string }>
> {
  return request(`/memory/search?q=${encodeURIComponent(q)}`);
}

export async function getHealth(): Promise<{ status: string; llm_available: boolean }> {
  return request("/health");
}
