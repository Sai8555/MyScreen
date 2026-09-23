import AppKit
import CoreGraphics

let inputPath = "/tmp/bg_cropped.png"
let outputPath = "Sources/MyScreen/Resources/dmg_background.png"

guard let baseImage = NSImage(contentsOfFile: inputPath) else {
    print("Error loading base image")
    exit(1)
}

let width: CGFloat = 1264
let height: CGFloat = 848

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(width),
    pixelsHigh: Int(height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!

NSGraphicsContext.saveGraphicsState()
let context = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = context

// 1. Draw base image
baseImage.draw(in: NSRect(x: 0, y: 0, width: width, height: height))

// 2. Subtle top vignette
let gradient = NSGradient(colors: [
    NSColor.black.withAlphaComponent(0.4),
    NSColor.clear
])!
gradient.draw(in: NSRect(x: 0, y: height - 150, width: width, height: 150), angle: 270)

// 3. Draw Header Title ("MyScreen" + "v1.0.0" badge beside it)
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.85)
shadow.shadowBlurRadius = 12
shadow.shadowOffset = NSSize(width: 0, height: -3)

let titleString = "MyScreen"
let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 52, weight: .bold),
    .foregroundColor: NSColor.white,
    .shadow: shadow
]
let titleSize = (titleString as NSString).size(withAttributes: titleAttrs)
(titleString as NSString).draw(at: NSPoint(x: 60, y: height - 90), withAttributes: titleAttrs)

// Draw "v1.0.0" pill badge beside "MyScreen"
let badgeX = 60 + titleSize.width + 16
let badgeY = height - 76
let badgeText = "v1.0.0"
let badgeAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 20, weight: .bold),
    .foregroundColor: NSColor.white
]
let badgeTextSize = (badgeText as NSString).size(withAttributes: badgeAttrs)
let badgeRect = NSRect(x: badgeX, y: badgeY - 6, width: badgeTextSize.width + 22, height: badgeTextSize.height + 10)
let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: badgeRect.height / 2, yRadius: badgeRect.height / 2)
NSColor.white.withAlphaComponent(0.22).setFill()
badgePath.fill()
NSColor.white.withAlphaComponent(0.45).setStroke()
badgePath.lineWidth = 1.5
badgePath.stroke()
(badgeText as NSString).draw(at: NSPoint(x: badgeX + 11, y: badgeY - 1), withAttributes: badgeAttrs)

// Subtitle
let subAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 24, weight: .medium),
    .foregroundColor: NSColor.white.withAlphaComponent(0.92),
    .shadow: shadow
]
(NSString("4K Live Video Wallpaper Engine for macOS")).draw(at: NSPoint(x: 60, y: height - 130), withAttributes: subAttrs)

// Center Y = 424 px from bottom (flipped coords)
let centerY: CGFloat = 424
let leftCenterX: CGFloat = 360  // 180 pt
let rightCenterX: CGFloat = 904 // 452 pt
let radius: CGFloat = 126       // 63 pt radius

// Function to draw crystal glass lens circle
func drawGlassCircle(centerX: CGFloat, centerY: CGFloat) {
    let rect = NSRect(x: centerX - radius, y: centerY - radius, width: radius * 2, height: radius * 2)
    let path = NSBezierPath(ovalIn: rect)

    let glassGrad = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.22),
        NSColor.white.withAlphaComponent(0.05)
    ])!
    glassGrad.draw(in: path, angle: 45)

    path.lineWidth = 3.0
    NSColor.white.withAlphaComponent(0.7).setStroke()
    path.stroke()
}

drawGlassCircle(centerX: leftCenterX, centerY: centerY)
drawGlassCircle(centerX: rightCenterX, centerY: centerY)

// Draw center arrow
let arrowPath = NSBezierPath()
let arrowY = centerY
let arrowStartX: CGFloat = 580
let arrowEndX: CGFloat = 684

arrowPath.move(to: NSPoint(x: arrowStartX, y: arrowY))
arrowPath.line(to: NSPoint(x: arrowEndX, y: arrowY))

arrowPath.move(to: NSPoint(x: arrowEndX - 24, y: arrowY + 22))
arrowPath.line(to: NSPoint(x: arrowEndX, y: arrowY))
arrowPath.line(to: NSPoint(x: arrowEndX - 24, y: arrowY - 22))

arrowPath.lineWidth = 6.0
arrowPath.lineCapStyle = .round
arrowPath.lineJoinStyle = .round

NSGraphicsContext.current?.cgContext.setShadow(offset: CGSize(width: 0, height: -2), blur: 12, color: CGColor(red: 1, green: 1, blue: 1, alpha: 0.6))
NSColor.white.withAlphaComponent(0.95).setStroke()
arrowPath.stroke()

NSGraphicsContext.restoreGraphicsState()

// Export to PNG
guard let pngData = rep.representation(using: .png, properties: [:]) else {
    print("Error generating PNG")
    exit(1)
}

try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("Successfully generated clean DMG background with v1.0.0 badge")
