import AVFoundation
import SwiftUI

// MARK: - Record View
struct RecordView: View {
    @EnvironmentObject var notesService: NotesService
    @EnvironmentObject var entitlementManager: EntitlementManager
    @Environment(\.dismiss) private var dismiss

    @State private var isRecording = false
    @State private var isPaused = false
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showSaveSheet = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    @State private var uploadProgress: Double = 0
    @State private var isUploading = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.islamicBackground
                    .ignoresSafeArea()

                VStack(spacing: Spacing.xxxl) {
                    Spacer()

                    // Waveform
                    WaveformView(
                        isAnimating: isRecording && !isPaused, barCount: 30, color: .islamicGold
                    )
                    .frame(height: 80)
                    .padding(.horizontal, Spacing.xl)

                    // Timer
                    Text(formatTime(recordingTime))
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundColor(.islamicBrown)

                    // Status
                    Text(statusText)
                        .font(AppFont.subheadline)
                        .foregroundColor(.islamicTextSecondary)

                    Spacer()

                    // Controls
                    controlsView

                    Spacer()
                }
            }
            .navigationTitle(Strings.Recording.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        stopRecording()
                        dismiss()
                    }
                    .foregroundColor(.islamicBrown)
                }
            }
        }
        .sheet(isPresented: $showSaveSheet) {
            SaveRecordingSheet(
                recordingURL: recordingURL,
                duration: Int(recordingTime),
                onSave: { title, speaker in
                    try await saveRecording(title: title, speaker: speaker)
                },
                onDiscard: {
                    cleanupRecording()
                    showSaveSheet = false  // Explicitly close sheet
                }
            )
        }
        .onAppear {
            setupAudioSession()
        }
    }

    private var statusText: String {
        if isPaused {
            return "Duraklatıldı"
        } else if isRecording {
            return "Kayıt yapılıyor..."
        } else {
            return "Kaydetmek için mikrofona dokunun"
        }
    }

    // MARK: - Controls View
    private var controlsView: some View {
        HStack(spacing: Spacing.xl) {
            // Pause/Resume (only when recording)
            if isRecording {
                Button(action: togglePause) {
                    ZStack {
                        Circle()
                            .fill(Color.islamicLightGray)
                            .frame(width: 60, height: 60)

                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.islamicBrown)
                    }
                }
            }

            // Main Record/Stop button
            Button(action: toggleRecording) {
                ZStack {
                    // Outer ring with pulse animation
                    Circle()
                        .stroke(Color.islamicGold.opacity(0.3), lineWidth: 4)
                        .frame(width: 100, height: 100)
                        .scaleEffect(isRecording && !isPaused ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                            value: isRecording && !isPaused)

                    // Main button
                    Circle()
                        .fill(Color.islamicGoldGradient)
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.islamicGold.opacity(0.4), radius: 10, x: 0, y: 5)

                    // Icon
                    if isRecording {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                    } else {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                    }
                }
            }

            // Stop (only when recording)
            if isRecording {
                Button(action: finishRecording) {
                    ZStack {
                        Circle()
                            .fill(Color.islamicBrown)
                            .frame(width: 60, height: 60)

                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    // MARK: - Recording Logic
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            session.requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        print("Microphone permission denied")
                        // Optionally show an alert here
                    }
                }
            }
        } catch {
            print("Audio session error: \(error)")
        }
    }

    private func toggleRecording() {
        if isRecording {
            finishRecording()
        } else {
            if entitlementManager.triggerPaywallIfNeeded(for: .recording) {
                return
            }
            startRecording()
        }
    }

    private func startRecording() {
        let audioFilename = FileManager.default.temporaryDirectory.appendingPathComponent(
            "\(UUID().uuidString).m4a")
        recordingURL = audioFilename

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            if audioRecorder?.record() == true {
                isRecording = true
                isPaused = false
                startTimer()
            } else {
                print("Failed to start recording")
                // Handle failure (e.g., show alert)
            }
        } catch {
            print("Recording error: \(error)")
        }
    }

    private func togglePause() {
        if isPaused {
            audioRecorder?.record()
            startTimer()
        } else {
            audioRecorder?.pause()
            timer?.invalidate()
        }
        isPaused.toggle()
    }

    private func finishRecording() {
        stopRecording()
        showSaveSheet = true
    }

    private func stopRecording() {
        audioRecorder?.stop()
        timer?.invalidate()
        isRecording = false
        isPaused = false
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordingTime += 1

            // Check max duration limit
            if let maxDuration = entitlementManager.currentPlan.maxRecordingDurationSec,
                recordingTime >= Double(maxDuration)
            {
                finishRecording()
            }
        }
    }

    private func cleanupRecording() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
        recordingTime = 0
    }

    private func saveRecording(title: String, speaker: String?) async throws {
        guard let url = recordingURL else { return }
        print("🎙️ Starting save process for: \(title)")

        // 1. Create note document first
        print("📝 Creating note document...")
        let noteId = try await notesService.createNote(
            type: .audioRecording,
            title: title,
            speaker: speaker,
            durationSec: Int(recordingTime)
        )
        print("✅ Note created with ID: \(noteId)")

        // 2. Upload audio to Storage
        print("⬆️ Uploading audio to Storage...")
        let storagePath = try await StorageService.shared.uploadAudio(
            from: url,
            noteId: noteId
        ) { progress in
            uploadProgress = progress
            print("📊 Upload progress: \(Int(progress * 100))%")
        }
        print("✅ Audio uploaded to: \(storagePath)")

        // 3. Update note with storage path
        print("🔄 Updating note with storage path...")
        try await notesService.updateNote(
            noteId: noteId,
            updates: [
                "audioStoragePath": storagePath
            ])
        print("✅ Note updated successfully")

        entitlementManager.useRecording()

        // Cleanup and dismiss
        await MainActor.run {
            print("🧹 Cleaning up and dismissing...")
            cleanupRecording()
            showSaveSheet = false  // Close sheet first
            dismiss()  // Close RecordView
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Save Recording Sheet
struct SaveRecordingSheet: View {
    let recordingURL: URL?
    let duration: Int
    let onSave: (String, String?) async throws -> Void
    let onDiscard: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var speaker = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                // ... (content remains same, just verify implementation of alert)
                // Duration badge
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.islamicGold)
                    Text("Kayıt süresi: \(formatDuration(duration))")
                        .font(AppFont.subheadline)
                        .foregroundColor(.islamicBrown)
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color.islamicGold.opacity(0.1))
                )

                // Title input
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
                        .foregroundColor(.islamicBrown)
                        .colorScheme(.light)
                }

                // Speaker input
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
                        .foregroundColor(.islamicBrown)
                        .colorScheme(.light)
                }

                // Processing info
                AppCard {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.islamicGold)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI İşleme")
                                .font(AppFont.bodyMedium(14))
                                .foregroundColor(.islamicBrown)
                            Text(
                                "Kaydettikten sonra transkript, özet ve dualar otomatik çıkarılacak"
                            )
                            .font(AppFont.caption)
                            .foregroundColor(.islamicTextSecondary)
                        }
                    }
                }

                Spacer()

                // Buttons
                VStack(spacing: Spacing.sm) {
                    Button(action: saveAction) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(Strings.Recording.save)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.md)
                    .background(Color.islamicGoldGradient)
                    .foregroundColor(.white)
                    .font(AppFont.buttonText)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    .disabled(title.isEmpty || isSaving)

                    Button(Strings.Recording.discard) {
                        onDiscard()
                    }
                    .foregroundColor(.red)
                    .font(AppFont.bodyText)
                }
            }
            .padding(Spacing.lg)
            .navigationTitle(Strings.Recording.saveRecording)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Bilinmeyen bir hata oluştu.")
            }
        }
    }

    private func saveAction() {
        isSaving = true
        Task {
            do {
                try await onSave(title, speaker.isEmpty ? nil : speaker)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isSaving = false
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    RecordView()
        .environmentObject(NotesService.shared)
}
