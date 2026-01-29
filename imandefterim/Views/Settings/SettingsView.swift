import StoreKit
import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var prayerTimesService: PrayerTimesService
    @EnvironmentObject var entitlementManager: EntitlementManager
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @State private var showCityPicker = false

    // Local state synced with Firestore
    @State private var prayerNotificationsEnabled = true
    @State private var dailyVerseEnabled = true
    @State private var prayerTimeOffset = 15
    @State private var showSubscriptionManagement = false

    // TODO: Replace these with your actual Notion or web links
    private let privacyPolicyURL = URL(
        string:
            "https://phase-fennel-4a2.notion.site/Gizlilik-Politikas-man-Defterim-2f2ac5640a7880babf1dfa7c6a194675?source=copy_link"
    )!
    private let termsOfUseURL = URL(
        string:
            "https://phase-fennel-4a2.notion.site/man-Defterim-Kullan-m-Ko-ullar-2f2ac5640a788091b795d778dd554a6f?source=copy_link"
    )!
    private let feedbackEmail = "imandefterim@gmail.com"
    // Valid App Store ID
    private let appStoreID = "6758206613"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header (Always visible)
                CustomNavigationHeader(title: Strings.Settings.title)

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Subscription & Premium
                        settingsSection("Abonelik") {
                            Button(action: {
                                showSubscriptionManagement = true
                            }) {
                                HStack(spacing: Spacing.md) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.islamicGold)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entitlementManager.currentPlan.displayName)
                                            .font(AppFont.bodyText)
                                            .foregroundColor(.islamicBrown)

                                        if entitlementManager.currentPlan == .free {
                                            Text("Basic veya Pro'ya yükseltin")
                                                .font(AppFont.caption)
                                                .foregroundColor(.islamicTextSecondary)
                                        } else {
                                            Text("Planı Yönet")
                                                .font(AppFont.caption)
                                                .foregroundColor(.islamicTextSecondary)
                                        }
                                    }

                                    Spacer()

                                    if entitlementManager.currentPlan == .free {
                                        Text("Yükselt")
                                            .font(AppFont.subheadline)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.islamicGold)
                                            .cornerRadius(8)
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.islamicWarmGray)
                                    }
                                }
                            }
                        }

                        if entitlementManager.currentPlan == .free {
                            PremiumBanner()
                        }

                        // City Selection
                        settingsSection("Namaz Ayarları") {
                            SettingsRow(
                                icon: "location.fill",
                                title: Strings.Settings.city,
                                value: userService.currentUserProfile?.cityName ?? "İstanbul"
                            ) {
                                showCityPicker = true
                            }
                        }

                        // Notifications
                        settingsSection("Bildirimler") {
                            SettingsToggleRow(
                                icon: "bell.fill",
                                title: "Namaz Vakti Bildirimleri",
                                isOn: $prayerNotificationsEnabled
                            )
                            .onChange(of: prayerNotificationsEnabled) { _, newValue in
                                updateNotificationPref(prayer: newValue)
                            }

                            if prayerNotificationsEnabled {
                                Divider()
                                    .padding(.leading, 56)

                                HStack(spacing: Spacing.md) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 18))
                                        .foregroundColor(.islamicGold)
                                        .frame(width: 24)

                                    Text("Bildirim Zamanı")
                                        .font(AppFont.bodyText)
                                        .foregroundColor(.islamicBrown)

                                    Spacer()

                                    Menu {
                                        Picker("Süre", selection: $prayerTimeOffset) {
                                            Text("30 dk önce").tag(30)
                                            Text("15 dk önce").tag(15)
                                            Text("10 dk önce").tag(10)
                                            Text("5 dk önce").tag(5)
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text("\(prayerTimeOffset) dk önce")
                                                .font(AppFont.subheadline)
                                                .foregroundColor(.islamicTextSecondary)
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.caption)
                                                .foregroundColor(.islamicWarmGray)
                                        }
                                    }
                                }
                                .onChange(of: prayerTimeOffset) { _, newValue in
                                    updateNotificationPref(offset: newValue)
                                }
                            }

                        }

                        // About
                        settingsSection(Strings.Settings.about) {
                            SettingsRow(
                                icon: "star.fill",
                                title: Strings.Settings.rateApp,
                                value: nil
                            ) {
                                // Open App Store review page directly using itms-apps scheme
                                if let url = URL(
                                    string:
                                        "itms-apps://itunes.apple.com/app/id\(appStoreID)?action=write-review"
                                ) {
                                    openURL(url)
                                }
                            }

                            Divider()
                                .padding(.leading, 56)

                            SettingsRow(
                                icon: "envelope.fill",
                                title: Strings.Settings.feedback,
                                value: nil
                            ) {
                                sendFeedbackEmail()
                            }

                            Divider()
                                .padding(.leading, 56)

                            SettingsRow(
                                icon: "doc.text.fill",
                                title: Strings.Settings.privacyPolicy,
                                value: nil
                            ) {
                                openURL(privacyPolicyURL)
                            }

                            Divider()
                                .padding(.leading, 56)

                            SettingsRow(
                                icon: "doc.fill",
                                title: Strings.Settings.termsOfUse,
                                value: nil
                            ) {
                                openURL(termsOfUseURL)
                            }
                        }

                        // Version
                        Text("\(Strings.Settings.version) 1.0.0")
                            .font(AppFont.caption)
                            .foregroundColor(.islamicTextTertiary)
                            .padding(.top, Spacing.md)

                        // Sign Out
                        Button(action: {
                            do {
                                try AuthService.shared.signOut()
                            } catch {
                                print("Sign out error: \(error)")
                            }
                        }) {
                            Text("Çıkış Yap")
                                .font(AppFont.bodyText)
                                .foregroundColor(.red.opacity(0.8))
                                .padding(.vertical, Spacing.sm)
                        }
                        .padding(.top, Spacing.md)
                    }
                    .padding(Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .background(Color.islamicBackground)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showCityPicker) {
            FirestoreCityPickerView()
        }
        .sheet(isPresented: $showSubscriptionManagement) {
            SubscriptionManagementView()
        }
        .onAppear {
            syncFromFirestore()
        }
    }

    // MARK: - Settings Section Builder
    private func settingsSection<Content: View>(
        _ title: String, @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(AppFont.caption)
                .foregroundColor(.islamicTextSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, Spacing.xs)

            AppCard {
                content()
            }
        }
    }

    private func syncFromFirestore() {
        if let prefs = userService.currentUserProfile?.notificationPrefs {
            prayerNotificationsEnabled = prefs.prayerTimesEnabled
            dailyVerseEnabled = prefs.dailyVerseEnabled
            if let offset = prefs.prayerTimeOffset {
                prayerTimeOffset = offset
            }
        }
    }

    private func updateNotificationPref(prayer: Bool? = nil, verse: Bool? = nil, offset: Int? = nil)
    {
        Task {
            try? await userService.updateNotificationPrefs(
                prayerTimesEnabled: prayer,
                dailyVerseEnabled: verse,
                prayerTimeOffset: offset
            )
        }
    }

    private func sendFeedbackEmail() {
        let subject = "İman Defterim Geri Bildirim"
        let body = "Merhaba,\n\nUygulamanız hakkında geri bildirimim:\n\n"
        let encodedSubject =
            subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(
            string: "mailto:\(feedbackEmail)?subject=\(encodedSubject)&body=\(encodedBody)")
        {
            openURL(url)
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.islamicGold)
                    .frame(width: 24)

                Text(title)
                    .font(AppFont.bodyText)
                    .foregroundColor(.islamicBrown)

                Spacer()

                if let value = value {
                    Text(value)
                        .font(AppFont.subheadline)
                        .foregroundColor(.islamicTextSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.islamicWarmGray)
            }
        }
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.islamicGold)
                .frame(width: 24)

            Text(title)
                .font(AppFont.bodyText)
                .foregroundColor(.islamicBrown)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(.islamicGold)
        }
    }
}

// MARK: - Firestore City Picker View
struct FirestoreCityPickerView: View {
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var prayerTimesService: PrayerTimesService
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredCities: [TurkishCity] {
        if searchText.isEmpty {
            return TurkishCity.allCases
        }
        return TurkishCity.allCases.filter {
            $0.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCities) { city in
                    Button(action: {
                        selectCity(city)
                    }) {
                        HStack {
                            Text(city.displayName)
                                .font(AppFont.bodyText)
                                .foregroundColor(.islamicBrown)

                            Spacer()

                            if userService.currentUserProfile?.cityName == city.rawValue {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.islamicGold)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: Strings.Notes.search)
            .navigationTitle(Strings.Settings.selectCity)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func selectCity(_ city: TurkishCity) {
        Task {
            try? await userService.updateCity(plateCode: city.plateCode, cityName: city.rawValue)
            await prayerTimesService.fetchForCurrentUser()
            dismiss()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(UserService.shared)
        .environmentObject(PrayerTimesService.shared)
        .environmentObject(EntitlementManager.shared)
}
