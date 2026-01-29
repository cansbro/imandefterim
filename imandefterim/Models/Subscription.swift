import Combine
import Foundation
import SwiftUI

// MARK: - Subscription Plan
enum SubscriptionPlan: String, Codable, CaseIterable {
    case free
    case starter
    case pro

    var displayName: String {
        switch self {
        case .free: return "Ücretsiz"
        case .starter: return "Basic"
        case .pro: return "Pro"
        }
    }

    var badge: String? {
        switch self {
        case .free: return nil
        case .starter: return "Önerilen"
        case .pro: return "Sınırsız"
        }
    }

    var shortDescription: String {
        switch self {
        case .free: return "Giriş Seviyesi"
        case .starter: return "Günlük Kullanıcı"
        case .pro: return "Derinlik Arayanlar"
        }
    }

    var bulletDescription: String {
        switch self {
        case .free: return "Günlük 3 AI Sorusu"
        case .starter: return "Günlük 20 AI Sorusu"
        case .pro: return "Tüm Özellikler Sınırsız"
        }
    }

    // AI Question Limits (per day)
    var dailyAIQuestionsLimit: Int {
        switch self {
        case .free: return 3
        case .starter: return 20
        case .pro: return 1000  // Effectively unlimited
        }
    }

    // Voice Note Limits (weekly or monthly)
    var voiceNoteLimit: Int? {
        switch self {
        case .free: return 1  // Weekly
        case .starter: return 15  // Monthly
        case .pro: return nil  // Unlimited
        }
    }

    // Max recording duration in seconds
    var maxRecordingDurationSec: Int? {
        switch self {
        case .free: return 60  // 1 min
        case .starter: return 300  // 5 min
        case .pro: return nil  // Unlimited
        }
    }

    // Plan Limits
    var recordingCountLimit: Int? {
        switch self {
        case .free: return 1
        case .starter: return 15
        case .pro: return nil
        }
    }

    var aiMinutesLimit: Int {
        switch self {
        case .free: return 3
        case .starter: return 20
        case .pro: return 1000
        }
    }

    var hasAIDetails: Bool { self != .free }
    var hasUnlimitedAI: Bool { self == .pro }
    var hasPrayerNotifications: Bool { self == .pro }
    var hasFamilySharing: Bool { self == .pro }
    var hasTranscriptSearch: Bool { self != .free }
}

// MARK: - Billing Period
enum BillingPeriod: String, Codable, CaseIterable {
    case weekly
    case monthly
    case yearly

    var displayName: String {
        switch self {
        case .weekly: return "Haftalık"
        case .monthly: return "Aylık"
        case .yearly: return "Yıllık"
        }
    }

    var savingsBadge: String? {
        switch self {
        case .weekly, .monthly: return nil
        case .yearly: return "En Avantajlı"
        }
    }
}

// MARK: - Subscription Pricing
struct SubscriptionPricing {
    let plan: SubscriptionPlan
    let period: BillingPeriod
    let price: Decimal
    let currency: String

    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: price as NSDecimalNumber) ?? "\(price) TL"
    }

    var monthlyEquivalent: Decimal? {
        guard period == .yearly else { return nil }
        return price / 12
    }

    var formattedMonthlyEquivalent: String? {
        guard let monthly = monthlyEquivalent else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: monthly as NSDecimalNumber)
    }

    // Mock pricing data
    static let starterWeekly = SubscriptionPricing(
        plan: .starter, period: .weekly, price: 49.99, currency: "TRY")
    static let starterMonthly = SubscriptionPricing(
        plan: .starter, period: .monthly, price: 129.99, currency: "TRY")
    static let starterYearly = SubscriptionPricing(
        plan: .starter, period: .yearly, price: 1299.99, currency: "TRY")

    static let proWeekly = SubscriptionPricing(
        plan: .pro, period: .weekly, price: 99.99, currency: "TRY")
    static let proMonthly = SubscriptionPricing(
        plan: .pro, period: .monthly, price: 299.99, currency: "TRY")
    static let proYearly = SubscriptionPricing(
        plan: .pro, period: .yearly, price: 2999.99, currency: "TRY")

    static func standard(for plan: SubscriptionPlan, period: BillingPeriod) -> SubscriptionPricing?
    {
        switch (plan, period) {
        case (.starter, .weekly): return .starterWeekly
        case (.starter, .monthly): return .starterMonthly
        case (.starter, .yearly): return .starterYearly
        case (.pro, .weekly): return .proWeekly
        case (.pro, .monthly): return .proMonthly
        case (.pro, .yearly): return .proYearly
        default: return nil
        }
    }

    static func savingsPercentage(plan: SubscriptionPlan) -> Int {
        switch plan {
        case .starter: return 48  // (79.99*12 - 499.99) / (79.99*12) ≈ 48%
        case .pro: return 50  // (149.99*12 - 899.99) / (149.99*12) ≈ 50%
        case .free: return 0
        }
    }
}

