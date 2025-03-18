//
//  GeneratorImageThumbnails.swift
//  Pods
//
//  Created by Michel Gutner on 15/01/25.
//


import Foundation
import AVFoundation
import UIKit

class VideoThumbnailGenerator {
  private let taskIdentifier = UUID().uuidString
  private var taskManager = TaskManager.shared
  private var imageGenerator: AVAssetImageGenerator?
  
  public init(videoURL: String, completion: @escaping @Sendable (UIImage, _ isComplete: Bool) -> Void) {
    generateThumbnails(from: videoURL, completion: completion)
  }
  
  /// Generates thumbnails for the given video URL.
  /// - Parameters:
  ///   - videoURL: A string representing the video URL.
  ///   - completion: A closure that provides each generated thumbnail and a flag indicating completion.
  private func generateThumbnails(from videoURL: String, completion: @escaping @Sendable (UIImage, _ isComplete: Bool) -> Void) {
    let task = Task.detached(priority: .userInitiated) { [weak self] in
      guard let self = self else { return }
      guard let url = URL(string: videoURL) else { return }
      
      let asset = AVURLAsset(url: url)
      self.imageGenerator = AVAssetImageGenerator(asset: asset)
      self.imageGenerator?.appliesPreferredTrackTransform = true
      self.imageGenerator?.maximumSize = CGSize(width: 230, height: 140)
      
      let videoDuration = asset.duration.seconds
      var frameTimes: [NSValue] = []
      
      for progress in stride(from: 0, to: videoDuration / Double(1 * 100), by: 0.01) {
        guard !Task.isCancelled else { return }
        let time = CMTime(seconds: videoDuration * Double(progress), preferredTimescale: 600)
        frameTimes.append(NSValue(time: time))
      }
      
      Debug.log("[VideoThumbnailGenerator] Thumbnail gerneration started with task ID: \(taskIdentifier)")
      
      await withCheckedContinuation { continuation in
        self.imageGenerator?.generateCGImagesAsynchronously(forTimes: frameTimes) { requestedTime, image, _, _, error in
          if Task.isCancelled {
            continuation.resume()
            return
          }
          
          if let error = error {
            Debug.log("[VideoThumbnailGenerator] Thumbnail generation error: \(error.localizedDescription)")
            continuation.resume()
            return
          }
          
          if let cgImage = image {
            DispatchQueue.main.async {
              let uiImage = UIImage(cgImage: cgImage)
              completion(uiImage, false)
            }
          }
          
          if requestedTime == frameTimes.last?.timeValue {
            continuation.resume()
            if let cgImage = image {
              completion(UIImage(cgImage: cgImage), true)
            }
            self.taskManager.cancelTask(id: self.taskIdentifier)
          }
        }
      }
    }
    
    taskManager.addTask(id: taskIdentifier, task: task)
  }
  
  /// Cancels the thumbnail generation process.
  public func cancel() {
    let tasks = taskManager.getTask(id: taskIdentifier)
    if tasks != nil {
      imageGenerator?.cancelAllCGImageGeneration()
      taskManager.cancelTask(id: taskIdentifier)
      Debug.log("[VideoThumbnailGenerator] Cancelled task for video thumbnail generation with ID: \(taskIdentifier)")
    }
  }
}
