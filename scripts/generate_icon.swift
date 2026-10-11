// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Steffan Douglas Haskins
// Original Kairos beta artwork. Run with: swift scripts/generate_icon.swift
import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
guard let bitmap = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: size * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    throw NSError(domain: "KairosIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot create an opaque RGB drawing context"])
}
let context = NSGraphicsContext(cgContext: bitmap, flipped: false)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high
let background = NSColor(srgbRed: 0.12, green: 0.28, blue: 0.23, alpha: 1)
background.setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

// A bridge with an open centre: a place to return, with one remembered moment.
let arch = NSBezierPath()
arch.move(to: NSPoint(x: 246, y: 264))
arch.line(to: NSPoint(x: 246, y: 482))
arch.curve(to: NSPoint(x: 778, y: 482),
           controlPoint1: NSPoint(x: 246, y: 848),
           controlPoint2: NSPoint(x: 778, y: 848))
arch.line(to: NSPoint(x: 778, y: 264))
arch.lineWidth = 66
arch.lineCapStyle = .round
NSColor(srgbRed: 0.95, green: 0.93, blue: 0.85, alpha: 1).setStroke()
arch.stroke()

let returnPath = NSBezierPath()
returnPath.move(to: NSPoint(x: 354, y: 294))
returnPath.curve(to: NSPoint(x: 670, y: 294),
                 controlPoint1: NSPoint(x: 408, y: 216),
                 controlPoint2: NSPoint(x: 616, y: 216))
returnPath.lineWidth = 42
returnPath.lineCapStyle = .round
returnPath.stroke()
NSColor(srgbRed: 0.87, green: 0.69, blue: 0.37, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 446, y: 418, width: 132, height: 132)).fill()
NSGraphicsContext.restoreGraphicsState()

let directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Kairos/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
guard let image = bitmap.makeImage(),
      let destination = CGImageDestinationCreateWithURL(directory.appendingPathComponent("AppIcon.png") as CFURL,
          UTType.png.identifier as CFString, 1, nil) else {
    throw NSError(domain: "KairosIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot create the PNG destination"])
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    throw NSError(domain: "KairosIcon", code: 3, userInfo: [NSLocalizedDescriptionKey: "Cannot write the PNG icon"])
}
print("Generated original opaque 1024 x 1024 Kairos beta icon")