// MARK: - User Quota
struct UserQuota: Codable {
    var aiQuestionsToday: Int
    var voiceNotesThisWeek: Int
    var voiceNotesThisMonth: Int
    var lastDailyReset: Date
    var lastWeeklyReset: Date
    var lastMonthlyReset: Date

    static let initial = UserQuota(
        aiQuestionsToday: 0,
        voiceNotesThisWeek: 0,
        voiceNotesThisMonth: 0,
        lastDailyReset: Date(),
        lastWeeklyReset: Date(),
        lastMonthlyReset: Date()
    )

    // Check if quotas should reset
    mutating func resetIfNeeded() {
        let now = Date()
        let calendar = Calendar.current

        // Daily reset
        if !calendar.isDate(lastDailyReset, inSameDayAs: now) {
            aiQuestionsToday = 0
            lastDailyReset = now
        }

        // Weekly reset
        if !calendar.isDate(lastWeeklyReset, equalTo: now, toGranularity: .weekOfYear) {
            voiceNotesThisWeek = 0
            lastWeeklyReset = now
        }

        // Monthly reset
        if !calendar.isDate(lastMonthlyReset, equalTo: now, toGranularity: .month) {
            voiceNotesThisMonth = 0
            lastMonthlyReset = now
        }
    }
}

// MARK: - Entitlement Manager
final class EntitlementManager: ObservableObject {
    static let shared = EntitlementManager()

    @Published var currentPlan: SubscriptionPlan = .free
    @Published var quota: UserQuota = .initial
    @Published var showPaywall = false
    @Published var paywallTrigger: PaywallTrigger?

    private let quotaKey = "userQuota"
    private let planKey = "subscriptionPlan"

    private init() {
        loadState()
        quota.resetIfNeeded()
    }

    // MARK: - Persistence
    private func loadState() {
        if let planRaw = UserDefaults.standard.string(forKey: planKey),
            let plan = SubscriptionPlan(rawValue: planRaw)
        {
            currentPlan = plan
        } else {
            // Explicitly default to free if no saved state
            currentPlan = .free
        }

        if let quotaData = UserDefaults.standard.data(forKey: quotaKey),
            let savedQuota = try? JSONDecoder().decode(UserQuota.self, from: quotaData)
        {
            quota = savedQuota
        }

        // Sanity check: If plan is Starter (which shouldn't be default), force to Free
        // This fixes the issue where new users might be seeing Starter by mistake
        if currentPlan == .starter {
            currentPlan = .free
            saveState()
        }
    }

    private func saveState() {
        UserDefaults.standard.set(currentPlan.rawValue, forKey: planKey)
        if let quotaData = try? JSONEncoder().encode(quota) {
            UserDefaults.standard.set(quotaData, forKey: quotaKey)
        }
    }

    // MARK: - Plan Updates (for StoreKit)
    func updatePlan(_ plan: SubscriptionPlan) {
        DispatchQueue.main.async {
            self.currentPlan = plan
            self.saveState()
            print("✅ EntitlementManager: Plan updated to \(plan.displayName)")
        }
    }

