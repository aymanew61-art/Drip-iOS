import SwiftUI

// MARK: – Drip Design System
// Minimal: Near-black bg, white text, ONE accent (cream/off-white), no rainbow

enum AppTheme {
    // Backgrounds
    static let bg       = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let surface  = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let surface2 = Color(red: 0.18, green: 0.18, blue: 0.18)

    // Text
    static let textPrimary   = Color.white
    static let textSecondary = Color(white: 0.55)
    static let textTertiary  = Color(white: 0.35)

    // Strokes
    static let stroke  = Color(white: 0.22)
    static let stroke2 = Color(white: 0.14)

    // Accent — ONE color only
    static let accent    = Color(red: 0.94, green: 0.92, blue: 0.86)   // warm cream
    static let accentDim = Color(red: 0.94, green: 0.92, blue: 0.86).opacity(0.12)

    // Status
    static let green  = Color(red: 0.25, green: 0.80, blue: 0.50)
    static let yellow = Color(red: 0.95, green: 0.80, blue: 0.30)
    static let red    = Color(red: 0.95, green: 0.35, blue: 0.35)

    // Item thumbnail background — light so clothes are visible
    static let thumbBg = Color(white: 0.16)

    // Typography helpers
    static func title(_ size: CGFloat = 32) -> Font { .system(size: size, weight: .black, design: .default) }
    static func label(_ size: CGFloat = 11) -> Font { .system(size: size, weight: .semibold) }
}

// MARK: – View modifiers

extension View {
    func dripCard(radius: CGFloat = 16) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius)
                .fill(AppTheme.surface)
                .overlay(RoundedRectangle(cornerRadius: radius).stroke(AppTheme.stroke2, lineWidth: 1))
        )
    }

    func dripBorder(radius: CGFloat = 16) -> some View {
        overlay(RoundedRectangle(cornerRadius: radius).stroke(AppTheme.stroke, lineWidth: 1))
    }

    func pressScale() -> some View { buttonStyle(PressScaleStyle()) }
}

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// Count-up text
struct CountUp: View {
    let to: Double; let fmt: String
    var suffix: String = ""
    @State private var v: Double = 0
    var body: some View {
        Text(String(format: fmt, v) + suffix)
            .onAppear { withAnimation(.easeOut(duration: 0.85)) { v = to } }
            .onChange(of: to) { _, n in withAnimation(.easeOut(duration: 0.5)) { v = n } }
    }
}

// Glasscard alias for backwards compat
extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View { dripCard(radius: cornerRadius) }
    func surfaceCard(cornerRadius: CGFloat = 16) -> some View { dripCard(radius: cornerRadius) }
    func accentCard(cornerRadius: CGFloat = 16) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(AppTheme.surface)
                .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(AppTheme.stroke, lineWidth: 1))
        )
    }
}
