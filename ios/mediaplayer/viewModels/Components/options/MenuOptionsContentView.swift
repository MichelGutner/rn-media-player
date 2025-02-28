import SwiftUI

struct MenuOptionsContentView: View {
  @Binding var isMenuVisible: Bool
  @Binding var menuItems: [MenuItem]
  @Binding var selectedOptions: [SelectedOption]
  var onMenuItemSelected: (String, String, Any) -> Void
  @State private var menuOffsetY = UIScreen.main.bounds.height
  @State private var selectedMenuItem: MenuItem = .init(id: nil, title: nil, icon: nil, options: [])
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
            if (selectedMenuItem.options!.isEmpty) {
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
                    selectedMenuItem = MenuItem(id: item.id, title: selectedTitle, icon: item.icon, options: item.options)
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
                        onMenuItemSelected(option.id, option.name, option.value)
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
      selectedMenuItem = .init(id: nil, title: nil, icon: nil, options: [])
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
}
