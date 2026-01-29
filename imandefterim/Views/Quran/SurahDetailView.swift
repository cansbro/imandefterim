import SwiftUI

// MARK: - Surah Detail View
struct SurahDetailView: View {
    let surah: Surah
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioManager = AudioManager.shared
    @State private var autoScrollEnabled = true

    // Missing State Properties
    @State private var showArabic = true
    @State private var fontSize: CGFloat = 18

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                contentView(proxy: proxy)
            }
            .background(Color.islamicBackground)
            .navigationTitle(surah.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .overlay(alignment: .bottom) {
                overlayContent
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didFinishVerseAudio)) { _ in
            playNextVerse()
        }
        .onDisappear {
            audioManager.stop()
        }
    }

    // MARK: - Subviews

    private func contentView(proxy: ScrollViewProxy) -> some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                surahHeader
                    .id("header")

                if surah.id != 9 {
                    bismillahView
                }

                verseList
            }
            .padding(.top, Spacing.md)
        }
        .onChange(of: audioManager.currentVerse) { newVerse in
            if let verse = newVerse, autoScrollEnabled {
                withAnimation {
                    proxy.scrollTo(verse.id, anchor: .center)
                }
            }
        }
    }

    private var bismillahView: some View {
        Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
            .font(.system(size: 24, design: .serif))
            .foregroundColor(.islamicGold)
            .multilineTextAlignment(.center)
            .padding(.vertical, Spacing.md)
    }

    private var verseList: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach(surah.verses) { verse in
                VerseCard(
                    verse: verse,
                    showArabic: showArabic,
                    fontSize: fontSize,
                    isPlaying: audioManager.currentVerse?.id == verse.id
                )
                .id(verse.id)
                .onTapGesture {
                    audioManager.play(verse: verse)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, 100)
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(.islamicBrown)
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Menu {
                fontSizeMenu
                arabicToggle
            } label: {
                Image(systemName: "textformat")
                    .foregroundColor(.islamicGold)
            }
        }
    }

    private var fontSizeMenu: some View {
        Menu {
            Button("Küçük") { fontSize = 16 }
            Button("Normal") { fontSize = 18 }
            Button("Büyük") { fontSize = 22 }
        } label: {
            Label(Strings.Quran.fontSize, systemImage: "textformat.size")
        }
    }

    private var arabicToggle: some View {
        Button(action: { showArabic.toggle() }) {
            Label(
                showArabic ? Strings.Quran.hideArabic : Strings.Quran.showArabic,
                systemImage: showArabic ? "eye.slash" : "eye"
            )
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        if audioManager.currentVerse != nil {
            audioPlayerBar
        }
    }

    // MARK: - Audio Player Bar
    private var audioPlayerBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                // Info
                VStack(alignment: .leading) {
                    Text(
                        audioManager.currentVerse.map { "\(surah.displayName) \($0.number). Ayet" }
                            ?? ""
                    )
                    .font(AppFont.caption1)
                    .foregroundColor(.islamicTextSecondary)

                    Text(audioManager.currentVerse?.turkishMeal ?? "")
                        .font(AppFont.caption2)
                        .foregroundColor(.islamicTextTertiary)
                        .lineLimit(1)
                }

                Spacer()

                // Controls
                HStack(spacing: 20) {
                    // Previous
                    Button(action: playPreviousVerse) {
                        Image(systemName: "backward.end.fill")
                            .foregroundColor(.islamicBrown)
                    }

                    // Play/Pause
                    Button(action: {
                        if audioManager.isPlaying {
                            audioManager.pause()
                        } else if let verse = audioManager.currentVerse {
                            audioManager.play(verse: verse)
                        }
                    }) {
                        Image(
                            systemName: audioManager.isPlaying
                                ? "pause.circle.fill" : "play.circle.fill"
                        )
                        .font(.system(size: 44))
                        .foregroundColor(.islamicGold)
                    }

                    // Next
                    Button(action: playNextVerse) {
                        Image(systemName: "forward.end.fill")
                            .foregroundColor(.islamicBrown)
                    }

                    // Speed
                    Menu {
                        Button("1.0x") { audioManager.setRate(1.0) }
                        Button("1.25x") { audioManager.setRate(1.25) }
                        Button("1.5x") { audioManager.setRate(1.5) }
                    } label: {
                        Text(String(format: "%.2fx", audioManager.currentRate))
                            .font(AppFont.caption2)
                            .padding(6)
                            .background(Color.islamicGold.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            .padding()
            .background(Color.islamicBackground)  // Ensure visibility
            .background(.regularMaterial)
        }
    }

    private func playNextVerse() {
        guard let current = audioManager.currentVerse,
            let index = surah.verses.firstIndex(where: { $0.id == current.id }),
            index + 1 < surah.verses.count
        else {
            return
        }
        let nextVerse = surah.verses[index + 1]
        audioManager.play(verse: nextVerse)
    }

    private func playPreviousVerse() {
        guard let current = audioManager.currentVerse,
            let index = surah.verses.firstIndex(where: { $0.id == current.id }),
            index > 0
        else {
            return
        }
        let prevVerse = surah.verses[index - 1]
        audioManager.play(verse: prevVerse)
    }

    // MARK: - Surah Header
    private var surahHeader: some View {
        AppCard(showBorder: true) {
            VStack(spacing: Spacing.sm) {
                Text(surah.arabicName)
                    .font(.system(size: 36, design: .serif))
                    .foregroundColor(.islamicGold)

                Text(surah.name)
                    .font(AppFont.title2)
                    .foregroundColor(.islamicBrown)

                Text(surah.meaning)
                    .font(AppFont.subheadline)
                    .foregroundColor(.islamicTextSecondary)

                HStack(spacing: Spacing.md) {
                    TagChip(surah.revelationType)
                    TagChip("\(surah.verseCount) ayet")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - Verse Card
struct VerseCard: View {
    let verse: Verse
    let showArabic: Bool
    let fontSize: CGFloat
    var isPlaying: Bool = false  // Default to false if not provided

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Verse number
                HStack {
                    Text("\(verse.number)")
                        .font(AppFont.bodySemibold(14))
                        .foregroundColor(isPlaying ? .white : .white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(isPlaying ? Color.green : Color.islamicGold)
                        )

                    if isPlaying {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.islamicGreen)
                            .padding(.leading, 4)
                            .transition(.scale.combined(with: .opacity))
                    }

                    Spacer()

                    // Action hint (only showing isPlaying state)
                    if isPlaying {
                        Text("Çalıyor...")
                            .font(AppFont.caption2)
                            .foregroundColor(.islamicGreen)
                    }

                    if isPlaying {
                        Image(systemName: "waveform")
                            .foregroundColor(.islamicGreen)
                    }
                }

                // Arabic text
                if showArabic, let arabic = verse.arabicText {
                    Text(arabic)
                        .font(.system(size: fontSize + 14, weight: .regular, design: .serif))
                        .foregroundColor(.islamicBrown)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                        .padding(.vertical, Spacing.sm)
                        .lineSpacing(12)
                }

                // Turkish meal
                Text(verse.turkishMeal)
                    .font(.system(size: fontSize - 2))
                    .foregroundColor(isPlaying ? .islamicTextPrimary : .islamicTextSecondary)
                    .lineSpacing(4)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPlaying ? Color.islamicGreen : Color.clear, lineWidth: 2)
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isPlaying ? Color.islamicGreen.opacity(0.1) : Color.clear)
        )
    }
}

#Preview {
    SurahDetailView(surah: QuranData.allSurahs[0])
}
