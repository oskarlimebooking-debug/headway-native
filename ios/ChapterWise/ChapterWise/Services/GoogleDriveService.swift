import Foundation
import AuthenticationServices
import SwiftData

actor GoogleDriveService {
    static let shared = GoogleDriveService()

    private let scopes = "https://www.googleapis.com/auth/drive.appdata"
    private let syncFileName = "chapterwise-sync.json"

    private var accessToken: String?
    private var syncFileId: String?

    // MARK: - Authentication
    func authenticate(clientId: String) async throws {
        guard !clientId.isEmpty else {
            throw SyncError.noClientId
        }

        let redirectURI = "com.chapterwise.app:/oauth2redirect"
        let authURL = "https://accounts.google.com/o/oauth2/v2/auth?client_id=\(clientId)&redirect_uri=\(redirectURI)&response_type=token&scope=\(scopes)"

        guard let url = URL(string: authURL) else {
            throw SyncError.invalidURL
        }

        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            Task { @MainActor in
                let session = ASWebAuthenticationSession(
                    url: url,
                    callbackURLScheme: "com.chapterwise.app"
                ) { callbackURL, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let callbackURL = callbackURL {
                        continuation.resume(returning: callbackURL)
                    } else {
                        continuation.resume(throwing: SyncError.authFailed)
                    }
                }

                session.presentationContextProvider = ASWebAuthPresentationContext.shared
                session.prefersEphemeralWebBrowserSession = false
                session.start()
            }
        }

        // Extract access token from callback URL fragment
        guard let fragment = callbackURL.fragment else {
            throw SyncError.authFailed
        }

        let params = fragment.components(separatedBy: "&").reduce(into: [String: String]()) { result, param in
            let parts = param.components(separatedBy: "=")
            if parts.count == 2 {
                result[parts[0]] = parts[1]
            }
        }

        guard let token = params["access_token"] else {
            throw SyncError.authFailed
        }

        accessToken = token
    }

    // MARK: - Sync
    func syncNow(context: ModelContext) async throws {
        guard let token = accessToken else {
            throw SyncError.notAuthenticated
        }

        // Find or create sync file
        let fileId = try await findOrCreateSyncFile(token: token)

        // Download existing sync data
        _ = try await downloadSyncFile(fileId: fileId, token: token)

        // Export local data
        let localData = try await DataExportService.shared.exportAll(context: context)

        // For now, upload local data (simple overwrite strategy)
        try await uploadSyncFile(fileId: fileId, data: localData, token: token)
    }

    private func findOrCreateSyncFile(token: String) async throws -> String {
        if let existingId = syncFileId { return existingId }

        // Search for existing file
        var request = URLRequest(url: URL(string: "https://www.googleapis.com/drive/v3/files?spaces=appDataFolder&q=name='\(syncFileName)'")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)

        struct FileList: Codable {
            let files: [DriveFile]
        }
        struct DriveFile: Codable {
            let id: String
            let name: String
        }

        if let fileList = try? JSONDecoder().decode(FileList.self, from: data),
           let existingFile = fileList.files.first {
            syncFileId = existingFile.id
            return existingFile.id
        }

        // Create new file
        var createRequest = URLRequest(url: URL(string: "https://www.googleapis.com/drive/v3/files")!)
        createRequest.httpMethod = "POST"
        createRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        createRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let metadata: [String: Any] = [
            "name": syncFileName,
            "parents": ["appDataFolder"]
        ]
        createRequest.httpBody = try JSONSerialization.data(withJSONObject: metadata)

        let (createData, _) = try await URLSession.shared.data(for: createRequest)
        let createdFile = try JSONDecoder().decode(DriveFile.self, from: createData)
        syncFileId = createdFile.id
        return createdFile.id
    }

    private func downloadSyncFile(fileId: String, token: String) async throws -> Data? {
        var request = URLRequest(url: URL(string: "https://www.googleapis.com/drive/v3/files/\(fileId)?alt=media")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return nil
        }
        return data
    }

    private func uploadSyncFile(fileId: String, data: Data, token: String) async throws {
        var request = URLRequest(url: URL(string: "https://www.googleapis.com/upload/drive/v3/files/\(fileId)?uploadType=media")!)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw SyncError.uploadFailed
        }
    }
}

// MARK: - ASWebAuthenticationSession Presentation
@MainActor
class ASWebAuthPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = ASWebAuthPresentationContext()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

// MARK: - Sync Errors
enum SyncError: LocalizedError {
    case noClientId
    case invalidURL
    case authFailed
    case notAuthenticated
    case uploadFailed
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .noClientId: return "Please enter a Google OAuth Client ID"
        case .invalidURL: return "Invalid authentication URL"
        case .authFailed: return "Authentication failed"
        case .notAuthenticated: return "Not connected to Google Drive"
        case .uploadFailed: return "Failed to upload sync data"
        case .downloadFailed: return "Failed to download sync data"
        }
    }
}
