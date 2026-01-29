import SwiftUI
import UIKit

struct AIChatView: View {
    @EnvironmentObject var entitlementManager: EntitlementManager
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isThinking = false
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.islamicBrown)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("İman Defterim AI")
                            .font(AppFont.headline)
                            .foregroundColor(.islamicBrown)
                    }

                    Spacer()

                    // Empty view for balance
                    Image(systemName: "chevron.down")
                        .foregroundColor(.clear)
                }
                .padding()
                .background(Color.islamicBackground)

                // Chat Area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Intro Message
                            if messages.isEmpty {
                                introView
                            }

                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }

                            if isThinking {
                                ThinkingBubble()
                                    .id("thinking")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: isThinking) { thinking in
                        if thinking { scrollToBottom(proxy: proxy, id: "thinking") }
                    }
                }
                .background(Color.islamicBackground)
                .onTapGesture { isFocused = false }

                // Input Area
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.islamicGold.opacity(0.2))

                    HStack(alignment: .bottom, spacing: Spacing.sm) {
                        // Text Field
                        TextField(
                            "Bir soru sor veya dua iste...", text: $messageText, axis: .vertical
                        )
                        .padding(12)
                        .background(Color.islamicCardBackground)
                        .foregroundColor(.islamicTextPrimary)
                        .cornerRadius(CornerRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.lg)
                                .stroke(Color.islamicGold.opacity(0.3), lineWidth: 1)
                        )
                        .focused($isFocused)
                        .lineLimit(1...5)

                        // Send Button
                        Button(action: sendMessage) {
                            ZStack {
                                Circle()
                                    .fill(
                                        messageText.isEmpty
                                            ? Color.gray.opacity(0.3) : Color.islamicGold
                                    )
                                    .frame(width: 44, height: 44)

                                Image(systemName: "arrow.up")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(messageText.isEmpty || isThinking)
                    }
                    .padding()
                    .background(Color.islamicBackground)
                }
            }
            .background(Color.islamicBackground)
        }
    }

    private var introView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer().frame(height: 40)

            ZStack {
                Circle()
                    .fill(Color.islamicGold.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(.islamicGold)
            }

            Text("Nasıl yardımcı olabilirim?")
                .font(AppFont.title2)
                .foregroundColor(.islamicBrown)

            // Starter Questions
            VStack(spacing: Spacing.sm) {
                StarterButton(
                    text: "Zenginlik için okunacak dua",
                    action: { sendStarter("Zenginlik için okunacak etkili dualar nelerdir?") })
                StarterButton(
                    text: "Bana Hz. Yusuf kıssasını anlat",
                    action: { sendStarter("Hz. Yusuf kıssasını anlat ve dersler çıkar.") })
                StarterButton(
                    text: "Namazda huşu nasıl sağlanır?",
                    action: { sendStarter("Namazda huşu nasıl sağlanır?") })
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Actions
    private func sendStarter(_ text: String) {
        messageText = text
        sendMessage()
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Check limits
        if entitlementManager.triggerPaywallIfNeeded(for: .aiProcessing) {
            return
        }

        let userText = messageText
        let userMsg = ChatMessage(text: userText, isUser: true)
        messages.append(userMsg)

        messageText = ""
        isThinking = true

        Task {
            do {
                let functions = FirebaseManager.shared.functions!
                let result = try await functions.httpsCallable("chatWithAI").call([
                    "prompt": userText
                ])

                if let data = result.data as? [String: Any],
                    let answer = data["answer"] as? String
                {

                    var videoResult: VideoResult? = nil
                    if let videoData = data["video"] as? [String: Any],
                        let vid = videoData["id"] as? String,
                        let vtitle = videoData["title"] as? String,
                        let vthumb = videoData["thumbnailUrl"] as? String
                    {
                        videoResult = VideoResult(id: vid, title: vtitle, thumbnailUrl: vthumb)
                    }

                    await MainActor.run {
                        isThinking = false
                        entitlementManager.useAIQuestion()
                        let aiMsg = ChatMessage(
                            text: answer,
                            isUser: false,
                            video: videoResult
                        )
                        messages.append(aiMsg)
                    }
                }
            } catch {
                print("AI Error: \(error)")
                await MainActor.run {
                    isThinking = false
                    let errorMsg = ChatMessage(
                        text:
                            "Üzgünüm, şu an yanıt veremiyorum. Lütfen internet bağlantını kontrol et veya daha sonra tekrar dene.",
                        isUser: false
                    )
                    messages.append(errorMsg)
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, id: String? = nil) {
        withAnimation {
            proxy.scrollTo(id ?? messages.last?.id, anchor: .bottom)
        }
    }
}

// MARK: - Models & Subviews

struct ChatMessage: Identifiable {
    let id = UUID().uuidString
    let text: String
    let isUser: Bool
    var video: VideoResult? = nil
}

struct VideoResult {
    let id: String
    let title: String
    let thumbnailUrl: String
}

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser { Spacer() }

            if !message.isUser {
                // AI Icon
                Circle()
                    .fill(Color.islamicGold)
                    .frame(width: 32, height: 32)
                    .overlay(Image(systemName: "sparkles").foregroundColor(.white).font(.caption))
            }

            VStack(alignment: .leading, spacing: 8) {
                if !message.text.isEmpty {
                    Text(message.text)
                        .font(AppFont.bodyText)
                        .foregroundColor(message.isUser ? .white : .islamicBrown)
                        .padding(12)
                        .background(
                            message.isUser
                                ? Color.islamicGold
                                : Color.islamicCardBackground
                        )
                        .cornerRadius(
                            16,
                            corners: message.isUser
                                ? [.topLeft, .topRight, .bottomLeft]
                                : [.topLeft, .topRight, .bottomRight]
                        )
                        .shadow(color: AppShadow.light, radius: 2, x: 0, y: 1)
                }

                // Video Card Implementation (Placeholder)
                if let video = message.video {
                    VideoCard(video: video)
                }
            }

            if !message.isUser { Spacer() }
        }
    }
}

struct ThinkingBubble: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Circle()
                .fill(Color.islamicGold)
                .frame(width: 32, height: 32)
                .overlay(Image(systemName: "sparkles").foregroundColor(.white).font(.caption))

            HStack(spacing: 4) {
                Circle().frame(width: 6, height: 6).opacity(0.5 + sin(phase) * 0.5)
                Circle().frame(width: 6, height: 6).opacity(0.5 + sin(phase + 1) * 0.5)
                Circle().frame(width: 6, height: 6).opacity(0.5 + sin(phase + 2) * 0.5)
            }
            .padding(12)
            .background(Color.islamicCardBackground)
            .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// Helper for rounded corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect, byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct StarterButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(AppFont.bodyMedium(15))
                .foregroundColor(.islamicBrown)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.islamicCardBackground)
                .cornerRadius(CornerRadius.md)
                .shadow(color: AppShadow.light, radius: 2, x: 0, y: 1)
        }
    }
}

// Mock Video Card
struct VideoCard: View {
    let video: VideoResult

    var body: some View {
        Link(destination: URL(string: "https://www.youtube.com/watch?v=\(video.id)")!) {
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail
                ZStack {
                    AsyncImage(url: URL(string: video.thumbnailUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(height: 112)
                    .clipped()

                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(AppFont.caption)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.islamicBrown)

                    HStack {
                        Image(systemName: "play.rectangle.fill")
                            .foregroundColor(.red)
                        Text("YouTube • İzle")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(8)
                .background(Color.white)
            }
            .frame(width: 200)
            .cornerRadius(12)
            .shadow(color: AppShadow.medium, radius: 4)
        }
    }
}
