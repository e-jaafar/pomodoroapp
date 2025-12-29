import AppKit

// Créer une icône simple
let sizes: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

let iconsetPath = "/Users/jaafarito/Desktop/taff:ecole/pomodoroapp/AppIcon.iconset"

for (size, filename) in sizes {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    
    // Background circle (tomato red)
    let bgColor = NSColor(red: 0.91, green: 0.30, blue: 0.24, alpha: 1.0)
    bgColor.setFill()
    let bgPath = NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: size, height: size))
    bgPath.fill()
    
    // Tomato emoji
    let emoji = "🍅"
    let fontSize = CGFloat(size) * 0.65
    let font = NSFont.systemFont(ofSize: fontSize)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font
    ]
    let textSize = emoji.size(withAttributes: attributes)
    let textRect = NSRect(
        x: (CGFloat(size) - textSize.width) / 2,
        y: (CGFloat(size) - textSize.height) / 2,
        width: textSize.width,
        height: textSize.height
    )
    emoji.draw(in: textRect, withAttributes: attributes)
    
    image.unlockFocus()
    
    // Save as PNG
    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        let url = URL(fileURLWithPath: "\(iconsetPath)/\(filename)")
        try? pngData.write(to: url)
    }
}

print("Icons created!")
