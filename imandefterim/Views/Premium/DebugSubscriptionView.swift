import SwiftUI

// MARK: - Debug Subscription View (Dev Only)
#if DEBUG
    struct DebugSubscriptionView: View {
        @EnvironmentObject var entitlementManager: EntitlementManager
        @Environment(\.dismiss) private var dismiss

        @State private var selectedPlan: SubscriptionPlan
        @State private var aiQuestions: Double
        @State private var voiceNotesWeek: Double
        @State private var voiceNotesMonth: Double

        init() {
            let manager = EntitlementManager.shared
            _selectedPlan = State(initialValue: manager.currentPlan)
            _aiQuestions = State(initialValue: Double(manager.quota.aiQuestionsToday))
            _voiceNotesWeek = State(initialValue: Double(manager.quota.voiceNotesThisWeek))
            _voiceNotesMonth = State(initialValue: Double(manager.quota.voiceNotesThisMonth))
        }

        var body: some View {
            NavigationStack {
                List {
                    // Plan Selection
                    Section("Plan Seçimi") {
                        ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                            Button(action: {
                                selectedPlan = plan
                                entitlementManager.setDebugPlan(plan)
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(plan.displayName)
                                            .font(AppFont.bodyText)
                                            .foregroundColor(.islamicBrown)

                                        Text(plan.badge ?? "Ücretsiz")
                                            .font(AppFont.caption)
                                            .foregroundColor(.islamicTextSecondary)
                                    }

                                    Spacer()

                                    if selectedPlan == plan {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.islamicGold)
                                    }
                                }
                            }
                        }
                    }

                    // Quota Adjustment
                    Section("Kota Ayarları") {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Günlük AI Sorusu: \(Int(aiQuestions))")
                                .font(AppFont.bodyText)
                            Slider(value: $aiQuestions, in: 0...50, step: 1)
                                .tint(.islamicGold)
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Haftalık Sesli Not: \(Int(voiceNotesWeek))")
                                .font(AppFont.bodyText)
                            Slider(value: $voiceNotesWeek, in: 0...10, step: 1)
                                .tint(.islamicGold)
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Aylık Sesli Not: \(Int(voiceNotesMonth))")
                                .font(AppFont.bodyText)
                            Slider(value: $voiceNotesMonth, in: 0...50, step: 1)
                                .tint(.islamicGold)
                        }

                        Button("Kotayı Uygula") {
                            entitlementManager.setDebugQuota(
                                aiQuestions: Int(aiQuestions),
                                voiceNotesWeek: Int(voiceNotesWeek),
                                voiceNotesMonth: Int(voiceNotesMonth)
                            )
                        }
                        .foregroundColor(.islamicGold)
                    }

                    // Quick Presets
                    Section("Hızlı Ayarlar") {
                        Button("Limitleri Doldur (Free)") {
                            entitlementManager.setDebugPlan(.free)
                            entitlementManager.setDebugQuota(
                                aiQuestions: 3, voiceNotesWeek: 1, voiceNotesMonth: 1)
                            selectedPlan = .free
                            aiQuestions = 3
                            voiceNotesWeek = 1
                            voiceNotesMonth = 1
                        }
                        .foregroundColor(.orange)

                        Button("Kotayı Sıfırla") {
                            entitlementManager.resetQuota()
                            aiQuestions = 0
                            voiceNotesWeek = 0
                            voiceNotesMonth = 0
                        }
                        .foregroundColor(.green)
                    }

                    // Current State
                    Section("Mevcut Durum") {
                        LabeledContent("Plan", value: entitlementManager.currentPlan.displayName)
                        LabeledContent(
                            "Kayıt Yapabilir",
                            value: entitlementManager.canRecord ? "Evet" : "Hayır")
                        LabeledContent(
                            "AI Kullanabilir",
                            value: entitlementManager.canAskAI ? "Evet" : "Hayır")
                        LabeledContent(
                            "Kalan Günlük AI", value: "\(entitlementManager.remainingAIQuestions)")

                        if let remaining = entitlementManager.remainingRecordings {
                            LabeledContent("Kalan Kayıt", value: "\(remaining)")
                        }
                    }
                }
                .navigationTitle("🛠 Paywall Test")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Tamam") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    #Preview {
        DebugSubscriptionView()
            .environmentObject(EntitlementManager.shared)
    }
#endif
