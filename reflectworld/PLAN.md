# ReflectWorld — Detailed Architecture Plan (v2, post-5 critiques)

> A daily journaling application that builds a compassionate world model of the user's inner life.

---

## Critique Log

### Critique 1: Scope & Feasibility
**Issues found:**
- Phase 1-6 is too ambitious for a single session; need to prioritize MVP that demonstrates core value
- faster-whisper + sentence-transformers are heavy dependencies; need graceful fallbacks
- D3 graph visualization is complex; defer to simple list view first
- LiteLLM requires API keys; must work without them for demo

**Fixes applied:**
- MVP scope: text + voice entries, basic transcription, memory graph, rule-based insights, optional LLM enhancement
- Fallback transcription: if Whisper unavailable, accept manual transcript paste
- Graph viz: simple node list with connections, not full D3
- Rule-based insight generation as default; LLM enhances when API key present

### Critique 2: Memory Graph Design
**Issues found:**
- Three-tier HM³ is over-engineered for MVP; two tiers sufficient (raw + condensed)
- Salience algorithm too complex without real usage data
- Cartridge concept adds abstraction without clear MVP benefit
- Graph edges need simpler relationship types

**Fixes applied:**
- Two tiers: `perceptual` (raw transcript chunks) and `reflective` (condensed insights)
- Simple salience: `access_count * 0.1 + emotional_weight`
- Removed cartridge abstraction; condensed content stored directly on reflective nodes
- Edge types simplified to: `related_to`, `evolved_from`, `contradicts`, `reminds_of`

### Critique 3: Agent Orchestration
**Issues found:**
- 4 separate agent classes is over-abstraction for MVP
- Selection stage (LVAgent) unnecessary without multiple MLLMs
- Compass Elastico controller needs load monitoring infrastructure we don't have
- Perception and Action agents overlap significantly

**Fixes applied:**
- Single `ProcessingPipeline` class with 3 stages: Extract → Condense → Reflect
- Config switching simplified: `local` (rules + embeddings) vs `llm` (when API key available)
- Merged Perception + Action into `ExtractStage`
- Reflection stage runs after every entry, not just on query

### Critique 4: UI/UX
**Issues found:**
- Three-column layout breaks on mobile
- MediaRecorder for video is complex (browser codec issues)
- Chat interface is a separate feature that dilutes journaling focus
- Mood picker needs predefined options, not freeform

**Fixes applied:**
- Responsive: sidebar collapses on mobile; insights panel as bottom sheet
- Voice recording primary; video as file upload (not live recording)
- Chat deferred to v2; focus on insights panel for MVP
- Mood picker: 8 predefined moods with emoji icons

### Critique 5: Data & Privacy
**Issues found:**
- No migration strategy for SQLite schema changes
- Upload directory not secured against path traversal
- No file size limits on media uploads
- Insights could feel creepy if too specific; need tone calibration

**Fixes applied:**
- SQLite with simple version tracking; auto-create on first run
- Upload validation: max 100MB, allowed extensions only, sanitized filenames
- Insights use hedged language: "It seems like..." not "You always..."
- Insight frequency capped: max 3 per day to avoid overwhelm

---

## 1. Vision & Design Principles

**Core metaphor**: A world model for humans — not surveillance, but companionship.

**UI inspiration**: Apple Notes — clean sidebar, soft typography, minimal chrome.

**Orchestration**: Compound AI pipeline with local-first processing, optional LLM enhancement.

---

## 2. Research Foundations

| Source | Technique | Application |
|---|---|---|
| ∞-Video (ICML 2025) | Sticky LTM consolidation | Salience-weighted memory nodes |
| GCAgent | Episodic memory + PAR loop | Extract→Condense→Reflect pipeline |
| VideoARM | Hierarchical memory tiers | Perceptual + Reflective tiers |
| MemGPT (CS329A) | Tiered memory | Working buffer + archival graph |
| Generative Agents | Observation→Reflection | Post-entry reflection synthesis |
| Compass | Config switching | local vs llm processing paths |

