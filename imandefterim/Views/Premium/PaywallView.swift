import SwiftUI

// MARK: - Paywall View
struct PaywallView: View {
    @EnvironmentObject var entitlementManager: EntitlementManager
    @StateObject private var storeKit = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var selectedPlan: SubscriptionPlan = .starter
    @State private var selectedPeriod: BillingPeriod = .weekly
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    let trigger: PaywallTrigger?

    // TODO: Update these with your actual Notion links
    private let privacyPolicyURL = URL(
        string:
            "https://phase-fennel-4a2.notion.site/Gizlilik-Politikas-man-Defterim-2f2ac5640a7880babf1dfa7c6a194675"
    )!
    private let termsOfUseURL = URL(
        string:
            "https://phase-fennel-4a2.notion.site/man-Defterim-Kullan-m-Ko-ullar-2f2ac5640a788091b795d778dd554a6f"
    )!

    init(trigger: PaywallTrigger? = nil) {
        self.trigger = trigger
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    headerSection

                    // Benefits
                    benefitsSection

                    // Period Toggle
                    periodToggle

                    // Plan Cards
                    planCardsSection

                    // CTA Button
                    ctaButton

                    // Trust Section
                    trustSection
                }
                .padding(Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(Color.islamicBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.islamicBrown)
                    }
                }
            }
            .overlay {
                if isPurchasing || storeKit.isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: Spacing.md) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.islamicGold)
                            Text("İşleniyor...")
                                .font(AppFont.bodyText)
                                .foregroundColor(.white)
                        }
                        .padding(Spacing.xl)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.lg)
                                .fill(Color.islamicBrown.opacity(0.9))
                        )
                    }
                }
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.islamicGold.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.islamicGold)
            }

            // Title
            Text(trigger == .manual ? "Premium'a Geç" : "İman Defterim Premium")
                .font(AppFont.largeTitle)
                .foregroundColor(.islamicBrown)
                .multilineTextAlignment(.center)

            // Subtitle
            Text(
                trigger?.message
                    ?? "Sınırsız kayıt, güçlü arama, namaz bildirimleri ve daha fazlası."
            )
            .font(AppFont.bodyText)
            .foregroundColor(.islamicTextSecondary)
            .multilineTextAlignment(.center)
        }
    }

    // MARK: - Benefits
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Free")
                .font(AppFont.caption)
                .fontWeight(.bold)
                .foregroundColor(.islamicGreen)
                .padding(.bottom, 2)

            BenefitRow(icon: "sparkles", text: "Günlük AI Sohbet (Kısıtlı)", color: .islamicGreen)
            BenefitRow(icon: "mic.fill", text: "Haftalık 1 Sesli Not (1 dk)", color: .islamicGreen)

            Divider()
                .padding(.vertical, Spacing.xs)

            Text("Basic")
                .font(AppFont.caption)
                .fontWeight(.bold)
                .foregroundColor(.islamicBlue)
                .padding(.bottom, 2)

            BenefitRow(icon: "nosign", text: "Reklamsız Deneyim", color: .islamicBlue)
            BenefitRow(icon: "book.fill", text: "Tüm Mealler ve Sesli Dinleme", color: .islamicBlue)
            BenefitRow(icon: "folder.fill", text: "Notları Klasörleme", color: .islamicBlue)
            BenefitRow(icon: "sparkles", text: "Günlük 20 AI Sorusu (Flash)", color: .islamicBlue)
            BenefitRow(
                icon: "mic.badge.plus", text: "Aylık 15 AI Özetli Not (5 dk)", color: .islamicBlue)

            Divider()
                .padding(.vertical, Spacing.xs)

            Text("Pro")
                .font(AppFont.caption)
                .fontWeight(.bold)
                .foregroundColor(.islamicGold)
                .padding(.bottom, 2)

            BenefitRow(
                icon: "infinity", text: "Tüm Özellikler Sınırsız", color: .islamicGold)
            BenefitRow(
                icon: "video.fill", text: "Video Analizi ve Sınırsız Not", color: .islamicGold)
            BenefitRow(icon: "person.2.fill", text: "Aile Paylaşımı Dahil", color: .islamicGold)
            BenefitRow(
                icon: "star.fill", text: "Yeni Özelliklere Erken Erişim", color: .islamicGold)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.islamicCardBackground)
        )
    }

    // MARK: - Period Toggle
    private var periodToggle: some View {
        HStack(spacing: 0) {
            ForEach([BillingPeriod.weekly, .monthly, .yearly], id: \.self) { period in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPeriod = period
                    }
                }) {
                    VStack(spacing: 2) {
                        if period == .yearly {
                            Text("%40+ Tasarruf")
                                .font(AppFont.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }

                        Text(period.displayName)
                            .font(AppFont.bodyMedium(15))
                    }
                    .foregroundColor(
                        selectedPeriod == period ? .islamicBrown : .islamicTextSecondary
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        selectedPeriod == period ? Color.islamicCardBackground : Color.clear
                    )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.islamicLightGray)
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    // MARK: - Plan Cards
    private var planCardsSection: some View {
        VStack(spacing: Spacing.md) {
            PlanCard(
                plan: .starter,
                period: selectedPeriod,
                isSelected: selectedPlan == .starter,
                onSelect: { selectedPlan = .starter }
            )

            PlanCard(
                plan: .pro,
                period: selectedPeriod,
                isSelected: selectedPlan == .pro,
                onSelect: { selectedPlan = .pro }
            )
        }
    }

    // MARK: - CTA Button
    private var ctaButton: some View {
        Button(action: purchaseSubscription) {
            HStack {
                VStack(spacing: 0) {
                    Text("7 Gün Ücretsiz Dene")
                        .font(AppFont.buttonText)

                    if let pricing = SubscriptionPricing.standard(
                        for: selectedPlan, period: selectedPeriod)
                    {
                        Text(
                            "Sonra \(pricing.formattedPrice) / \(selectedPeriod.displayName.lowercased())"
                        )
                        .font(AppFont.caption2)
                        .opacity(0.9)
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                selectedPlan == .pro
                    ? AnyShapeStyle(Color.islamicGoldGradient)
                    : AnyShapeStyle(Color.islamicBlue)
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
        .disabled(isPurchasing || storeKit.isLoading)
    }

    // MARK: - Trust Section
    private var trustSection: some View {
        VStack(spacing: Spacing.sm) {
            Text("İstediğin zaman iptal edebilirsin.")
                .font(AppFont.caption)
                .foregroundColor(.islamicTextTertiary)

            Text("Yıllık planla daha az öde, tüm yıl kesintisiz kullan.")
                .font(AppFont.caption)
                .foregroundColor(.islamicTextTertiary)

            HStack(spacing: Spacing.lg) {
                Button("Satın alımları geri yükle") {
                    restorePurchases()
                }
                .font(AppFont.caption)
                .foregroundColor(.islamicGold)

                Button("Kullanım Koşulları") {
                    openURL(termsOfUseURL)
                }
                .font(AppFont.caption)
                .foregroundColor(.islamicGold)

                Button("Gizlilik Politikası") {
                    openURL(privacyPolicyURL)
                }
                .font(AppFont.caption)
                .foregroundColor(.islamicGold)
            }
        }
    }

    // MARK: - Purchase
    private func purchaseSubscription() {
        guard let product = storeKit.product(for: selectedPlan, period: selectedPeriod) else {
            // Fallback to debug mode if products not loaded
            #if DEBUG
                entitlementManager.setDebugPlan(selectedPlan)
                dismiss()
            #else
                errorMessage = "Ürün bulunamadı. Lütfen internet bağlantınızı kontrol edin."
                showError = true
            #endif
            return
        }

        isPurchasing = true
        Task {
            do {
                let success = try await storeKit.purchase(product)
                if success {
                    dismiss()
                }
            } catch {
                errorMessage = "Satın alma hatası: \(error.localizedDescription)"
                showError = true
            }
            isPurchasing = false
        }
    }

    // MARK: - Restore
    private func restorePurchases() {
        Task {
            await storeKit.restorePurchases()

            if storeKit.hasActiveSubscription {
                dismiss()
            } else {
                errorMessage = "Geri yüklenecek satın alma bulunamadı."
                showError = true
            }
        }
    }
}

// MARK: - Benefit Row
struct BenefitRow: View {
    let icon: String
    let text: String
    var color: Color = .islamicGold

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(AppFont.bodyText)
                .foregroundColor(.islamicBrown)

            Spacer()
        }
    }
}

// MARK: - Plan Card
struct PlanCard: View {
    let plan: SubscriptionPlan
    let period: BillingPeriod
    let isSelected: Bool
    let onSelect: () -> Void

    private var pricing: SubscriptionPricing {
        switch (plan, period) {
        case (.starter, .weekly): return .starterWeekly
        case (.starter, .monthly): return .starterMonthly
        case (.starter, .yearly): return .starterYearly
        case (.pro, .weekly): return .proWeekly
        case (.pro, .monthly): return .proMonthly
        case (.pro, .yearly): return .proYearly
        default: return .starterMonthly
        }
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: Spacing.xs) {
                            Text(plan.displayName)
                                .font(AppFont.headline)
                                .foregroundColor(.islamicBrown)

                            if let badge = plan.badge {
                                Text(badge)
                                    .font(AppFont.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, Spacing.xs)
                                    .padding(.vertical, 2)
                                    .background(
                                        plan == .pro ? Color.islamicGold : Color.islamicBlue
                                    )
                                    .clipShape(Capsule())
                            }
                        }

                        Text(plan.shortDescription)
                            .font(AppFont.caption)
                            .foregroundColor(.islamicTextSecondary)
                    }

                    Spacer()

                    // Selection indicator
                    ZStack {
                        Circle()
                            .stroke(
                                isSelected ? Color.islamicGold : Color.islamicWarmGray, lineWidth: 2
                            )
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(Color.islamicGold)
                                .frame(width: 14, height: 14)
                        }
                    }
                }

                Divider()

                // Pricing
                HStack(alignment: .bottom, spacing: Spacing.xs) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pricing.formattedPrice)
                            .font(AppFont.title2)
                            .foregroundColor(.islamicBrown)

                        Text("7 Gün Ücretsiz")
                            .font(AppFont.caption2)
                            .foregroundColor(.islamicGreen)
                            .fontWeight(.bold)
                    }

                    Text("/\(period.displayName.lowercased())")
                        .font(AppFont.caption)
                        .foregroundColor(.islamicTextSecondary)
                        .padding(.bottom, 4)

                    Spacer()

                    if period == .yearly, let monthly = pricing.formattedMonthlyEquivalent {
                        Text("Aylık ~\(monthly)")
                            .font(AppFont.caption)
                            .foregroundColor(.islamicTextTertiary)
                            .padding(.bottom, 4)
                    }
                }

                // Bullet
                Text(plan.bulletDescription)
                    .font(AppFont.caption)
                    .foregroundColor(.islamicGold)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.islamicCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .stroke(isSelected ? Color.islamicGold : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Limit Reached View
struct LimitReachedView: View {
    @EnvironmentObject var entitlementManager: EntitlementManager
    @Environment(\.dismiss) private var dismiss

    let trigger: PaywallTrigger
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.orange)
            }

            // Title
            Text(trigger.title)
                .font(AppFont.title2)
                .foregroundColor(.islamicBrown)
                .multilineTextAlignment(.center)

            // Message
            Text(trigger.message)
                .font(AppFont.bodyText)
                .foregroundColor(.islamicTextSecondary)
                .multilineTextAlignment(.center)

            // Quota Display
            if entitlementManager.currentPlan == .free {
                QuotaDisplayCard()
            }

            // Buttons
            VStack(spacing: Spacing.sm) {
                Button(action: { showPaywall = true }) {
                    Text("Premium'u Aç")
                        .font(AppFont.buttonText)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.islamicGoldGradient)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                }

                Button("Daha Sonra") {
                    dismiss()
                }
                .font(AppFont.bodyText)
                .foregroundColor(.islamicTextSecondary)
            }
        }
        .padding(Spacing.xl)
        .background(Color.islamicBackground)
        .sheet(isPresented: $showPaywall) {
            PaywallView(trigger: trigger)
                .environmentObject(entitlementManager)
        }
    }
}

