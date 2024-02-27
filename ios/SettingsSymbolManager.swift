import SwiftUI

@available(iOS 13.0, *)
struct SettingsSymbolManager: View {
  var imageName: String
  var onTap: () -> Void
  var config: NSDictionary?
  
  @State private var dynamicFontSize: CGFloat = calculateSizeByWidth(size18, variantPercent30)

  
  var body: some View {
    VStack {
      let configColor = config?["color"]
      let color = Color(transformStringIntoUIColor(color: configColor as? String))
      
      Button(action: onTap) {
        Image(systemName: imageName)
          .font(.system(size: dynamicFontSize))
          .foregroundColor(color)
      }
      .onAppear {
        NotificationCenter.default.addObserver(forName: UIApplication.willChangeStatusBarOrientationNotification, object: nil, queue: .main) { _ in
          updateDynamicFontSize()
        }
      }
    }
    .fixedSize(horizontal: true, vertical: true)
  }

  private func updateDynamicFontSize() {
    dynamicFontSize = calculateSizeByWidth(size18, variantPercent30)
  }
}
