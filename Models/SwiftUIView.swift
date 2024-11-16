//
//  EvoPlayerSwiftUIView.swift
//  Pods
//
//  Created by Michel Gutner on 09/11/24.
//


//
//  EvoPlayerSwiftUIView.swift
//  react-native-evo-player
//
//  Created by Michel Gutner on 07/11/24.
//

import Foundation
import SwiftUI
import AVKit

struct SwiftUIView: View {
    var player: AVPlayer?
    @State private var playerLayer: AVPlayerLayer?

    var body: some View {
//        GeometryReader { geometry in
//            let size = geometry.size
//            
            Group {
                if let player = player {
//                    CustomAVPlayer(player: player)
                } else {
                    Text("Loading player...")
                }
            }
//            .frame(width: size.width, height: size.height)
//        }
        .onAppear {
            // Inicializa o player quando a view aparece
//            if let url = videoURL {
//                player = AVPlayer(url: url)
//            }
        }
    }

    var videoURL: URL? {
        let urlString = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4"
        return URL(string: urlString)
    }
}
