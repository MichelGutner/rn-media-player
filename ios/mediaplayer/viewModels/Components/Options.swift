//
//  Options.swift
//  Pods
//
//  Created by Michel Gutner on 20/01/25.
//

import SwiftUI

@available(iOS 14.0, *)
extension View {
  func optionsSheet<Content: View>(
    isPresented: Binding<Bool>,
    onDismiss: @escaping () -> () = {},
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    self.sheet(isPresented: isPresented, onDismiss: onDismiss ) {
        content()
        .frame(maxWidth: 380, maxHeight: .infinity)
        .background(Color(UIColor.red))
//        .background(Color(UIColor.systemBackground))
        .contentShape(Rectangle())
//        .ignoresSafeArea(.container, edges: .bottom)
    }
  }
}
