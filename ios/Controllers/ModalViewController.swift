//
//  ModalLayoutManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 28/01/24.
//

import SwiftUI

@available(iOS 13.0, *)
struct ModalViewController<Content: View>: View {
  @Environment(\.colorScheme) var colorScheme
  
  var onModalAppear: () -> Void
  var onModalDisappear: () -> Void
  var onModalCompletion: () -> Void
  var modalContent: () -> Content
  
  @State private var modalOffset = UIScreen.main.bounds.height
  
  var body: some View {
    ZStack {
      Color(.black).opacity(0.3)
        .onTapGesture {
          hideModal()
        }
        .edgesIgnoringSafeArea(.all)
      
      VStack(alignment: .leading, spacing: calculateSizeByWidth(StandardSizes.small16, VariantPercent.p20)) {
        HStack(alignment: .center) {
          Spacer()
          Button(action: hideModal) {
            Image(systemName: "xmark").foregroundColor(Color.primary)
          }
        }
        .padding(.top, 12)
        modalContent()
      }
      .fixedSize(horizontal: false, vertical: true)
      .padding(.leading)
      .padding(.trailing)
      .padding(.bottom)
      .background(colorScheme == .light ? Color.white : Color.black)
      .cornerRadius(16)
      .shadow(color: Color.secondary, radius: 0.4, x: 0.1, y: 0.1)
      .frame(minWidth: UIScreen.main.bounds.width * 0.3, maxWidth: UIScreen.main.bounds.width * 0.6, alignment: .leading)
      .offset(x: 0, y: modalOffset)
      .onAppear {
        withAnimation(.interactiveSpring(dampingFraction: 1.0)) {
          modalOffset = 0
          onModalAppear()
        }
      }
      .onDisappear {
        onModalDisappear()
        modalOffset = UIScreen.main.bounds.height
      }
    }
  }
  
  func hideModal() {
    withAnimation(.interactiveSpring(dampingFraction: 1.5)) {
      modalOffset = UIScreen.main.bounds.height
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      onModalCompletion()
    }
  }
}
