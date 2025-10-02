import SwiftUI

// Extension for rounding
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// Extension for view modifiers
extension View {
    func techBorder() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(LinearGradient(
                    gradient: Gradient(colors: [.cyan.opacity(0.5), .blue.opacity(0.5)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 1.5)
        )
    }
}
    