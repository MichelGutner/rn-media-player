//
//  Menus.swift
//  Pods
//
//  Created by Michel Gutner on 29/11/24.
//

import SwiftUI

@available(iOS 14.0, *)
struct CustomMenus: View {
  public var onSelect: ((String, Any)) -> Void
    @State private var selectedOptionItem: [String: String] = [:]
    
  var body: some View {
    Menu {
      ForEach(menuOptions, id: \.key) { option in
        createMenu(for: option)
      }
    } label: {
      Image(systemName: "ellipsis.circle")
        .foregroundColor(.white)
        .font(.system(size: 16))
        .padding(12)
    }
  }
    
    // MARK: - Subviews
    private func createMenu(for option: (key: String, values: NSDictionary)) -> some View {
        let values = option.values["data"] as? [NSDictionary] ?? []
        let initialSelected = option.values["initialItemSelected"] as? String
        let currentSelection = selectedOptionItem[option.key]
        
        return Menu(option.key) {
            ForEach(values, id: \.self) { item in
                let isSelected = (item["name"] as? String == currentSelection) ||
                                 (currentSelection == nil && item["name"] as? String == initialSelected)
                menuButton(for: item, in: option, isSelected: isSelected)
            }
        }
    }
    
    private func menuButton(for item: NSDictionary, in option: (key: String, values: NSDictionary), isSelected: Bool) -> some View {
        if let name = item["name"] as? String {
            return Button(action: {
                if let value = item["value"] {
                    selectedOptionItem[option.key] = name
                  NotificationCenter.default.post(name: .EventMenuSelectOption, object: (option.key, value))
                  onSelect((option.key, value))
                }
            }) {
              if #available(iOS 14.5, *) {
                if isSelected {
                  Label(name, systemImage: "checkmark")
                    .labelStyle(.titleAndIcon)
                } else {
                  Text(name)
                }
              } else {
                if isSelected {
                  Label(name, systemImage: "checkmark")
                } else {
                  Text(name)
                }
              }
            }
            .eraseToAnyView()
        }
        return EmptyView().eraseToAnyView()
    }
    

    private var menuOptions: [(key: String, values: NSDictionary)] {
      guard let menus = appConfig.playbackMenu else { return [] }
        return menus.compactMap { (key, value) in
            guard let key = key as? String, let values = value as? NSDictionary else { return nil }
            return (key: key, values: values)
        }
    }
}


extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
