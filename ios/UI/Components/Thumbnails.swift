//
//  Thumbnails.swift
//  Pods
//
//  Created by Michel Gutner on 07/10/24.
//

import SwiftUI
import AVKit

@available(iOS 14.0, *)
struct Thumbnails : View {
  @Binding var duration: Double
  var geometry: GeometryProxy
  @Binding var UIControlsProps: Styles?
  
  @Binding var sliderProgress: CGFloat
  @Binding var isSeeking: Bool
  @Binding var draggingImage: UIImage?
  
  var body: some View {
    let calculatedWidthThumbnailSizeByWidth = calculateSizeByWidth(180, 0.4)
    let calculatedHeightThumbnailSizeByWidth = calculateSizeByWidth(100, 0.4)
    
    let thumbSize: CGSize = .init(width: calculatedWidthThumbnailSizeByWidth, height: calculatedHeightThumbnailSizeByWidth)
    
    HStack {
      if let draggingImage {
        VStack {
          Image(uiImage: draggingImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: thumbSize.width, height: thumbSize.height)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .stroke(Color(uiColor: (UIControlsProps?.seekSlider.thumbnailBorderColor) ?? .white), lineWidth: 0.5)
            )
          Text(stringFromTimeInterval(interval: TimeInterval(truncating: (sliderProgress * duration) as NSNumber)))
            .font(.caption)
            .foregroundColor(Color(uiColor: .white))
            .fontWeight(.semibold)
        }
      }
    }
    .frame(width: thumbSize.width, height: thumbSize.height)
    .opacity(isSeeking && draggingImage != nil ? 1 : 0)
    .offset(x: sliderProgress * ((geometry.size.width) - thumbSize.width), y: -(thumbSize.height + 24))
  }
}
