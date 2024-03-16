import SwiftUI

@available(iOS 13.0, *)
struct DoubleTapSeek: View {
  @State private var tappedQuantity: Int = 0
  @State private var isTapped: Bool = false
  @State private var showArrows: [Bool] = [false, false, false]
  @State private var resetDuration: TimeInterval = 0.7
  @State private var resetTimer: Timer?
  
  var isForward: Bool = false
  var onTap: (Int) -> Void
  var advanceValue: Int = 10
  var suffixAdvanceValue: String
  var isFinished: () -> Void
  
  
  var body: some View {
    Circle()
      .fill(Color.black).opacity(VariantPercent.p10)
      .scaleEffect(2, anchor: isForward ? .leading : .trailing)
      .opacity(isTapped ? 1 : 0)
      .overlay(
        HStack {
          VStack(spacing: 10) {
            HStack(spacing: 0) {
              ForEach((0...2).reversed(), id: \.self) { index in
                Image(systemName: "arrowtriangle.backward.fill")
                  .opacity(showArrows[index] ? 1 : 0)
                  .foregroundColor(.white)
              }
            }
            .font(.title)
            .rotationEffect(.init(degrees: isForward ? 180 : 0))
            
            Text("\(!isForward ? "- " : "")\(tappedQuantity * advanceValue) ".appending(suffixAdvanceValue))
              .font(.caption)
              .fontWeight(.bold)
              .foregroundColor(.white)
            
          }
        }
      )
      .opacity(isTapped ? 1 : 0)
      .contentShape(Rectangle())
      .onTapGesture(count: isTapped ? 1 : 2) {
        self.isTapped = true
        tappedQuantity += 1
        onTap(advanceValue)

        resetTimer?.invalidate()
        
        withAnimation(.easeInOut(duration: 0.1)) {
          self.showArrows[0] = true
        }
        
        withAnimation(.easeInOut(duration: 0.2).delay(0.1)) {
          self.showArrows[0] = false
          self.showArrows[1] = true
        }
        
        withAnimation(.easeInOut(duration: 0.2).delay(0.25)) {
          self.showArrows[1] = false
          self.showArrows[2] = true
        }
        
        withAnimation(.easeInOut(duration: 0.2).delay(0.35)) {
          self.showArrows[2] = false
          
        }
        resetTimer = Timer.scheduledTimer(withTimeInterval: resetDuration, repeats: false) { _ in
          self.isTapped = false
          tappedQuantity = 0
          isFinished()
        }
      }
  }
}
