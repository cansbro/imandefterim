import SwiftUI

// MARK: - Today View
struct TodayView: View {
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var prayerTimesService: PrayerTimesService
    @EnvironmentObject var entitlementManager: EntitlementManager

    @StateObject private var dailyContentService = DailyContentService.shared
    @State private var showAIChat = false
    @State private var showPrayerTimes = false

    private let calendar = Calendar.current
    private let today = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header (Always visible)
                CustomNavigationHeader(title: Strings.Today.title)

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Quota Card
                        QuotaCard()

                        // AI Chat Card (New)
                        AIChatCard(onTap: { showAIChat = true })

                        // Compact Verse Card (Redesigned)
                        compactHeroCard

                        // Week mini calendar
                        weekCalendar

                        // Mini cards row
                        HStack(spacing: Spacing.md) {
                            nextPrayerCard
                        }

                        // Prayer Times List
                        prayerTimesSection
                    }
                    .padding(Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .background(Color.islamicBackground)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showPrayerTimes) {
            FirestorePrayerTimesView()
        }
        .fullScreenCover(isPresented: $showAIChat) {
            AIChatView()
        }
        .onAppear {
            refreshPrayerTimes()
            dailyContentService.checkAndUpdateDailyContent()
        }
        .onChange(of: userService.currentUserProfile?.cityPlateCode) { _, _ in
            refreshPrayerTimes()
        }
    }

    private func refreshPrayerTimes() {
        Task {
            await prayerTimesService.fetchForCurrentUser()
        }
    }

    // MARK: - Compact Verse Card (Redesign)
    private var compactHeroCard: some View {
        AppCard {
            if let content = dailyContentService.currentContent {
                HStack(alignment: .top, spacing: Spacing.md) {
                    // Left: Vertical Line & Icon
                    VStack(spacing: 8) {
                        Image(systemName: "book.closed.fill")
                            .foregroundColor(.islamicGold)
                            .font(.system(size: 20))

                        Capsule()
                            .fill(Color.islamicGold.opacity(0.3))
                            .frame(width: 2)
                    }
                    .frame(maxHeight: .infinity)

                    // Right: Verse Content
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Günün Ayeti")
                                .font(AppFont.caption)
                                .foregroundColor(.islamicTextTertiary)
                                .textCase(.uppercase)

                            Spacer()

                            ShareLink(item: generateShareText(content: content)) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16))
                                    .foregroundColor(.islamicGold)
                            }
                        }

                        Text(content.verse.text)
                            .font(AppFont.bodyMedium(15))
                            .foregroundColor(.islamicBrown)
                            .lineLimit(3)

                        Text(content.verse.reference)
                            .font(AppFont.caption2)
                            .foregroundColor(.islamicTextSecondary)
                    }
                }
                .padding(.vertical, Spacing.xs)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }

    private func generateShareText(content: DailyContent) -> String {
        return """
            \(content.verse.textArabic)

            \(content.verse.text)

            \(content.verse.reference)

            İman Defterim ile paylaşıldı.
            """
    }

    // MARK: - Week Calendar
    private var weekCalendar: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(-3..<4, id: \.self) { offset in
                if let date = calendar.date(byAdding: .day, value: offset, to: today) {
                    DayCell(
                        date: date,
                        isToday: offset == 0,
                        hasStreak: offset <= 0 && offset >= -2
                    )
                }
            }
        }
    }

    // MARK: - Next Prayer Card
    private var nextPrayerCard: some View {
        Button(action: { showPrayerTimes = true }) {
            AppCard(showBorder: true) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "moon.stars.fill")
                            .foregroundColor(.islamicGold)
                        Text(Strings.Today.nextPrayer)
                            .font(AppFont.caption)
                            .foregroundColor(.islamicTextSecondary)
                    }

                    if prayerTimesService.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if let error = prayerTimesService.error {
                        VStack(alignment: .leading) {
                            Text("Hata oluştu")
                                .font(AppFont.caption)
                                .foregroundColor(.red)
                            Button("Tekrar Dene") {
                                refreshPrayerTimes()
                            }
                            .font(AppFont.caption2)
                            .foregroundColor(.islamicGold)
                        }
                    } else if let next = prayerTimesService.nextPrayer() {
                        Text(next.name)
                            .font(AppFont.headline)
                            .foregroundColor(.islamicBrown)

                        HStack {
                            Text(next.time)
                                .font(AppFont.title3)
                                .foregroundColor(.islamicGold)

                            Text("(\(next.remaining))")
                                .font(AppFont.caption)
                                .foregroundColor(.islamicTextTertiary)
                        }
                    } else {
                        // If no next prayer, show failure or Imsak next day
                        Text("Vakitler Alınamadı")
                            .font(AppFont.subheadline)
                            .foregroundColor(.islamicTextTertiary)
                    }

                    // City name
                    if let city = userService.currentUserProfile?.cityName {
                        Text(city)
                            .font(AppFont.caption)
                            .foregroundColor(.islamicTextTertiary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // Daily Verse Card Removed (Merged into Hero Card)

    // MARK: - Prayer Times Section (replaces Quick Actions)
    private var prayerTimesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(Strings.Today.prayerTimes)
                    .font(AppFont.headline)
                    .foregroundColor(.islamicBrown)

                Spacer()

                if let city = userService.currentUserProfile?.cityName {
                    Text(city)
                        .font(AppFont.caption)
                        .foregroundColor(.islamicTextTertiary)
                }
            }

            if prayerTimesService.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else {
                // Compact prayer times grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: Spacing.sm
                ) {
                    ForEach(prayerTimesService.allTimes(), id: \.name) { prayer in
                        CompactPrayerTimeCell(
                            name: prayer.name,
                            time: prayer.time,
                            icon: prayer.icon,
                            isNext: prayer.isNext
                        )
                    }
                }
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: today)
    }
}

