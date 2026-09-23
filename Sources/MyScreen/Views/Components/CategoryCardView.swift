import SwiftUI

public struct CategoryCardView: View {
    public let title: String
    public let sampleImageURL: URL?
    public let iconName: String
    public let onSelect: () -> Void

    @State private var isHovered = false

    public init(title: String, sampleImageURL: URL?, iconName: String, onSelect: @escaping () -> Void) {
        self.title = title
        self.sampleImageURL = sampleImageURL
        self.iconName = iconName
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .bottomLeading) {
                // Background image or gradient
                if let url = sampleImageURL {
                    RemoteImageView(url: url)
                        .frame(height: 130)
                        .frame(maxWidth: .infinity)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [Color.purple.opacity(0.4), Color.black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 130)
                }

                // Dark vignette overlay
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Category Title Text
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
                    Spacer()
                }
                .padding(16)
            }
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isHovered ? Color.white.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: isHovered ? Color.white.opacity(0.15) : Color.black.opacity(0.2), radius: 8, x: 0, y: 3)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.18), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
