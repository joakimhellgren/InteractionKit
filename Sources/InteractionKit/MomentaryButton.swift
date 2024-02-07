import SwiftUI

public struct MomentaryButton<T: View>: View {
    @Binding private var isOn: Bool
    private let label: T
    
    public init(isOn: Binding<Bool>, label: () -> T) {
        self._isOn = isOn
        self.label = label()
    }
    
    public var body: some View {
        Button(action:{}){label}.buttonStyle(MomentaryButtonStyle(isPressed: $isOn))
    }
    
    private struct MomentaryButtonStyle: ButtonStyle {
        @Binding var isPressed: Bool
        public func makeBody(configuration: Configuration) -> some View {
            configuration.label.gesture(DragGesture(minimumDistance: 0).onChanged({ _ in
                isPressed = true
            }).onEnded({ _ in
                isPressed = false
            }))
        }
    }
}