// MARK: - Compact Prayer Time Cell
struct CompactPrayerTimeCell: View {
    let name: String
    let time: String
    let icon: String
    let isNext: Bool

    var body: some View {
        VStack(spacing: Spacing.xs) {
            // Icon
            ZStack {
                Circle()
                    .fill(isNext ? Color.islamicGold : Color.islamicLightGray)
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isNext ? .white : .islamicWarmGray)
            }

            // Name
            Text(name)
                .font(isNext ? AppFont.caption : AppFont.caption2)
                .foregroundColor(isNext ? .islamicBrown : .islamicTextSecondary)
                .fontWeight(isNext ? .semibold : .regular)

            // Time
            Text(time)
                .font(isNext ? AppFont.bodyMedium(14) : AppFont.caption)
                .foregroundColor(isNext ? .islamicGold : .islamicBrown)
                .fontWeight(isNext ? .bold : .medium)

            // Next indicator
            if isNext {
                Text("Sıradaki")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.islamicGold)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(isNext ? Color.islamicGold.opacity(0.1) : Color.islamicCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(isNext ? Color.islamicGold : Color.clear, lineWidth: 1)
                )
        )
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let isToday: Bool
    let hasStreak: Bool

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).prefix(2).uppercased()
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayName)
                .font(AppFont.caption2)
                .foregroundColor(isToday ? .islamicGold : .islamicTextTertiary)

            ZStack {
                Circle()
                    .fill(isToday ? Color.islamicGold : Color.clear)
                    .frame(width: 36, height: 36)

                Text(dayNumber)
                    .font(AppFont.bodyMedium(14))
                    .foregroundColor(isToday ? .white : .islamicBrown)
            }

            // Streak indicator
            Circle()
                .fill(hasStreak ? Color.islamicGold : Color.clear)
                .frame(width: 4, height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TodayView()
        .environmentObject(UserService.shared)
        .environmentObject(PrayerTimesService.shared)
        .environmentObject(EntitlementManager.shared)

}
