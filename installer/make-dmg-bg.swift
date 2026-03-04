#!/usr/bin/env swift
// installer/make-dmg-bg.swift
// Generates installer/dmg-background.png (1400 × 920 px @ 2x for 700 × 460 pt window)
// Run from project root: swift installer/make-dmg-bg.swift

import Foundation
import AppKit
import CoreGraphics
import CoreText

// MARK: - Constants

// Canvas size in pixels (2× retina backing for a 700 × 460 pt Finder window)
let W: CGFloat = 1400
let H: CGFloat = 920

// Icon zone centres in PNG pixels (2× Finder point coords)
// App icon at Finder pt (175, 230) → PNG (350, 460)
// Applications at Finder pt (525, 230) → PNG (1050, 460)
// Note: PNG Y-axis is top-down; CG Y-axis is bottom-up.
// Finder Y=230 → CG Y = H - 230*2 = 920 - 460 = 460 (symmetric, at exact midpoint)
let appCenterCG  = CGPoint(x: 350,  y: 460)  // CG coords (bottom-up)
let appsCenterCG = CGPoint(x: 1050, y: 460)  // CG coords (bottom-up)

// Colors
let cs = CGColorSpaceCreateDeviceRGB()

func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> CGColor {
    CGColor(colorSpace: cs, components: [r, g, b, a])!
}

let colorBgTop   = rgba(0.051, 0.051, 0.071, 1.0)  // #0D0D12
let colorBgBot   = rgba(0.024, 0.024, 0.031, 1.0)  // #060608
let colorDot     = rgba(1, 1, 1, 0.030)
let colorGlowL   = rgba(1, 1, 1, 0.060)
let colorGlowR   = rgba(1, 1, 1, 0.040)
let colorRing    = rgba(1, 1, 1, 0.000)             // placeholder; set per-ring below
let colorArrow   = rgba(1, 1, 1, 0.550)
let colorLabel   = rgba(1, 1, 1, 0.300)
let colorTitle   = rgba(1, 1, 1, 0.850)
let colorTagline = rgba(1, 1, 1, 0.280)
let colorDivider = rgba(1, 1, 1, 0.060)
let colorTransp  = rgba(0, 0, 0, 0.000)

// MARK: - Context

