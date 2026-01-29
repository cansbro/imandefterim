import SwiftUI

// MARK: - Note Detail View (Firestore)
struct NoteDetailView: View {
    let note: FirestoreNote
    @EnvironmentObject var notesService: NotesService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var isPlaying = false
    @State private var playbackProgress: Double = 0.0

    private let tabs = [
        Strings.Recording.summary,
        Strings.Recording.transcript,
    ]

    @StateObject private var audioManager = AudioManager.shared
    @State private var audioURL: URL?

    // MARK: - Share Content
    private var shareContent: String {
        var content = "📝 \(note.title)\n"
        content += "📅 \(note.formattedDate)\n\n"

        if let summary = note.summaryText, !summary.isEmpty {
            content += "📖 Özet:\n\(summary)\n\n"
        }

        if let transcript = note.transcriptText, !transcript.isEmpty {
            content += "📜 Transkript:\n\(transcript)\n"
        }

        content += "\n— İman Defterim uygulamasından paylaşıldı"
        return content
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Status banner if processing
                    if note.status == .processing {
                        processingBanner
                    } else if note.status == .failed {
                        failedBanner
                    }

                    // Audio Player Card (if audio type)
                    if note.type == .audioRecording || note.type == .uploadedAudio {
                        audioPlayerCard
                            .padding(.horizontal, Spacing.md)
                            .padding(.top, Spacing.md)
                    }

                    // Tab Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            ForEach(0..<tabs.count, id: \.self) { index in
                                TabButton(
                                    title: tabs[index],
                                    isSelected: selectedTab == index
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedTab = index
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                    .padding(.top, Spacing.lg)

                    // Tab Content
                    VStack(spacing: Spacing.md) {
                        switch selectedTab {
                        case 0:
                            summaryContent
                        default:
                            transcriptContent
                        }
                    }
                    .padding(Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .background(Color.islamicBackground)
            .navigationTitle(note.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.islamicBrown)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        ShareLink(item: shareContent) {
                            Label("Paylaş", systemImage: "square.and.arrow.up")
                        }

                        Button(role: .destructive) {
                            Task {
                                try? await notesService.deleteNote(noteId: note.id ?? "")
                                dismiss()
                            }
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.islamicGold)
                    }
                }
            }
            .task {
                if let path = note.audioStoragePath {
                    print("🎵 NoteDetailView: Attempting to fetch audio URL for path: \(path)")
                    do {
                        audioURL = try await StorageService.shared.getDownloadURL(path: path)
                        print(
                            "✅ NoteDetailView: Audio URL fetched successfully: \(audioURL?.absoluteString ?? "nil")"
                        )
                    } catch {
                        print("❌ NoteDetailView: Failed to get audio URL: \(error)")
                    }
                } else {
                    print("⚠️ NoteDetailView: No audioStoragePath found for note")
                }
            }
            .onDisappear {
                audioManager.stop()
            }
        }
    }

    // MARK: - Processing Banner
    private var processingBanner: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
                .scaleEffect(0.8)

            VStack(alignment: .leading, spacing: 2) {
                Text("İşleniyor...")
                    .font(AppFont.caption)
                    .bold()

                if let message = note.aiStatusMessage {
                    Text(message)
                        .font(AppFont.caption2)
                        .multilineTextAlignment(.leading)
                } else {
                    Text("Transkript ve özet hazırlanıyor")
                        .font(AppFont.caption2)
                }
            }
            .foregroundColor(.white)

            Spacer()

            // Eğer işlem çok uzun sürerse (örn: 5 dk) retry butonu gösterilebilir
            // Şimdilik test amaçlı her zaman görünür yapabiliriz veya status failed ise
            if let date = note.createdAt, Date().timeIntervalSince(date) > 300 {  // 5 dakika
                Button(action: {
                    retryProcessing()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.white)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(Color.islamicGold)
    }

    // MARK: - Failed Banner
    private var failedBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
            VStack(alignment: .leading, spacing: 2) {
                Text("İşleme başarısız oldu")
                    .font(AppFont.caption)
                    .bold()
                if let message = note.aiStatusMessage {
                    Text(message)
                        .font(AppFont.caption2)
                        .multilineTextAlignment(.leading)
                }
            }
            .foregroundColor(.white)

            Spacer()

            Button("Tekrar Dene") {
                retryProcessing()
            }
            .font(AppFont.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.2))
            .cornerRadius(4)
            .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(Color.red)
        .cornerRadius(8)
    }

    // MARK: - Retry Action
    private func retryProcessing() {
        Task {
            guard let noteId = note.id else { return }
            do {
                try await notesService.retryProcessing(noteId: noteId)
                // Başarılı olursa UI zaten listener sayesinde güncellenecek
                // Ancak hızlı feedback için manuel not güncellenebilir (opsiyonel)
            } catch {
                print("Retry failed: \(error)")
                // Hata gösterilebilir
            }
        }
    }

    // MARK: - Audio Player Card
    private var audioPlayerCard: some View {
        AppCard(showBorder: true) {
            VStack(spacing: Spacing.md) {
                // Waveform
                WaveformView(isAnimating: isPlaying, barCount: 40, color: .islamicGold)
                    .frame(height: 50)
                    .opacity(0.6)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.islamicLightGray)
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.islamicGold)
                            .frame(width: geo.size.width * playbackProgress, height: 4)
                    }
                }
                .frame(height: 4)

                // Time labels
                HStack {
                    Text(formatTime(Double(note.durationSec ?? 0) * playbackProgress))
                        .font(AppFont.caption)
                        .foregroundColor(.islamicTextSecondary)

                    Spacer()

                    Text(note.formattedDuration)
                        .font(AppFont.caption)
                        .foregroundColor(.islamicTextSecondary)
                }

                // Controls
                HStack(spacing: Spacing.xl) {
                    Button(action: {}) {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 24))
                            .foregroundColor(.islamicBrown)
                    }

                    Button(action: togglePlayback) {
                        ZStack {
                            Circle()
                                .fill(Color.islamicGoldGradient)
                                .frame(width: 56, height: 56)

                            if audioManager.isLoading && audioManager.currentVerse == nil
                                && isPlaying
                            {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                        }
                    }

                    Button(action: {}) {
                        Image(systemName: "goforward.15")
                            .font(.system(size: 24))
                            .foregroundColor(.islamicBrown)
                    }
                }
            }
        }
    }

    // MARK: - Summary Content
    private var summaryContent: some View {
        AppCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.islamicGold)
                    Text("AI Özet")
                        .font(AppFont.headline)
                        .foregroundColor(.islamicBrown)
                }

                if let summary = note.summaryText, !summary.isEmpty {
                    Text(summary)
                        .font(AppFont.bodyText)
                        .foregroundColor(.islamicTextSecondary)
                        .lineSpacing(6)
                } else if note.status == .processing {
                    HStack {
                        ProgressView()
                        Text("Özet hazırlanıyor...")
                            .font(AppFont.subheadline)
                            .foregroundColor(.islamicTextTertiary)
                    }
                } else {
                    Text("Henüz özet oluşturulmadı")
                        .font(AppFont.subheadline)
                        .foregroundColor(.islamicTextTertiary)
                        .italic()
                }
            }
        }
    }

    // MARK: - Transcript Content
    private var transcriptContent: some View {
        AppCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(.islamicGold)
                    Text(Strings.Recording.transcript)
                        .font(AppFont.headline)
                        .foregroundColor(.islamicBrown)
                }

                if let transcript = note.transcriptText, !transcript.isEmpty {
                    Text(transcript)
                        .font(AppFont.bodyText)
                        .foregroundColor(.islamicTextSecondary)
                        .lineSpacing(6)
                } else if note.status == .processing {
                    HStack {
                        ProgressView()
                        Text("Transkript hazırlanıyor...")
                            .font(AppFont.subheadline)
                            .foregroundColor(.islamicTextTertiary)
                    }
                } else {
                    Text("Transkript mevcut değil")
                        .font(AppFont.subheadline)
                        .foregroundColor(.islamicTextTertiary)
                        .italic()
                }
            }
        }
    }

    // MARK: - Duas Content
    private var duasContent: some View {
        VStack(spacing: Spacing.md) {
            if note.duas.isEmpty {
                if note.status == .processing {
                    AppCard {
                        HStack {
                            ProgressView()
                            Text("Dualar çıkarılıyor...")
                                .font(AppFont.subheadline)
                                .foregroundColor(.islamicTextTertiary)
                        }
                    }
                } else {
                    EmptyStateView(
                        icon: "hands.sparkles",
                        title: "Dua Bulunamadı",
                        message: "Bu kayıtta henüz dua tespit edilmedi"
                    )
                }
            } else {
                ForEach(note.duas) { dua in
                    FirestoreDuaCard(dua: dua)
                }
            }
        }
    }

    // MARK: - Notes Content
    private var notesContent: some View {
        AppCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(.islamicGold)
                    Text(Strings.Recording.addNote)
                        .font(AppFont.headline)
                        .foregroundColor(.islamicBrown)
                }

                Text(
                    note.manualNotes
                        ?? "Henüz kişisel not eklenmedi. Kayıt hakkındaki düşüncelerinizi buraya yazabilirsiniz."
                )
                .font(AppFont.bodyText)
                .foregroundColor(
                    note.manualNotes == nil ? .islamicTextTertiary : .islamicTextSecondary
                )
                .italic(note.manualNotes == nil)
            }
        }
    }

    private func togglePlayback() {
        if isPlaying {
            audioManager.pause()
            isPlaying = false
        } else {
            if let url = audioURL {
                audioManager.play(url: url)
                isPlaying = true
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// ... (Tabs and Mock remain)

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.bodyMedium(14))
                .foregroundColor(isSelected ? .islamicGold : .islamicTextSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    isSelected
                        ? AnyShapeStyle(Color.islamicGold.opacity(0.1)) : AnyShapeStyle(Color.clear)
                )
                .clipShape(Capsule())
        }
    }
}

