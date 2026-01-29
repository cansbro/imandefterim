import AVFoundation
import Combine
import Foundation

class AudioManager: ObservableObject {
    static let shared = AudioManager()

    @Published var isPlaying: Bool = false
    @Published var currentRate: Float = 1.0
    @Published var currentVerse: Verse?
    @Published var isLoading: Bool = false

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback, mode: .spokenAudio, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    func play(verse: Verse) {
        guard let urlString = verse.audioUrl, let url = URL(string: urlString) else {
            print("Invalid audio URL for verse: \(verse.id)")
            return
        }
        play(url: url)
        currentVerse = verse
    }

    func play(url: URL) {
        // If same URL is already loaded and paused, just resume
        if let currentItem = player?.currentItem,
            (currentItem.asset as? AVURLAsset)?.url == url,
            player != nil
        {
            player?.play()
            player?.rate = currentRate
            isPlaying = true
            return
        }

        stop(clearVerse: false)  // Stop previous playback but keep verse for UI transition

        isLoading = true

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        self.playerItem = playerItem

        // Observe completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        player?.playImmediately(atRate: currentRate)
        isPlaying = true
        isLoading = false
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func stop(clearVerse: Bool = true) {
        player?.pause()
        player = nil
        playerItem = nil
        isPlaying = false
        if clearVerse {
            currentVerse = nil
        }

        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }

    func setRate(_ rate: Float) {
        currentRate = rate
        if isPlaying {
            player?.rate = rate
        }
    }

    @objc private func playerDidFinishPlaying(note: NSNotification) {
        isPlaying = false
        // Logic to play next verse could be handled here or by the view model/coordinator
        // For now, we'll just stop. The view can observe `isPlaying` becoming false and trigger next.
        NotificationCenter.default.post(
            name: .didFinishVerseAudio, object: nil, userInfo: ["verse": currentVerse as Any])
    }
}

extension Notification.Name {
    static let didFinishVerseAudio = Notification.Name("didFinishVerseAudio")
}
