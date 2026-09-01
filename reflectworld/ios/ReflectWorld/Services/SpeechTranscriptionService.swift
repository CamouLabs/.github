import AVFoundation
import Foundation
import Speech

@MainActor
final class SpeechTranscriptionService: ObservableObject {
    @Published var isTranscribing = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.authorizationStatus = status
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }

    func transcribeAudio(at url: URL) async throws -> String {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable
        }

        isTranscribing = true
        defer { isTranscribing = false }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        return try await withCheckedThrowingContinuation { continuation in
            speechRecognizer.recognitionTask(with: request) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result, result.isFinal else { return }
                continuation.resume(returning: result.bestTranscription.formattedString)
            }
        }
    }

    func extractAudioFromVideo(videoURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw TranscriptionError.exportFailed
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).m4a")

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        await exportSession.export()

        if exportSession.status == .completed {
            return outputURL
        }
        throw TranscriptionError.exportFailed
    }

    func transcribeVideo(at videoURL: URL) async throws -> String {
        let audioURL = try await extractAudioFromVideo(videoURL: videoURL)
        let transcript = try await transcribeAudio(at: audioURL)
        try? FileManager.default.removeItem(at: audioURL)
        return transcript
    }

    enum TranscriptionError: LocalizedError {
        case recognizerUnavailable
        case exportFailed

        var errorDescription: String? {
            switch self {
            case .recognizerUnavailable: return "Speech recognition is not available."
            case .exportFailed: return "Could not extract audio from video."
            }
        }
    }
}
