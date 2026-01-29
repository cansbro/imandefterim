import FirebaseFirestore
import Foundation

// MARK: - Note Type
enum NoteType: String, Codable, CaseIterable {
    case audioRecording = "audio_recording"
    case youtubeLink = "youtube_link"
    case uploadedAudio = "uploaded_audio"
    case scannedText = "scanned_text"

    var displayName: String {
        switch self {
        case .audioRecording: return "Ses Kaydı"
        case .youtubeLink: return "YouTube"
        case .uploadedAudio: return "Yüklenen Ses"
        case .scannedText: return "Taranan Metin"
        }
    }

    var icon: String {
        switch self {
        case .audioRecording: return "mic.fill"
        case .youtubeLink: return "play.circle.fill"
        case .uploadedAudio: return "doc.fill"
        case .scannedText: return "camera.viewfinder"
        }
    }
}

// MARK: - Note Status
enum NoteStatus: String, Codable {
    case processing
    case ready
    case failed
}

// MARK: - Note Dua
struct NoteDua: Codable, Identifiable {
    var id: String { text }
    let text: String
    let startSec: Int?
    let endSec: Int?
    let createdAt: Date?
}

// MARK: - Firestore Note Model
struct FirestoreNote: Codable, Identifiable {
    @DocumentID var id: String?
    let uid: String
    let type: NoteType
    var title: String
    var speaker: String?
    let createdAt: Date?
    var durationSec: Int?
    var tags: [String]
    var folderId: String?
    var status: NoteStatus
    var summaryText: String?
    var transcriptText: String?
    var duas: [NoteDua]
    var audioStoragePath: String?
    var youtubeUrl: String?
    var scannedText: String?
    var manualNotes: String?
    var aiStatusMessage: String?

