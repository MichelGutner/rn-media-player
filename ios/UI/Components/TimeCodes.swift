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
  @Binding var time: Double
  @Binding var UIControlsProps: Styles?
  var suffixValue: String = ""
    
  var body: some View {
    Text(suffixValue.appending(stringFromTimeInterval(interval: time)))
      .font(.system(size: 12))
      .foregroundColor(Color(uiColor: (UIControlsProps?.timeCodes.durationColor ?? .white)))
  }
}
