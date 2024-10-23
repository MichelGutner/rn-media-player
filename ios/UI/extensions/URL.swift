//
//  URL.swift
//  Pods
//
//  Created by Michel Gutner on 20/10/24.
//

extension URL {
  func isReachable(completion: @escaping (Bool, (any Error)?, Int?) -> ()) {
        var request = URLRequest(url: self)
        request.httpMethod = "HEAD"
        URLSession.shared.dataTask(with: request) { data, response, error in
          let statusCode = (response as? HTTPURLResponse)?.statusCode
          if (statusCode == 200) {
            completion(true, nil, nil)
          } else {
            completion(false, error, statusCode)
          }
        }.resume()
    }
}
