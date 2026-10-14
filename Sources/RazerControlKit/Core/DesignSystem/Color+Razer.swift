import SwiftUI

public extension Color {
    static let razerGreen = Color(red: 0.0, green: 0.90, blue: 0.0)
    static let razerGreenDark = Color(red: 0.0, green: 0.70, blue: 0.0)
    static let razerGreenGaze = Color(red: 0.0, green: 1.0, blue: 0.25).opacity(0.15)
    
    static let razerBackground = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let razerCard = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let razerCardHover = Color(red: 0.16, green: 0.16, blue: 0.16)
    static let razerBorder = Color(red: 0.20, green: 0.20, blue: 0.20)
    static let razerMutedText = Color(red: 0.60, green: 0.60, blue: 0.60)
    
    // Status colors
    static let razerSuccess = Color(red: 0.15, green: 0.85, blue: 0.35)
    static let razerWarning = Color(red: 0.95, green: 0.65, blue: 0.15)
    static let razerDanger = Color(red: 0.95, green: 0.25, blue: 0.25)
    static let razerInfo = Color(red: 0.20, green: 0.60, blue: 1.0)
}

public struct RazerCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    public init() {}

    public func body(content: Content) -> some View {
        content
            .padding(16)
            .background(colorScheme == .dark ? Color.razerCard : Color(nsColor: .windowBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.razerBorder, lineWidth: 1)
            )
    }
}

public extension View {
    func razerCard() -> some View {
        self.modifier(RazerCardModifier())
    }
}
