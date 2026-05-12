//
//  Color+MiSana.swift
//  MiSana — Design tokens
//
//  Drop into your project. All colors come from the canonical design system.
//  Light-mode hex values match colors_and_type.css. Dark-mode variants are
//  declared per token via UIColor's dynamic provider so every surface, card,
//  border, and text label adapts automatically.
//

import SwiftUI
import UIKit

extension Color {
    /// MiSana design tokens. Use as `Color.miSana.brand`, `Color.miSana.card`, etc.
    enum miSana {

        // MARK: - Brand
        static let brand        = Color(hex: 0x1169A0)   // Primary brand blue
        static let brandHover   = Color(hex: 0x0E5A8C)
        static let brandSoft    = Color(hex: 0x3A8AC2)
        static let brandFill    = Color(hex: 0x4A99D6)   // Friendlier brand for big buttons / fills

        // MARK: - Surfaces (adaptive)
        /// Soft cream-blue screen background in light; near-black in dark.
        static let screenCream  = dynamic(light: 0xF1F5F8, dark: 0x0B1118)
        /// Alternate pale-blue screen background; near-black in dark.
        static let screenBlue   = dynamic(light: 0xE8EFF6, dark: 0x0E141C)
        /// Card surface: white in light, elevated dark surface in dark.
        static let card         = dynamic(light: 0xFFFFFF, dark: 0x1A2230)
        /// 1px hairline border for cards.
        static let hairline     = dynamic(light: 0xE4E8EE, dark: 0x2A3340)

        // MARK: - Soft tinted card backgrounds (icon chips)
        static let cardSoftBlue  = dynamic(light: 0xEAF2F9, dark: 0x1B2A38)
        static let cardSoftPink  = dynamic(light: 0xFDECEE, dark: 0x352026)
        static let cardSoftMint  = dynamic(light: 0xE6F2EC, dark: 0x1E2E27)
        static let cardSoftSand  = dynamic(light: 0xFBEFD9, dark: 0x33291A)
        static let cardSoftLilac = dynamic(light: 0xE9E5F5, dark: 0x272135)
        static let cardSoftPeach = dynamic(light: 0xFFE7DC, dark: 0x33221A)

        // MARK: - Text (adaptive)
        /// Primary label / number color. Near-black navy in light, near-white in dark.
        static let fg           = dynamic(light: 0x0F1A2B, dark: 0xF2F4F8)
        /// Secondary text (units, captions).
        static let fg2          = dynamic(light: 0x5A6478, dark: 0xA3ADBF)
        /// Tertiary text (menu dots, eyebrow muted).
        static let fg3          = dynamic(light: 0x94A0B4, dark: 0x6E788A)

        // MARK: - Metric accents (icon + sparkline colors — same in both modes)
        static let heart        = Color(hex: 0xE5484D)
        static let oxygen       = Color(hex: 0x3CA5DF)
        static let water        = Color(hex: 0x5BB6E3)
        static let active       = Color(hex: 0xF2A93F)   // Steps / movement
        static let sleep        = Color(hex: 0x3CA5DF)   // Sleep / rest (cool blue)
        static let sleepSpark   = Color(hex: 0x7DC5EA)
        static let energy       = Color(hex: 0xE5704A)   // Active energy / kcal
        static let energySpark  = Color(hex: 0xF0997A)
        static let oxygenSpark  = Color(hex: 0x7CC4A6)

        // MARK: - Helper
        private static func dynamic(light: UInt32, dark: UInt32) -> Color {
            Color(UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(hex: dark)
                    : UIColor(hex: light)
            })
        }
    }
}

// MARK: - Hex initializers
extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >>  8) & 0xFF) / 255
        let b = Double( hex        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

extension UIColor {
    fileprivate convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >>  8) & 0xFF) / 255
        let b = CGFloat( hex        & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
