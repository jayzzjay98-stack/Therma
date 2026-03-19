import AppKit
import Foundation

let outputURL = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppBundle/AppIcon.png")
let size = CGSize(width: 1024, height: 1024)

let image = NSImage(size: size)
image.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else {
    fputs("Unable to create graphics context.\n", stderr)
    exit(1)
}

// MARK: - Helpers

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        calibratedRed:   CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8)  & 0xFF) / 255,
        blue:  CGFloat( hex        & 0xFF) / 255,
        alpha: alpha
    )
}

func fillRoundedRect(_ rect: CGRect, radius: CGFloat, colors: [NSColor], angle: CGFloat = -45) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    path.addClip()
    let gradient = NSGradient(colors: colors) ?? NSGradient(starting: colors[0], ending: colors.last!)!
    gradient.draw(in: path, angle: angle)
    NSBezierPath.defaultWindingRule = .nonZero
    NSBezierPath(rect: .infinite).setClip()
}

func fillOval(_ rect: CGRect, colors: [NSColor], angle: CGFloat = 90) {
    let path = NSBezierPath(ovalIn: rect)
    path.addClip()
    let gradient = NSGradient(colors: colors) ?? NSGradient(starting: colors[0], ending: colors.last!)!
    gradient.draw(in: path, angle: angle)
    NSBezierPath(rect: .infinite).setClip()
}

func strokePath(_ path: NSBezierPath, color: NSColor, width: CGFloat) {
    color.setStroke()
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.stroke()
}

func fillPath(_ path: NSBezierPath, color: NSColor) {
    color.setFill()
    path.fill()
}

let canvas = CGRect(origin: .zero, size: size)

// ── BACKGROUND: deep midnight gradient ───────────────────────────────────────
fillRoundedRect(canvas, radius: 240,
    colors: [color(0x0D0D22), color(0x14083A), color(0x0A1828)],
    angle: 135)

// Soft blue radial glow — top-right
NSGraphicsContext.current?.cgContext.saveGState()
let topRightBlob = NSBezierPath(ovalIn: CGRect(x: 480, y: 550, width: 700, height: 700))
topRightBlob.addClip()
let blueGlow = NSGradient(colors: [color(0x3070FF, alpha: 0.20), color(0x3070FF, alpha: 0)])!
blueGlow.draw(from: NSPoint(x: 820, y: 1050), to: NSPoint(x: 820, y: 550), options: [])
NSGraphicsContext.current?.cgContext.restoreGState()

// Soft orange glow — bottom-left
NSGraphicsContext.current?.cgContext.saveGState()
let bottomLeftBlob = NSBezierPath(ovalIn: CGRect(x: -200, y: -200, width: 620, height: 620))
bottomLeftBlob.addClip()
let orangeGlow = NSGradient(colors: [color(0xFF6030, alpha: 0.16), color(0xFF6030, alpha: 0)])!
orangeGlow.draw(from: NSPoint(x: 100, y: 100), to: NSPoint(x: 500, y: 500), options: [])
NSGraphicsContext.current?.cgContext.restoreGState()

// ── THERMOMETER ───────────────────────────────────────────────────────────────
// Dimensions
let tubeX: CGFloat    = 432
let tubeY: CGFloat    = 318
let tubeW: CGFloat    = 160
let tubeH: CGFloat    = 430
let tubeR: CGFloat    = 80   // fully rounded top
let bulbD: CGFloat    = 300
let bulbX: CGFloat    = (1024 - bulbD) / 2
let bulbY: CGFloat    = tubeY - bulbD * 0.38

// --- Bulb outer glow ---
NSGraphicsContext.current?.cgContext.saveGState()
let outerGlowRect = CGRect(x: bulbX - 60, y: bulbY - 60, width: bulbD + 120, height: bulbD + 120)
NSBezierPath(ovalIn: outerGlowRect).addClip()
let bulbGlow = NSGradient(colors: [color(0xFF7040, alpha: 0.35), color(0xFF7040, alpha: 0)])!
bulbGlow.draw(in: NSBezierPath(ovalIn: outerGlowRect), angle: 90)
NSGraphicsContext.current?.cgContext.restoreGState()

