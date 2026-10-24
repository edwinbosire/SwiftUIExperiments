import SwiftUI
import UIKit

/// Inspect horizontal drags while leaving vertical pans to the surrounding scroll view.
struct XStockInspectionGesture: UIViewRepresentable {
    let onChange: (CGPoint) -> Void
    let onEnd: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.pan(_:)))
        pan.delegate = context.coordinator
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: XStockInspectionGesture
        init(parent: XStockInspectionGesture) { self.parent = parent }

        func gestureRecognizerShouldBegin(_ gesture: UIGestureRecognizer) -> Bool {
            guard let pan = gesture as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }

        func gestureRecognizer(_ gesture: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            other.view is UIScrollView
        }

        @objc func pan(_ gesture: UIPanGestureRecognizer) {
            switch gesture.state {
            case .began, .changed: parent.onChange(gesture.location(in: gesture.view))
            case .ended, .cancelled, .failed: parent.onEnd()
            default: break
            }
        }
    }
}
