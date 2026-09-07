# ReflectWorld

A native **iPhone app** for daily journaling that builds a compassionate world model of your inner life. Voice and video notes are transcribed on-device, condensed into a graph-structured memory, and reflected back as gentle insights over time.

## iPhone App (primary)

SwiftUI native app with Apple Notes-inspired UI.

```bash
open reflectworld/ios/ReflectWorld.xcodeproj
```

Requires Xcode 15+, iOS 17+, and an iPhone or Simulator. See [ios/README.md](ios/README.md).

### On-device features

- Grouped entry list and editor (Apple Notes style)
- Voice notes via microphone + on-device Speech transcription
- Video notes via photo library import + audio extraction
- Memory graph with perceptual and reflective tiers
- Empathic insights (reminders, patterns, encouragement, reflection questions)
- Extract → Condense → Reflect pipeline (GCAgent / ∞-Video inspired)
- All data stored locally with SwiftData

### Permissions

Microphone, Speech Recognition, and Photo Library (for video import).

## Optional Python Backend

The FastAPI backend (`backend/`) provides Whisper transcription and optional LLM-enhanced insights when you run a companion server. The iPhone app works fully without it.

```bash
cd backend && pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Set `OPENAI_API_KEY` in `backend/.env` for LLM enhancement.

## Architecture

See [PLAN.md](PLAN.md) for research foundations and critique log.

```
iPhone (SwiftUI + SwiftData)
  ├── Speech / AVFoundation (voice & video)
  ├── Memory graph (on-device)
  └── Processing pipeline

Optional: FastAPI backend for Whisper + LiteLLM
```

## Research Foundations

| Source | Application |
|--------|-------------|
| ∞-Video (ICML 2025) | Sticky memory salience |
| GCAgent | Extract → Condense → Reflect |
| VideoARM | Hierarchical memory tiers |
| MemGPT (Stanford CS329A) | Tiered memory |
| Compass Compound AI | On-device vs server paths |

## Privacy

All journal data stays on your iPhone. No cloud sync by default. Optional backend is user-controlled.

## Web prototype

A Next.js web prototype exists in `frontend/` for development reference; the shipped product is the native iOS app.
