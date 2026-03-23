import SwiftUI

/// Draws an L-shaped bracket at one corner of its parent frame.
/// Used as a decorative element matching the Figma "Network Topology" box style.
struct CornerBracket: View {
    enum Corner { case topLeading, topTrailing, bottomLeading, bottomTrailing }

    let corner: Corner
    let size: CGFloat
    let color: Color
    var lineWidth: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height

                switch corner {
                case .topLeading:
                    path.move(to: CGPoint(x: 0, y: size))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: size, y: 0))
                case .topTrailing:
                    path.move(to: CGPoint(x: w - size, y: 0))
                    path.addLine(to: CGPoint(x: w, y: 0))
                    path.addLine(to: CGPoint(x: w, y: size))
                case .bottomLeading:
                    path.move(to: CGPoint(x: 0, y: h - size))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.addLine(to: CGPoint(x: size, y: h))
                case .bottomTrailing:
                    path.move(to: CGPoint(x: w, y: h - size))
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.addLine(to: CGPoint(x: w - size, y: h))
                }
            }
            .stroke(color, lineWidth: lineWidth)
        }
    }
}
