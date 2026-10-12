// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Steffan Douglas Haskins
import SwiftUI
import UIKit

// The same identity in both appearances. Gold is an accent, never body copy
// on ivory. Explicit row surfaces prevent dark mode reverting to system gray.
enum KairosStyle {
    static let aegean = Color(red: 10 / 255, green: 37 / 255, blue: 64 / 255)
    static let ivory = Color(red: 248 / 255, green: 244 / 255, blue: 239 / 255)
    static let background = adaptive(light: 0xF8F4EF, dark: 0x071B2D)
    static let surface = adaptive(light: 0xFFFDF8, dark: 0x102C44)
    static let ink = adaptive(light: 0x0A2540, dark: 0xF8F4EF)
    static let secondaryInk = adaptive(light: 0x3D3D3D, dark: 0xC8C1B6)
    static let bronze = adaptive(light: 0xB08D57, dark: 0xD4B27B)
    static let authorInk = adaptive(light: 0x735324, dark: 0xD4B27B)
    static let outline = adaptive(light: 0x6A7E90, dark: 0x6F899F)

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((value >> 16) & 0xFF) / 255,
                           green: CGFloat((value >> 8) & 0xFF) / 255,
                           blue: CGFloat(value & 0xFF) / 255, alpha: 1)
        })
    }
}
