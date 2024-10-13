//
//  TimeCodes.swift
//  Pods
//
//  Created by Michel Gutner on 07/10/24.
//
import SwiftUI
import AVKit

@available(iOS 14.0, *)
struct TimeCodes: View {
  @StateObject private var observable = PlaybackObservable()
  @Binding var UIControlsProps: HashableControllers?
    
  var body: some View {
    let sizeTimeCodes = calculateSizeByWidth(10, 0.2)
    
    HStack() {
      Text(stringFromTimeInterval(interval: observable.duration))
        .font(.system(size: 12))
        .foregroundColor(Color(uiColor: (UIControlsProps?.timeCodes.durationColor ?? .white)))
      
    }
  }
}
