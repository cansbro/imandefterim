import Foundation
import WidgetKit

// MARK: - Widget Data Provider
/// Ana uygulama ve widget arasında veri paylaşımını yöneten servis
final class WidgetDataProvider {
    static let shared = WidgetDataProvider()

    // App Group identifier - Apple Developer Portal'da oluşturulmalı
    static let appGroupIdentifier = "group.imandefterim.shared"

    // UserDefaults keys
    private let notesDataKey = "widget_notes_data"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupIdentifier)
    }

    private init() {}

    // MARK: - Save Notes for Widget
    /// NotesService'den gelen notları widget için cache'ler
    func saveNotesForWidget(_ notes: [FirestoreNote]) {
        let sharedNotes = notes.prefix(5).compactMap { note -> SharedNoteData? in
            guard let id = note.id else { return nil }
            return SharedNoteData(
                id: id,
                title: note.title,
                type: note.type.rawValue,
                createdAt: note.createdAt ?? Date(),
                speaker: note.speaker
            )
        }

        let widgetData = WidgetNotesData(notes: Array(sharedNotes), lastUpdate: Date())

        if let encoded = try? JSONEncoder().encode(widgetData) {
            sharedDefaults?.set(encoded, forKey: notesDataKey)

            // Widget timeline'ı güncelle
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // MARK: - Load Notes for Widget
    /// Widget tarafından kullanılacak notları yükler
    func loadNotesForWidget() -> WidgetNotesData {
        guard let data = sharedDefaults?.data(forKey: notesDataKey),
            let widgetData = try? JSONDecoder().decode(WidgetNotesData.self, from: data)
        else {
            return .empty
        }
        return widgetData
    }

    // MARK: - Clear Widget Data
    func clearWidgetData() {
        sharedDefaults?.removeObject(forKey: notesDataKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - NotesService Extension
extension NotesService {
    /// Notlar değiştiğinde widget'ı güncelle
    func updateWidgetData() {
        WidgetDataProvider.shared.saveNotesForWidget(notes)
    }
}
