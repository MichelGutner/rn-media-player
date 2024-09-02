//
//  VideoPlayerModalMoreOptions.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 05/03/24.
//

import SwiftUI

struct MoreOptionsContentView: View {
  @State private var isActiveAutoPlay: Bool = true
  @State private var isActiveLoop: Bool = false
  var onTapAutoPlay: (Bool) -> Void
  var onTapLoop: (Bool) -> Void
  
  
  init(isActiveAutoPlay: Bool, isActiveLoop: Bool, onTapAutoPlay: @escaping (Bool) -> Void, onTapLoop: @escaping (Bool) -> Void) {
    _isActiveAutoPlay = State(initialValue: isActiveAutoPlay)
    _isActiveLoop = State(initialValue: isActiveLoop)
    self.onTapAutoPlay = onTapAutoPlay
    self.onTapLoop = onTapLoop
  }
  
    var body: some View {
        VStack {
          SectionAutoPlayView()
          SectionLoopView()
        }
    }
  
  @ViewBuilder
  func SectionAutoPlayView() -> some View {
      HStack(alignment: .center) {
        Image(
          systemName: !isActiveAutoPlay ? "play.circle" : "pause.circle"
        )
        .font(.system(size: StandardSizes.medium22))
        .foregroundColor(isActiveAutoPlay ? Color.primary : Color.gray)
        
        Text("Auto Play")
          .foregroundColor(isActiveAutoPlay ? Color.primary : Color.gray)
        
        Spacer()
        
        CustomSwitch(isActived: $isActiveAutoPlay) { isActive in
          onTapAutoPlay(isActive)
        }
    }
  }
  
  @ViewBuilder
  func SectionLoopView() -> some View {
      HStack(alignment: .center) {
        Image(systemName: "repeat.1")
          .font(.system(size: StandardSizes.medium22))
          .foregroundColor(isActiveLoop ? Color.primary : Color.gray)
        
        Text("Loop Video")
          .foregroundColor(isActiveLoop ? Color.primary : Color.gray)
        
        Spacer()
        
        CustomSwitch(isActived: $isActiveLoop) { isActive in
          onTapLoop(isActive)
        }
    }
  }
}
