import SwiftUI

struct MenuOptionsContentView: View {
  @Binding var isMenuVisible: Bool
  @Binding var menuData: NSDictionary
  var onMenuItemSelected: (String, Any) -> Void
  @State private var menuOffsetY = UIScreen.main.bounds.height
  @State private var selectedMenuItem: MenuItem = .init(title: nil, icon: nil, options: [])
  @State private var selectedOptions: [SelectedOption] = []
  @State private var menuItems: [MenuItem] = []
  @State private var isModalVisible: Bool = false
  
  var body: some View {
    VStack {
      Spacer()
      VStack {
        HStack {
          Spacer()
          Rectangle()
            .fill(Color.gray)
            .frame(width: 30, height: 3)
            .clipShape(Capsule())
          Spacer()
        }
        VStack {
          ScrollView {
            if selectedMenuItem.options!.isEmpty {
              let sortedMenuItems = menuItems.sorted {
                if $0.icon == "text.word.spacing" { return true }
                if $1.icon == "text.word.spacing" { return false }
                if $0.icon == "timer" { return true }
                if $1.icon == "timer" { return false }
                return $0.title! < $1.title!
              }
              
              ForEach(sortedMenuItems, id: \ .title) { item in
                MenuItemView(
                  title: item.title,
                  leftIcon: item.icon,
                  rightIcon: "chevron.right",
                  selectedOption: selectedOptions.first(where: { $0.parentTitle == item.title })?.selectedOption
                ) { selectedTitle in
                  hideMenu()
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    selectedMenuItem = MenuItem(title: selectedTitle, icon: item.icon, options: item.options)
                    showMenu()
                  }
                }
              }
            } else {
              if let options = selectedMenuItem.options, let title = selectedMenuItem.title {
                VStack {
                  ForEach(options, id: \ .name) { option in
                    MenuItemView(
                      title: option.name,
                      leftIcon: selectedOptions.first(where: { $0.parentTitle == title })?.selectedOption == option.name ? "checkmark" : nil,
                      rightIcon: nil,
                      onSelect: { selectedTitle in
                        selectedOptions.removeAll(where: { $0.parentTitle == title })
                        selectedOptions.append(SelectedOption(parentTitle: title, selectedOption: selectedTitle))
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                          closeMenu()
                        }
                        onMenuItemSelected(option.id, option.value)
                      }
                    )
                  }
                }
              }
            }
          }
        }
      }
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: calculateMaxWidth())
      .padding()
      .background(Color(UIColor.tertiarySystemBackground))
      .cornerRadius(12)
      .gesture(
        DragGesture()
          .onChanged { value in
            withAnimation(.easeInOut(duration: 0.1)) {
              if value.translation.height > 0 {
                menuOffsetY = value.translation.height
              }
            }
          }
          .onEnded { value in
            if menuOffsetY > 80 {
              closeMenu()
            } else {
              withAnimation(.easeInOut(duration: 0.2)) {
                menuOffsetY = 0
              }
            }
          }
      )
      .offset(y: menuOffsetY)
      .onAppear {
        if menuOffsetY > 0 {
          showMenu()
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
    .background(
      Color.clear
        .contentShape(Rectangle())
        .edgesIgnoringSafeArea(.all)
        .onTapGesture {
          if isModalVisible {
            closeMenu()
          }
        }
    )
    .opacity(isMenuVisible ? 1 : 0)
    .onAppear {
      let isValidToGenerateNewMenuItems: Bool = menuItems.isEmpty || menuData.count != menuItems.first.map(\.options?.count) ?? 0
      
      if  isValidToGenerateNewMenuItems {
        menuItems.removeAll()
        parseMenuData()
      }
    }
  }
  
  private func showMenu() {
    isMenuVisible = true
    withAnimation(.smooth(duration: 0.35)) {
      menuOffsetY = 0
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
      isModalVisible = true
    }
  }
  
  private func hideMenu() {
    isModalVisible = false
    withAnimation(.easeInOut(duration: 0.35)) {
      menuOffsetY = UIScreen.main.bounds.height
    }
  }
  
  private func closeMenu() {
    hideMenu()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
      isMenuVisible = false
      selectedMenuItem = .init(title: nil, icon: nil, options: [])
    }
  }
  
  private func calculateMaxWidth() -> CGFloat {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene
    let window = windowScene?.windows.first
    let screenHeight = (window?.bounds.height ?? UIScreen.main.bounds.height)
    let screenWidth = (window?.bounds.width ?? UIScreen.main.bounds.width)
    let isLandscape = screenWidth > screenHeight
    
    return isLandscape ? screenHeight : screenWidth
  }
  
  private func parseMenuData() {
    menuData.allKeys.forEach { key in
      guard let keyString = key as? String,
            let values = menuData[key] as? NSDictionary,
            let optionsArray = values["options"] as? [NSDictionary],
            let title = values["title"] as? String else { return }
      let initialSelection = values["initialOptionSelected"] ?? optionsArray.first!["name"] as! String
      let isDisabled = values["disabled"] as? Bool ?? false
      
      let icon: String
      switch keyString {
      case "speeds":
        icon = "timer"
      case "qualities":
        icon = "text.word.spacing"
      case "captions":
        icon = "captions.bubble"
      default:
        icon = "questionmark.circle"
      }
      
      let options = optionsArray.compactMap { dict -> MenuOption? in
        guard let name = dict["name"] as? String, let value = dict["value"] else { return nil }
        selectedOptions.append(SelectedOption(parentTitle: title, selectedOption: initialSelection as! String))
        return MenuOption(id: keyString, name: name, value: value, selected: initialSelection as! String)
      }
      
      if !isDisabled { 
        self.menuItems.append(MenuItem(title: title, icon: icon, options: options))
      }
    }
  }
}
