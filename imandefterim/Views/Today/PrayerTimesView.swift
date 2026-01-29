import SwiftUI

// MARK: - Firestore Prayer Times View
struct FirestorePrayerTimesView: View {
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var prayerTimesService: PrayerTimesService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // City Header
                    cityHeader

                    // All prayer times
                    if prayerTimesService.isLoading {
                        ProgressView()
                            .padding(.top, Spacing.xxxl)
                    } else {
                        prayerTimesList
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.islamicBackground)
            .navigationTitle(Strings.Prayer.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.islamicBrown)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(Strings.Prayer.refresh) {
                        Task {
                            await prayerTimesService.fetchForCurrentUser()
                        }
                    }
                    .foregroundColor(.islamicGold)
                }
            }
        }
    }

    // MARK: - City Header
    private var cityHeader: some View {
        AppCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let city = userService.currentUserProfile?.cityName {
                        Text(city)
                            .font(AppFont.title3)
                            .foregroundColor(.islamicBrown)
                    }

                    Text(formattedDate)
                        .font(AppFont.subheadline)
                        .foregroundColor(.islamicTextSecondary)
                }

                Spacer()

                Image(systemName: "location.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.islamicGold)
            }
        }
    }

    // MARK: - Prayer Times List
    private var prayerTimesList: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(prayerTimesService.allTimes(), id: \.name) { prayer in
                PrayerTimeRow(
                    name: prayer.name,
                    time: prayer.time,
                    icon: prayer.icon,
                    isNext: prayer.isNext
                )
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy, EEEE"
        return formatter.string(from: Date())
    }
}

// MARK: - Prayer Time Row
struct PrayerTimeRow: View {
    let name: String
    let time: String
    let icon: String
    let isNext: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(isNext ? Color.islamicGold : Color.islamicLightGray)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isNext ? .white : .islamicWarmGray)
            }

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(isNext ? AppFont.headline : AppFont.bodyText)
                    .foregroundColor(isNext ? .islamicBrown : .islamicTextSecondary)

                if isNext {
                    Text(Strings.Prayer.next)
                        .font(AppFont.caption)
                        .foregroundColor(.islamicGold)
                }
            }

            Spacer()

            // Time
            Text(time)
                .font(isNext ? AppFont.title3 : AppFont.bodyText)
                .foregroundColor(isNext ? .islamicGold : .islamicBrown)
                .fontWeight(isNext ? .semibold : .regular)
        }
        .padding(Spacing.md)
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

#Preview {
    FirestorePrayerTimesView()
        .environmentObject(UserService.shared)
        .environmentObject(PrayerTimesService.shared)
}
