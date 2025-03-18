//
//  ContentSection.swift
//  Pods
//
//  Created by Michel Gutner on 21/02/25.
//
import SwiftUI

struct MenuItemView : View {
  var title : String?
  var leftIcon: String?
  var rightIcon: String?
  var selectedOption: String?
  var onSelect: ((_ title: String) -> Void)?
  @State private var isHovered: Bool = false
  
  var body: some View {
    Button(action: {
      if let title {
        onSelect?(title)
      }
      isHovered = true
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        isHovered = false
      }
    }, label: {
      ZStack {
        Rectangle()
          .fill(isHovered ? Color(uiColor: .secondarySystemFill) : Color.clear)
        
        HStack {
          if let leftIcon {
            Image(systemName: leftIcon)
              .frame(width: 24, height: 24)
              .customColor(.primary)
          } else {
            HStack {}
              .frame(width: 24, height: 24)
          }
          
          if let title {
            Text(title)
              .bold()
              .lineLimit(1)
              .font(.subheadline)
              .customColor(.primary)
          }
          
          Spacer()
          
          if let selectedOption {
            Text(selectedOption)
              .font(.caption)
              .customColor(.primary)
          }
          
          if let rightIcon {
            Image(systemName: rightIcon)
              .font(.caption)
              .customColor(.primary)
          }
        }
        .padding(.all, 8)
      }
      .contentShape(Rectangle())
    })
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .buttonStyle(.plain)
    .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, perform: {}, onPressingChanged: { isPressed in
      isHovered = isPressed
    })
  }
}
