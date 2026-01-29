import SwiftUI
import Vision
import VisionKit

// MARK: - Scan Text View
struct ScanTextView: View {
    @EnvironmentObject var notesService: NotesService
    @Environment(\.dismiss) private var dismiss

    @State private var scannedText = ""
    @State private var title = ""
    @State private var isShowingScanner = true
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if scannedText.isEmpty {
                        // Empty State - Show scan prompt
                        VStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.islamicGold.opacity(0.15))
                                    .frame(width: 80, height: 80)

                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 32))
                                    .foregroundColor(.islamicGold)
                            }

                            Text("Metin Taramadı")
                                .font(AppFont.bodyMedium(14))
                                .foregroundColor(.islamicBrown)

                            Text("Tarama ekranı açıldığında belge veya metni kameraya gösterin")
                                .font(AppFont.caption)
                                .foregroundColor(.islamicTextSecondary)
                                .multilineTextAlignment(.center)

                            Button("Taramaya Başla") {
                                isShowingScanner = true
                            }
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, Spacing.md)
                            .background(Color.islamicGoldGradient)
                            .foregroundColor(.white)
                            .font(AppFont.buttonText)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.xl)
                    } else {
                        // Title Input
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Başlık *")
                                .font(AppFont.caption)
                                .foregroundColor(.islamicTextSecondary)

                            TextField("Not başlığı", text: $title)
                                .font(AppFont.bodyText)
                                .padding(Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .fill(Color.islamicLightGray)
                                )
                                .foregroundColor(.islamicTextPrimary)
                        }

                        // Scanned Text Section
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Text("Taranan Metin")
                                    .font(AppFont.caption)
                                    .foregroundColor(.islamicTextSecondary)

                                Spacer()

                                Button("Tekrar Tara") {
                                    isShowingScanner = true
                                }
                                .font(AppFont.caption)
                                .foregroundColor(.islamicGold)
                            }

                            TextEditor(text: $scannedText)
                                .font(AppFont.bodyText)
                                .foregroundColor(.islamicTextPrimary)
                                .frame(minHeight: 200)
                                .padding(Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .fill(Color.islamicLightGray)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .stroke(Color.islamicWarmGray.opacity(0.3), lineWidth: 1)
                                )
                        }

                        // Character count
                        HStack {
                            Spacer()
                            Text("\(scannedText.count) karakter")
                                .font(AppFont.caption)
                                .foregroundColor(.islamicTextSecondary)
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
                        .disabled(title.isEmpty || scannedText.isEmpty || isSaving)
                        .opacity(title.isEmpty || scannedText.isEmpty ? 0.6 : 1.0)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.islamicBackground)
            .navigationTitle("Metin Tara")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(.islamicBrown)
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                DocumentScannerView(scannedText: $scannedText)
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
                    type: .scannedText,
                    title: title,
                    scannedText: scannedText
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

// MARK: - Document Scanner View
struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var scannedText: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }

    func updateUIViewController(
        _ uiViewController: VNDocumentCameraViewController, context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView

        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan
        ) {
            // Process scanned pages
            var recognizedText = ""

            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                recognizedText += recognizeText(from: image)
                if pageIndex < scan.pageCount - 1 {
                    recognizedText += "\n\n---\n\n"
                }
            }

            parent.scannedText = recognizedText
            controller.dismiss(animated: true)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController, didFailWithError error: Error
        ) {
            print("Document scanner error: \(error)")
            controller.dismiss(animated: true)
        }

        private func recognizeText(from image: UIImage) -> String {
            guard let cgImage = image.cgImage else { return "" }

            var recognizedText = ""

            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    return
                }

                for observation in observations {
                    if let topCandidate = observation.topCandidates(1).first {
                        recognizedText += topCandidate.string + "\n"
                    }
                }
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["tr", "ar", "en"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])

            return recognizedText
        }
    }
}

#Preview {
    ScanTextView()
        .environmentObject(NotesService.shared)
}
