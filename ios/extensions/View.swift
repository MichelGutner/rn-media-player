//
//  View.swift
//  Pods
//
//  Created by Michel Gutner on 23/02/25.
//
import SwiftUI

extension View {
  @ViewBuilder
  func customColor(_ color: Color) -> some View {
    if #available(iOS 15.0, *) {
      self.foregroundStyle(color)
    } else {
      self.foregroundColor(color)
    }
  }
}
