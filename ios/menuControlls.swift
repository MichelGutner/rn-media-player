//
//  MenuControlls.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 10/12/23.
//

import Foundation
import AVKit

@available(iOS 13.0, *)
class MenuControlls {
  private weak var _player: AVPlayer?
  init(player: AVPlayer) {
    _player = player
  }
  
  lazy var rateList: UIMenu = {
    return UIMenu(title: "Taxas de reprodução", image: UIImage(systemName: "clock.arrow.2.circlepath"), children: [
      UIAction(title: "0.5x", image: nil, handler: { [self] _ in
        _player?.rate = 0.5
      }),
      UIAction(title: "normal", image: nil, handler: { [self] _ in
        _player?.rate = 1.0
      }),
      UIAction(title: "1.25x", image: nil, handler: { [self] _ in
        _player?.rate = 1.25
      }),
      UIAction(title: "1.5x", image: nil, handler: { [self] _ in
        _player?.rate = 1.5
      }),
      UIAction(title: "2x", image: nil, handler: { [self] _ in
        _player?.rate = 2.0
      })
    ])
    _player?.play()
  }()
  
  lazy var qualityList: UIMenu = {
    return UIMenu(title: "Qualidade", image: UIImage(systemName: "chart.bar.fill"), children: [
      UIAction(title: "1080p", image: nil, handler: { [self] _ in
//        playerItem.seek(to: player.currentTime())
//        player.replaceCurrentItem(with: playerItem)
        
      }),
      UIAction(title: "720p", image: nil, handler: { [self] _ in
//        playerItem.seek(to: player.currentTime())
//        player.replaceCurrentItem(with: playerItem)
        
      }),
      UIAction(title: "560p", image: nil, handler: { [self] _ in
//        playerItem.seek(to: player.currentTime())
//        player.replaceCurrentItem(with: playerItem)
        
      }),
      UIAction(title: "340p", image: nil, handler: { [self] _ in
//        playerItem.seek(to: player.currentTime())
//        player.replaceCurrentItem(with: playerItem)
        
      }),
      UIAction(title: "240p", image: nil, handler: { [self] _ in
//        playerItem.seek(to: player.currentTime())
//        player.replaceCurrentItem(with: playerItem)
        
      }),
      UIAction(title: "140p", image: nil, handler: { [self] _ in
//        playerItem.seek(to: player.currentTime())
//        player.replaceCurrentItem(with: playerItem)
        
      })
    ])
  }()
  
  lazy var mainMenu = UIMenu(title: "Menu", options: .displayInline, children: [
    rateList,
    qualityList
//    UIAction(title: "Qualidade", image: UIImage(systemName: "chart.bar.fill"), handler: { [weak self] _ in
//      // Handle the action for "Qualidade" (openPhotos() is a placeholder)
//      self?.openPhotos()
//    })
  ])
  

  public lazy var showMenu = UIMenu(title: "", children: [mainMenu])
}
