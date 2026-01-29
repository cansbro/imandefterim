import Foundation

// MARK: - Demo Data
struct DemoData {

    // MARK: - Demo Recordings
    static let recordings: [Recording] = [
        Recording(
            id: UUID(),
            title: "Cuma Hutbesi - Sabır ve Şükür",
            speaker: "İmam Hoca",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            duration: 1845,  // 30:45
            transcript: """
                Bismillahirrahmanirrahim. Muhterem Müslümanlar, bugünkü hutbemizde sabır ve şükür konusunu ele alacağız.

                Sabır, Kur'an-ı Kerim'de en çok geçen kavramlardan biridir. Rabbimiz "Sabredin, muhakkak Allah sabredenlerle beraberdir" buyuruyor.

                Şükür ise nimetlerin farkında olmaktır. Her sabah gözlerimizi açtığımızda, sağlıklı bir nefes aldığımızda şükretmeliyiz.

                Allah'ım, bizi sabreden ve şükreden kullarından eyle. Amin.
                """,
            summary: [
                "Sabır, Kur'an'ın en temel kavramlarından biridir",
                "Allah sabredenlerle beraberdir (Bakara 153)",
                "Şükür nimetlerin farkında olmaktır",
                "Her gün şükredilecek sayısız nimet vardır",
                "Sabır ve şükür birbirini tamamlar",
            ],
            duas: [
                Dua(
                    text: "Allah'ım, bizi sabreden ve şükreden kullarından eyle",
                    source: "Hutbe Duası"),
                Dua(
                    text:
                        "Rabbena atina fid-dünya haseneten ve fil-ahireti haseneten ve kına azabennar",
                    arabicText: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً", source: "Bakara 201"),
            ],
            tags: [Strings.Notes.tagSummary, Strings.Notes.tagTranscript, Strings.Notes.tagDua]
        ),
        Recording(
            id: UUID(),
            title: "Tefsir Dersi - Yasin Suresi",
            speaker: "Mehmet Hoca",
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            duration: 2520,  // 42:00
            transcript: """
                Yasin Suresi, Kur'an'ın kalbi olarak nitelendirilmiştir. Peygamber Efendimiz (s.a.v.) "Her şeyin bir kalbi vardır, Kur'an'ın kalbi de Yasin'dir" buyurmuştur.

                Sure, tevhid, risalet ve ahiret konularını işler. İlk ayetlerde Hz. Muhammed'in peygamberliği teyit edilir.

                "İnneke le minel murselin" - Sen elbette gönderilen peygamberlerdensin.

                Bu sure ölülere okunur çünkü ahiret hayatını hatırlatır ve ölüme hazırlığı öğütler.
                """,
            summary: [
                "Yasin Suresi 'Kur'an'ın kalbi' olarak bilinir",
                "Tevhid, risalet ve ahiret temalarını işler",
                "Hz. Muhammed'in peygamberliğini teyit eder",
                "Ölülere okunması sünnettir",
                "Ahiret hayatını ve hesap gününü hatırlatır",
            ],
            duas: [
                Dua(
                    text: "Allah'ım, Yasin Suresinin feyzinden nasiplenenlerden eyle",
                    source: "Tefsir Dersi")
            ],
            tags: [Strings.Notes.tagSummary, Strings.Notes.tagTranscript]
        ),
    ]

    // MARK: - Today's Content
    struct TodayContent {
        static let theme = "Şükür"
        static let themeSubtitle = "Nimetlerin farkında ol"
        static let heroMessage = "Şükreden kullar arasına gir, nimetler artar."
        static let guideTitle = "İman Defterim ile Bugün"

        static let dailyVerse = (
            text: "Eğer şükrederseniz, elbette size nimetimi artırırım.",
            reference: "İbrahim Suresi, 7"
        )
    }

    // Convenience accessor
    static var todayContent: TodayContent.Type { TodayContent.self }

    // MARK: - Demo Folders
    static let folders: [Folder] = [
        Folder(name: "Cuma Hutbeleri", color: "#B48C50"),
        Folder(name: "Tefsir Dersleri", color: "#4A7C59"),
    ]
}
