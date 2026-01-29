import SwiftUI

// MARK: - Quran View
struct QuranView: View {
    @State private var searchText = ""
    @State private var selectedSurah: Surah?

    private var filteredSurahs: [Surah] {
        if searchText.isEmpty {
            return QuranData.allSurahs
        }
        return QuranData.allSurahs.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.meaning.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header (Always visible)
                CustomNavigationHeader(title: Strings.Quran.title)

                ScrollView {
                    VStack(spacing: Spacing.md) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.islamicWarmGray)
                            TextField(Strings.Notes.search, text: $searchText)
                                .font(AppFont.bodyText)
                                .foregroundColor(.islamicTextPrimary)
                        }
                        .padding(Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(Color.islamicLightGray)
                        )
                        .padding(.horizontal, Spacing.md)

                        // Premium Banner
                        PremiumBanner()
                            .padding(.horizontal, Spacing.md)

                        // Surah List
                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(filteredSurahs) { surah in
                                SurahCard(surah: surah)
                                    .onTapGesture {
                                        selectedSurah = surah
                                    }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                    .padding(.top, Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .background(Color.islamicBackground)
            .navigationBarHidden(true)
        }
        .fullScreenCover(item: $selectedSurah) { surah in
            SurahDetailView(surah: surah)
        }
    }
}

// MARK: - Surah Card
struct SurahCard: View {
    let surah: Surah

    var body: some View {
        AppCard {
            HStack(spacing: Spacing.md) {
                // Surah number
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color.islamicGold.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Text("\(surah.id)")
                        .font(AppFont.bodySemibold(16))
                        .foregroundColor(.islamicGold)
                }

                // Surah info
                VStack(alignment: .leading, spacing: 2) {
                    Text(surah.name)
                        .font(AppFont.headline)
                        .foregroundColor(.islamicBrown)

                    HStack(spacing: Spacing.xs) {
                        Text(surah.meaning)
                            .font(AppFont.caption)
                            .foregroundColor(.islamicTextSecondary)

                        Text("•")
                            .foregroundColor(.islamicWarmGray)

                        Text("\(surah.verseCount) ayet")
                            .font(AppFont.caption)
                            .foregroundColor(.islamicTextSecondary)
                    }
                }

                Spacer()

                // Arabic name
                Text(surah.arabicName)
                    .font(.system(size: 22, design: .serif))
                    .foregroundColor(.islamicGold)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.islamicWarmGray)
            }
        }
    }
}

#Preview {
    QuranView()
}
