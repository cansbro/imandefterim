import SwiftUI

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentPage = 0
    @State private var showCityPicker = false
    @AppStorage("selectedCity") private var selectedCity: String = TurkishCity.istanbul.rawValue

    private let pages: [(icon: String, title: String, subtitle: String)] = [
        ("waveform.circle.fill", Strings.Onboarding.page1Title, Strings.Onboarding.page1Subtitle),
        ("moon.stars.fill", Strings.Onboarding.page2Title, Strings.Onboarding.page2Subtitle),
        ("book.fill", Strings.Onboarding.page3Title, Strings.Onboarding.page3Subtitle),
    ]

    var body: some View {
        ZStack {
            // Background gradient
            Color.islamicBrownGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button(Strings.Onboarding.skip) {
                            withAnimation {
                                currentPage = pages.count - 1
                            }
                        }
                        .font(AppFont.bodyMedium(15))
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .frame(height: 44)

                Spacer()

                // Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(
                            icon: pages[index].icon,
                            title: pages[index].title,
                            subtitle: pages[index].subtitle
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // Page indicators
                HStack(spacing: Spacing.xs) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(
                                currentPage == index ? Color.islamicGold : Color.white.opacity(0.3)
                            )
                            .frame(width: 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, Spacing.xxl)

                // Action buttons
                VStack(spacing: Spacing.md) {
                    if currentPage == pages.count - 1 {
                        // City selection button
                        Button(action: { showCityPicker = true }) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("\(Strings.Onboarding.selectCity): \(selectedCity)")
                            }
                            .font(AppFont.bodyMedium(15))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }

                        // Get started button
                        Button(action: completeOnboarding) {
                            Text(Strings.Onboarding.getStarted)
                                .font(AppFont.bodySemibold(16))
                                .foregroundColor(.islamicBrown)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .fill(Color.islamicGold)
                                )
                        }
                    } else {
                        Button(action: nextPage) {
                            Text(Strings.Onboarding.next)
                                .font(AppFont.bodySemibold(16))
                                .foregroundColor(.islamicBrown)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .fill(Color.islamicGold)
                                )
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }
        }
        .sheet(isPresented: $showCityPicker) {
            CityPickerSheet(selectedCity: $selectedCity)
        }
    }

    private func nextPage() {
        withAnimation(.spring()) {
            currentPage += 1
        }
    }

    private func completeOnboarding() {
        withAnimation {
            isOnboardingComplete = true
        }
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.islamicGold.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(.islamicGold)
            }

            // Text
            VStack(spacing: Spacing.md) {
                Text(title)
                    .font(AppFont.largeTitle)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(AppFont.bodyText)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - City Picker Sheet
struct CityPickerSheet: View {
    @Binding var selectedCity: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredCities: [TurkishCity] {
        if searchText.isEmpty {
            return TurkishCity.allCases
        }
        return TurkishCity.allCases.filter {
            $0.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCities) { city in
                    Button(action: {
                        selectedCity = city.rawValue
                        dismiss()
                    }) {
                        HStack {
                            Text(city.displayName)
                                .font(AppFont.bodyText)
                                .foregroundColor(.islamicBrown)

                            Spacer()

                            if selectedCity == city.rawValue {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.islamicGold)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: Strings.Notes.search)
            .navigationTitle(Strings.Onboarding.selectCity)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
