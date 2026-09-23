import SwiftUI

public enum DesignTokens {
    // MARK: - Color Palette (Dark Aesthetic)
    public static let background = Color(red: 0.07, green: 0.08, blue: 0.10) // #121419
    public static let cardBackground = Color(red: 0.11, green: 0.12, blue: 0.15) // #1C1F26
    public static let surfaceElevated = Color(red: 0.14, green: 0.16, blue: 0.20) // #242933
    public static let pillBackground = Color.black.opacity(0.45)
    public static let textPrimary = Color.white
    public static let textSecondary = Color(white: 0.65)
    public static let textMuted = Color(white: 0.45)
    public static let accent = Color(red: 0.52, green: 0.38, blue: 0.98) // #8561FA
    public static let accentGradient = LinearGradient(
        colors: [Color(red: 0.52, green: 0.38, blue: 0.98), Color(red: 0.36, green: 0.25, blue: 0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Dimensions & Radius
    public static let cardCornerRadius: CGFloat = 16
    public static let pillCornerRadius: CGFloat = 24
    public static let modalCornerRadius: CGFloat = 20

    // MARK: - Shadow & Glassmorphism
    public static let pillShadow = Color.black.opacity(0.3)
}
