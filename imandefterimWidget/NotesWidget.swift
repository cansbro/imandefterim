import SwiftUI
import WidgetKit

// MARK: - Notes Widget Provider
struct NotesWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> NotesWidgetEntry {
        NotesWidgetEntry(date: Date(), notes: sampleNotes)
    }

    func getSnapshot(in context: Context, completion: @escaping (NotesWidgetEntry) -> Void) {
        let entry = NotesWidgetEntry(date: Date(), notes: loadNotes())
        completion(entry)
    }

    func getTimeline(
        in context: Context, completion: @escaping (Timeline<NotesWidgetEntry>) -> Void
    ) {
        let notes = loadNotes()
        let entry = NotesWidgetEntry(date: Date(), notes: notes)

        // Her 30 dakikada bir güncelle
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadNotes() -> [SharedNoteData] {
        guard let defaults = UserDefaults(suiteName: "group.imandefterim.shared"),
            let data = defaults.data(forKey: "widget_notes_data"),
            let widgetData = try? JSONDecoder().decode(WidgetNotesData.self, from: data)
        else {
            return []
        }
        return widgetData.notes
    }

    private var sampleNotes: [SharedNoteData] {
        [
            SharedNoteData(
                id: "1", title: "Cuma Hutbesi", type: "audio_recording", createdAt: Date(),
                speaker: "Hocam"),
            SharedNoteData(
                id: "2", title: "Tefsir Dersi", type: "youtube_link",
                createdAt: Date().addingTimeInterval(-3600), speaker: nil),
            SharedNoteData(
                id: "3", title: "Siyer Notları", type: "scanned_text",
                createdAt: Date().addingTimeInterval(-7200), speaker: nil),
        ]
    }
}

// MARK: - Entry
struct NotesWidgetEntry: TimelineEntry {
    let date: Date
    let notes: [SharedNoteData]
}

// MARK: - Notes Widget
struct NotesWidget: Widget {
    let kind: String = "NotesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NotesWidgetProvider()) { entry in
            NotesWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Notlarım")
        .description("Son notlarınızı görüntüleyin")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Views
struct NotesWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: NotesWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallNotesWidgetView(entry: entry)
        case .systemMedium:
            MediumNotesWidgetView(entry: entry)
        default:
            SmallNotesWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget View
struct SmallNotesWidgetView: View {
    var entry: NotesWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "book.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("Son Not")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            if let note = entry.notes.first {
                Spacer()

                // Note icon
                Image(systemName: note.typeIcon)
                    .font(.title2)
                    .foregroundColor(.orange)

                // Title
                Text(note.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)

                // Date
                Text(note.relativeDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()
            } else {
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "note.text")
                        .font(.largeTitle)
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Henüz not yok")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .padding()
        .widgetURL(URL(string: "imandefterim://notes"))
    }
}

// MARK: - Medium Widget View
struct MediumNotesWidgetView: View {
    var entry: NotesWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "book.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("Son Notlarım")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(entry.notes.count) not")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if entry.notes.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "note.text")
                            .font(.largeTitle)
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Henüz not yok")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                // Notes list
                ForEach(entry.notes.prefix(3)) { note in
                    Link(destination: URL(string: "imandefterim://note/\(note.id)")!) {
                        HStack(spacing: 10) {
                            // Type icon
                            Image(systemName: note.typeIcon)
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                                .frame(width: 20)

                            // Title
                            Text(note.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .foregroundColor(.primary)

                            Spacer()

                            // Date
                            Text(note.relativeDate)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .padding()
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    NotesWidget()
} timeline: {
    NotesWidgetEntry(
        date: .now,
        notes: [
            SharedNoteData(
                id: "1", title: "Cuma Hutbesi", type: "audio_recording", createdAt: Date(),
                speaker: "İmam Hoca")
        ])
    NotesWidgetEntry(date: .now, notes: [])
}

#Preview(as: .systemMedium) {
    NotesWidget()
} timeline: {
    NotesWidgetEntry(
        date: .now,
        notes: [
            SharedNoteData(
                id: "1", title: "Cuma Hutbesi", type: "audio_recording", createdAt: Date(),
                speaker: "İmam Hoca"),
            SharedNoteData(
                id: "2", title: "Tefsir Dersi - Bakara Suresi", type: "youtube_link",
                createdAt: Date().addingTimeInterval(-3600), speaker: nil),
            SharedNoteData(
                id: "3", title: "Siyer Notları", type: "scanned_text",
                createdAt: Date().addingTimeInterval(-7200), speaker: nil),
        ])
}
