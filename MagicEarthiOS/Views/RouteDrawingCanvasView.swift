import UIKit
import SwiftUI
import CoreLocation

class RouteDrawingUIView: UIView {
    var isDrawingMode: Bool = true {
        didSet {
            isUserInteractionEnabled = isDrawingMode
            setNeedsDisplay()
        }
    }
    
    var touchPoints: [CGPoint] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var onPointAdded: ((CGPoint) -> Void)?
    var onDrawingFinished: (([CGPoint]) -> Void)?
    
    private let strokeColor = UIColor(red: 0.22, green: 1.0, blue: 0.08, alpha: 0.95) // Neon Lime #39FF14
    private let strokeGlowColor = UIColor(red: 0.22, green: 1.0, blue: 0.08, alpha: 0.4)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isOpaque = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawingMode, let touch = touches.first else { return }
        let pt = touch.location(in: self)
        touchPoints.append(pt)
        onPointAdded?(pt)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawingMode, let touch = touches.first else { return }
        let pt = touch.location(in: self)
        
        if let last = touchPoints.last {
            let dx = pt.x - last.x
            let dy = pt.y - last.y
            if hypot(dx, dy) >= 6.0 {
                touchPoints.append(pt)
                onPointAdded?(pt)
            }
        } else {
            touchPoints.append(pt)
            onPointAdded?(pt)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawingMode else { return }
        onDrawingFinished?(touchPoints)
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), touchPoints.count > 1 else { return }
        
        context.saveGState()
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        // 1. Glow stroke
        let glowPath = UIBezierPath()
        glowPath.move(to: touchPoints[0])
        for i in 1..<touchPoints.count {
            glowPath.addLine(to: touchPoints[i])
        }
        context.setStrokeColor(strokeGlowColor.cgColor)
        context.setLineWidth(14.0)
        context.addPath(glowPath.cgPath)
        context.strokePath()
        
        // 2. Main Neon Lime stroke
        let mainPath = UIBezierPath()
        mainPath.move(to: touchPoints[0])
        for i in 1..<touchPoints.count {
            mainPath.addLine(to: touchPoints[i])
        }
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(6.0)
        context.addPath(mainPath.cgPath)
        context.strokePath()
        
        // 3. Draw Start Pin (Green circle with white dot)
        if let start = touchPoints.first {
            drawPin(context: context, at: start, fillColor: UIColor.systemGreen, label: "A")
        }
        
        // 4. Draw End Pin (Orange circle with white dot)
        if touchPoints.count > 2, let end = touchPoints.last {
            drawPin(context: context, at: end, fillColor: UIColor.systemOrange, label: "B")
        }
        
        context.restoreGState()
    }
    
    private func drawPin(context: CGContext, at point: CGPoint, fillColor: UIColor, label: String) {
        let radius: CGFloat = 12.0
        let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        
        // Shadow
        context.setShadow(offset: CGSize(width: 0, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.4).cgColor)
        
        // Outer colored circle
        context.setFillColor(fillColor.cgColor)
        context.fillEllipse(in: rect)
        
        // Inner white ring
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2.5)
        context.strokeEllipse(in: rect)
    }
}

struct RouteDrawingCanvasView: UIViewRepresentable {
    @Binding var isDrawingMode: Bool
    @Binding var touchPoints: [CGPoint]
    var onPointAdded: ((CGPoint) -> Void)?
    var onDrawingFinished: (([CGPoint]) -> Void)?
    
    func makeUIView(context: Context) -> RouteDrawingUIView {
        let view = RouteDrawingUIView()
        view.isDrawingMode = isDrawingMode
        view.touchPoints = touchPoints
        view.onPointAdded = onPointAdded
        view.onDrawingFinished = onDrawingFinished
        return view
    }
    
    func updateUIView(_ uiView: RouteDrawingUIView, context: Context) {
        uiView.isDrawingMode = isDrawingMode
        if uiView.touchPoints.count != touchPoints.count {
            uiView.touchPoints = touchPoints
        }
    }
}