---

## 3. MVP Architecture

```
Frontend (Next.js)          Backend (FastAPI)
┌─────────────────┐         ┌──────────────────────────┐
│ Sidebar         │  REST   │ Entry CRUD               │
│ EntryEditor     │◄───────►│ Media Upload + Whisper   │
│ InsightsPanel   │         │ Memory Graph (NetworkX)  │
│ MediaRecorder   │         │ Processing Pipeline      │
└─────────────────┘         │ Insight Generator        │
                            └──────────────────────────┘
```

---

## 4. Processing Pipeline (3 stages)

### Extract Stage
- Input: transcript (from Whisper or text)
- Output: entities (people, emotions, themes), event segments
- Method: LLM if available, else keyword/regex extraction

### Condense Stage
- Input: entities + segments + existing graph context
- Output: new perceptual nodes, updated reflective nodes
- Method: LLM summarization or template-based condensation

### Reflect Stage
- Input: updated graph state
- Output: cross-memory connections, new insights
- Method: graph clustering + empathic prompt (or rule-based patterns)

---

## 5. Tech Stack (MVP)

| Component | Choice |
|---|---|
| Frontend | Next.js 14, Tailwind, TypeScript |
| Backend | FastAPI, Python 3.12 |
| DB | SQLite via aiosqlite |
| Graph | NetworkX (in-memory, persisted as JSON) |
| Transcription | faster-whisper (base model) |
| Embeddings | sentence-transformers/all-MiniLM-L6-v2 |
| LLM | LiteLLM (optional, env OPENAI_API_KEY) |
| Media | ffmpeg for video→audio |

---

## 6. API Endpoints (MVP)

```
POST   /api/entries              Create entry
GET    /api/entries              List entries
GET    /api/entries/{id}         Get entry
PUT    /api/entries/{id}         Update entry
DELETE /api/entries/{id}         Delete entry
POST   /api/media/upload         Upload media
POST   /api/entries/{id}/process Trigger processing pipeline
GET    /api/memory/graph         Graph nodes + edges
GET    /api/memory/search?q=     Semantic search
GET    /api/insights             List insights
POST   /api/insights/generate    Generate insights
POST   /api/insights/{id}/read   Mark read
GET    /api/health               Health check
```

---

## 7. UI Components (MVP)

- `Sidebar` — entry list, date groups, search, new button
- `EntryEditor` — title, content, mood picker, voice record button, file upload
- `InsightsPanel` — insight cards with type badges
- `MemoryView` — simple node list with connection indicators
- `MediaRecorder` — voice recording via MediaRecorder API

---

## 8. File Structure

```
reflectworld/
├── PLAN.md
├── README.md
├── backend/
│   ├── main.py
│   ├── requirements.txt
│   ├── config.py
│   ├── database.py
│   ├── models/schemas.py
│   ├── services/
│   │   ├── transcription.py
│   │   ├── memory_graph.py
│   │   ├── embeddings.py
│   │   ├── pipeline.py
│   │   └── insights.py
│   └── api/
│       ├── entries.py
│       ├── media.py
│       ├── memory.py
│       └── insights.py
├── frontend/
│   ├── package.json
│   ├── next.config.js
│   ├── tailwind.config.js
│   ├── postcss.config.js
│   ├── tsconfig.json
│   └── src/
│       ├── app/
│       │   ├── layout.tsx
│       │   ├── page.tsx
│       │   └── globals.css
│       ├── components/
│       │   ├── Sidebar.tsx
│       │   ├── EntryEditor.tsx
│       │   ├── InsightsPanel.tsx
│       │   ├── MediaRecorder.tsx
│       │   └── MemoryView.tsx
│       └── lib/api.ts
├── data/
└── scripts/start.sh
```
