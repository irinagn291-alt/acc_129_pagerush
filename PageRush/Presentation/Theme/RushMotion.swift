import SwiftUI

enum RushMotion {
    @MainActor
    static func slide(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.12) : .spring(response: 0.5, dampingFraction: 0.82)
    }

    @MainActor
    static func pop(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.4, dampingFraction: 0.78)
    }
}
