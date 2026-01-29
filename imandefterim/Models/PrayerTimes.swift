import Foundation

// MARK: - Prayer Time Model
struct PrayerTime: Identifiable {
    let id = UUID()
    let name: String
    let time: String
    let icon: String

    var timeAsDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: time)
    }
}

// MARK: - Daily Prayer Times
struct DailyPrayerTimes {
    let city: TurkishCity
    let date: Date
    let imsak: String
    let gunes: String
    let ogle: String
    let ikindi: String
    let aksam: String
    let yatsi: String

    var allTimes: [PrayerTime] {
        [
            PrayerTime(name: Strings.Prayer.imsak, time: imsak, icon: "moon.stars.fill"),
            PrayerTime(name: Strings.Prayer.gunes, time: gunes, icon: "sunrise.fill"),
            PrayerTime(name: Strings.Prayer.ogle, time: ogle, icon: "sun.max.fill"),
            PrayerTime(name: Strings.Prayer.ikindi, time: ikindi, icon: "sun.haze.fill"),
            PrayerTime(name: Strings.Prayer.aksam, time: aksam, icon: "sunset.fill"),
            PrayerTime(name: Strings.Prayer.yatsi, time: yatsi, icon: "moon.fill"),
        ]
    }

    func nextPrayer() -> (prayer: PrayerTime, remainingTime: String)? {
        let now = Date()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        for prayer in allTimes {
            if let prayerDate = prayer.timeAsDate {
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                let prayerComponents = calendar.dateComponents([.hour, .minute], from: prayerDate)
                components.hour = prayerComponents.hour
                components.minute = prayerComponents.minute

                if let fullPrayerDate = calendar.date(from: components), fullPrayerDate > now {
                    let diff = fullPrayerDate.timeIntervalSince(now)
                    let hours = Int(diff) / 3600
                    let minutes = (Int(diff) % 3600) / 60

                    let remaining = hours > 0 ? "\(hours) sa \(minutes) dk" : "\(minutes) dk"
                    return (prayer, remaining)
                }
            }
        }

        // All prayers passed, return tomorrow's imsak
        return (allTimes[0], "Yarın")
    }
}

