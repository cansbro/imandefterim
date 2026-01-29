import StoreKit
import SwiftUI

// MARK: - Subscription Management View
struct SubscriptionManagementView: View {
    @EnvironmentObject var entitlementManager: EntitlementManager
    @StateObject private var storeKit = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var selectedPeriod: BillingPeriod = .yearly
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showManageAlert = false

    // URLs
    private let privacyPolicyURL = URL(
        string:
            "https://phase-fennel-4a2.notion.site/Gizlilik-Politikas-man-Defterim-2f2ac5640a7880babf1dfa7c6a194675"
    )!
    private let termsOfUseURL = URL(
        string:
            "https://phase-fennel-4a2.notion.site/man-Defterim-Kullan-m-Ko-ullar-2f2ac5640a788091b795d778dd554a6f"
    )!

    var body: some View {
        NavigationStack {
            ZStack {
                Color.islamicBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header
                        VStack(spacing: Spacing.xs) {
                            Text("Abonelik Planı Seçin")
                                .font(AppFont.title3)
                                .foregroundColor(.islamicBrown)

                            Text("İstediğiniz plana geçiş yapın")
                                .font(AppFont.caption)
                                .foregroundColor(.islamicTextSecondary)
                        }
                        .padding(.top, Spacing.md)

                        // Period Toggle
                        HStack(spacing: 0) {
                            ForEach([BillingPeriod.weekly, .monthly, .yearly], id: \.self) {
                                period in
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
                                        selectedPeriod == period
                                            ? .islamicBrown : .islamicTextSecondary
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.sm)
                                    .background(
                                        selectedPeriod == period
                                            ? Color.islamicCardBackground : Color.clear
                                    )
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(Color.islamicLightGray)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

                        // Plan Cards
                        VStack(spacing: Spacing.md) {
                            ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                                SubscriptionOptionCard(
                                    plan: plan,
                                    period: selectedPeriod,
                                    isSelected: entitlementManager.currentPlan == plan,
                                    price: SubscriptionPricing.standard(
                                        for: plan, period: selectedPeriod)?
                                        .formattedPrice
                                ) {
                                    handlePlanSelection(plan)
                                }
                            }
                        }

                        // Checkmark list for Pro
                        if entitlementManager.currentPlan != .pro {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Pro ile şunlara sahip olun:")
                                    .font(AppFont.caption)
                                    .foregroundColor(.islamicTextSecondary)
                                    .padding(.top, Spacing.md)

                                BenefitRow(icon: "infinity", text: "Tüm Özellikler Sınırsız")
                                BenefitRow(
                                    icon: "video.fill", text: "Video Analizi ve Sınırsız Not")
                                BenefitRow(icon: "person.2.fill", text: "Aile Paylaşımı Dahil")
                                BenefitRow(icon: "star.fill", text: "Yeni Özelliklere Erken Erişim")
                            }
                            .padding(.horizontal, Spacing.md)
                        }

                        Button(action: {
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions")
                            {
                                openURL(url)
                            }
                        }) {
                            Text("Apple Aboneliklerinde Yönet")
                                .font(AppFont.caption)
                                .foregroundColor(.islamicGold)
                                .underline()
                        }
                        .padding(.top, Spacing.md)

                        // Legal & Restore Section
                        VStack(spacing: Spacing.sm) {
                            Divider()
                                .padding(.vertical, Spacing.sm)

                            Button("Satın Alımları Geri Yükle") {
                                restorePurchases()
                            }
                            .font(AppFont.caption)
                            .foregroundColor(.islamicGold)

                            HStack(spacing: Spacing.lg) {
                                Button("Kullanım Koşulları") {
                                    openURL(termsOfUseURL)
                                }
                                .font(AppFont.caption)
                                .foregroundColor(.islamicTextSecondary)

                                Button("Gizlilik Politikası") {
                                    openURL(privacyPolicyURL)
                                }
                                .font(AppFont.caption)
                                .foregroundColor(.islamicTextSecondary)
                            }
                        }
                        .padding(.top, Spacing.md)
                    }
                    .padding(Spacing.md)
                    .padding(.bottom, Spacing.xxxl)  // Add padding for bottom safe area
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(.islamicBrown)
                }
            }
            .overlay {
                if isPurchasing || storeKit.isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                    }
                }
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Abonelik Yönetimi", isPresented: $showManageAlert) {
                Button("Ayarlara Git", role: .none) {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        openURL(url)
                    }
                }
                Button("İptal", role: .cancel) {}
            } message: {
                Text(
                    "Ücretsiz plana geçmek veya aboneliğinizi iptal etmek için Apple Abonelikler sayfasını kullanmalısınız."
                )
            }
        }
    }

    private func handlePlanSelection(_ plan: SubscriptionPlan) {
        if plan == .free {
            showManageAlert = true
            return
        }

        if plan == entitlementManager.currentPlan {
            return
        }

        purchase(plan)
    }

    private func purchase(_ plan: SubscriptionPlan) {
        guard let product = storeKit.product(for: plan, period: selectedPeriod) else {
            #if DEBUG
                entitlementManager.setDebugPlan(plan)
                dismiss()
            #else
                errorMessage = "Ürün bulunamadı."
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
                errorMessage = error.localizedDescription
                showError = true
            }
            isPurchasing = false
        }
    }

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

// MARK: - Subscription Option Card
struct SubscriptionOptionCard: View {
    let plan: SubscriptionPlan
    let period: BillingPeriod
    let isSelected: Bool
    var price: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: Spacing.xs) {
                        Text(plan.displayName)
                            .font(AppFont.headline)
                            .foregroundColor(.islamicBrown)

                        if let badge = plan.badge {
                            Text(badge)
                                .font(AppFont.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(plan == .pro ? Color.islamicGold : Color.green)
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 4) {
                        Text(plan.shortDescription)
                            .font(AppFont.caption)
                            .foregroundColor(.islamicTextSecondary)

                        if let price = price, plan != .free {
                            HStack(alignment: .top, spacing: 2) {
                                Text("•")
                                    .font(AppFont.caption)
                                    .foregroundColor(.islamicGold)
                                    .fontWeight(.medium)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(
                                        "\(price)/\(period == .weekly ? "hafta" : (period == .monthly ? "ay" : "yıl"))"
                                    )
                                    .font(AppFont.caption)
                                    .foregroundColor(.islamicGold)
                                    .fontWeight(.medium)

                                    Text("7 Gün Ücretsiz")
                                        .font(AppFont.caption2)
                                        .foregroundColor(.islamicGreen)
                                }
                            }
                        }
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.islamicGold)
                } else {
                    Circle()
                        .stroke(Color.islamicWarmGray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding()
            .background(Color.islamicCardBackground)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? Color.islamicGold : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SubscriptionManagementView()
        .environmentObject(EntitlementManager.shared)
}