// MARK: - Firestore Dua Card
struct FirestoreDuaCard: View {
    let dua: NoteDua

    var body: some View {
        AppCard(showBorder: true) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(dua.text)
                    .font(AppFont.bodyText)
                    .foregroundColor(.islamicTextSecondary)

                // Timestamp if available
                if let start = dua.startSec {
                    Text("\(formatTime(start))")
                        .font(AppFont.caption)
                        .foregroundColor(.islamicGold)
                }

                // Actions
                HStack {
                    Spacer()

                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundColor(.islamicWarmGray)
                    }

                    Button(action: {}) {
                        Image(systemName: "heart")
                            .font(.system(size: 16))
                            .foregroundColor(.islamicWarmGray)
                    }
                }
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    let mockNote = FirestoreNote(
        id: "test",
        uid: "user1",
        type: .audioRecording,
        title: "Test Kayıt",
        speaker: "Hoca",
        createdAt: Date(),
        durationSec: 300,
        tags: ["Özet", "Transkript"],
        folderId: nil,
        status: .ready,
        summaryText: "Bu bir test özetidir.",
        transcriptText: "Bu bir test transkriptidir.",
        duas: [],
        audioStoragePath: nil,
        youtubeUrl: nil,
        scannedText: nil,
        manualNotes: nil
    )
    NoteDetailView(note: mockNote)
}
