import SwiftUI

// MARK: - Premium Banner (Updated)
struct PremiumBanner: View {
    @EnvironmentObject var entitlementManager: EntitlementManager
    @State private var showPaywall = false

    var body: some View {
        // Don't show if user is already premium
        if entitlementManager.currentPlan == .free {
            Button(action: { showPaywall = true }) {
                HStack(spacing: Spacing.md) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.islamicGold.opacity(0.2))
                            .frame(width: 44, height: 44)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.islamicGold)
                    }

                    // Text
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Premium.title)
                            .font(AppFont.headline)
                            .foregroundColor(.islamicBrown)

                        Text("Transkript, özet ve dua çıkarımı ile arşivini güçlendir.")
                            .font(AppFont.caption)
                            .foregroundColor(.islamicTextSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Arrow
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.islamicGold)
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(Color.islamicGold.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.lg)
                                .stroke(Color.islamicGold.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showPaywall) {
                PaywallView(trigger: .manual)
                    .environmentObject(entitlementManager)
            }
        }
    }
}

// MARK: - Quota Card (for Today screen)
struct QuotaCard: View {
    @EnvironmentObject var entitlementManager: EntitlementManager
    @State private var showPaywall = false

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    Text("Aylık Kullanım")
                        .font(AppFont.headline)
                        .foregroundColor(.islamicBrown)

                    Spacer()

                    // Plan badge
                    Text(entitlementManager.currentPlan.displayName)
                        .font(AppFont.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 2)
                        .background(
                            entitlementManager.currentPlan == .pro
                                ? Color.islamicGold
                                : entitlementManager.currentPlan == .starter
                                    ? Color.green : Color.islamicWarmGray
                        )
                        .clipShape(Capsule())
                }

                // Quota bars
                if entitlementManager.currentPlan == .free {
                    // Recording quota (Weekly for Free)
                    QuotaProgressRow(
                        title: "Sesli Not (Haftalık)",
                        current: entitlementManager.quota.voiceNotesThisWeek,
                        max: entitlementManager.currentPlan.voiceNoteLimit ?? 1,
                        unit: ""
                    )

                    // AI quota (Daily)
                    QuotaProgressRow(
                        title: "AI Sorusu (Günlük)",
                        current: entitlementManager.quota.aiQuestionsToday,
                        max: entitlementManager.currentPlan.dailyAIQuestionsLimit,
                        unit: "",
                        showRemaining: true
                    )
                } else if entitlementManager.currentPlan == .starter {
                    // Recording quota (Monthly for Basic)
                    QuotaProgressRow(
                        title: "Sesli Not (Aylık)",
                        current: entitlementManager.quota.voiceNotesThisMonth,
                        max: entitlementManager.currentPlan.voiceNoteLimit ?? 15,
                        unit: ""
                    )

                    // AI quota (Daily)
                    QuotaProgressRow(
                        title: "AI Sorusu (Günlük)",
                        current: entitlementManager.quota.aiQuestionsToday,
                        max: entitlementManager.currentPlan.dailyAIQuestionsLimit,
                        unit: "",
                        showRemaining: true
                    )
                } else {
                    // Pro
                    Text("Sınırsız Kullanım")
                        .font(AppFont.bodyMedium(14))
                        .foregroundColor(.islamicGold)
                }

                // Upgrade CTA for free users
                if entitlementManager.currentPlan == .free {
                    Button(action: { showPaywall = true }) {
                        HStack {
                            Text("Premium'u Aç")
                                .font(AppFont.bodyMedium(14))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.islamicGold)
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(trigger: .manual)
                .environmentObject(entitlementManager)
        }
    }
}

// MARK: - Quota Progress Row
struct QuotaProgressRow: View {
    let title: String
    let current: Int
    let max: Int
    var unit: String = ""
    var showRemaining: Bool = false

    private var progress: Double {
        guard max > 0 else { return 0 }
        return min(1.0, Double(current) / Double(max))
    }

    private var remaining: Int {
        return Swift.max(0, max - current)
    }

    private var isLow: Bool {
        return remaining <= max / 5  // Less than 20%
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(title)
                    .font(AppFont.caption)
                    .foregroundColor(.islamicTextSecondary)

                Spacer()

                if showRemaining {
                    Text("\(remaining) \(unit) kaldı")
                        .font(AppFont.caption)
                        .foregroundColor(isLow ? .orange : .islamicTextTertiary)
                } else {
                    Text("\(current)/\(max)")
                        .font(AppFont.caption)
                        .foregroundColor(isLow ? .orange : .islamicTextTertiary)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.islamicLightGray)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(isLow ? Color.orange : Color.islamicGold)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Settings Premium Section
struct SettingsPremiumSection: View {
    @EnvironmentObject var entitlementManager: EntitlementManager
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Current plan info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mevcut Plan")
                        .font(AppFont.caption)
                        .foregroundColor(.islamicTextSecondary)

                    Text(entitlementManager.currentPlan.displayName)
                        .font(AppFont.headline)
                        .foregroundColor(.islamicBrown)
                }

                Spacer()

                if entitlementManager.currentPlan != .pro {
                    Button("Yükselt") {
                        showPaywall = true
                    }
                    .font(AppFont.bodyMedium(14))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.islamicGold)
                    .clipShape(Capsule())
                }
            }

            Divider()

            // AI quota details
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Bu Ay")
                    .font(AppFont.caption)
                    .foregroundColor(.islamicTextSecondary)

                // Recording
                HStack {
                    Text("Sesli Not")
                        .font(AppFont.bodyText)
                        .foregroundColor(.islamicBrown)
                    Spacer()
                    if let limit = entitlementManager.currentPlan.voiceNoteLimit {
                        let current =
                            entitlementManager.currentPlan == .free
                            ? entitlementManager.quota.voiceNotesThisWeek
                            : entitlementManager.quota.voiceNotesThisMonth
                        let period = entitlementManager.currentPlan == .free ? "Haftalık" : "Aylık"
                        Text("\(current)/\(limit) (\(period))")
                            .font(AppFont.bodyMedium(14))
                            .foregroundColor(.islamicTextSecondary)
                    } else {
                        Text("Sınırsız")
                            .font(AppFont.bodyMedium(14))
                            .foregroundColor(.islamicGold)
                    }
                }

                // AI Questions
                HStack {
                    Text("AI Sorusu (Günlük)")
                        .font(AppFont.bodyText)
                        .foregroundColor(.islamicBrown)
                    Spacer()
                    Text(
                        "\(entitlementManager.remainingAIQuestions)/\(entitlementManager.currentPlan.dailyAIQuestionsLimit)"
                    )
                    .font(AppFont.bodyMedium(14))
                    .foregroundColor(.islamicTextSecondary)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(trigger: .manual)
                .environmentObject(entitlementManager)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PremiumBanner()
        QuotaCard()
    }
    .padding()
    .environmentObject(EntitlementManager.shared)
}
