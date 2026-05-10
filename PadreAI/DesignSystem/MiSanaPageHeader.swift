//
//  MiSanaPageHeader.swift
//  MiSana — Reusable page header (white title card on blue gradient)
//
//  Used at the top of every primary tab to give a consistent look:
//      VStack {
//          MiSanaPageHeader(title: "Prepara tu cita",
//                           subtitle: "Organiza lo que sientes...")
//          // page content
//      }
//      .miSanaBlueHeaderBackground()
//

import SwiftUI

struct MiSanaPageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.miSana.fg)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.miSana.fg2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20).fill(Color.miSana.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.miSana.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        .padding(.horizontal)
    }
}

// MARK: - Background modifier

extension View {
    /// Layers a blue gradient at the top with the cream screen color below.
    /// Apply to the content container (e.g. a ScrollView) of any primary tab.
    func miSanaBlueHeaderBackground() -> some View {
        self.background(
            ZStack(alignment: .top) {
                Color.miSana.screenCream.ignoresSafeArea()
                LinearGradient(
                    colors: [
                        Color.brand.opacity(0.95),
                        Color.brand.opacity(0.55),
                        Color.brand.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 320)
                .ignoresSafeArea(edges: .top)
            }
        )
    }
}
