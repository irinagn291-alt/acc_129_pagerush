import SwiftUI

enum PageRushPalette {
    static let primary = Color(red: 1.0, green: 0.42, blue: 0.21)
    static let secondary = Color(red: 0.0, green: 0.31, blue: 0.54)
    static let accent = Color(red: 1.0, green: 0.82, blue: 0.25)
    static let canvas = Color(red: 1.0, green: 0.97, blue: 0.94)
    static let surface = Color.white
    static let ink = Color(red: 0.11, green: 0.11, blue: 0.12)

    static let radiusPill: CGFloat = 24
    static let radiusCard: CGFloat = 20
    static let radiusSheet: CGFloat = 28

    static var energyGradient: LinearGradient {
        LinearGradient(
            colors: [canvas, accent.opacity(0.25), surface],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var rushStroke: LinearGradient {
        LinearGradient(
            colors: [primary.opacity(0.6), secondary.opacity(0.4)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func cardShadow(reduceMotion: Bool) -> (color: Color, radius: CGFloat, y: CGFloat) {
        (ink.opacity(0.1), reduceMotion ? 2 : 12, 6)
    }

    static func rounded(_ style: Font.TextStyle = .title2) -> Font {
        .system(style, design: .rounded).weight(.bold)
    }
}
