import SwiftUI
import UniformTypeIdentifiers

// MARK: - Upload Audio View
struct UploadAudioView: View {
    @EnvironmentObject var notesService: NotesService
    @EnvironmentObject var entitlementManager: EntitlementManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFileURL: URL?
    @State private var fileName = ""
    @State private var title = ""
    @State private var speaker = ""
    @State private var isShowingFilePicker = false
    @State private var isSaving = false
    @State private var uploadProgress: Double = 0
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // File Picker Button
                    Button(action: { isShowingFilePicker = true }) {
                        VStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.islamicGold.opacity(0.15))
                                    .frame(width: 80, height: 80)

                                Image(
                                    systemName: selectedFileURL != nil
                                        ? "checkmark.circle.fill" : "doc.badge.plus"
                                )
                                .font(.system(size: 32))
                                .foregroundColor(.islamicGold)
                            }

                            if selectedFileURL != nil {
                                Text(fileName)
                                    .font(AppFont.bodyMedium(14))
                                    .foregroundColor(.islamicBrown)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)

                                Text("Farklı dosya seçmek için dokunun")
                                    .font(AppFont.caption)
                                    .foregroundColor(.islamicTextSecondary)
                            } else {
                                Text("Ses Dosyası Seç")
                                    .font(AppFont.bodyMedium(14))
                                    .foregroundColor(.islamicBrown)

                                Text("MP3, M4A, WAV desteklenir")
                                    .font(AppFont.caption)
                                    .foregroundColor(.islamicTextSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.xl)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.lg)
                                .stroke(
                                    selectedFileURL != nil
                                        ? Color.islamicGold : Color.islamicWarmGray.opacity(0.3),
                                    style: StrokeStyle(
                                        lineWidth: 2, dash: selectedFileURL != nil ? [] : [8])
                                )
                        )
                    }

                    // Title Input
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Başlık *")
                            .font(AppFont.caption)
                            .foregroundColor(.islamicTextSecondary)

                        TextField("Kayıt başlığı", text: $title)
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

                    // Upload Progress
                    if isSaving {
                        VStack(spacing: Spacing.sm) {
                            ProgressView(value: uploadProgress)
                                .tint(.islamicGold)

                            Text("Yükleniyor... %\(Int(uploadProgress * 100))")
                                .font(AppFont.caption)
                                .foregroundColor(.islamicTextSecondary)
                        }
                        .padding(Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(Color.islamicGold.opacity(0.1))
                        )
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
                                    "Yükledikten sonra transkript, özet ve dualar otomatik çıkarılacak"
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
                            HStack(spacing: Spacing.sm) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Yükleniyor...")
                            }
                        } else {
                            Text("Yükle ve Kaydet")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.md)
                    .background(Color.islamicGoldGradient)
                    .foregroundColor(.white)
                    .font(AppFont.buttonText)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    .disabled(selectedFileURL == nil || title.isEmpty || isSaving)
                    .opacity(selectedFileURL == nil || title.isEmpty ? 0.6 : 1.0)
                }
                .padding(Spacing.lg)
            }
            .background(Color.islamicBackground)
            .navigationTitle("Ses Yükle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(.islamicBrown)
                    .disabled(isSaving)
                }
            }
            .sheet(isPresented: $isShowingFilePicker) {
                AudioDocumentPicker(selectedURL: $selectedFileURL, fileName: $fileName)
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveNote() {
        guard let fileURL = selectedFileURL else { return }

        if entitlementManager.triggerPaywallIfNeeded(for: .recording) {
            return
        }

        isSaving = true
        uploadProgress = 0

        Task {
            do {
                // Start accessing the security-scoped resource
                let accessing = fileURL.startAccessingSecurityScopedResource()
                defer {
                    if accessing {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }

                // Copy file to temporary location
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                    fileURL.lastPathComponent)
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                try FileManager.default.copyItem(at: fileURL, to: tempURL)

                // 1. Create note document first
                let noteId = try await notesService.createNote(
                    type: .uploadedAudio,
                    title: title,
                    speaker: speaker.isEmpty ? nil : speaker
                )

                // 2. Upload audio to Storage
                let storagePath = try await StorageService.shared.uploadAudio(
                    from: tempURL,
                    noteId: noteId
                ) { progress in
                    Task { @MainActor in
                        uploadProgress = progress
                    }
                }

                // 3. Update note with storage path
                try await notesService.updateNote(
                    noteId: noteId,
                    updates: ["audioStoragePath": storagePath]
                )

                entitlementManager.useRecording()

                // Cleanup temp file
                try? FileManager.default.removeItem(at: tempURL)

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

// MARK: - Audio Document Picker
struct AudioDocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    @Binding var fileName: String

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [
            .audio,
            .mp3,
            UTType("public.mpeg-4-audio") ?? .audio,
            .wav,
        ]

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIDocumentPickerViewController, context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: AudioDocumentPicker

        init(_ parent: AudioDocumentPicker) {
            self.parent = parent
        }

        func documentPicker(
            _ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]
        ) {
            guard let url = urls.first else { return }
            parent.selectedURL = url
            parent.fileName = url.lastPathComponent
        }
    }
}

#Preview {
    UploadAudioView()
        .environmentObject(NotesService.shared)
}
