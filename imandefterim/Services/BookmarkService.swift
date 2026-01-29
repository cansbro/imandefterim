import Foundation

struct VerseBookmark: Codable, Identifiable {
    let surahId: Int
    let verseNumber: Int
    let timestamp: Date

    var id: String {
        "\(surahId):\(verseNumber)"
    }
}

final class BookmarkService: ObservableObject {
    static let shared = BookmarkService()

    @Published private(set) var bookmarks: [VerseBookmark] = []

    private let key = "bookmarked_verses"

    private init() {
        loadBookmarks()
    }

    private func loadBookmarks() {
        if let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([VerseBookmark].self, from: data)
        {
            bookmarks = decoded
        }
    }

    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    func isBookmarked(surahId: Int, verseNumber: Int) -> Bool {
        return bookmarks.contains { $0.surahId == surahId && $0.verseNumber == verseNumber }
    }

    func toggleBookmark(surahId: Int, verseNumber: Int) {
        if isBookmarked(surahId: surahId, verseNumber: verseNumber) {
            bookmarks.removeAll { $0.surahId == surahId && $0.verseNumber == verseNumber }
        } else {
            let bookmark = VerseBookmark(
                surahId: surahId, verseNumber: verseNumber, timestamp: Date())
            bookmarks.append(bookmark)
        }
        saveBookmarks()
        objectWillChange.send()
    }
}
