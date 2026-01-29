import SwiftUI

// MARK: - YouTube Link View
struct YouTubeLinkView: View {
    @EnvironmentObject var notesService: NotesService
    @Environment(\.dismiss) private var dismiss

    @State private var youtubeURL = ""
    @State private var title = ""
    @State private var speaker = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var isValidURL: Bool {
        let patterns = [
            "youtube.com/watch",
            "youtu.be/",
            "youtube.com/embed/",
            "youtube.com/v/",
        ]
        return patterns.contains { youtubeURL.lowercased().contains($0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // YouTube URL Input
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("YouTube Linki *")
                            .font(AppFont.caption)
                            .foregroundColor(.islamicTextSecondary)

                        TextField("https://youtube.com/watch?v=...", text: $youtubeURL)
                            .font(AppFont.bodyText)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding(Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .fill(Color.islamicLightGray)
                            )
                            .foregroundColor(.islamicTextPrimary)

                        if !youtubeURL.isEmpty && !isValidURL {
                            Text("Geçerli bir YouTube linki girin")
                                .font(AppFont.caption)
                                .foregroundColor(.red)
                        }
                    }

                    // Title Input
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Başlık *")
                            .font(AppFont.caption)
                            .foregroundColor(.islamicTextSecondary)

                        TextField("Video başlığı", text: $title)
                            .font(AppFont.bodyText)
                            .padding(Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .fill(Color.islamicLightGray)
                            )
                            .foregroundColor(.islamicTextPrimary)
                    }

                    // Speaker Input
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Konuşmacı (isteğe bağlı)")
                            .font(AppFont.caption)
                            .foregroundColor(.islamicTextSecondary)

                        TextField("Hoca, vaiz vb.", text: $speaker)
                            .font(AppFont.bodyText)
                            .padding(Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .fill(Color.islamicLightGray)
                            )
                            .foregroundColor(.islamicTextPrimary)
                    }

                    // Info Card
                    AppCard {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.islamicGold)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("AI İşleme")
                                    .font(AppFont.bodyMedium(14))
                                    .foregroundColor(.islamicBrown)
                                Text(
                                    "Video kaydedildikten sonra transkript, özet ve dualar otomatik çıkarılacak"
                                )
                                .font(AppFont.caption)
                                .foregroundColor(.islamicTextSecondary)
                            }
                        }
                    }

                    Spacer(minLength: Spacing.xl)

                    // Save Button
                    Button(action: saveNote) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Kaydet")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.md)
                    .background(Color.islamicGoldGradient)
                    .foregroundColor(.white)
                    .font(AppFont.buttonText)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    .disabled(title.isEmpty || !isValidURL || isSaving)
                    .opacity(title.isEmpty || !isValidURL ? 0.6 : 1.0)
                }
                .padding(Spacing.lg)
            }
            .background(Color.islamicBackground)
            .navigationTitle("YouTube Linki Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(.islamicBrown)
                }
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveNote() {
        isSaving = true

        Task {
            do {
                _ = try await notesService.createNote(
                    type: .youtubeLink,
                    title: title,
                    speaker: speaker.isEmpty ? nil : speaker,
                    youtubeUrl: youtubeURL
                )

                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isSaving = false
                }
            }
        }
    }
}

#Preview {
    YouTubeLinkView()
        .environmentObject(NotesService.shared)
}