// --- Tube shell (glass-dark) ---
let tubePath = NSBezierPath(roundedRect: CGRect(x: tubeX, y: tubeY, width: tubeW, height: tubeH),
                             xRadius: tubeR, yRadius: tubeR)
NSGraphicsContext.current?.cgContext.saveGState()
tubePath.addClip()
let tubeGradient = NSGradient(colors: [color(0x1E2B55, alpha: 0.90), color(0x0F1832, alpha: 0.90)])!
tubeGradient.draw(in: tubePath, angle: 135)
NSGraphicsContext.current?.cgContext.restoreGState()

// Tube glass border
strokePath(tubePath, color: color(0x7090FF, alpha: 0.40), width: 4)

// --- Bulb shell (glass-dark) ---
let bulbRect = CGRect(x: bulbX, y: bulbY, width: bulbD, height: bulbD)
NSGraphicsContext.current?.cgContext.saveGState()
NSBezierPath(ovalIn: bulbRect).addClip()
let bulbBase = NSGradient(colors: [color(0x2A1820), color(0x1A0E14)])!
bulbBase.draw(in: NSBezierPath(ovalIn: bulbRect), angle: 90)
NSGraphicsContext.current?.cgContext.restoreGState()

NSBezierPath(ovalIn: bulbRect).lineWidth = 4
color(0xFF7040, alpha: 0.50).setStroke()
NSBezierPath(ovalIn: bulbRect).stroke()

// --- Mercury fill in tube ---
let mercuryW: CGFloat = tubeW - 44
let mercuryX: CGFloat = tubeX + 22
let mercuryH: CGFloat = tubeH * 0.62
let mercuryY: CGFloat = tubeY + 22
let mercuryPath = NSBezierPath(roundedRect: CGRect(x: mercuryX, y: mercuryY, width: mercuryW, height: mercuryH),
                                xRadius: mercuryW / 2, yRadius: mercuryW / 2)
NSGraphicsContext.current?.cgContext.saveGState()
mercuryPath.addClip()
let mercuryGradient = NSGradient(colors: [color(0xFF5020), color(0xFF9040), color(0xFFCC00), color(0x00CCFF)])!
mercuryGradient.draw(in: mercuryPath, angle: 90)
NSGraphicsContext.current?.cgContext.restoreGState()

// --- Mercury fill in bulb ---
NSGraphicsContext.current?.cgContext.saveGState()
let bulbFillRect = bulbRect.insetBy(dx: 24, dy: 24)
NSBezierPath(ovalIn: bulbFillRect).addClip()
let bulbFill = NSGradient(colors: [color(0xFF8040), color(0xFF4020)])!
bulbFill.draw(in: NSBezierPath(ovalIn: bulbFillRect), angle: 90)
NSGraphicsContext.current?.cgContext.restoreGState()

// Bulb inner shine
let shineRect = CGRect(x: bulbX + 52, y: bulbY + bulbD * 0.52, width: 60, height: 40)
NSGraphicsContext.current?.cgContext.saveGState()
NSBezierPath(ovalIn: shineRect).addClip()
let shineGrad = NSGradient(colors: [color(0xFFFFFF, alpha: 0.45), color(0xFFFFFF, alpha: 0)])!
shineGrad.draw(in: NSBezierPath(ovalIn: shineRect), angle: 90)
NSGraphicsContext.current?.cgContext.restoreGState()

