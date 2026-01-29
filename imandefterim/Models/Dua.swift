import Foundation

// MARK: - Dua (Prayer) Model
struct Dua: Identifiable, Codable {
    let id: UUID
    var recordingId: UUID?
    var text: String
    var arabicText: String?
    var source: String?
    var note: String?
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        recordingId: UUID? = nil,
        text: String,
        arabicText: String? = nil,
        source: String? = nil,
        note: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.recordingId = recordingId
        self.text = text
        self.arabicText = arabicText
        self.source = source
        self.note = note
        self.isFavorite = isFavorite
    }
}
