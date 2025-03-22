//
//  ContentView.swift
//  Pods
//
//  Created by Michel Gutner on 19/03/25.
//


import SwiftUI

protocol PlayListDelegate : AnyObject {
  func didSelectVideo(with video: PlayListItem)
  func didClosePlayList()
}

struct PlayList: View {
  @Binding var list: [PlayListItem]
  @State private var selectedEpisodeID: UUID?
  weak var delegate: PlayListDelegate?
  
  var body: some View {
    VStack {
      HStack {
        Text("Mais videos")
          .font(.title)

        Spacer()
        Button(action: {
          
        }, label: {
          ButtonTemplate(imageName: .constant("xmark")) {
            delegate?.didClosePlayList()
          }
        })
      }
      .padding()
      
      Spacer()
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 20) {
          Spacer()
          ForEach(list, id: \.title) { video in
            VideoListItem(
              video: video,
              action: { video in
                delegate?.didSelectVideo(with: video)
              })
          }
          Spacer()
        }
      }
    }
    .onDisappear {
      list.removeAll()
    }
  }
}

func getUIScreen() -> UIScreen {
  let currentWindow = UIApplication.currentWindow
  guard let screen = currentWindow?.windowScene?.screen else { return UIScreen() }
  
  return screen
}

// 📌 Componente de Episódio
struct VideoListItem: View {
  let video: PlayListItem
  let action: (PlayListItem) -> Void
  
  var body: some View {
    let calculatedWidth = calculateSizeByWidth(180, 0.4)
    let calculatedHeight = calculateSizeByWidth(130, 0.4)
    
    VStack {
        Button(action: {
          action(video)
        }, label: {
          Image(uiImage: video.image ?? UIImage())
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: calculatedWidth, height: calculatedHeight)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: Color.black.opacity(0.5), radius: 1.5)
            .overlay(
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 40, height: 40)

                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            )
        })
      
      HStack {
        Text(video.title)
          .font(.custom("Poppins-Medium", size: 14))
          .padding(12)
        Spacer()
      }
    }
  }
}

