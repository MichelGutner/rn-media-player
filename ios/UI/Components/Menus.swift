//
//  Mennus.swift
//  Pods
//
//  Created by Michel Gutner on 04/10/24.
//
import SwiftUI
import AVKit

@available(iOS 14.0, *)
struct Menus: View {
  var options: NSDictionary?
  var controls: PlayerControls
  @State private var selectedOptionItem: [String: String] = [:]
  var color: UIColor?
  
  var body: some View {
    let transformedNSDictionaryIntoSwiftDictionary: [(key: String, values: NSDictionary)] = options?.compactMap { (key, value) -> (key: String, values: NSDictionary)? in
      if let key = key as? String, let values = value as? NSDictionary {
        return (key: key, values: values)
      }
      return nil
    } ?? []
    
    return Menu {
      ForEach(transformedNSDictionaryIntoSwiftDictionary, id: \.key) { option in
        let values = option.values["data"] as? [NSDictionary]
        let initialSelected = option.values["initialItemSelected"] as? String
        
        Menu(option.key) {
          ForEach(values ?? [], id: \.self) { item in
            Button(action: {
              if let value = item["value"], let selectedName = item["name"] as? String {
                controls.optionSelected(option.key, value)
                selectedOptionItem[option.key] = selectedName
              }
            }) {
              if let name = item["name"] as? String {
                if selectedOptionItem[option.key] == nil {
                  if name == initialSelected {
                    Label(name, systemImage: "checkmark")
                  } else {
                    Text(name)
                  }
                } else {
                  if let selectedOption = selectedOptionItem[option.key], name == selectedOption {
                    Label(name, systemImage: "checkmark")
                  } else {
                    Text(name)
                  }
                }
              }
            }
          }
        }
      }
    } label: {
      Circle()
        .fill(Color.black.opacity(0.4))
        .frame(width: 40, height: 40)
        .overlay(
          Image(systemName: "ellipsis")
            .font(.system(size: 14.0, weight: .bold))
            .foregroundColor(Color(uiColor: color ?? .white))
        )
    }
  }
}
