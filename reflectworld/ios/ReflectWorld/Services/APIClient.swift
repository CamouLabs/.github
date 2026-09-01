import Foundation

/// Optional backend client for enhanced transcription and LLM-powered insights.
/// The iPhone app works fully on-device without this.
final class APIClient {
    static let shared = APIClient()

    var baseURL: String {
        UserDefaults.standard.string(forKey: "reflectworld_api_base") ?? ""
    }

    var isConfigured: Bool {
        !baseURL.isEmpty
    }

    func createMediaEntry(fileURL: URL, title: String?, mood: String?) async throws -> RemoteEntry {
        guard isConfigured else { throw APIError.notConfigured }

        let url = URL(string: "\(baseURL)/api/media/create-entry")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let fileData = try Data(contentsOf: fileURL)
        let filename = fileURL.lastPathComponent

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        if let title {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"title\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(title)\r\n".data(using: .utf8)!)
        }
        if let mood {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"mood\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(mood)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.requestFailed
        }
        return try JSONDecoder().decode(RemoteEntry.self, from: data)
    }

    enum APIError: LocalizedError {
        case notConfigured
        case requestFailed

        var errorDescription: String? {
            switch self {
            case .notConfigured: return "Backend URL not configured."
            case .requestFailed: return "Backend request failed."
            }
        }
    }
}

struct RemoteEntry: Decodable {
    let id: String
    let title: String
    let content: String
    let transcript: String?
    let mood: String?
}
