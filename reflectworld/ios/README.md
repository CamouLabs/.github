# ReflectWorld iOS

Native SwiftUI iPhone app — open in Xcode on macOS.

## Requirements

- Xcode 15+
- iOS 17+ (SwiftData)
- iPhone (portrait)

## Open & Run

```bash
open reflectworld/ios/ReflectWorld.xcodeproj
```

1. Select your iPhone or Simulator (iPhone 15+ recommended)
2. Set your Development Team in Signing & Capabilities
3. Press Run (⌘R)

## Features (on-device)

| Feature | Technology |
|---------|------------|
| Journal list & editor | SwiftUI, Apple Notes-style grouped list |
| Voice notes | AVAudioRecorder + Speech framework |
| Video notes | PhotosPicker + AVAssetExportSession |
| Transcription | On-device SFSpeechRecognizer |
| Memory graph | SwiftData + keyword similarity |
| Insights | Extract → Condense → Reflect pipeline |
| Privacy | All data local in SwiftData |

## Optional Backend

The Python FastAPI backend (`reflectworld/backend/`) can enhance transcription and insights with Whisper + LLM. Configure in app via UserDefaults key `reflectworld_api_base` or extend Settings UI.

## Project Structure

```
ios/
  ReflectWorld.xcodeproj
  ReflectWorld/
    ReflectWorldApp.swift
    Models/JournalModels.swift
    Services/
      SpeechTranscriptionService.swift
      AudioRecorderService.swift
      MemoryGraphService.swift
      ProcessingPipeline.swift
      APIClient.swift
    Views/
      ContentView.swift
      EntryListView.swift
      EntryEditorView.swift
      InsightsSheet.swift
      MemoryGraphView.swift
```

## Permissions

The app requests:
- **Microphone** — voice journal entries
- **Speech Recognition** — on-device transcription
- **Photo Library** — import video notes
