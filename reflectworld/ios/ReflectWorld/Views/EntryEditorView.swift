import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

struct EntryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var entry: JournalEntry

    @StateObject private var audioRecorder = AudioRecorderService()
    @StateObject private var speechService = SpeechTranscriptionService()

    @State private var isProcessing = false
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TextField("Title", text: $entry.title)
                    .font(.title2.weight(.semibold))
                    .onChange(of: entry.title) { _, _ in touchEntry() }

                MoodPickerView(selectedMood: Binding(
                    get: { entry.moodEnum },
                    set: { entry.mood = $0?.rawValue; touchEntry() }
                ))

                if let transcript = entry.transcript, entry.mediaTypeEnum != .text {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TRANSCRIPT")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(transcript)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                TextEditor(text: $entry.content)
                    .font(.body)
                    .frame(minHeight: 200)
                    .scrollContentBackground(.hidden)
                    .onChange(of: entry.content) { _, _ in touchEntry() }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                voiceButton
                videoPicker
                Spacer()
                reflectButton
            }
        }
        .task {
            await speechService.requestAuthorization()
        }
    }

    private var voiceButton: some View {
        Button {
            if audioRecorder.isRecording {
                Task { await handleVoiceStop() }
            } else {
                do {
                    try audioRecorder.startRecording()
                } catch {
                    errorMessage = "Could not start recording."
                }
            }
        } label: {
            if audioRecorder.isRecording {
                HStack(spacing: 6) {
                    Image(systemName: "stop.circle.fill")
                        .foregroundStyle(.red)
                    Text(formatDuration(audioRecorder.recordingDuration))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.red)
                }
            } else {
                Image(systemName: "mic.circle")
            }
        }
        .disabled(isProcessing || speechService.isTranscribing)
    }

    private var videoPicker: some View {
        PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
            Image(systemName: "video.circle")
        }
        .disabled(isProcessing || speechService.isTranscribing)
        .onChange(of: selectedVideoItem) { _, item in
            guard let item else { return }
            Task { await handleVideoImport(item) }
        }
    }

    private var reflectButton: some View {
        Button {
            Task { await runReflect() }
        } label: {
            if isProcessing {
                ProgressView()
            } else {
                Text(entry.processed ? "Re-reflect" : "Reflect & Remember")
                    .fontWeight(.medium)
            }
        }
        .disabled(isProcessing || entry.displayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func touchEntry() {
        entry.updatedAt = Date()
        try? modelContext.save()
    }

    private func handleVoiceStop() async {
        guard let url = audioRecorder.stopRecording() else { return }
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            let transcript = try await speechService.transcribeAudio(at: url)
            entry.mediaType = MediaType.audio.rawValue
            entry.mediaPath = url.path
            entry.transcript = transcript
            if entry.content.isEmpty { entry.content = transcript }
            entry.title = entry.title.isEmpty ? "Voice note" : entry.title
            touchEntry()

            let pipeline = ProcessingPipeline(modelContext: modelContext)
            await pipeline.process(entry: entry)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleVideoImport(_ item: PhotosPickerItem) async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false; selectedVideoItem = nil }

        do {
            guard let movie = try await item.loadTransferable(type: VideoFile.self) else { return }
            let dest = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("video-\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: movie.url, to: dest)

            let transcript = try await speechService.transcribeVideo(at: dest)
            entry.mediaType = MediaType.video.rawValue
            entry.mediaPath = dest.path
            entry.transcript = transcript
            if entry.content.isEmpty { entry.content = transcript }
            entry.title = entry.title.isEmpty ? "Video note" : entry.title
            touchEntry()

            let pipeline = ProcessingPipeline(modelContext: modelContext)
            await pipeline.process(entry: entry)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func runReflect() async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }
        touchEntry()
        let pipeline = ProcessingPipeline(modelContext: modelContext)
        await pipeline.process(entry: entry)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

/// Transferable wrapper for video files from PhotosPicker
struct VideoFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: dest)
            return Self(url: dest)
        }
    }
}

struct MoodPickerView: View {
    @Binding var selectedMood: Mood?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Mood.allCases) { mood in
                    Button {
                        selectedMood = selectedMood == mood ? nil : mood
                    } label: {
                        HStack(spacing: 4) {
                            Text(mood.emoji)
                            Text(mood.label)
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            selectedMood == mood
                                ? Color.accentColor.opacity(0.15)
                                : Color(.secondarySystemGroupedBackground)
                        )
                        .foregroundStyle(selectedMood == mood ? Color.accentColor : .primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