func makeContext() -> CGContext {
    CGContext(
        data: nil,
        width: Int(W),
        height: Int(H),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: cs,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
}

// MARK: - Layer 1: Dark gradient background

func drawBackground(_ ctx: CGContext) {
    // Linear gradient top→bottom in screen space.
    // CG Y is bottom-up, so "top of screen" = CG Y = H, "bottom" = CG Y = 0.
    let colors = [colorBgTop, colorBgBot] as CFArray
    let locs: [CGFloat] = [0, 1]
    let grad = CGGradient(colorsSpace: cs, colors: colors, locations: locs)!
    ctx.drawLinearGradient(
        grad,
        start: CGPoint(x: W / 2, y: H),  // top of screen
        end:   CGPoint(x: W / 2, y: 0),  // bottom of screen
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
}

// MARK: - Layer 2: Subtle dot grid

func drawGrid(_ ctx: CGContext) {
    let spacing: CGFloat = 40
    let r: CGFloat = 1.2
    ctx.setFillColor(colorDot)
    var x: CGFloat = spacing
    while x < W {
        var y: CGFloat = spacing
        while y < H {
            ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            y += spacing
        }
        x += spacing
    }
}

// MARK: - Layer 3 & 4: Radial glows under icon zones

func drawRadialGlow(_ ctx: CGContext, centre: CGPoint, radius: CGFloat, color: CGColor) {
    let grad = CGGradient(
        colorsSpace: cs,
        colors: [color, colorTransp] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawRadialGradient(
        grad,
        startCenter: centre, startRadius: 0,
        endCenter:   centre, endRadius:   radius,
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
}

// MARK: - Layer 5: Pulse rings (concentric circles around app icon)

func drawPulseRings(_ ctx: CGContext) {
    let radii:  [CGFloat] = [90, 135, 180, 225, 270]
    let alphas: [CGFloat] = [0.13, 0.10, 0.07, 0.05, 0.03]
    for (i, r) in radii.enumerated() {
        ctx.setStrokeColor(rgba(1, 1, 1, alphas[i]))
        ctx.setLineWidth(1.5)
        ctx.addEllipse(in: CGRect(
            x: appCenterCG.x - r, y: appCenterCG.y - r,
            width: r * 2, height: r * 2
        ))
        ctx.strokePath()
    }
}

// MARK: - Layer 6: Whisper arcs (echoing the icon.svg wave lines)

func drawWhisperArcs(_ ctx: CGContext) {
    // Three short S-curve arcs radiating to the right of the app icon,
    // mirroring the sinusoidal wave in icon.svg.
    let offsets: [CGFloat] = [0, 26, 52]
    let alphas:  [CGFloat] = [0.18, 0.11, 0.06]
    let lineWidths: [CGFloat] = [2.5, 2.0, 1.5]

    for (i, offset) in offsets.enumerated() {
        let startX = appCenterCG.x + 68 + offset
        let startY = appCenterCG.y + 48   // top of arc in CG (higher CG Y = higher on screen)
        let endY   = appCenterCG.y - 48   // bottom of arc in CG

        // S-curve: control points create the characteristic whisper-wave shape
        let cp1 = CGPoint(x: startX + 24, y: startY - 24)
        let cp2 = CGPoint(x: startX - 24, y: endY   + 24)

        ctx.setStrokeColor(rgba(1, 1, 1, alphas[i]))
        ctx.setLineWidth(lineWidths[i])
        ctx.setLineCap(.round)
        ctx.move(to: CGPoint(x: startX, y: startY))
        ctx.addCurve(to: CGPoint(x: startX, y: endY), control1: cp1, control2: cp2)
        ctx.strokePath()
    }
}

// MARK: - Layer 7: Center vertical divider

func drawDivider(_ ctx: CGContext) {
    let x = W / 2
    let margin: CGFloat = 80
    ctx.setStrokeColor(colorDivider)
    ctx.setLineWidth(1)
    ctx.move(to:    CGPoint(x: x, y: margin))
    ctx.addLine(to: CGPoint(x: x, y: H - margin))
    ctx.strokePath()
}

// MARK: - Layer 8: Curved arrow from app → Applications

func drawCurvedArrow(_ ctx: CGContext) {
    // Arrow runs just below the icon midline on screen.
    // CG coords: Y = H - screenY. Icons are at screen Y=460 (exactly mid).
    // Arrow runs at screen Y ≈ 480 → CG Y ≈ 440. Starts 95px right of app icon, ends 95px left of apps.
    let startPt = CGPoint(x: appCenterCG.x + 95, y: appCenterCG.y - 20)   // just below+right of app
    let endPt   = CGPoint(x: appsCenterCG.x - 95, y: appsCenterCG.y - 20)  // just below+left of apps

    // Arc bows downward on screen → higher screen Y → lower CG Y.
    // Control point at screen Y ≈ 560 → CG Y ≈ 360.
    let ctrlPt = CGPoint(x: W / 2, y: appCenterCG.y - 100)

    ctx.setStrokeColor(colorArrow)
    ctx.setLineWidth(3.0)
    ctx.setLineCap(.round)
    ctx.move(to: startPt)
    ctx.addQuadCurve(to: endPt, control: ctrlPt)
    ctx.strokePath()

    // Arrowhead at endPt: tangent direction from ctrlPt → endPt
    let dx = endPt.x - ctrlPt.x
    let dy = endPt.y - ctrlPt.y
    let len = sqrt(dx * dx + dy * dy)
    let nx = dx / len
    let ny = dy / len
    let px =  ny   // perpendicular
    let py = -nx

    let arrowLen:   CGFloat = 20
    let arrowWidth: CGFloat = 11

    let base  = CGPoint(x: endPt.x - nx * arrowLen, y: endPt.y - ny * arrowLen)
    let left  = CGPoint(x: base.x + px * arrowWidth, y: base.y + py * arrowWidth)
    let right = CGPoint(x: base.x - px * arrowWidth, y: base.y - py * arrowWidth)

    ctx.setFillColor(colorArrow)
    ctx.move(to: endPt)
    ctx.addLine(to: left)
    ctx.addLine(to: right)
    ctx.closePath()
    ctx.fillPath()
}

// MARK: - Layer 9: "drag to install" label

func drawDragLabel(_ ctx: CGContext) {
    // Positioned below the arrow arc, centred horizontally.
    // Arrow bows to screen Y≈560; label just below at screen Y≈600 → CG Y≈320.
    // Use uppercase + wide tracking for a small-caps visual effect.
    let text = "DRAG TO INSTALL"
    let fontSize: CGFloat = 18

    let font = NSFont.systemFont(ofSize: fontSize, weight: .light)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(cgColor: colorLabel)!,
        .kern: CGFloat(5.0),
    ]
    let attrStr = NSAttributedString(string: text, attributes: attrs)
    let line = CTLineCreateWithAttributedString(attrStr)
    let bounds = CTLineGetBoundsWithOptions(line, [])

    let labelX = (W - bounds.width) / 2
    let labelY: CGFloat = 320  // CG Y (≈ screen Y 600)

    ctx.saveGState()
    ctx.textMatrix = .identity
    ctx.textPosition = CGPoint(x: labelX, y: labelY)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

// MARK: - Layer 10: "Commandment" title

func drawTitle(_ ctx: CGContext) {
    let text = "Commandment"
    let fontSize: CGFloat = 36

    let font = NSFont.systemFont(ofSize: fontSize, weight: .thin)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(cgColor: colorTitle)!,
        .kern: CGFloat(6),
    ]
    let attrStr = NSAttributedString(string: text, attributes: attrs)
    let line = CTLineCreateWithAttributedString(attrStr)
    let bounds = CTLineGetBoundsWithOptions(line, [])

    // Baseline at screen Y ≈ 52 → CG Y ≈ H - 52 - cap-height ≈ 842
    let titleX = (W - bounds.width) / 2
    let titleY: CGFloat = H - 96  // CG Y baseline

    ctx.saveGState()
    ctx.textMatrix = .identity
    ctx.textPosition = CGPoint(x: titleX, y: titleY)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

// MARK: - Layer 11: Tagline

func drawTagline(_ ctx: CGContext) {
    let text = "Dictate, transcribe, command"
    let fontSize: CGFloat = 18

    let font = NSFont.systemFont(ofSize: fontSize, weight: .ultraLight)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(cgColor: colorTagline)!,
        .kern: CGFloat(2),
    ]
    let attrStr = NSAttributedString(string: text, attributes: attrs)
    let line = CTLineCreateWithAttributedString(attrStr)
    let bounds = CTLineGetBoundsWithOptions(line, [])

    let tagX = (W - bounds.width) / 2
    let tagY: CGFloat = H - 148  // CG Y baseline (≈ screen Y 148)

    ctx.saveGState()
    ctx.textMatrix = .identity
    ctx.textPosition = CGPoint(x: tagX, y: tagY)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

// MARK: - Main

let ctx = makeContext()

// Draw layers back-to-front
drawBackground(ctx)
drawGrid(ctx)
drawRadialGlow(ctx, centre: appCenterCG,  radius: 220, color: colorGlowL)
drawRadialGlow(ctx, centre: appsCenterCG, radius: 180, color: colorGlowR)
drawPulseRings(ctx)
drawWhisperArcs(ctx)
drawDivider(ctx)
drawCurvedArrow(ctx)
drawDragLabel(ctx)
drawTitle(ctx)
drawTagline(ctx)

// Write PNG
guard let cgImage = ctx.makeImage() else {
    fputs("error: could not create CGImage\n", stderr)
    exit(1)
}
let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
bitmapRep.size = NSSize(width: W / 2, height: H / 2) // 144 DPI — marks image as @2x retina
guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
    fputs("error: could not encode PNG\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("installer/dmg-background.png")
do {
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try pngData.write(to: outputURL)
    print("✓ dmg-background.png written → \(outputURL.path)")
    print("  Size: \(Int(W))×\(Int(H)) px (2× retina for 700×460 pt window)")
} catch {
    fputs("error writing file: \(error)\n", stderr)
    exit(1)
}
