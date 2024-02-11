import Foundation

class DownloadManager: NSObject, URLSessionDownloadDelegate {
  private var downloadTask: URLSessionDownloadTask!
  private var completion: ((URL?, Error?) -> Void)?
  private var onProgress: ((Float) -> Void)?
  private var destinationFileUrl: URL?
  
  func downloadVideo(from url: URL, title: String = "video", onProgress: @escaping (Float) -> Void, completion: @escaping (URL?, Error?) -> Void) {
    self.completion = completion
    self.onProgress = onProgress
    let documentsUrl: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    self.destinationFileUrl = documentsUrl.appendingPathComponent("\(title.replacingOccurrences(of: " ", with: "").lowercased()).mp4")

    let sessionConfig = URLSessionConfiguration.default
    let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
    
    let request = URLRequest(url: url)
    
    downloadTask = session.downloadTask(with: request)
    downloadTask.resume()
  }
  
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    guard let completion = completion else { return }
    do {
      try FileManager.default.copyItem(at: location, to: destinationFileUrl!)
      completion(destinationFileUrl, nil)
    } catch {
      completion(nil, error)
    }
  }
  
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let completion = completion else { return }
    
    if let error = error {
      completion(nil, error)
    }
  }
  
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
    guard let onProgress = onProgress else { return }
    onProgress(progress * 100)
  }
}
