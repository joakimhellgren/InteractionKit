#if !os(macOS) || targetEnvironment(macCatalyst)

import SwiftUI

public protocol TouchDelegate: AnyObject {
    var touches: [CGPoint] { get set }
}

public struct TouchView<T: TouchDelegate, Content: View>: View {
    private let delegate: T
    private let tintColor: UIColor
    private let showTouches: Bool
    
    @ViewBuilder
    private let content: (GeometryProxy) -> Content
    
    public init(
        delegate: T,
        tintColor: UIColor = .tintColor,
        showTouches: Bool = true,
        @ViewBuilder content: @escaping (GeometryProxy) -> Content
    ) {
        self.delegate = delegate
        self.tintColor = tintColor
        self.showTouches = showTouches
        self.content = content
    }
    
    public var body: some View {
        TouchViewRepresentable(
            delegate: delegate,
            tintColor: tintColor,
            showTouches: showTouches,
            content: {
                GeometryReader { proxy in
                    ZStack {
                        content(proxy)
                    }
                }
            }
        )
    }
}

public struct TouchViewRepresentable<T: View>: UIViewRepresentable {
    private let delegate: TouchDelegate
    private let view: UIViewType
    private let tintColor: UIColor
    private let showTouches: Bool
    private let touchIndicator: TouchIndicatorGestureRecognizer
    
    public init(
        delegate: TouchDelegate,
        tintColor: UIColor,
        showTouches: Bool,
        @ViewBuilder content: () -> T
    ) {
        self.view = UIHostingController(rootView: content()).view
        self.tintColor = tintColor
        self.showTouches = showTouches
        self.delegate = delegate
        self.touchIndicator = TouchIndicatorGestureRecognizer(target: view, action: nil)
    }
    
    public func makeUIView(context: Context) -> UIView {
        touchIndicator.showTouches = showTouches
        touchIndicator.tintColor = tintColor
        touchIndicator.touchDelegate = context.coordinator
        touchIndicator.delegate = context.coordinator
        view.addGestureRecognizer(touchIndicator)
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        touchIndicator.showTouches = showTouches
        touchIndicator.tintColor = tintColor
    }
    
    public func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    public class Coordinator: NSObject, UIGestureRecognizerDelegate, TouchDelegate {
        var parent: TouchViewRepresentable
        public var touches = [CGPoint]() {
            didSet { parent.delegate.touches = touches }
        }
        public init(_ parent: TouchViewRepresentable) {
            self.parent = parent
        }
        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}

public class TouchIndicatorGestureRecognizer: UIGestureRecognizer {
    private static var maxNumberOfTouches: Int = 32
    // MARK: - Properties
    public var tintColor: UIColor = .tintColor
    public var showTouches: Bool = true
    
    private var touchBubbles = [UITouch : UIView]()
    private var currentTouches = NSMutableSet(capacity: Int(maxNumberOfTouches))
    
    public weak var touchDelegate: TouchDelegate?
    
    private func updateDelegate() {
        if let touches = currentTouches.allObjects as? [UITouch] {
            let points = touches.map { $0.location(in: nil) }
            touchDelegate?.touches = points
        }
    }
    
    public override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        for touch in touches {
            currentTouches.add(touch)
            if showTouches {
                createIndicatorView(touch)
            }
        }
        updateDelegate()
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        for touch in touches {
            currentTouches.add(touch)
            if showTouches {
                moveIndicatorView(touch)
            }
        }
        updateDelegate()
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        for touch in touches {
            currentTouches.remove(touch)
            if showTouches {
                removeIndicatorView(touch)
            }
        }
        updateDelegate()
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        for touch in touches{
            currentTouches.remove(touch)
            if showTouches {
                removeIndicatorView(touch)
            }
        }
        updateDelegate()
    }
    
    private class func indicator(color: UIColor) -> UIView {
        let indicator = UIView(frame: CGRect(x: 0, y: 0,
                                             width: 66.0,
                                             height: 66.0))
        indicator.backgroundColor = color
        indicator.alpha = 0.8
        indicator.layer.cornerRadius = 66.0/2.0
        return indicator
    }
    
    private func createIndicatorView(_ touch: UITouch) {
        state = .began
        
        let indicator = TouchIndicatorGestureRecognizer.indicator(color: tintColor)
        indicator.center = touch.location(in: view)
        indicator.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        indicator.layer.zPosition = CGFloat(MAXFLOAT);
        
        if let gestureView = view {
            gestureView.addSubview(indicator)
            touchBubbles[touch] = indicator
        }
        
        UIView.animate(withDuration: 0.2, delay: 0,
                       usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0,
                       options: .allowUserInteraction, animations: { () -> Void in
            indicator.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    private func moveIndicatorView(_ touch: UITouch) {
        if let indicator = touchBubbles[touch] {
            indicator.center = touch.location(in: view)
            state = .changed
        }
    }
    
    private func removeIndicatorView(_ touch: UITouch) {
        if let indicator = touchBubbles[touch] {
            UIView.animate(withDuration: 0.2, delay: 0,
                           usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0,
                           options: .allowUserInteraction, animations: { () -> Void in
                indicator.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            }, completion: { (finished) -> Void in
                indicator.removeFromSuperview()
                self.touchBubbles.removeValue(forKey: touch)
                if self.touchBubbles.count == 0 {
                    self.state = .ended
                }
            })
        }
    }
}

#endif
