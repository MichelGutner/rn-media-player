//
//  Menus.swift
//  Pods
//
//  Created by Michel Gutner on 29/11/24.
//

import SwiftUI

@available(iOS 14.0, *)
struct CustomMenus: View {
    @Binding var menus: NSDictionary?
    @State private var selectedOptionItem: [String: String] = [:]
    
    var body: some View {
        Menu {
            ForEach(menuOptions, id: \.key) { option in
                createMenu(for: option)
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .frame(width: 20, height: 20)
                .padding(.horizontal, 8)
                .foregroundColor(.white)
                .font(.system(size: 20))
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
            .eraseToAnyView() // Resolve problemas de tipo misto
        }
        return EmptyView().eraseToAnyView()
    }
    
    // MARK: - Computed Properties
    private var menuOptions: [(key: String, values: NSDictionary)] {
        guard let menus = menus else { return [] }
        return menus.compactMap { (key, value) in
            guard let key = key as? String, let values = value as? NSDictionary else { return nil }
            return (key: key, values: values)
        }
    }
}

// MARK: - Extensions
extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
