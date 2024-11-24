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
import SwiftUI
import AVFoundation
import MediaPlayer
import AVKit

struct RoutePickerView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.activeTintColor = .white
        routePickerView.tintColor = .white
        routePickerView.prioritizesVideoDevices = true
        return routePickerView
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        // Update logic if needed in future
    }
}
