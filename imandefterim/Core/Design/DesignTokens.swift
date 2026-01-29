import SwiftUI

// MARK: - Color Palette (Premium Islamic Theme)
extension Color {
    // Primary colors - Referans uygulamadaki gibi koyu kahve/bronze
    static let islamicBrown = Color(red: 44 / 255, green: 24 / 255, blue: 16 / 255)  // #2C1810
    static let islamicDarkBrown = Color(red: 35 / 255, green: 20 / 255, blue: 14 / 255)  // Darker variant
    static let islamicGold = Color(red: 180 / 255, green: 140 / 255, blue: 80 / 255)  // Bronze/Gold
    static let islamicBronze = Color(red: 160 / 255, green: 120 / 255, blue: 70 / 255)  // Warmer bronze
    static let islamicCream = Color(red: 253 / 255, green: 248 / 255, blue: 243 / 255)  // #FDF8F3

    // Secondary colors
    static let islamicLightBrown = Color(red: 92 / 255, green: 64 / 255, blue: 51 / 255)
    static let islamicWarmGray = Color(red: 180 / 255, green: 170 / 255, blue: 160 / 255)
    static let islamicLightGray = Color(red: 245 / 255, green: 242 / 255, blue: 238 / 255)

    // Semantic colors
    static let islamicGreen = Color(red: 46 / 255, green: 139 / 255, blue: 87 / 255)  // #2E8B57
    static let islamicBlue = Color(red: 0 / 255, green: 122 / 255, blue: 255 / 255)  // #007AFF

    // Semantic colors
    static let islamicBackground = islamicCream
    static let islamicSurface = Color.white
    static let islamicCardBackground = Color.white
    static let islamicPrimary = islamicBrown
    static let islamicAccent = islamicGold
    static let islamicTextPrimary = islamicBrown
    static let islamicTextSecondary = islamicLightBrown
    static let islamicTextTertiary = islamicWarmGray

    // Gradient presets
    static let islamicGoldGradient = LinearGradient(
        colors: [islamicGold, islamicBronze],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let islamicBrownGradient = LinearGradient(
        colors: [islamicBrown, islamicDarkBrown],
        startPoint: .top,
        endPoint: .bottom
    )

    static let islamicPremiumGradient = LinearGradient(
        colors: [
            Color(red: 60 / 255, green: 40 / 255, blue: 30 / 255),
            Color(red: 40 / 255, green: 25 / 255, blue: 18 / 255),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography
struct AppFont {
    // Serif for titles (premium feel)
    static func serifTitle(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }

    static func serifMedium(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .serif)
    }

    // Regular for body
    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }

    static func bodyMedium(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium)
    }

    static func bodySemibold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold)
    }

    static func bodyBold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold)
    }

    // Presets
    static let largeTitle = serifTitle(32)
    static let title = serifTitle(24)
    static let title2 = serifTitle(20)
    static let title3 = serifMedium(18)
    static let headline = bodySemibold(17)
    static let bodyText = body(16)
    static let callout = body(15)
    static let subheadline = body(14)
    static let footnote = body(13)
    static let caption = body(12)
    static let caption1 = body(12)  // Added missing caption1
    static let caption2 = body(11)
    static let buttonText = bodySemibold(16)
}

// MARK: - Spacing
struct Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius
struct CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let full: CGFloat = 9999
}

// MARK: - Shadow
struct AppShadow {
    static let subtle = Color.black.opacity(0.04)
    static let light = Color.black.opacity(0.08)
    static let medium = Color.black.opacity(0.12)
    static let strong = Color.black.opacity(0.16)
}

// MARK: - Reusable Card Component
struct AppCard<Content: View>: View {
    let showBorder: Bool
    let content: () -> Content

    init(showBorder: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.showBorder = showBorder
        self.content = content
    }

    var body: some View {
        content()
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.islamicCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(showBorder ? Color.islamicGold.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .shadow(color: AppShadow.light, radius: 8, x: 0, y: 4)
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.bodySemibold(16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color.islamicGoldGradient)
                )
        }
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.bodyMedium(15))
                .foregroundColor(.islamicBrown)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color.islamicBrown.opacity(0.3), lineWidth: 1.5)
                )
        }
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color = .islamicGold) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(AppFont.caption)
            .foregroundColor(color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String, title: String, message: String, actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.islamicWarmGray)

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(AppFont.title3)
                    .foregroundColor(.islamicBrown)

                Text(message)
                    .font(AppFont.subheadline)
                    .foregroundColor(.islamicTextSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppFont.bodySemibold(14))
                        .foregroundColor(.islamicGold)
                }
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xxl)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .islamicGold))
                .scaleEffect(1.2)

            Text(Strings.Common.loading)
                .font(AppFont.subheadline)
                .foregroundColor(.islamicTextSecondary)
        }
    }
}

// MARK: - Waveform View
struct WaveformView: View {
    let isAnimating: Bool
    let barCount: Int
    let color: Color

    @State private var heights: [CGFloat] = []

    init(isAnimating: Bool = true, barCount: Int = 30, color: Color = .islamicGold) {
        self.isAnimating = isAnimating
        self.barCount = barCount
        self.color = color
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 4, height: heights.indices.contains(index) ? heights[index] : 10)
                    .animation(
                        isAnimating
                            ? Animation.easeInOut(duration: 0.4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.05)
                            : .default,
                        value: heights
                    )
            }
        }
        .onAppear {
            heights = (0..<barCount).map { _ in CGFloat.random(in: 10...50) }
            if isAnimating {
                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                    heights = (0..<barCount).map { _ in CGFloat.random(in: 10...50) }
                }
            }
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.title3)
                .foregroundColor(.islamicBrown)

            Spacer()

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppFont.subheadline)
                        .foregroundColor(.islamicGold)
                }
            }
        }
    }
}

// MARK: - Segment Control
struct SegmentControl: View {
    let options: [String]
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedIndex = index
                    }
                }) {
                    Text(options[index])
                        .font(AppFont.bodyMedium(14))
                        .foregroundColor(selectedIndex == index ? .white : .islamicBrown)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            selectedIndex == index
                                ? AnyShapeStyle(Color.islamicBrown) : AnyShapeStyle(Color.clear)
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
}
