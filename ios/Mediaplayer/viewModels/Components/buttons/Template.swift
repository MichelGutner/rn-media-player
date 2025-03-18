//
//  Template.swift
//  Pods
//
//  Created by Michel Gutner on 23/02/25.
//
import SwiftUI

struct ButtonTemplate : View {
  @Binding var imageName: String
  @State var isHover: Bool = false
  var action: (() -> Void)?
  
  var body: some View {
    Button(action: {
      action?()
      isHover = true
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        isHover = false
      }
    }, label: {
      ZStack {
        Circle()
          .fill(isHover ? Color.black.opacity(0.2) : Color.clear)
          .frame(width: 40, height: 40)
        
        Image(systemName: imageName)
          .foregroundColor(.white)
          .font(.system(size: 18))
          .padding(8)
      }
    })
    .buttonStyle(PlainButtonStyle())
    .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, perform: {}, onPressingChanged: { isPressed in
      isHover = isPressed
    })
    .animation(.easeIn(duration: 0.35), value: isHover)
    .contentShape(Circle())
  }
}
