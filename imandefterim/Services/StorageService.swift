import FirebaseStorage
import Foundation

// MARK: - Storage Service
final class StorageService {
    static let shared = StorageService()

    private init() {}

    // MARK: - Audio Upload
    func uploadAudio(data: Data, noteId: String) async throws -> String {
        guard let userId = AuthService.shared.currentUserId else {
            throw StorageError.notAuthenticated
        }

        let path = "users/\(userId)/audio/\(noteId).m4a"
        let ref = FirebaseManager.shared.storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "audio/x-m4a"

        _ = try await ref.putDataAsync(data, metadata: metadata)

        return path
    }

    // MARK: - Audio Upload from URL
    func uploadAudio(from localURL: URL, noteId: String, progressHandler: ((Double) -> Void)? = nil)
        async throws -> String
    {
        guard let userId = AuthService.shared.currentUserId else {
            throw StorageError.notAuthenticated
        }

        // Ensure file exists/is readable to fail fast
        let data = try Data(contentsOf: localURL)

        let path = "users/\(userId)/audio/\(noteId).m4a"
        let ref = FirebaseManager.shared.storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "audio/x-m4a"

        // Use putDataAsync which is more reliable in simulator context
        _ = try await ref.putDataAsync(data, metadata: metadata) { progress in
            if let progressHandler = progressHandler, let progress = progress {
                let percent = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                DispatchQueue.main.async {
                    progressHandler(percent)
                }
            }
        }

        return path
    }

    // MARK: - Get Download URL
    func getDownloadURL(path: String) async throws -> URL {
        let ref = FirebaseManager.shared.storage.reference().child(path)
        return try await ref.downloadURL()
    }

    // MARK: - Download Audio Data
    func downloadAudio(path: String) async throws -> Data {
        let ref = FirebaseManager.shared.storage.reference().child(path)
        let maxSize: Int64 = 100 * 1024 * 1024  // 100MB max
        return try await ref.data(maxSize: maxSize)
    }

    // MARK: - Delete Audio
    func deleteAudio(path: String) async throws {
        let ref = FirebaseManager.shared.storage.reference().child(path)
        try await ref.delete()
    }
}

// MARK: - Storage Errors
enum StorageError: LocalizedError {
    case notAuthenticated
    case uploadFailed
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Kullanıcı girişi gerekli"
        case .uploadFailed:
            return "Dosya yüklenemedi"
        case .downloadFailed:
            return "Dosya indirilemedi"
        }
    }
}
