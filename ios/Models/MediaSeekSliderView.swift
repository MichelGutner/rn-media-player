//
//  CustomSeekSliderView.swift
//  Pods
//
//  Created by Michel Gutner on 25/11/24.
//


import SwiftUI
import AVFoundation

struct MediaSeekSliderView: UIViewRepresentable {
    @Binding var mediaSession: MediaSessionManager
    @Binding var sliderProgress: CGFloat
    @Binding var bufferingProgress: CGFloat
    var onProgressChanged: ((CGFloat) -> Void)?
    var onProgressEnded: ((CGFloat) -> Void)?
  
  @State private var duration: Double = 0.0
  @State private var missingDuration: Double = 0.0
  @State private var currentTime: Double = 0.0

  
    func makeUIView(context: Context) -> MediaSeekSlider {
        let slider = MediaSeekSlider()
        slider.bufferingProgress = bufferingProgress
        slider.sliderProgress = sliderProgress
        
        // Configura callbacks
        slider.onProgressChanged = { progress in
            DispatchQueue.main.async {
                sliderProgress = progress
                onProgressChanged?(progress)
            }
        }
        
        slider.onProgressEnded = { progress in
            DispatchQueue.main.async {
                sliderProgress = progress
                onProgressEnded?(progress)
            }
        }
      
        return slider
    }
    
    func updateUIView(_ uiView: MediaSeekSlider, context: Context) {
        uiView.bufferingProgress = bufferingProgress
        uiView.sliderProgress = sliderProgress
    }
}
