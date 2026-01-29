import Foundation
import SwiftUI

// MARK: - Daily Content Model
struct DailyContent: Codable {
    let verse: DailyVerse
    let heroMessage: String
    let heroTheme: String
}

struct DailyVerse: Codable {
    let text: String
    let textArabic: String
    let reference: String
}

// MARK: - Daily Content Service
final class DailyContentService: ObservableObject {
    static let shared = DailyContentService()

    @Published private(set) var currentContent: DailyContent?

    // Updated keys to invalidate old cache
    private let contentKey = "daily_content_cache_v3"
    private let dateKey = "daily_content_date_v3"

    private init() {
        checkAndUpdateDailyContent()
    }

    func checkAndUpdateDailyContent() {
        let today = Calendar.current.startOfDay(for: Date())
        let savedDate = UserDefaults.standard.object(forKey: dateKey) as? Date

        if let savedDate = savedDate, savedDate == today,
            let data = UserDefaults.standard.data(forKey: contentKey),
            let content = try? JSONDecoder().decode(DailyContent.self, from: data)
        {
            self.currentContent = content
            return
        }

        generateNewContent(for: today)
    }

    private func generateNewContent(for date: Date) {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = Calendar.current.component(.year, from: date)
        let seed = dayOfYear + year

        // Comprehensive content list
        let contents = [
            DailyContent(
                verse: DailyVerse(
                    text: "Eğer şükrederseniz, elbette size nimetimi artırırım.",
                    textArabic: "لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ",
                    reference: "İbrahim Suresi, 7"),
                heroMessage: "Sahip olduklarının kıymetini bilmek, yenilerinin habercisidir.",
                heroTheme: "Şükür"
            ),
            DailyContent(
                verse: DailyVerse(
                    text: "Allah hiçbir kimseyi gücünün yetmediği bir şeyle yükümlü tutmaz.",
                    textArabic: "لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا",
                    reference: "Bakara Suresi, 286"),
                heroMessage: "Şu an yaşadığın zorluk, taşıyabileceğin kadardır. Pes etme.",
                heroTheme: "Sabır ve Güç"
            ),
            DailyContent(
                verse: DailyVerse(
                    text: "Şüphesiz her zorlukla beraber bir kolaylık vardır.",
                    textArabic: "إِنَّ مَعَ الْعُسْرِ يُسْرًا",
                    reference: "İnşirah Suresi, 5"),
                heroMessage: "Her karanlık gecenin sonunda güneş mutlaka doğar.",
                heroTheme: "Umut"
            ),
            DailyContent(
                verse: DailyVerse(
                    text: "Kalpler ancak Allah'ı anmakla huzur bulur.",
                    textArabic: "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ",
                    reference: "Ra'd Suresi, 28"
                ),
                heroMessage: "Ruhun daraldığında O'nu an, ferahlığı hisset.",
                heroTheme: "Huzur"
            ),
            DailyContent(
                verse: DailyVerse(
                    text: "Kim Allah'a tevekkül ederse, Allah ona yeter.",
                    textArabic: "وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ",
                    reference: "Talak Suresi, 3"),
                heroMessage: "Elinden geleni yap, gerisini En Güçlü'ye bırak.",
                heroTheme: "Tevekkül"
            ),
            DailyContent(
                verse: DailyVerse(
                    text: "Müminler ancak kardeştirler.",
                    textArabic: "إِنَّمَا الْمُؤْمِنُونَ إِخْوَةٌ",
                    reference: "Hucurât Suresi, 10"),
                heroMessage: "Bugün bir dostunun halini hatırını sormaya ne dersin?",
                heroTheme: "Kardeşlik"
            ),
            DailyContent(
                verse: DailyVerse(
                    text: "İnsan için ancak çalıştığının karşılığı vardır.",
                    textArabic: "وَأَن لَّيْسَ لِلْإِنسَانِ إِلَّا مَا سَعَىٰ",
                    reference: "Necm Suresi, 39"),
                heroMessage: "Emeklerin zayi olmaz, sabırla devam et.",
                heroTheme: "Çalışmak"
            ),
            DailyContent(
                verse: DailyVerse(
                    text: "Rabbimiz, katından bize bir rahmet ver.",
                    textArabic: "رَبَّنَا آتِنَا مِن لَّدُنكَ رَحْمَةً",
                    reference: "Kehf Suresi, 10"),
                heroMessage: "Dualarında ısrarcı ol, kapılar elbet açılır.",
                heroTheme: "Dua"
            ),
            DailyContent(
                verse: DailyVerse(
                    text: "Allah, göklerin ve yerin nurudur.",
                    textArabic: "اللَّهُ نُورُ السَّمَاوَاتِ وَالْأَرْضِ",
                    reference: "Nûr Suresi, 35"),
                heroMessage: "Hayatına O'nun nuruyla bak, her şey aydınlansın.",
                heroTheme: "Nur"
            ),
            DailyContent(
                verse: DailyVerse(
                    text: "İyilikle kötülük bir olmaz. Sen kötülüğü en güzel olanla sav.",
                    textArabic: "وَلَا تَسْتَوِي الْحَسَنَةُ وَلَا السَّيِّئَةُ ۚ ادْفَعْ بِالَّتِي هِيَ أَحْسَنُ",
                    reference: "Fussilet Suresi, 34"),
                heroMessage: "Sana taş atana sen gül at, kalbini kirletme.",
                heroTheme: "İyilik"
            ),
        ]

        // Create deterministic index
        let index = seed % contents.count
        let newContent = contents[index]

        if let data = try? JSONEncoder().encode(newContent) {
            UserDefaults.standard.set(data, forKey: contentKey)
            UserDefaults.standard.set(date, forKey: dateKey)
        }

        DispatchQueue.main.async {
            self.currentContent = newContent
        }
    }
}
