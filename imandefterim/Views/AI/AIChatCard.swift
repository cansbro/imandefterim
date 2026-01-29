import SwiftUI

// MARK: - AI Chat Card
struct AIChatCard: View {
    @EnvironmentObject var usersService: UserService
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.islamicCardBackground)
                    .shadow(color: AppShadow.light, radius: 10, x: 0, y: 4)

                VStack(spacing: Spacing.md) {
                    // Header: Icon + Greeting
                    HStack(spacing: Spacing.md) {
                        // Animated AI Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                                .shadow(color: .purple.opacity(0.3), radius: 8)

                            Circle()
                                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                .frame(width: 48, height: 48)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("İman Defterim")
                                .font(AppFont.caption)
                                .foregroundColor(.islamicTextSecondary)

                            Text("AI ile sohbet et")
                                .font(AppFont.headline)
                                .foregroundColor(.islamicBrown)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.islamicTextTertiary)
                    }

                    // Divider
                    Rectangle()
                        .fill(Color.islamicGold.opacity(0.1))
                        .frame(height: 1)

                    // Suggestion Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            SuggestionChip(icon: "hands.sparkles.fill", text: "Rızık Duası")
                            SuggestionChip(icon: "heart.fill", text: "Sabır Duası")
                            SuggestionChip(icon: "book.fill", text: "Hz. Yusuf Kıssası")
                            SuggestionChip(icon: "moon.stars.fill", text: "Uyku Duası")
                        }
                        .padding(.horizontal, 2)  // avoid clipping shadow
                    }
                }
                .padding(Spacing.md)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Suggestion Chip
private struct SuggestionChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(AppFont.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.islamicTextSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.islamicBackground)
                .overlay(
                    Capsule()
                        .stroke(Color.islamicGold.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    AIChatCard(onTap: {})
        .environmentObject(UserService.shared)
        .padding()
        .background(Color.gray.opacity(0.1))
}
