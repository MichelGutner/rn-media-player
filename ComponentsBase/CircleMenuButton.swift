//
//  CircleMenuButton.swift
//  rn-media-player
//
//  Created by Michel Gutner on 02/09/24.
//

import Foundation
import SwiftUI

@available(iOS 14.0, *)
func CreateCircleMenuButton(menus: NSDictionary?, _ overlay: some View, action: @escaping (_ label: String, _ value: Any) -> Void) -> some View {
    var transformedNSDictionaryIntoSwiftDictionary: [(key: String, values: [NSDictionary])] = []
    
    if let menus = menus {
        transformedNSDictionaryIntoSwiftDictionary = menus.compactMap { (key, value) -> (key: String, values: [NSDictionary])? in
            if let key = key as? String, let values = value as? [NSDictionary] {
                return (key: key, values: values)
            }

            return nil
        }
    }

    return Menu {
        ForEach(transformedNSDictionaryIntoSwiftDictionary, id: \.key) { option in
            Menu(option.key) {
                ForEach(option.values, id: \.self) { item in
                    Button(action: {
                        let label = item["name"] as! String
                        let value = item["value"] as Any
                        action(option.key, value)
                    }) {
                        if let label = item["name"] as? String {
                            Label(label, systemImage: "chevron.right")
                        }
                    }
                }
            }
        }
    } label: {
        Circle()
            .fill(Color.black.opacity(0.3))
            .frame(width: 40, height: 40)
            .overlay(overlay)
    }
}
