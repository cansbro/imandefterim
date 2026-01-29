import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var entitlementManager: EntitlementManager
    @State private var selectedTab: Tab = .today
    @State private var showRecordSheet = false
    @State private var showNewNoteSheet = false
    @State private var showYouTubeLinkView = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case .notes:
                    NotesView()
                case .today:
                    TodayView()
                case .quran:
                    QuranView()
                case .settings:
                    SettingsView()
                }
            }

            // Custom Tab Bar & Banner
            VStack(spacing: 0) {
                Spacer()

                // Ad Banner - Only show for free users
                if entitlementManager.currentPlan == .free {
                    BannerAdView()
                        .frame(height: 50)
                        .background(Color.islamicCardBackground)
                }

                CustomTabBar(
                    selectedTab: $selectedTab,
                    onPlusTap: { showNewNoteSheet = true }
                )
            }
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showNewNoteSheet) {
            NewNoteSheet(
                onRecordAudio: {
                    showNewNoteSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showRecordSheet = true
                    }
                },
                onYouTubeLink: {
                    showNewNoteSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showYouTubeLinkView = true
                    }
                }
            )
            .presentationDetents([.height(280)])  // Reduced height
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showRecordSheet) {
            RecordView()
        }
        .sheet(isPresented: $showYouTubeLinkView) {
            YouTubeLinkView()
        }
    }
}

// MARK: - New Note Sheet
struct NewNoteSheet: View {
    let onRecordAudio: () -> Void
    let onYouTubeLink: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Title
            Text("Yeni Not")
                .font(AppFont.title3)
                .foregroundColor(.islamicBrown)
                .padding(.top, 42)

            // Options
            VStack(spacing: Spacing.sm) {
                NewNoteOptionRow(
                    icon: "mic.fill",
                    iconColor: .islamicGold,
                    title: "Ses Kaydı",
                    action: onRecordAudio
                )

                NewNoteOptionRow(
                    icon: "play.circle.fill",
                    iconColor: .red,
                    title: "YouTube Linki",
                    action: onYouTubeLink
                )
            }
            .padding(.horizontal, Spacing.md)

            Spacer()

            // Close button
            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(Color.islamicLightGray)
                        .frame(width: 50, height: 50)

                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.islamicBrown)
                }
            }
            .padding(.bottom, Spacing.lg)
        }
        .background(Color.islamicBackground)
    }
}

// MARK: - New Note Option Row
struct NewNoteOptionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }

                // Title
                Text(title)
                    .font(AppFont.bodyText)
                    .foregroundColor(.islamicBrown)

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.islamicCardBackground)
            )
        }
    }
}

// MARK: - Tab Enum
enum Tab: CaseIterable {
    case notes
    case today
    case quran
    case settings

    var title: String {
        switch self {
        case .notes: return Strings.Tab.notes
        case .today: return Strings.Tab.today
        case .quran: return Strings.Tab.quran
        case .settings: return Strings.Tab.settings
        }
    }

    var icon: String {
        switch self {
        case .notes: return "doc.text"
        case .today: return "heart.fill"
        case .quran: return "book.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var selectedIcon: String {
        switch self {
        case .notes: return "doc.text.fill"
        case .today: return "heart.fill"
        case .quran: return "book.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    let onPlusTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Notes Tab
            TabBarButton(
                tab: .notes,
                selectedTab: $selectedTab
            )

            // Today Tab
            TabBarButton(
                tab: .today,
                selectedTab: $selectedTab
            )

            // Center Plus Button
            Button(action: onPlusTap) {
                ZStack {
                    Circle()
                        .fill(Color.islamicGoldGradient)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.islamicGold.opacity(0.4), radius: 8, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -16)

            // Quran Tab
            TabBarButton(
                tab: .quran,
                selectedTab: $selectedTab
            )

            // Settings Tab
            TabBarButton(
                tab: .settings,
                selectedTab: $selectedTab
            )
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.lg)
        .background(
            Rectangle()
                .fill(Color.islamicCardBackground)
                .shadow(color: AppShadow.medium, radius: 20, x: 0, y: -5)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let tab: Tab
    @Binding var selectedTab: Tab

    private var isSelected: Bool {
        selectedTab == tab
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .islamicGold : .islamicWarmGray)

                Text(tab.title)
                    .font(AppFont.caption2)
                    .foregroundColor(isSelected ? .islamicGold : .islamicWarmGray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    MainTabView()
}
