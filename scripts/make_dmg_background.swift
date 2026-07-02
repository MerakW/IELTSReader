import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let outputPath = CommandLine.arguments.dropFirst().first ?? "/tmp/ieltsreader-dmg-background.png"
let width = 720
let height = 440

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

guard let context = CGContext(
    data: nil,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: width * 4,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Could not create drawing context")
}

context.setFillColor(color(246, 247, 249))
context.fill(CGRect(x: 0, y: 0, width: width, height: height))

func fillRect(_ rect: CGRect, _ fill: CGColor) {
    context.setFillColor(fill)
    context.fill(rect)
}

func strokeRect(_ rect: CGRect, _ stroke: CGColor, width lineWidth: CGFloat = 1) {
    context.setStrokeColor(stroke)
    context.setLineWidth(lineWidth)
    context.stroke(rect)
}

func drawText(_ text: String, x: CGFloat, yFromTop: CGFloat, size: CGFloat, weight: CTFontUIFontType, color textColor: CGColor) {
    let font = CTFontCreateUIFontForLanguage(weight, size, nil) ?? CTFontCreateWithName("Helvetica" as CFString, size, nil)
    let attributes: [CFString: Any] = [
        kCTFontAttributeName: font,
        kCTForegroundColorAttributeName: textColor
    ]
    let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(nil, text as CFString, attributes as CFDictionary))
    context.textPosition = CGPoint(x: x, y: CGFloat(height) - yFromTop - size)
    CTLineDraw(line, context)
}

drawText("IELTSReader", x: 52, yFromTop: 44, size: 32, weight: .system, color: color(31, 41, 55))
drawText("Drag IELTSReader into Applications to install.", x: 52, yFromTop: 84, size: 16, weight: .application, color: color(82, 96, 113))

let cardFill = color(238, 242, 247)
let border = color(214, 221, 230)
fillRect(CGRect(x: 115, y: 172, width: 150, height: 150), cardFill)
strokeRect(CGRect(x: 115, y: 172, width: 150, height: 150), border, width: 1)
fillRect(CGRect(x: 455, y: 172, width: 150, height: 150), cardFill)
strokeRect(CGRect(x: 455, y: 172, width: 150, height: 150), border, width: 1)

context.setFillColor(color(190, 200, 214))
context.fill(CGRect(x: 300, y: 247, width: 120, height: 5))
context.beginPath()
context.move(to: CGPoint(x: 430, y: 249.5))
context.addLine(to: CGPoint(x: 404, y: 266))
context.addLine(to: CGPoint(x: 404, y: 233))
context.closePath()
context.fillPath()

fillRect(CGRect(x: 0, y: 140, width: width, height: 1), color(214, 221, 230, 0.65))

guard let image = context.makeImage() else {
    fatalError("Could not create background image")
}

let data = NSMutableData()
guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("Could not create image destination")
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    fatalError("Could not write PNG data")
}
try data.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
