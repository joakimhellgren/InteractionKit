import SwiftUI
import Foundation

public extension BinaryFloatingPoint {
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


public struct VerticalDrawer<TopBarContent: View, MainContent: View, BottomBarContent: View>: View {
    private let proxy: GeometryProxy
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
    
    public init(
        in proxy: GeometryProxy,
        contentFraction range: ClosedRange<CGFloat> = 0...0.5,
        barFraction: CGFloat = 0.15,
        @ViewBuilder topContent: @escaping () -> TopBarContent,
        @ViewBuilder mainContent: @escaping () -> MainContent,
        @ViewBuilder bottomContent: @escaping () -> BottomBarContent
    ) {
        self.proxy = proxy
        self.topContent = topContent
        self.mainContent = mainContent
        self.bottomContent = bottomContent
        self.range = range
        self.preferredBarFraction = barFraction
    }
    
    private var contentOpacity: CGFloat {
        min(max(0, currentHeight.normalize(min: 0, max: 32)), 1)
    }
    
    private var toolbarScale: CGFloat {
        min(max(0.5, currentHeight.normalize(min: 0, max: 12, from: 0.5, to: 1.0)), 1)
    }
    
    private var shadowColor: Color {
        .black.opacity(0.2 * contentOpacity)
    }
    
    private let spacing = 0.0
    private let borderWidth = 0.5
    private let cornerRadius = 8.0
    
    private var size: CGSize { proxy.size }
    public var body: some View {
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
                        .opacity(contentOpacity)
                        .background(.ultraThinMaterial)
                    bottomContent()
                        .zIndex(1)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, maxHeight: preferredBarHeight(in: size))
                        .background(.bar, ignoresSafeAreaEdges: .bottom)
                        .overlay(RoundedCornerShape(
                            corners: [.bottomLeft, .bottomRight],
                            radius: cornerRadius
                        ).stroke(
                            indicatorColor.opacity(contentOpacity),
                            lineWidth: borderWidth
                        ).ignoresSafeArea(edges: .bottom))
                }
                
            }
            .task { resetSheet(in: size) }
    }
    
    private func preferredBarHeight(in size: CGSize) -> CGFloat {
        (size.height * range.upperBound) * preferredBarFraction
    }
    
    private func dragIndicator(in size: CGSize) -> some View {
        Capsule()
            .fill(.bar)
            .strokeBorder(indicatorColor, lineWidth: borderWidth)
            .frame(width: 22, height: 6)
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
                    currentHeight = max(0, height)
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

