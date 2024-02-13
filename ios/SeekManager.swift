import SwiftUI
import AVKit

@available(iOS 13.0, *)
struct SeekSliderManagerX: View {
    weak var player: AVPlayer?

    @ObservedObject private var observer = PlayerObserver()
    @State private var sliderValue: Double = 0.0
    @State private var duration: CGFloat = 0.0
    @State private var progress: String = ""
    @State private var progressPositionX: CGFloat = 0.0
    @State private var timeObserver: Any?
    @State private var isSeeking: Bool = false

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Slider(value: $sliderValue, in: 0...Double(duration))
                    .frame(width: UIScreen.main.bounds.width * 0.7)
                    .background(Color.white)
                    .padding(6)
                    .overlay(
                        GeometryReader { geometry in
                            Text(progress)
                                .foregroundColor(.white)
                                .position(x: progressPositionX, y: 0)
                        }
                    )
                Text(stringFromTimeInterval(interval: duration)).font(.system(size: 12)).foregroundColor(.white)
            }
        }
        .onAppear {
            periodicTimeObserver()
            NotificationCenter.default.addObserver(observer, selector: #selector(PlayerObserver.playbackItemDuration(_:)), name: .AVPlayerItemNewAccessLogEntry, object: player?.currentItem)
        }
        .onReceive(observer.$playbackDuration) { duration in
            if duration != 0.0 {
                self.duration = duration
            }
        }
    }

    func seekSliderChanged(time: CGFloat) {
        guard let duration = self.player?.currentItem?.duration else { return }
        let seconds: Float64 = Double(time) * CMTimeGetSeconds(duration)

        if seconds.isNaN == false {
            let seekTime = CMTime(value: CMTimeValue(seconds), timescale: 1)
            player?.seek(to: seekTime, completionHandler: { [self] completed in
                if completed {
                    isSeeking = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        // Update the progress position after seeking
                        updateProgressPosition()
                    }
                }
            })
        }
    }

    func periodicTimeObserver() {
        let interval = CMTime(value: 1, timescale: 1)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [self] time in
            progress = stringFromTimeInterval(interval: time.seconds)
            sliderValue = time.seconds

            // Update the progress position during playback
            updateProgressPosition()
        }
    }

    func updateProgressPosition() {
        let totalWidth = UIScreen.main.bounds.width * 0.7
        let percentage = CGFloat(sliderValue) / CGFloat(duration)
        progressPositionX = totalWidth * percentage
    }
}
