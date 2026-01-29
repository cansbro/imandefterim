import Foundation

// MARK: - Surah Model
struct Surah: Identifiable, Codable {
    let id: Int
    let name: String
    let arabicName: String
    let meaning: String
    let verseCount: Int
    let revelationType: String  // Mekki / Medeni
    var verses: [Verse]

    var displayName: String {
        "\(id). \(name)"
    }
}

// MARK: - Verse (Ayet) Model
struct Verse: Identifiable, Codable, Equatable {
    let id: Int
    let surahId: Int
    let number: Int
    let arabicText: String?
    let turkishMeal: String

    var reference: String {
        "\(surahId):\(number)"
    }

    var audioUrl: String? {
        // Format: https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3
        // Need global verse index. This is complex without it.
        // Alternative: Use verse key like "1:1.mp3" if supported by source.
        // Using api.alquran.cloud structure:
        // https://cdn.islamic.network/quran/audio/128/ar.alafasy/{VERSE_ID}.mp3
        // We need the cumulative verse ID or a surah-based endpoint.
        // Let's use a surah:verse format if the CDN supports it, or calculate ID.
        // For now, let's assume standard Al-Quran Cloud format which uses ID.
        // Since we don't have cumulative ID easily, let's use a different source or format.
        // Or assume ID is available.
        // WAIT, the JSON might have audio.
        // If not, we can construct: https://everyayah.com/data/Abdul_Basit_Mujawwad_128kbps/{SURAH_3_DIGITS}{VERSE_3_DIGITS}.mp3
        let surahStr = String(format: "%03d", surahId)
        let verseStr = String(format: "%03d", number)
        return "https://everyayah.com/data/Abdul_Basit_Mujawwad_128kbps/\(surahStr)\(verseStr).mp3"
    }
}

// MARK: - Quran Data Loader
struct QuranData {
    /// All surahs loaded from JSON file
    static let allSurahs: [Surah] = {
        guard let url = Bundle.main.url(forResource: "quran_data", withExtension: "json") else {
            print("❌ ERROR: quran_data.json not found in bundle")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let surahs = try decoder.decode([Surah].self, from: data)
            print("✅ Loaded \(surahs.count) surahs from JSON")
            return surahs
        } catch {
            print("❌ ERROR loading Quran data: \(error)")
            return []
        }
    }()

    /// Get a specific surah by ID
    static func surah(id: Int) -> Surah? {
        return allSurahs.first { $0.id == id }
    }

    /// Get a specific verse by surah ID and verse number
    static func verse(surahId: Int, verseNumber: Int) -> Verse? {
        guard let surah = surah(id: surahId) else { return nil }
        return surah.verses.first { $0.number == verseNumber }
    }

    /// Get all verses across all surahs (for searching, etc.)
    static var allVerses: [Verse] {
        return allSurahs.flatMap { $0.verses }
    }
}
