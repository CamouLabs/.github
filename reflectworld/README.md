# ReflectWorld

A daily journaling application that builds a compassionate world model of your inner life. Voice and video notes become condensed, graph-structured memory that agents reason over to offer empathic reflection and timely insights.

## Features

- **Apple Notes-inspired UI** — clean sidebar, minimal editor, soft aesthetics
- **Voice & video journaling** — record voice notes or upload audio/video; local Whisper transcription
- **Memory graph** — perceptual and reflective memory tiers with semantic connections
- **Empathic insights** — gentle reminders, pattern recognition, encouragement, reflection questions
- **Research-backed pipeline** — Extract → Condense → Reflect (GCAgent, ∞-Video, MemGPT-inspired)

## Architecture

See [PLAN.md](PLAN.md) for the full architecture plan with research citations and critique log.

```
Frontend (Next.js)  ←→  Backend (FastAPI)
                            ├── Whisper transcription
                            ├── Memory graph (NetworkX)
                            ├── Embeddings (sentence-transformers)
                            └── Processing pipeline (optional LiteLLM)
```

## Quick Start

```bash
chmod +x scripts/start.sh
./scripts/start.sh
```

Or manually:

```bash
# Backend
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000

# Frontend
cd frontend
npm install
npm run dev
```

Open http://localhost:3000

## Optional: LLM Enhancement

Set `OPENAI_API_KEY` in `backend/.env` for AI-enhanced entity extraction, condensation, and insights:

```bash
echo "OPENAI_API_KEY=sk-..." > backend/.env
```

Without an API key, the app works fully with rule-based extraction and empathic templates.

## Research Foundations

| Source | Application |
|--------|-------------|
| ∞-Video (ICML 2025) | Sticky memory salience consolidation |
| GCAgent | Extract → Condense → Reflect pipeline |
| VideoARM | Hierarchical memory tiers |
| LVAgent | Multi-stage agent orchestration |
| MemGPT (Stanford CS329A) | Tiered memory architecture |
| Generative Agents | Observation → Reflection synthesis |
| Compass Compound AI | Local vs LLM config switching |

## Privacy

All data stored locally (SQLite + filesystem). No cloud sync. LLM calls optional.
