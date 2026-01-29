import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseFunctions
import FirebaseStorage
import Foundation

// MARK: - Firebase Configuration
enum FirebaseEnvironment {
    case production
    case emulator

    static var current: FirebaseEnvironment {
        #if DEBUG
            // Emulator kullanmak için true yap
            return ProcessInfo.processInfo.environment["USE_FIREBASE_EMULATOR"] == "true"
                ? .emulator : .production
        #else
            return .production
        #endif
    }
}

// MARK: - Firebase Manager
final class FirebaseManager {
    static let shared = FirebaseManager()

    private(set) var auth: Auth!
    private(set) var firestore: Firestore!
    private(set) var storage: Storage!
    private(set) var functions: Functions!

    private init() {}

    /// Firebase'i yapılandır - AppDelegate veya App init'te çağrılmalı
    func configure() {
        guard FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()

        auth = Auth.auth()
        firestore = Firestore.firestore()
        storage = Storage.storage()
        functions = Functions.functions()

        configureForEnvironment()
    }

    private func configureForEnvironment() {
        switch FirebaseEnvironment.current {
        case .emulator:
            configureEmulators()
        case .production:
            // Production ayarları
            let settings = FirestoreSettings()
            settings.cacheSettings = PersistentCacheSettings()
            firestore.settings = settings
        }
    }

    private func configureEmulators() {
        // Local emulator host
        let host = "localhost"

        // Auth Emulator (port 9099)
        auth.useEmulator(withHost: host, port: 9099)

        // Firestore Emulator (port 8080)
        let firestoreSettings = Firestore.firestore().settings
        firestoreSettings.host = "\(host):8080"
        firestoreSettings.isSSLEnabled = false
        firestoreSettings.cacheSettings = MemoryCacheSettings()
        firestore.settings = firestoreSettings

        // Storage Emulator (port 9199)
        storage.useEmulator(withHost: host, port: 9199)

        // Functions Emulator (port 5001)
        functions.useEmulator(withHost: host, port: 5001)

        print("🔧 Firebase Emulator Suite aktif")
    }

    // MARK: - Collection References
    var usersCollection: CollectionReference {
        firestore.collection("users")
    }

    var notesCollection: CollectionReference {
        firestore.collection("notes")
    }

    var foldersCollection: CollectionReference {
        firestore.collection("folders")
    }

    var prayerTimesCollection: CollectionReference {
        firestore.collection("prayerTimes")
    }

    var dailyContentCollection: CollectionReference {
        firestore.collection("dailyContent")
    }
}
