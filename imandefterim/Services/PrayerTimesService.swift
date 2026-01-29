import FirebaseFirestore
import Foundation

// MARK: - Firestore Prayer Times Model
struct FirestorePrayerTimes: Codable {
    let plateCode: Int
    let date: String  // yyyy-MM-dd
    let times: PrayerTimesData
    let source: String?
    let fetchedAt: Date?

    struct PrayerTimesData: Codable {
        let imsak: String
        let gunes: String
        let ogle: String
        let ikindi: String
        let aksam: String
        let yatsi: String
    }
}

// MARK: - Prayer Times Service
final class PrayerTimesService: ObservableObject {
    static let shared = PrayerTimesService()

    @Published private(set) var currentPrayerTimes: FirestorePrayerTimes?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private init() {}

    // MARK: - Fetch Prayer Times
    func fetchPrayerTimes(plateCode: Int, date: Date = Date()) async throws -> FirestorePrayerTimes
    {
        let dateString = formatDate(date)
        let documentId = "\(plateCode)_\(dateString)"

        // 1. Try Firestore Cache
        let docRef = FirebaseManager.shared.prayerTimesCollection.document(documentId)

        do {
            let snapshot = try await docRef.getDocument()
            if snapshot.exists, let data = snapshot.data() {
                let times = try Firestore.Decoder().decode(FirestorePrayerTimes.self, from: data)
                await MainActor.run {
                    self.currentPrayerTimes = times
                }
                return times
            }
        } catch {
            print("⚠️ Firestore fetch failed: \(error), trying API...")
        }

        // 2. Try Aladhan API
        if let apiTimes = await fetchFromAPI(plateCode: plateCode, date: date) {
            // Save to cache asynchronously without blocking return
            Task {
                try? await savePrayerTimesToCache(apiTimes)
            }

            await MainActor.run {
                self.currentPrayerTimes = apiTimes
            }
            return apiTimes
        }

        // 3. Fallback to Mock Data
        print("⚠️ API failed, using mock data")
        let mockTimes = generateMockTimes(plateCode: plateCode, date: dateString)
        // Optionally save mock to cache so we don't try API every time?
        // Let's NOT save mock to cache so we retry real data next time.

        await MainActor.run {
            self.currentPrayerTimes = mockTimes
        }

        return mockTimes
    }

    // MARK: - Get Current Prayer Times for User
    func fetchForCurrentUser() async {
        // Use user's city or default to Istanbul (34)
        let plateCode = UserService.shared.currentUserProfile?.cityPlateCode ?? 34

        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }

        do {
            _ = try await fetchPrayerTimes(plateCode: plateCode)
            print("✅ Prayer times loaded for plateCode: \(plateCode)")
        } catch {
            print("❌ Prayer times error: \(error)")
            // Even if fetchPrayerTimes throws (which it shouldn't with new logic except extreme cases),
            // we should have caught it inside or returned mock.
            // If we are here, something went really wrong.
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }

        await MainActor.run {
            self.isLoading = false
        }
    }

    // MARK: - API Fetch Implementation
    private func fetchFromAPI(plateCode: Int, date: Date) async -> FirestorePrayerTimes? {
        // Use user's city name from profile, defaulting to Istanbul if not found
        let cityName = UserService.shared.currentUserProfile?.cityName ?? "Istanbul"
        let dateStrForApi = formatDateForApi(date)  // dd-MM-yyyy

        // URL: http://api.aladhan.com/v1/timingsByCity/{date}?city={city}&country=Turkey&method=13
        // method 13 = Diyanet

        guard
            let url = URL(
                string:
                    "http://api.aladhan.com/v1/timingsByCity/\(dateStrForApi)?city=\(cityName)&country=Turkey&method=13"
            )
        else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(AladhanResponse.self, from: data)
            let timings = response.data.timings

            return FirestorePrayerTimes(
                plateCode: plateCode,
                date: formatDate(date),
                times: FirestorePrayerTimes.PrayerTimesData(
                    imsak: timings.Imsak,
                    gunes: timings.Sunrise,
                    ogle: timings.Dhuhr,
                    ikindi: timings.Asr,
                    aksam: timings.Maghrib,
                    yatsi: timings.Isha
                ),
                source: "API",
                fetchedAt: Date()
            )
        } catch {
            print("❌ API Fetch Error: \(error)")
            return nil
        }
    }

    // MARK: - Next Prayer Calculation
    func nextPrayer() -> (name: String, time: String, remaining: String)? {
        guard let times = currentPrayerTimes else { return nil }

        // Parse times manually to be safe
        let prayers = [
            (Strings.Prayer.imsak, times.times.imsak),
            (Strings.Prayer.gunes, times.times.gunes),
            (Strings.Prayer.ogle, times.times.ogle),
            (Strings.Prayer.ikindi, times.times.ikindi),
            (Strings.Prayer.aksam, times.times.aksam),
            (Strings.Prayer.yatsi, times.times.yatsi),
        ]

        let now = Date()
        let calendar = Calendar.current

        // Helper to create Date from time string for today
        func date(for timeStr: String) -> Date? {
            let parts = timeStr.trimmingCharacters(in: .whitespacesAndNewlines).split(
                separator: ":")
            guard parts.count == 2,
                let hour = Int(parts[0]),
                let minute = Int(parts[1])  // API might return "06:45 (EEST)", so handle that if needed, but Diyanet usually clean
            else { return nil }

            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now)
        }

        for (name, timeStr) in prayers {
            // Remove any timezone info from API if Present (e.g. "06:45 (EEST)")
            let cleanTime = timeStr.components(separatedBy: " ").first ?? timeStr

            if let prayerDate = date(for: cleanTime), prayerDate > now {
                let diff = prayerDate.timeIntervalSince(now)
                let hours = Int(diff) / 3600
                let minutes = (Int(diff) % 3600) / 60

                let remaining = hours > 0 ? "\(hours) sa \(minutes) dk" : "\(minutes) dk"
                return (name, cleanTime, remaining)
            }
        }

        // If all passed, next is tomorrow's Imsak (approximate using today's time + 24h)
        return (Strings.Prayer.imsak, times.times.imsak, "Yarın")
    }

    // MARK: - All Times
    func allTimes() -> [(name: String, time: String, icon: String, isNext: Bool)] {
        guard let times = currentPrayerTimes else { return [] }
        let nextPrayerName = nextPrayer()?.name

        // Helper to clean time string
        func clean(_ time: String) -> String {
            return time.components(separatedBy: " ").first ?? time
        }

        return [
            (
                Strings.Prayer.imsak, clean(times.times.imsak), "moon.stars.fill",
                nextPrayerName == Strings.Prayer.imsak
            ),
            (
                Strings.Prayer.gunes, clean(times.times.gunes), "sunrise.fill",
                nextPrayerName == Strings.Prayer.gunes
            ),
            (
                Strings.Prayer.ogle, clean(times.times.ogle), "sun.max.fill",
                nextPrayerName == Strings.Prayer.ogle
            ),
            (
                Strings.Prayer.ikindi, clean(times.times.ikindi), "sun.haze.fill",
                nextPrayerName == Strings.Prayer.ikindi
            ),
            (
                Strings.Prayer.aksam, clean(times.times.aksam), "sunset.fill",
                nextPrayerName == Strings.Prayer.aksam
            ),
            (
                Strings.Prayer.yatsi, clean(times.times.yatsi), "moon.fill",
                nextPrayerName == Strings.Prayer.yatsi
            ),
        ]
    }

    // MARK: - Private Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func formatDateForApi(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
    }

    private func savePrayerTimesToCache(_ times: FirestorePrayerTimes) async throws {
        let documentId = "\(times.plateCode)_\(times.date)"
        let data = try Firestore.Encoder().encode(times)
        try await FirebaseManager.shared.prayerTimesCollection.document(documentId).setData(data)
    }

    // MARK: - Mock Data Generator
    private func generateMockTimes(plateCode: Int, date: String) -> FirestorePrayerTimes {
        // İl koduna göre slight offset (gerçekte API'den gelecek)
        let baseOffset = (plateCode - 34) * 2  // İstanbul base

        func adjustTime(_ base: String, offset: Int) -> String {
            let parts = base.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2 else { return base }
            var hour = parts[0]
            var minute = parts[1] + offset
            if minute >= 60 {
                minute -= 60
                hour += 1
            } else if minute < 0 {
                minute += 60
                hour -= 1
            }
            hour = max(0, min(23, hour))
            return String(format: "%02d:%02d", hour, minute)
        }

        return FirestorePrayerTimes(
            plateCode: plateCode,
            date: date,
            times: FirestorePrayerTimes.PrayerTimesData(
                imsak: adjustTime("06:45", offset: baseOffset),
                gunes: adjustTime("08:15", offset: baseOffset),
                ogle: adjustTime("13:05", offset: baseOffset),
                ikindi: adjustTime("15:35", offset: baseOffset),
                aksam: adjustTime("17:50", offset: baseOffset),
                yatsi: adjustTime("19:15", offset: baseOffset)
            ),
            source: "mock",
            fetchedAt: Date()
        )
    }
}

// MARK: - Aladhan API Models
struct AladhanResponse: Codable {
    let code: Int
    let status: String
    let data: AladhanData
}

struct AladhanData: Codable {
    let timings: AladhanTimings
}

struct AladhanTimings: Codable {
    let Imsak: String
    let Sunrise: String
    let Dhuhr: String
    let Asr: String
    let Sunset: String
    let Maghrib: String
    let Isha: String
    let Midnight: String
}