// MARK: - Quota Display Card
struct QuotaDisplayCard: View {
    @EnvironmentObject var entitlementManager: EntitlementManager

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text("Aylık Kullanım")
                .font(AppFont.caption)
                .foregroundColor(.islamicTextSecondary)

            HStack(spacing: Spacing.lg) {
                // Recording quota
                if let remaining = entitlementManager.remainingRecordings {
                    QuotaItem(
                        title: "Sesli Not",
                        value: "\(remaining) kaldı",
                        isLimited: remaining == 0
                    )
                } else {
                    QuotaItem(
                        title: "Sesli Not",
                        value: "Sınırsız",
                        isLimited: false
                    )
                }

                // AI quota
                QuotaItem(
                    title: "AI Sorusu",
                    value: "\(entitlementManager.remainingAIQuestions) kaldı",
                    isLimited: entitlementManager.remainingAIQuestions == 0
                )
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.islamicLightGray)
        )
    }
}

// MARK: - Quota Item
struct QuotaItem: View {
    let title: String
    let value: String
    var isLimited: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(AppFont.caption2)
                .foregroundColor(.islamicTextSecondary)

            Text(value)
                .font(AppFont.bodyMedium(14))
                .foregroundColor(isLimited ? .red : .islamicBrown)
        }
    }
}

#Preview {
    PaywallView(trigger: .manual)
        .environmentObject(EntitlementManager.shared)
}
