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
  @Binding var player: AVPlayer
  var geometry: GeometryProxy
  @Binding var UIControlsProps: HashableControllers?
  @Binding var thumbnails: NSDictionary?
  
  @Binding var sliderProgress: CGFloat
  @Binding var isSeeking: Bool
  @Binding var draggingImage: UIImage?
  
  var body: some View {
    let calculatedWidthThumbnailSizeByWidth = calculateSizeByWidth(175, 0.4)
    let calculatedHeightThumbnailSizeByWidth = calculateSizeByWidth(100, 0.4)
    
    let thumbSize: CGSize = .init(width: calculatedWidthThumbnailSizeByWidth, height: calculatedHeightThumbnailSizeByWidth)
    
    HStack {
      if let draggingImage {
        VStack {
          Image(uiImage: draggingImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: thumbSize.width, height: thumbSize.height)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .stroke(Color(uiColor: (UIControlsProps?.seekSlider.thumbnailBorderColor ?? .white)), lineWidth: 1)
            )
          Text(stringFromTimeInterval(interval: TimeInterval(truncating: (sliderProgress * (player.currentItem?.duration.seconds)!) as NSNumber)))
            .font(.caption)
            .foregroundColor(Color(uiColor: UIControlsProps?.seekSlider.thumbnailTimeCodeColor ?? .white))
            .fontWeight(.semibold)
        }
      } else {
        RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
          .fill(.black)
          .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
              .stroke(Color(uiColor: (UIControlsProps?.seekSlider.thumbnailBorderColor) ?? .white), lineWidth: 1)
          )
      }
    }
    .frame(width: thumbSize.width, height: thumbSize.height)
    .opacity(isSeeking ? 1 : 0)
    .offset(x: sliderProgress * ((geometry.size.width - 32) - thumbSize.width))
  }
}
