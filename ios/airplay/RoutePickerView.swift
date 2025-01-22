//  RoutePickerView.swift
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
        routePickerView.activeTintColor = .blue
        routePickerView.tintColor = .white
        routePickerView.prioritizesVideoDevices = true
      
        return routePickerView
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        // Update logic if needed in future
    }
}