// MARK: - Turkish Cities (81 İl)
enum TurkishCity: String, CaseIterable, Identifiable {
    case adana = "Adana"
    case adiyaman = "Adıyaman"
    case afyonkarahisar = "Afyonkarahisar"
    case agri = "Ağrı"
    case aksaray = "Aksaray"
    case amasya = "Amasya"
    case ankara = "Ankara"
    case antalya = "Antalya"
    case ardahan = "Ardahan"
    case artvin = "Artvin"
    case aydin = "Aydın"
    case balikesir = "Balıkesir"
    case bartin = "Bartın"
    case batman = "Batman"
    case bayburt = "Bayburt"
    case bilecik = "Bilecik"
    case bingol = "Bingöl"
    case bitlis = "Bitlis"
    case bolu = "Bolu"
    case burdur = "Burdur"
    case bursa = "Bursa"
    case canakkale = "Çanakkale"
    case cankiri = "Çankırı"
    case corum = "Çorum"
    case denizli = "Denizli"
    case diyarbakir = "Diyarbakır"
    case duzce = "Düzce"
    case edirne = "Edirne"
    case elazig = "Elazığ"
    case erzincan = "Erzincan"
    case erzurum = "Erzurum"
    case eskisehir = "Eskişehir"
    case gaziantep = "Gaziantep"
    case giresun = "Giresun"
    case gumushane = "Gümüşhane"
    case hakkari = "Hakkari"
    case hatay = "Hatay"
    case igdir = "Iğdır"
    case isparta = "Isparta"
    case istanbul = "İstanbul"
    case izmir = "İzmir"
    case kahramanmaras = "Kahramanmaraş"
    case karabuk = "Karabük"
    case karaman = "Karaman"
    case kars = "Kars"
    case kastamonu = "Kastamonu"
    case kayseri = "Kayseri"
    case kilis = "Kilis"
    case kirikkale = "Kırıkkale"
    case kirklareli = "Kırklareli"
    case kirsehir = "Kırşehir"
    case kocaeli = "Kocaeli"
    case konya = "Konya"
    case kutahya = "Kütahya"
    case malatya = "Malatya"
    case manisa = "Manisa"
    case mardin = "Mardin"
    case mersin = "Mersin"
    case mugla = "Muğla"
    case mus = "Muş"
    case nevsehir = "Nevşehir"
    case nigde = "Niğde"
    case ordu = "Ordu"
    case osmaniye = "Osmaniye"
    case rize = "Rize"
    case sakarya = "Sakarya"
    case samsun = "Samsun"
    case sanliurfa = "Şanlıurfa"
    case siirt = "Siirt"
    case sinop = "Sinop"
    case sirnak = "Şırnak"
    case sivas = "Sivas"
    case tekirdag = "Tekirdağ"
    case tokat = "Tokat"
    case trabzon = "Trabzon"
    case tunceli = "Tunceli"
    case usak = "Uşak"
    case van = "Van"
    case yalova = "Yalova"
    case yozgat = "Yozgat"
    case zonguldak = "Zonguldak"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var plateCode: Int {
        switch self {
        case .adana: return 1
        case .adiyaman: return 2
        case .afyonkarahisar: return 3
        case .agri: return 4
        case .amasya: return 5
        case .ankara: return 6
        case .antalya: return 7
        case .artvin: return 8
        case .aydin: return 9
        case .balikesir: return 10
        case .bilecik: return 11
        case .bingol: return 12
        case .bitlis: return 13
        case .bolu: return 14
        case .burdur: return 15
        case .bursa: return 16
        case .canakkale: return 17
        case .cankiri: return 18
        case .corum: return 19
        case .denizli: return 20
        case .diyarbakir: return 21
        case .edirne: return 22
        case .elazig: return 23
        case .erzincan: return 24
        case .erzurum: return 25
        case .eskisehir: return 26
        case .gaziantep: return 27
        case .giresun: return 28
        case .gumushane: return 29
        case .hakkari: return 30
        case .hatay: return 31
        case .isparta: return 32
        case .mersin: return 33
        case .istanbul: return 34
        case .izmir: return 35
        case .kars: return 36
        case .kastamonu: return 37
        case .kayseri: return 38
        case .kirklareli: return 39
        case .kirsehir: return 40
        case .kocaeli: return 41
        case .konya: return 42
        case .kutahya: return 43
        case .malatya: return 44
        case .manisa: return 45
        case .kahramanmaras: return 46
        case .mardin: return 47
        case .mugla: return 48
        case .mus: return 49
        case .nevsehir: return 50
        case .nigde: return 51
        case .ordu: return 52
        case .rize: return 53
        case .sakarya: return 54
        case .samsun: return 55
        case .siirt: return 56
        case .sinop: return 57
        case .sivas: return 58
        case .tekirdag: return 59
        case .tokat: return 60
        case .trabzon: return 61
        case .tunceli: return 62
        case .sanliurfa: return 63
        case .usak: return 64
        case .van: return 65
        case .yozgat: return 66
        case .zonguldak: return 67
        case .aksaray: return 68
        case .bayburt: return 69
        case .karaman: return 70
        case .kirikkale: return 71
        case .batman: return 72
        case .sirnak: return 73
        case .bartin: return 74
        case .ardahan: return 75
        case .igdir: return 76
        case .yalova: return 77
        case .karabuk: return 78
        case .kilis: return 79
        case .osmaniye: return 80
        case .duzce: return 81
        }
    }
}

// MARK: - Prayer Times Provider Protocol
protocol PrayerTimesProvider {
    func getPrayerTimes(for city: TurkishCity, date: Date) -> DailyPrayerTimes
}

// MARK: - Mock Prayer Times Provider
class MockPrayerTimesProvider: PrayerTimesProvider {
    static let shared = MockPrayerTimesProvider()

    private let mockData: [TurkishCity: DailyPrayerTimes] = [
        .istanbul: DailyPrayerTimes(
            city: .istanbul,
            date: Date(),
            imsak: "06:45",
            gunes: "08:15",
            ogle: "13:05",
            ikindi: "15:35",
            aksam: "17:50",
            yatsi: "19:15"
        ),
        .ankara: DailyPrayerTimes(
            city: .ankara,
            date: Date(),
            imsak: "06:35",
            gunes: "08:05",
            ogle: "12:55",
            ikindi: "15:25",
            aksam: "17:40",
            yatsi: "19:05"
        ),
        .izmir: DailyPrayerTimes(
            city: .izmir,
            date: Date(),
            imsak: "06:55",
            gunes: "08:25",
            ogle: "13:15",
            ikindi: "15:45",
            aksam: "18:00",
            yatsi: "19:25"
        ),
    ]

    func getPrayerTimes(for city: TurkishCity, date: Date) -> DailyPrayerTimes {
        // Return mock data if available, otherwise generate based on Istanbul with offset
        if let data = mockData[city] {
            return data
        }

        // Default to Istanbul times with slight variation
        return DailyPrayerTimes(
            city: city,
            date: date,
            imsak: "06:45",
            gunes: "08:15",
            ogle: "13:05",
            ikindi: "15:35",
            aksam: "17:50",
            yatsi: "19:15"
        )
    }
}
