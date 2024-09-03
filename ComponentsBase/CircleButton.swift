//
//  CircleButton.swift
//  rn-media-player
//
//  Created by Michel Gutner on 02/09/24.
//

import Foundation
import SwiftUI

func CreateCircleButton(action: @escaping () -> Void,_ overlay: some View) -> some View {
    Button(action: action) {
        Circle()
            .fill(.gray.opacity(0.15))
            .frame(width: 40, height: 40)
            .overlay(overlay)
            .padding(.all, 8)
    }
}
