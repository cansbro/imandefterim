import Foundation

// MARK: - Shared Note Data (Widget için basitleştirilmiş model)
struct SharedNoteData: Codable, Identifiable {
    let id: String
    let title: String
    let type: String  // audio_recording, youtube_link, uploaded_audio, scanned_text
    let createdAt: Date
    let speaker: String?

    var typeIcon: String {
        switch type {
        case "audio_recording":
            return "mic.fill"
        case "youtube_link":
            return "play.rectangle.fill"
        case "uploaded_audio":
            return "waveform"
        case "scanned_text":
            return "doc.text.viewfinder"
        default:
            return "note.text"
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Widget Data Container
struct WidgetNotesData: Codable {
    let notes: [SharedNoteData]
    let lastUpdate: Date

    static let empty = WidgetNotesData(notes: [], lastUpdate: Date())
}
