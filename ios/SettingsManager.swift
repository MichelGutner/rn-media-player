//
//  SettingsManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 09/02/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct SettingsManager: View {
    var onTap: () -> Void
    var size: CGFloat
    var isTapped: Bool

    var body: some View {
        Button(action: {
            withAnimation(.linear(duration: 0.2)) {
                onTap()
            }
        }) {
            Image(systemName: "gear")
                .font(.system(size: size))
                .foregroundColor(.white)
        }
        .fixedSize(horizontal: true, vertical: true)
    }
}
