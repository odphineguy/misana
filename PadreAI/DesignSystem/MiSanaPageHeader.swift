//
//  MiSanaPageHeader.swift
//  MiSana — Reusable page header (white title card on blue gradient)
//
//  Used at the top of every primary tab to give a consistent look:
//      VStack {
//          MiSanaPageHeader(title: "Prepara tu cita",
//                           subtitle: "Organiza lo que sientes...",
//                           illustration: "hero_my_visit")
//          // page content
//      }
//      .miSanaBlueHeaderBackground()
//

import SwiftUI

struct MiSanaPageHeader: View {
    let title: String
    let subtitle: String
    var illustration: String? = nil

    var body: some View {
        Group {
            if let illustration {
                illustratedCard(illustration)
            } else {
                plainCard
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.miSana.hairline, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        .padding(.horizontal)
    }

    // MARK: - Variants

    private var plainCard: some View {
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
    }

    private func illustratedCard(_ name: String) -> some View {
        // The illustration PNG has a fixed light sky-blue background that does not adapt to
        // dark mode, so the overlay text must use fixed dark colors in both schemes.
        let illustrationTitleColor = Color(red: 0.06, green: 0.16, blue: 0.36)
        let illustrationSubtitleColor = Color(red: 0.28, green: 0.36, blue: 0.52)

        return ZStack(alignment: .leading) {
            Image(name)
                .resizable()
                .aspectRatio(1916.0 / 821.0, contentMode: .fill)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(illustrationTitleColor)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(illustrationSubtitleColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .containerRelativeFrame(.horizontal, alignment: .leading) { width, _ in
                width * 0.5
            }
        }
    }
}

// MARK: - Background modifier

extension View {
    /// Layers a blue gradient at the top with the screen color below.
    /// Apply to the content container (e.g. a ScrollView) of any primary tab.
    func miSanaBlueHeaderBackground() -> some View {
        self.background(MiSanaHeaderBackground())
    }
}

private struct MiSanaHeaderBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack(alignment: .top) {
            Color.miSana.screenCream.ignoresSafeArea()
            LinearGradient(
                colors: scheme == .dark
                    ? [
                        Color.brand.opacity(0.55),
                        Color.brand.opacity(0.28),
                        Color.brand.opacity(0.0)
                      ]
                    : [
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
    }
}
