import AVFoundation
import SwiftUI
import UIKit

/// Muted, auto-playing background video that cycles through `urls`, over a
/// dark backdrop (kept when offline) and under a black dim layer.
struct BackgroundVideo: View {
    let urls: [URL]
    var dim: Double = 0.45
    var grayscale = false

    var body: some View {
        ZStack {
            Color(argb: 0xFF0F1114)
            VideoPlayerLayer(urls: urls)
                .saturation(grayscale ? 0.1 : 1)
            Color.black.opacity(dim)
        }
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct VideoPlayerLayer: UIViewRepresentable {
    let urls: [URL]

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.start(urls)
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {}

    static func dismantleUIView(_ uiView: PlayerView, coordinator: ()) {
        uiView.stop()
    }
}

private final class PlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    private let player = AVPlayer()
    private var urls: [URL] = []
    private var index = 0
    private var observer: NSObjectProtocol?

    func start(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        self.urls = urls
        backgroundColor = .clear
        player.isMuted = true
        player.preventsDisplaySleepDuringVideoPlayback = false
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        observer = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main
        ) { [weak self] note in
            MainActor.assumeIsolated {
                guard let self, (note.object as? AVPlayerItem) === self.player.currentItem else { return }
                self.next()
            }
        }
        play(at: 0)
    }

    private func next() {
        if urls.count == 1 {
            player.seek(to: .zero)
            player.play()
        } else {
            play(at: (index + 1) % urls.count)
        }
    }

    private func play(at i: Int) {
        index = i
        player.replaceCurrentItem(with: AVPlayerItem(url: urls[i]))
        player.play()
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
    }
}
