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


public struct VerticalDrawer<TopBarContent: View, MainContent: View, BottomBarContent: View, BarStyle: ShapeStyle, ContentStyle: ShapeStyle, StrokeStyle: ShapeStyle>: View {
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
    
    private let barStyle: BarStyle
    private let contentStyle: ContentStyle
    private let strokeStyle: StrokeStyle
    
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
        barStyle: BarStyle = .bar,
        contentStyle: ContentStyle = .regularMaterial,
        strokeStyle: StrokeStyle = .quinary,
        @ViewBuilder topContent: @escaping () -> TopBarContent,
        @ViewBuilder mainContent: @escaping () -> MainContent,
        @ViewBuilder bottomContent: @escaping () -> BottomBarContent
    ) {
        self.proxy = proxy
        self.range = range
        self.preferredBarFraction = barFraction
        
        self.barStyle = barStyle
        self.contentStyle = contentStyle
        self.strokeStyle = strokeStyle
        
        self.topContent = topContent
        self.mainContent = mainContent
        self.bottomContent = bottomContent
    }
    
    private var size: CGSize {
        proxy.size
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
    
    public var body: some View {
        VStack(spacing: spacing) {
            Spacer()
            topContent()
                .zIndex(1)
                .frame(width: size.width, height: preferredBarHeight(in: size))
                .background(barStyle)
                .overlay(RoundedCornerShape(
                    corners: [.topLeft, .topRight],
                    radius: cornerRadius
                ).stroke(
                    strokeStyle,
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
                    .background(
                            Rectangle()
                                .fill(contentStyle)
                                .frame(minHeight: contentStyle is Material ? 3 : 0)
                    )
                bottomContent()
                    .zIndex(1)
                    .frame(width: size.width, height: preferredBarHeight(in: size))
                    .background(barStyle)
                    .overlay(RoundedCornerShape(
                        corners: [.bottomLeft, .bottomRight],
                        radius: cornerRadius
                    ).stroke(
                        strokeStyle.opacity(contentOpacity),
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
            .strokeBorder(strokeStyle, lineWidth: borderWidth)
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
                    let maxHeight = (size.height * range.upperBound) - (preferredBarHeight(in: size)*2)
                    let yDistance = previousHeight - gesture.translation.height
                    let height = min(max(minHeight, yDistance), maxHeight)
                    currentHeight = max(0, height)
                } else {
                    previousHeight = currentHeight
                }
            }
            .updating($isDragging) { _, newState, _ in newState = true }
    }
    
    private func resetSheet(in size: CGSize) {
        currentHeight = size.height * range.upperBound
    }
}

