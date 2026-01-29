import SwiftUI
import WidgetKit

// MARK: - Quick Note Widget Provider
struct QuickNoteWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> QuickNoteEntry {
        QuickNoteEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickNoteEntry) -> Void) {
        let entry = QuickNoteEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickNoteEntry>) -> Void)
    {
        let entry = QuickNoteEntry(date: Date())
        // Bu widget statik, güncelleme gerekmiyor
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Entry
struct QuickNoteEntry: TimelineEntry {
    let date: Date
}

// MARK: - Quick Note Widget
struct QuickNoteWidget: Widget {
    let kind: String = "QuickNoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickNoteWidgetProvider()) { entry in
            QuickNoteWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Hızlı Not")
        .description("Tek dokunuşla yeni not ekleyin")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Quick Note Widget View
struct QuickNoteWidgetView: View {
    var entry: QuickNoteEntry

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            // Add icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.orange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }

            // Text
            Text("Yeni Not")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("Kayıt başlat")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "imandefterim://addnote"))
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    QuickNoteWidget()
} timeline: {
    QuickNoteEntry(date: .now)
}
