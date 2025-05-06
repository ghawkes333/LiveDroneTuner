import UIKit

class Arc: UIView {
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius: CGFloat = rect.width / 2 - 5
        
        // Degrees are measured in radians
        let startAngle: CGFloat = .pi    // 180 degrees
        let endAngle: CGFloat = 0        // 0 degrees

        context.setStrokeColor(UIColor.label.cgColor)
        context.setLineWidth(3.0)

        context.addArc(center: center,
                       radius: radius,
                       startAngle: startAngle,
                       endAngle: endAngle,
                       clockwise: false)

        context.strokePath()

    }
}
