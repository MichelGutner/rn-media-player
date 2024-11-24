//
//  view.swift
//  Pods
//
//  Created by Michel Gutner on 24/11/24.
//
import SwiftUI

extension View {
  func ifAvailable<T: View>(iOS version: Double, modifier: (Self) -> T) -> some View {
      if #available(iOS 15.0, *), version <= 15.0 {
          return AnyView(modifier(self))
      } else {
          return AnyView(self)
      }
  }
}
