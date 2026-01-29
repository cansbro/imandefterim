import Foundation

// MARK: - Recording Model
struct Recording: Identifiable, Codable {
    let id: UUID
    var title: String
    var speaker: String?
    var date: Date
    var duration: TimeInterval
    var audioPath: String?
    var transcript: String?
    var summary: [String]
    var duas: [Dua]
    var tags: [String]
    var bookmarks: [Bookmark]
    var folderId: UUID?
    var personalNote: String?

    init(
        id: UUID = UUID(),
        title: String,
        speaker: String? = nil,
        date: Date = Date(),
        duration: TimeInterval = 0,
        audioPath: String? = nil,
        transcript: String? = nil,
        summary: [String] = [],
        duas: [Dua] = [],
        tags: [String] = [],
        bookmarks: [Bookmark] = [],
        folderId: UUID? = nil,
        personalNote: String? = nil
    ) {
        self.id = id
        self.title = title
        self.speaker = speaker
        self.date = date
        self.duration = duration
        self.audioPath = audioPath
        self.transcript = transcript
        self.summary = summary
        self.duas = duas
        self.tags = tags
        self.bookmarks = bookmarks
        self.folderId = folderId
        self.personalNote = personalNote
    }

    var formattedDuration: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Bookmark
struct Bookmark: Identifiable, Codable {
    let id: UUID
    var timestamp: TimeInterval
    var note: String?

    init(id: UUID = UUID(), timestamp: TimeInterval, note: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.note = note
    }
}
