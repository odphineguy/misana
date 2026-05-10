//
//  Color+MiSana.swift
//  MiSana — Design tokens
//
//  Drop into your project. All colors come from the canonical design system.
//  Hex values match colors_and_type.css.
//

import SwiftUI

extension Color {
    /// MiSana design tokens. Use as `Color.miSana.brand`, `Color.miSana.card`, etc.
    enum miSana {

        // MARK: - Brand
        static let brand        = Color(hex: 0x1169A0)   // Primary brand blue
        static let brandHover   = Color(hex: 0x0E5A8C)
        static let brandSoft    = Color(hex: 0x3A8AC2)
        static let brandFill    = Color(hex: 0x4A99D6)   // Friendlier brand for big buttons / fills

        // MARK: - Surfaces
        /// Soft cream-blue screen background. Cards sit on top of this.
        static let screenCream  = Color(hex: 0xF1F5F8)
        /// Alternate pale-blue screen background (Appointments-style).
        static let screenBlue   = Color(hex: 0xE8EFF6)
        /// Pure white card surface.
        static let card         = Color.white
        /// 1px hairline border for cards.
        static let hairline     = Color(hex: 0xE4E8EE)

        // MARK: - Soft tinted card backgrounds (icon chips)
        static let cardSoftBlue = Color(hex: 0xEAF2F9)
        static let cardSoftPink = Color(hex: 0xFDECEE)
        static let cardSoftMint = Color(hex: 0xE6F2EC)
        static let cardSoftSand = Color(hex: 0xFBEFD9)
        static let cardSoftLilac = Color(hex: 0xE9E5F5)
        static let cardSoftPeach = Color(hex: 0xFFE7DC)

        // MARK: - Text
        /// Primary label / number color. Near-black navy, NOT pure black.
        static let fg           = Color(hex: 0x0F1A2B)
        /// Secondary text (units, captions).
        static let fg2          = Color(hex: 0x5A6478)
        /// Tertiary text (menu dots, eyebrow muted).
        static let fg3          = Color(hex: 0x94A0B4)

        // MARK: - Metric accents (icon + sparkline colors)
        static let heart        = Color(hex: 0xE5484D)
        static let oxygen       = Color(hex: 0x3CA5DF)
        static let water        = Color(hex: 0x5BB6E3)
        static let active       = Color(hex: 0xF2A93F)   // Steps / movement
        static let sleep        = Color(hex: 0x3CA5DF)   // Sleep / rest (cool blue)
        static let sleepSpark   = Color(hex: 0x7DC5EA)
        static let energy       = Color(hex: 0xE5704A)   // Active energy / kcal
        static let energySpark  = Color(hex: 0xF0997A)
        static let oxygenSpark  = Color(hex: 0x7CC4A6)
    }
}

// MARK: - Hex initializer
extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >>  8) & 0xFF) / 255
        let b = Double( hex        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
