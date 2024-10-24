//
//  Overlay.swift
//  Pods
//
//  Created by Michel Gutner on 24/10/24.
//

import SwiftUI

@available(iOS 14.0, *)
struct OverlayManager : View {
  var onTapBackward: (Int) -> Void
  var onTapForward: (Int) -> Void
  var scheduleHideControls: () -> Void
  var advanceValue: Int
  var suffixAdvanceValue: String
  var onTapOverlay: () -> Void
  @State private var isTapped: Bool = false
  @State private var isTappedLeft: Bool = false
  
  var body: some View {
    VStack {
      HStack(spacing: StandardSizes.large55) {
        DoubleTapSeek(isTapped: $isTappedLeft, onTap:  onTapBackward, advanceValue: advanceValue, suffixAdvanceValue: suffixAdvanceValue, isFinished: scheduleHideControls)
        DoubleTapSeek(isTapped: $isTapped, isForward: true, onTap:  onTapForward, advanceValue: advanceValue, suffixAdvanceValue: suffixAdvanceValue, isFinished: scheduleHideControls)
      }
    }
    .onTapGesture {
      onTapOverlay()
    }
    .onAppear {
      scheduleHideControls()
    }
  }
}
