import Foundation
import PhotosUI

public func downloadVideo(from url: URL, title: String = "video", completion: @escaping (URL?, Error?) -> Void) {
  let documentsUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
  let destinationFileUrl = documentsUrl.appendingPathComponent("\(title).mp4")
  
  
  let sessionConfig = URLSessionConfiguration.default
  let session = URLSession(configuration: sessionConfig)
  
  let request = URLRequest(url:url)
  
  let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
    if let tempLocalUrl = tempLocalUrl, error == nil {
      
      if let statusCode = (response as? HTTPURLResponse)?.statusCode {
        completion(destinationFileUrl, nil)
      }
      
      do {
        try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
      } catch (let writeError) {
        completion(nil, writeError)
      }
    }
  }
  task.resume()
  
}
