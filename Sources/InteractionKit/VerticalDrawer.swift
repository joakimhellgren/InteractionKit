import SwiftUI
import Foundation

extension BinaryFloatingPoint {
    /// Returns normalized value for the range between `a` and `b`
    /// - Parameters:
    ///   - min: minimum range of measurement
    ///   - max: maximum range of measurement
    ///   - a: minimum range of scale
    ///   - b: minimum range of scale
    func normalize(min: Self, max: Self, from a: Self = 0, to b: Self = 1) -> Self {
        (b - a) * ((self - min) / (max - min)) + a
    }
    
    var isNegative: Bool {
        self < 0
    }
    
    var polarityLabel: String {
        isNegative ? "negative" : "positive"
    }
}


struct VerticalDrawer<TopBarContent: View, MainContent: View, BottomBarContent: View>: View {
    private let range: ClosedRange<CGFloat>
    private let preferredBarFraction: CGFloat
    
    @Environment(\.colorScheme)
    private var colorScheme
    
    @ViewBuilder
    private let topContent: () -> TopBarContent
    
    @ViewBuilder
    private let mainContent: () -> MainContent
    
    @ViewBuilder
    private let bottomContent: () -> BottomBarContent
    
    @State
    private var currentHeight: CGFloat = .zero
    
    @State
    private var previousHeight: CGFloat = .zero
    
    @GestureState
    private var isDragging = false
    
    init(
        contentFraction range: ClosedRange<CGFloat> = 0...0.5,
        barFraction: CGFloat = 0.15,
        @ViewBuilder topContent: @escaping () -> TopBarContent,
        @ViewBuilder mainContent: @escaping () -> MainContent,
        @ViewBuilder bottomContent: @escaping () -> BottomBarContent
    ) {
        self.topContent = topContent
        self.mainContent = mainContent
        self.bottomContent = bottomContent
        self.range = range
        self.preferredBarFraction = barFraction
    }
    
    private var contentOpacity: CGFloat {
        min(max(0, currentHeight.normalize(min: 0, max: maxBarHeight*0.75)), 1)
    }
    
    private var toolbarScale: CGFloat {
        min(max(0.5, currentHeight.normalize(min: 0, max: maxBarHeight*0.25, from: 0.5, to: 1.0)), 1)
    }
    
    private var shadowColor: Color {
        .black.opacity(0.2 * contentOpacity)
    }
    
    private let spacing = 0.0
    private let borderWidth = 0.5
    private let cornerRadius = 8.0
    private let minBarHeight = 12.0
    private let maxBarHeight = 44.0
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            VStack(spacing: spacing) {
                Spacer()
                topContent()
                    .zIndex(1)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity ,maxHeight: preferredBarHeight(in: size))
                    .background(.bar)
                    .overlay(RoundedCornerShape(
                        corners: [.topLeft, .topRight],
                        radius: cornerRadius
                    ).stroke(
                        indicatorColor,
                        lineWidth: borderWidth
                    ))
                    .clipShape(RoundedCornerShape(
                        corners: [.topLeft, .topRight],
                        radius: cornerRadius
                    ))
                    .overlay(
                        alignment: .top,
                        content: { dragIndicator(in: size) }
                    )
                
                VStack(spacing: spacing) {
                    mainContent()
                        .frame(maxWidth: size.width, maxHeight: currentHeight)
                        .background(.ultraThinMaterial)
                        .opacity(contentOpacity)
                    bottomContent()
                        .zIndex(1)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, maxHeight: preferredBarHeight(in: size))
                        .background(.bar, ignoresSafeAreaEdges: .bottom)
                        .overlay(RoundedCornerShape(
                            corners: [.topLeft, .topRight],
                            radius: cornerRadius
                        ).stroke(
                            indicatorColor,
                            lineWidth: borderWidth
                        ).ignoresSafeArea(edges: .bottom))
                }
                
            }
            .task { resetSheet(in: size) }
        }
    }
    
    private func preferredBarHeight(in size: CGSize) -> CGFloat {
        (size.height * range.upperBound) * preferredBarFraction
    }
    
    private func dragIndicator(in size: CGSize) -> some View {
        Capsule()
            .fill(.bar)
            .strokeBorder(indicatorColor)
            .frame(width: maxBarHeight, height: 6)
            //.position(x: size.width/2, y: 0)
            .offset(y: -3)
            .contentShape(Rectangle())
            .gesture(onDrag(in: size))
            .zIndex(2)
    }
    
    private func onDrag(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { gesture in
                if isDragging {
                    let minHeight = max(0, size.height * range.lowerBound)
                    let maxHeight = size.height * range.upperBound
                    let yDistance = previousHeight - gesture.translation.height
                    let height = min(max(minHeight, yDistance), maxHeight)
                    currentHeight = max(0.5, height)
                } else {
                    previousHeight = currentHeight
                }
            }
            .updating($isDragging) { _, newState, _ in newState = true }
    }
    
    private var indicatorColor: some ShapeStyle {
        colorScheme == .light ? .quaternary : .quinary
    }
    
    private func resetSheet(in size: CGSize) {
        currentHeight = size.height * range.upperBound
    }
}


#Preview {
    VerticalDrawer(
        topContent: {
            HStack {
                Text("Top bar")
            }
        },
        mainContent: {
            Text("Content goes here")
                
        },
        bottomContent: {
            HStack {
                Text("Bottom bar")
            }
        }
    )
    .foregroundStyle(.secondary)
}
