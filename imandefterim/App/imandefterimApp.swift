import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import SwiftUI

// MARK: - App Delegate for Firebase Configuration
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Firebase'i burada yapılandır - StateObject'lerden ÖNCE
        FirebaseManager.shared.configure()
        return true
    }
}

@main
struct imandefterimApp: App {
    // AppDelegate'i bağla - Firebase StateObject'lerden önce çalışır
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var authService = AuthService.shared
    @StateObject private var userService = UserService.shared
    @StateObject private var notesService = NotesService.shared
    @StateObject private var prayerTimesService = PrayerTimesService.shared
    @StateObject private var entitlementManager = EntitlementManager.shared
    @StateObject private var adsManager = AdsManager.shared

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var authFailed = false

    init() {
        // Fix for invisible Navigation Bar Titles in Dark Mode
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()

        // islamicBackground = #FDF8F3 (253, 248, 243)
        let backgroundColor = UIColor(red: 253 / 255, green: 248 / 255, blue: 243 / 255, alpha: 1.0)
        appearance.backgroundColor = backgroundColor

        // islamicBrown = #2C1810 (44, 24, 16)
        let foregroundColor = UIColor(red: 44 / 255, green: 24 / 255, blue: 16 / 255, alpha: 1.0)

        // Large Title
        appearance.largeTitleTextAttributes = [
            .foregroundColor: foregroundColor,
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
        ]

        // Inline Title
        appearance.titleTextAttributes = [
            .foregroundColor: foregroundColor,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    // Deep link navigation state
    @State private var showRecordView = false
    @State private var deepLinkNoteId: String? = nil

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading && !authFailed {
                    // Auth yüklenirken splash
                    SplashView()
                } else if !authService.isAuthenticated {
                    // Kimlik doğrulama gerekli
                    AuthenticationView()
                } else if !hasCompletedOnboarding {
                    // Onboarding
                    OnboardingView(isOnboardingComplete: $hasCompletedOnboarding)
                } else {
                    // Ana uygulama
                    MainTabView()
                        .onAppear {
                            startServices()
                        }
                        .sheet(isPresented: $showRecordView) {
                            RecordView()
                                .environmentObject(notesService)
                                .environmentObject(entitlementManager)
                        }
                }
            }
            .environmentObject(authService)
            .environmentObject(userService)
            .environmentObject(notesService)
            .environmentObject(prayerTimesService)
            .environmentObject(entitlementManager)

            .sheet(isPresented: $entitlementManager.showPaywall) {
                if let trigger = entitlementManager.paywallTrigger {
                    LimitReachedView(trigger: trigger)
                        .environmentObject(entitlementManager)
                } else {
                    PaywallView(trigger: .manual)
                        .environmentObject(entitlementManager)
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    // MARK: - Deep Link Handling
    private func handleDeepLink(_ url: URL) {
        // Google Sign-In URL'lerini işle
        if GIDSignIn.sharedInstance.handle(url) {
            return
        }

        // Widget deep link'lerini işle
        guard url.scheme == "imandefterim" else { return }

        switch url.host {
        case "addnote":
            // Yeni not ekleme ekranını aç
            showRecordView = true

        case "note":
            // Belirli bir notu aç - URL path'inden ID al
            if let noteId = url.pathComponents.last, !noteId.isEmpty {
                deepLinkNoteId = noteId
                // TODO: Navigate to specific note detail
            }

        case "notes":
            // Notlar sekmesine git - MainTabView'da tab değişikliği gerekir
            break

        default:
            break
        }
    }

    private func signInAnonymously() async {
        // Timeout after 5 seconds if auth is taking too long
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if !authService.isAuthenticated {
                print("⚠️ Auth timeout - bypassing auth")
                await MainActor.run { authFailed = true }
            }
        }

        do {
            try await authService.signInAnonymously()
        } catch {
            print("❌ Auth error: \(error)")
            await MainActor.run { authFailed = true }
        }
    }

    private func startServices() {
        guard let userId = authService.currentUserId else { return }

        // User profil dinlemeye başla
        userService.startListening(userId: userId)

        // Notes dinlemeye başla
        notesService.startListening()

        // Namaz vakitlerini yükle
        Task {
            await prayerTimesService.fetchForCurrentUser()
        }
    }
}

// MARK: - Splash View
struct SplashView: View {
    var body: some View {
        ZStack {
            Color.islamicBackground
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.islamicGold)

                Text(Strings.App.name)
                    .font(AppFont.largeTitle)
                    .foregroundColor(.islamicBrown)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .islamicGold))
            }
        }
    }
}

// MARK: - Auth Loading View
struct AuthLoadingView: View {
    var body: some View {
        ZStack {
            Color.islamicBackground
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 50))
                    .foregroundColor(.islamicGold)

                Text("Giriş yapılıyor...")
                    .font(AppFont.bodyText)
                    .foregroundColor(.islamicTextSecondary)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .islamicGold))
            }
        }
    }
}
