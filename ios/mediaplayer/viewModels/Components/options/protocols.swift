//
//  protocols.swift
//  Pods
//
//  Created by Michel Gutner on 23/02/25.
//

public enum EMenuOptionItem {
  case speeds
  case qualities
  case captions
  case unkown
}

public struct MenuItem {
  let id: String?
  let title: String?
  let icon: String?
  var options: [MenuOption]?
}

public struct MenuOption {
  let id: String
  let name: String
  let value: Any
  var selected: String
}

public struct SelectedOption {
  let parentTitle: String
  let selectedOption: String
}
