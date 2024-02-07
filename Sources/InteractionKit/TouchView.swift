#if !os(macOS) || targetEnvironment(macCatalyst)

import SwiftUI

public protocol TouchDelegate: AnyObject {
    var touches: [CGPoint] { get set }
}

public struct TouchView<T: View>: UIViewRepresentable {
    public weak var touchDelegate: TouchDelegate?
    let view: UIViewType
    let tintColor: UIColor
    let showTouches: Bool
    
    public init(
        touchDelegate: TouchDelegate? = nil,
        tintColor: UIColor = .tintColor,
        showTouches: Bool = true,
        @ViewBuilder content: () -> T
    ) {
        self.view = UIHostingController(rootView: content()).view
        self.tintColor = tintColor
        self.showTouches = showTouches
        self.touchDelegate = touchDelegate
    }
    
    public func makeUIView(context: Context) -> UIView {
        let touchIndicator = TouchIndicatorGestureRecognizer(target: view, action: nil)
        touchIndicator.showTouches = showTouches
        touchIndicator.tintColor = tintColor
        touchIndicator.touchDelegate = context.coordinator
        touchIndicator.delegate = context.coordinator
        view.addGestureRecognizer(touchIndicator)
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {}
    public func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    public class Coordinator: NSObject, UIGestureRecognizerDelegate, TouchDelegate {
        var parent: TouchView
        public var touches = [CGPoint]() {
            didSet { parent.touchDelegate?.touches = touches }
        }
        public init(_ parent: TouchView) {
            self.parent = parent
        }
        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}

public class TouchIndicatorGestureRecognizer: UIGestureRecognizer {
    private static var maxNumberOfKeys: Int = 32
    // MARK: - Properties
    public var tintColor: UIColor = .tintColor
    public var showTouches: Bool = true
    
    private var activeTouches = [UITouch : UIView]()
    private var currentTouches = NSMutableSet(capacity: Int(maxNumberOfKeys))
    
    public weak var touchDelegate: TouchDelegate?
    
    private func updateDelegate() {
        if let touches = currentTouches.allObjects as? [UITouch] {
            let points = touches.map { $0.location(in: nil) }
            touchDelegate?.touches = points
        }
    }
    
    // MARK: - Init
    
    public override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
    }
    
    // MARK: - Override
    
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
    
    // MARK: - Indicator
    
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
            activeTouches[touch] = indicator
        }
        
        UIView.animate(withDuration: 0.2, delay: 0,
                       usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0,
                       options: .allowUserInteraction, animations: { () -> Void in
            indicator.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    private func moveIndicatorView(_ touch: UITouch) {
        if let indicator = activeTouches[touch] {
            indicator.center = touch.location(in: view)
            state = .changed
        }
    }
    
    private func removeIndicatorView(_ touch: UITouch) {
        if let indicator = activeTouches[touch] {
            UIView.animate(withDuration: 0.2, delay: 0,
                           usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0,
                           options: .allowUserInteraction, animations: { () -> Void in
                indicator.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            }, completion: { (finished) -> Void in
                indicator.removeFromSuperview()
                self.activeTouches.removeValue(forKey: touch)
                if self.activeTouches.count == 0 {
                    self.state = .ended
                }
            })
        }
    }
}

#endif
