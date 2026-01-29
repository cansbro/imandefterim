import FirebaseFirestore
import Foundation

// MARK: - Firestore User Model
struct FirestoreUser: Codable {
    let createdAt: Date?
    var cityPlateCode: Int
    var cityName: String
    var notificationPrefs: NotificationPrefs
    var premiumStatus: Bool
    var fcmToken: String?
    var lastActiveAt: Date?

    struct NotificationPrefs: Codable {
        var prayerTimesEnabled: Bool
        var dailyVerseEnabled: Bool
        var prayerTimeOffset: Int?  // Minutes before prayer (5, 15, 30 etc)
    }

    static let `default` = FirestoreUser(
        createdAt: nil,
        cityPlateCode: 34,
        cityName: "İstanbul",
        notificationPrefs: NotificationPrefs(
            prayerTimesEnabled: true, dailyVerseEnabled: true, prayerTimeOffset: 15),
        premiumStatus: false,
        fcmToken: nil,
        lastActiveAt: nil
    )
}

// MARK: - User Service
final class UserService: ObservableObject {
    static let shared = UserService()

    @Published private(set) var currentUserProfile: FirestoreUser?
    @Published private(set) var isLoading = false

    private var listener: ListenerRegistration?

    private init() {}

    deinit {
        listener?.remove()
    }

    // MARK: - Start Listening
    func startListening(userId: String) {
        listener?.remove()

        listener = FirebaseManager.shared.usersCollection
            .document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let data = snapshot?.data() else {
                    self?.currentUserProfile = nil
                    return
                }

                do {
                    let user = try Firestore.Decoder().decode(FirestoreUser.self, from: data)
                    DispatchQueue.main.async {
                        self?.currentUserProfile = user
                    }
                } catch {
                    print("User decode error: \(error)")
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Update City
    func updateCity(plateCode: Int, cityName: String) async throws {
        guard let userId = AuthService.shared.currentUserId else { return }

        try await FirebaseManager.shared.usersCollection.document(userId).updateData([
            "cityPlateCode": plateCode,
            "cityName": cityName,
        ])
    }

    // MARK: - Update Notification Prefs
    func updateNotificationPrefs(
        prayerTimesEnabled: Bool? = nil,
        dailyVerseEnabled: Bool? = nil,
        prayerTimeOffset: Int? = nil
    )
        async throws
    {
        guard let userId = AuthService.shared.currentUserId else { return }

        var updates: [String: Any] = [:]
        if let prayer = prayerTimesEnabled {
            updates["notificationPrefs.prayerTimesEnabled"] = prayer
        }
        if let verse = dailyVerseEnabled {
            updates["notificationPrefs.dailyVerseEnabled"] = verse
        }
        if let offset = prayerTimeOffset {
            updates["notificationPrefs.prayerTimeOffset"] = offset
        }

        if !updates.isEmpty {
            try await FirebaseManager.shared.usersCollection.document(userId).updateData(updates)
        }
    }

    // MARK: - Update FCM Token
    func updateFCMToken(_ token: String) async throws {
        guard let userId = AuthService.shared.currentUserId else { return }

        try await FirebaseManager.shared.usersCollection.document(userId).updateData([
            "fcmToken": token
        ])
    }
}