// --- Tube inner glass shine ---
let tubeShineRect = CGRect(x: tubeX + 14, y: tubeY + tubeH * 0.25, width: 20, height: tubeH * 0.55)
NSGraphicsContext.current?.cgContext.saveGState()
NSBezierPath(roundedRect: tubeShineRect, xRadius: 10, yRadius: 10).addClip()
let tubeShineGrad = NSGradient(colors: [color(0xFFFFFF, alpha: 0.18), color(0xFFFFFF, alpha: 0)])!
tubeShineGrad.draw(in: NSBezierPath(roundedRect: tubeShineRect, xRadius: 10, yRadius: 10), angle: 90)
NSGraphicsContext.current?.cgContext.restoreGState()

// --- Tick marks on right side of tube ---
let tickColor = color(0x8090CC, alpha: 0.70)
let tickRight = tubeX + tubeW + 18
let tickSpacing = tubeH / 5
for i in 1...4 {
    let y = tubeY + CGFloat(i) * tickSpacing
    let w: CGFloat = i % 2 == 0 ? 30 : 20
    let tick = NSBezierPath()
    tick.move(to: NSPoint(x: tickRight, y: y))
    tick.line(to: NSPoint(x: tickRight + w, y: y))
    strokePath(tick, color: tickColor, width: 3)
}

// --- Temperature dots floating left ---
let dotPositions: [(CGFloat, CGFloat, CGFloat, NSColor)] = [
    (tubeX - 90,  tubeY + tubeH * 0.80, 10, color(0x60CCFF, alpha: 0.90)),
    (tubeX - 60,  tubeY + tubeH * 0.55, 7,  color(0x80DDFF, alpha: 0.70)),
    (tubeX - 110, tubeY + tubeH * 0.35, 8,  color(0xFFAA60, alpha: 0.80)),
    (tubeX - 75,  tubeY + tubeH * 0.15, 6,  color(0xFF7040, alpha: 0.85)),
]
for (x, y, r, c) in dotPositions {
    fillPath(NSBezierPath(ovalIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), color: c)
}

// ── MERCURY GLOW at top of fill ────────────────────────────────────────────
NSGraphicsContext.current?.cgContext.saveGState()
let mercuryTopGlowRect = CGRect(x: mercuryX - 20, y: mercuryY + mercuryH - 30, width: mercuryW + 40, height: 60)
NSBezierPath(ovalIn: mercuryTopGlowRect).addClip()
let mercuryGlow = NSGradient(colors: [color(0x00E5FF, alpha: 0.45), color(0x00E5FF, alpha: 0)])!
mercuryGlow.draw(in: NSBezierPath(ovalIn: mercuryTopGlowRect), angle: 90)
NSGraphicsContext.current?.cgContext.restoreGState()

// ── DEGREE SYMBOL ─────────────────────────────────────────────────────────────
let degreeAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 120, weight: .thin),
    .foregroundColor: color(0xAABBFF, alpha: 0.85)
]
let degreeStr = NSAttributedString(string: "°", attributes: degreeAttrs)
let degreeSize = degreeStr.size()
degreeStr.draw(at: CGPoint(x: tubeX + tubeW + 22, y: tubeY + tubeH - degreeSize.height + 10))

// ── TOP VIGNETTE (soft white highlight) ───────────────────────────────────────
NSGraphicsContext.current?.cgContext.saveGState()
let vigPath = NSBezierPath(roundedRect: canvas.insetBy(dx: 20, dy: 20), xRadius: 220, yRadius: 220)
vigPath.addClip()
let vignette = NSGradient(colors: [color(0xFFFFFF, alpha: 0.06), color(0xFFFFFF, alpha: 0)])!
vignette.draw(in: vigPath, relativeCenterPosition: NSPoint(x: -0.5, y: 0.7))
NSGraphicsContext.current?.cgContext.restoreGState()

// ── FINISH ────────────────────────────────────────────────────────────────────
image.unlockFocus()

guard
    let tiff   = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png    = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Unable to encode PNG.\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try png.write(to: outputURL)
print("Wrote \(outputURL.path)")