    // MARK: - Recording Checks
    var canRecord: Bool {
        quota.resetIfNeeded()

        switch currentPlan {
        case .free:
            return quota.voiceNotesThisWeek < (currentPlan.voiceNoteLimit ?? 0)
        case .starter:
            return quota.voiceNotesThisMonth < (currentPlan.voiceNoteLimit ?? 0)
        case .pro:
            return true
        }
    }

    var remainingRecordings: Int? {
        quota.resetIfNeeded()
        guard let limit = currentPlan.voiceNoteLimit else { return nil }

        switch currentPlan {
        case .free:
            return max(0, limit - quota.voiceNotesThisWeek)
        case .starter:
            return max(0, limit - quota.voiceNotesThisMonth)
        case .pro:
            return nil
        }
    }

    // MARK: - AI Processing Checks
    var canAskAI: Bool {
        quota.resetIfNeeded()
        return quota.aiQuestionsToday < currentPlan.dailyAIQuestionsLimit
    }

    var remainingAIQuestions: Int {
        quota.resetIfNeeded()
        return Swift.max(0, currentPlan.dailyAIQuestionsLimit - quota.aiQuestionsToday)
    }

    var remainingAIMinutes: Int {
        return remainingAIQuestions
    }

    // MARK: - Quota Usage
    func useRecording() {
        quota.voiceNotesThisWeek += 1
        quota.voiceNotesThisMonth += 1
        saveState()
    }

    func useAIQuestion() {
        quota.aiQuestionsToday += 1
        saveState()
    }

    // MARK: - Paywall Triggers
    func triggerPaywallIfNeeded(for action: PaywallTrigger) -> Bool {
        switch action {
        case .recording:
            if !canRecord {
                paywallTrigger = action
                showPaywall = true
                return true
            }
        case .aiProcessing:
            if !canAskAI {
                paywallTrigger = action
                showPaywall = true
                return true
            }
        case .search, .notifications:
            if currentPlan == .free {
                paywallTrigger = action
                showPaywall = true
                return true
            }
        case .manual:
            paywallTrigger = action
            showPaywall = true
            return true
        }
        return false
    }

    var canProcessAI: Bool {
        return canAskAI
    }

    // MARK: - Debug (Dev only)
    #if DEBUG
        func setDebugPlan(_ plan: SubscriptionPlan) {
            currentPlan = plan
            saveState()
        }

        func setDebugQuota(aiQuestions: Int, voiceNotesWeek: Int, voiceNotesMonth: Int) {
            quota.aiQuestionsToday = aiQuestions
            quota.voiceNotesThisWeek = voiceNotesWeek
            quota.voiceNotesThisMonth = voiceNotesMonth
            saveState()
        }

        func resetQuota() {
            quota = .initial
            saveState()
        }
    #endif
}

// MARK: - Paywall Trigger
enum PaywallTrigger {
    case recording
    case aiProcessing
    case search
    case notifications
    case manual

    var title: String {
        switch self {
        case .recording: return "Kayıt Limitine Ulaştın"
        case .aiProcessing: return "Soru Limitine Ulaştın"
        case .search: return "Pro Özelliği"
        case .notifications: return "Pro Özelliği"
        case .manual: return "Premium'a Geç"
        }
    }

    var message: String {
        switch self {
        case .recording:
            return "Ücretsiz kullanım hakkın doldu. Daha fazla kayıt için Premium'a geçebilirsin."
        case .aiProcessing:
            return "Günlük soru limitine ulaştın. Gemini 3 Pro ile sınırsız sohbet için Pro'ya geç!"
        case .search:
            return "Arama özelliği Pro aboneliğe özeldir."
        case .notifications:
            return "Bildirimler Pro aboneliğe özeldir."
        case .manual:
            return "İman Defterim ile vaazlarını kaydet, özetle ve arşivle."
        }
    }
}
