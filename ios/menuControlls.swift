//
//  MenuControlls.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 10/12/23.
//

import Foundation

@available(iOS 13.0, *)
class MenuControlls {
  lazy var tapmeitems: UIMenu = {
    return UIMenu(title: "More", options: .displayInline, children: [
      UIAction(title: "Taxas de reprodução", image: UIImage(systemName: "clock.arrow.2.circlepath"), handler: { [weak self] _ in self?.openCamera()}),
      UIAction(title: "Qualidade", image: UIImage(systemName: "chart.bar.fill"), handler: { [weak self] _ in self?.openPhotos()}),
    ])
  }()
  
  public lazy var menu: UIMenu = {
    return UIMenu(title: "", children: [tapmeitems])
  }()
  
  @objc func openCamera() {
    print("open camera")
  }
  
  @objc func openPhotos() {
    print("open photos")
  }
}
