//
//  AppLanguage.swift
//  MiSana
//
//  Created by Abe Perez on 3/11/26.
//

import Foundation
import SwiftUI

// MARK: - Brand Colors

extension Color {
    static let brand = Color(red: 0x11/255, green: 0x69/255, blue: 0xA0/255) // #1169A0
}

extension ShapeStyle where Self == Color {
    static var brand: Color { .brand }
}

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    func label(for language: AppLanguage) -> String {
        switch self {
        case .system: return language == .spanish ? "Sistema" : "System"
        case .light: return language == .spanish ? "Claro" : "Light"
        case .dark: return language == .spanish ? "Oscuro" : "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

enum AppLanguage: String, Codable {
    case spanish = "es"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "English"
        }
    }
    
    var locale: Locale {
        Locale(identifier: rawValue)
    }
}
