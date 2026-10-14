// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Steffan Douglas Haskins
// Package the selected artwork without redrawing or cropping it.
// Run from the repository root: swift scripts/generate_icon.swift
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let master = root.appendingPathComponent("Design/AppIcon-master.png")
guard let source = CGImageSourceCreateWithURL(master as CFURL, nil),
      let artwork = CGImageSourceCreateImageAtIndex(source, 0, nil),
      artwork.width == artwork.height else {
    throw NSError(domain: "KairosIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected the square, owner-selected Design/AppIcon-master.png"])
}
let size = 1024
guard let bitmap = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: size * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    throw NSError(domain: "KairosIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot create an opaque RGB drawing context"])
}
bitmap.interpolationQuality = .high
bitmap.draw(artwork, in: CGRect(x: 0, y: 0, width: size, height: size))

let directory = root.appendingPathComponent("Kairos/Assets.xcassets/AppIcon.appiconset")
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
print("Packaged the selected gold bridge as an opaque 1024 x 1024 sRGB icon")
