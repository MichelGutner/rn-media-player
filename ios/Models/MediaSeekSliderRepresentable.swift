//
//  CustomSeekSliderView.swift
//  Pods
//
//  Created by Michel Gutner on 25/11/24.
//


import SwiftUI
import AVFoundation

struct MediaSeekSliderRepresentable: UIViewRepresentable {
  @Binding var bufferingProgress: Double
  @Binding var sliderProgress: Double
  var onProgressBegan: ((CGFloat) -> Void)?
  var onProgressChanged: ((CGFloat) -> Void)?
  var onProgressEnded: ((CGFloat) -> Void)?
  
  
  func makeUIView(context: Context) -> MediaSeekSlider {
    let slider = MediaSeekSlider()
    slider.bufferingProgress = bufferingProgress
    slider.sliderProgress = sliderProgress
    
    // Configura callbacks
    slider.onProgressBegan = { progress in
      DispatchQueue.main.async {
        onProgressBegan?(progress)
      }
    }
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