    // Computed properties
    var formattedDuration: String {
        guard let duration = durationSec else { return "" }
        let mins = duration / 60
        let secs = duration % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var formattedDate: String {
        guard let date = createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Firestore Folder Model
struct FirestoreFolder: Codable, Identifiable {
    @DocumentID var id: String?
    let uid: String
    var name: String
    let createdAt: Date?
    var noteCount: Int?
}

// MARK: - Notes Service
final class NotesService: ObservableObject {
    static let shared = NotesService()

    @Published private(set) var notes: [FirestoreNote] = []
    // Public computed property merging source of truth + local changes
    @Published var folders: [FirestoreFolder] = []
    @Published private(set) var isLoading = false

    // Internal state for robust optimistic updates
    private var firestoreFolders: [FirestoreFolder] = []
    private var pendingFolders: [FirestoreFolder] = []
    private var deletedFolderIds: Set<String> = []

    private var notesListener: ListenerRegistration?
    private var foldersListener: ListenerRegistration?

    private init() {}

    deinit {
        stopListening()
    }

    // MARK: - State Merging Logic
    private func updatePublicFolders() {
        // Merge: (Pending + Firestore) - Deleted
        // 1. Start with pending folders (newly created ones)
        var combined = pendingFolders

        // 2. Add firestore folders, but ONLY if they are not in pending (by ID) //    (avoid duplicates if server already caught up)
        for folder in firestoreFolders {
            if !combined.contains(where: { $0.id == folder.id }) {
                combined.append(folder)
            }
        }

        // 3. Filter out deleted folders
        combined.removeAll { folder in
            guard let id = folder.id else { return false }
            return deletedFolderIds.contains(id)
        }

        // 4. Sort by date (newest first)
        combined.sort { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }

        // 5. Publish
        self.folders = combined
    }

    // MARK: - Start Listening
    func startListening() {
        guard let userId = AuthService.shared.currentUserId else {
            print("❌ StartListening failed: No User ID")
            return
        }

        print("🎧 NotesService: Starting listener for user \(userId)")

        // Notes listener
        notesListener = FirebaseManager.shared.notesCollection
            .whereField("uid", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Notes listener error: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ Notes listener: No documents found")
                    return
                }

                print("NoteService: Listener received \(documents.count) notes")

                let notes = documents.compactMap { doc -> FirestoreNote? in
                    try? doc.data(as: FirestoreNote.self)
                }

                DispatchQueue.main.async {
                    self?.notes = notes
                    // Widget verilerini güncelle
                    self?.updateWidgetData()
                }
            }

        // Folders listener
        foldersListener = FirebaseManager.shared.foldersCollection
            .whereField("uid", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }

                let fetchedFolders = documents.compactMap { doc -> FirestoreFolder? in
                    try? doc.data(as: FirestoreFolder.self)
                }

                DispatchQueue.main.async {
                    self.firestoreFolders = fetchedFolders

                    // Cleanup pending: if a pending folder is now in firestore, remove it from pending logic
                    self.pendingFolders.removeAll { pending in
                        fetchedFolders.contains(where: { $0.id == pending.id })
                    }

                    // Cleanup deleted: if a deleted folder is gone from firestore, remove from deleted set
                    let currentIds = Set(fetchedFolders.compactMap { $0.id })
                    self.deletedFolderIds = self.deletedFolderIds.filter { currentIds.contains($0) }

                    self.updatePublicFolders()
                }
            }
    }

    func stopListening() {
        notesListener?.remove()
        foldersListener?.remove()
    }

    // MARK: - Create Note
    func createNote(
        type: NoteType,
        title: String,
        speaker: String? = nil,
        durationSec: Int? = nil,
        audioStoragePath: String? = nil,
        youtubeUrl: String? = nil,
        scannedText: String? = nil
    ) async throws -> String {
        guard let userId = AuthService.shared.currentUserId else {
            throw NotesError.notAuthenticated
        }

        let noteRef = FirebaseManager.shared.notesCollection.document()

        var tags: [String] = []
        if type == .audioRecording || type == .uploadedAudio || type == .youtubeLink
            || type == .scannedText
        {
            tags = ["Özet", "Transkript", "Dua"]
        }

        let noteData: [String: Any] = [
            "uid": userId,
            "type": type.rawValue,
            "title": title,
            "speaker": speaker as Any,
            "createdAt": FieldValue.serverTimestamp(),
            "durationSec": durationSec as Any,
            "tags": tags,
            "folderId": NSNull(),
            "status": NoteStatus.processing.rawValue,
            "summaryText": NSNull(),
            "transcriptText": NSNull(),
            "duas": [],
            "audioStoragePath": audioStoragePath as Any,
            "youtubeUrl": youtubeUrl as Any,
            "scannedText": scannedText as Any,
            "manualNotes": NSNull(),
        ]

        // Add timeout logic (10 seconds)
        return try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                try await noteRef.setData(noteData)
                return noteRef.documentID
            }

            group.addTask {
                try await Task.sleep(nanoseconds: 10 * 1_000_000_000)  // 10 seconds
                throw NotesError.timeout
            }

            // Return the first one to complete (either success or timeout error)
            guard let result = try await group.next() else {
                throw NotesError.unknown
            }
            group.cancelAll()  // Cancel the other task
            return result
        }
    }

    // MARK: - Update Note
    func updateNote(noteId: String, updates: [String: Any]) async throws {
        try await FirebaseManager.shared.notesCollection.document(noteId).updateData(updates)
    }

    // MARK: - Delete Note
    func deleteNote(noteId: String) async throws {
        // İlk önce audio varsa sil
        if let note = notes.first(where: { $0.id == noteId }),
            let audioPath = note.audioStoragePath
        {
            try? await StorageService.shared.deleteAudio(path: audioPath)
        }

        try await FirebaseManager.shared.notesCollection.document(noteId).delete()
    }

    // MARK: - Create Folder
    func createFolder(name: String) async throws -> String {
        guard let userId = AuthService.shared.currentUserId else {
            throw NotesError.notAuthenticated
        }

        let folderRef = FirebaseManager.shared.foldersCollection.document()
        let folderId = folderRef.documentID

        // Optimistic Update: Add to pending
        let tempFolder = FirestoreFolder(
            id: folderId,
            uid: userId,
            name: name,
            createdAt: Date(),
            noteCount: 0
        )

        await MainActor.run {
            self.pendingFolders.insert(tempFolder, at: 0)
            self.updatePublicFolders()
        }

        let folderData: [String: Any] = [
            "uid": userId,
            "name": name,
            "createdAt": FieldValue.serverTimestamp(),
            "noteCount": 0,
        ]

        do {
            try await folderRef.setData(folderData)
            return folderId
        } catch {
            // Revert optimistic update on error
            await MainActor.run {
                if let index = self.pendingFolders.firstIndex(where: { $0.id == folderId }) {
                    self.pendingFolders.remove(at: index)
                    self.updatePublicFolders()
                }
            }
            throw error
        }
    }

    // MARK: - Delete Folder
    func deleteFolder(folderId: String) async throws {
        // Optimistic Update: Add to deleted set
        await MainActor.run {
            self.deletedFolderIds.insert(folderId)
            self.updatePublicFolders()
        }

        // Klasördeki notların folderId'sini temizle
        let notesInFolder = notes.filter { $0.folderId == folderId }
        for note in notesInFolder {
            if let noteId = note.id {
                try await updateNote(noteId: noteId, updates: ["folderId": NSNull()])
            }
        }

        do {
            try await FirebaseManager.shared.foldersCollection.document(folderId).delete()
        } catch {
            // Revert optimistic update
            await MainActor.run {
                self.deletedFolderIds.remove(folderId)
                self.updatePublicFolders()
            }
            print("Error deleting folder: \(error)")
        }
    }

    // MARK: - Move Note to Folder
    func moveNoteToFolder(noteId: String, folderId: String?) async throws {
        let update: [String: Any] =
            folderId != nil ? ["folderId": folderId!] : ["folderId": NSNull()]
        try await updateNote(noteId: noteId, updates: update)
    }

    // MARK: - Get Notes for Folder
    func notes(for folderId: String) -> [FirestoreNote] {
        notes.filter { $0.folderId == folderId }
    }

    // MARK: - Retry Processing
    func retryProcessing(noteId: String) async throws {
        // Callable function çağır
        let functions = FirebaseManager.shared.functions!
        let data = ["noteId": noteId]

        _ = try await functions.httpsCallable("retryProcessNote").call(data)
    }
}

// MARK: - Notes Errors
enum NotesError: LocalizedError {
    case notAuthenticated
    case notFound
    case timeout
    case unknown

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Kullanıcı girişi gerekli"
        case .notFound:
            return "Not bulunamadı"
        case .timeout:
            return
                "İşlem zaman aşımına uğradı. Lütfen internet bağlantınızı veya veritabanı ayarlarınızı kontrol edin."
        case .unknown:
            return "Bilinmeyen bir hata oluştu"
        }
    }
}
