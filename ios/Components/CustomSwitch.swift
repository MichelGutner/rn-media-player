//
//  CustomSwitch.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 06/03/24.
//

import SwiftUI

@available(iOS 13.0, *)
struct CustomSwitch: View {
  @Binding var isActived: Bool
  var onSelect: (Bool) -> Void

    var body: some View {
      ZStack(alignment: isActived ? .trailing : .leading) {
        Capsule().fill(isActived ? Color.blue : Color.gray).frame(width: 40, height: 15)
        ZStack {
          Capsule()
            .fill(Color.white)
            .frame(width: 25, height: 25)
            .cornerRadius(.infinity)
            .overlay(
              Circle()
                .stroke(.black, lineWidth: 1).opacity(0.1)
                .cornerRadius(.infinity)
            )
        }
      }
      .onTapGesture {
        withAnimation(.easeInOut(duration: 0.35)) {
          isActived.toggle()
          onSelect(isActived)
        }
      }
    }
}
