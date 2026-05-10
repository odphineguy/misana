//
//  HomeHealthSection.swift
//  MiSana — Drop-in 2x2 grid of premium health cards
//
//  Replaces the existing HealthTile section in HomeView when Apple Health
//  is connected. Wire it to your existing HealthKitManager:
//
//      if healthKit.isAuthorized {
//          HomeHealthSection(
//              heartRate: healthKit.heartRate,
//              heartRateHistory: healthKit.heartRateHistory,
//              sleepHours: healthKit.lastNightSleepHours,
//              sleepHistory: healthKit.sleepWeek,
//              steps: healthKit.todaySteps,
//              stepsHistory: healthKit.stepsWeek,
//              activeEnergy: healthKit.activeEnergyKcal,
//              activeEnergyHistory: healthKit.activeEnergyWeek,
//              language: appLang
//          )
//      }
//

import SwiftUI

struct HomeHealthSection: View {
    // Live values
    let heartRate: Int
    let sleepHours: Double            // e.g. 6.2
    let steps: Int
    let activeEnergy: Int             // kcal

    // Histories (sparklines) — last 7 points
    let heartRateHistory: [Double]
    let sleepHistory: [Double]
    let stepsHistory: [Double]
    let activeEnergyHistory: [Double]

    // Locale-aware labels
    var language: String = "es"       // "es" | "en"

    // Tap handlers (open detail sheets in HomeView)
    var onHeartTap:  (() -> Void)? = nil
    var onSleepTap:  (() -> Void)? = nil
    var onStepsTap:  (() -> Void)? = nil
    var onEnergyTap: (() -> Void)? = nil

    private func t(_ es: String, _ en: String) -> String {
        language == "es" ? es : en
    }

    private var sleepValueText: String {
        let h = Int(sleepHours)
        let m = Int((sleepHours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }

    private var sleepRichText: Text {
        let h = Int(sleepHours)
        let m = Int((sleepHours - Double(h)) * 60)
        let bigDigit  = Font.system(size: 24, weight: .bold)
        let smallUnit = Font.system(size: 12, weight: .medium)
        return Text("\(h)").font(bigDigit).foregroundColor(.miSana.fg).tracking(-0.6)
             + Text("h ").font(smallUnit).foregroundColor(.miSana.fg2)
             + Text("\(m)").font(bigDigit).foregroundColor(.miSana.fg).tracking(-0.6)
             + Text("m").font(smallUnit).foregroundColor(.miSana.fg2)
    }

    var body: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

        LazyVGrid(columns: columns, spacing: 12) {
            // Heart rate
            MetricCard(
                icon: "heart.fill",
                iconColor: .miSana.heart,
                iconBackground: .miSana.cardSoftPink,
                label: t("Ritmo cardíaco", "Heart rate"),
                value: "\(heartRate)",
                unit: "BPM",
                history: heartRateHistory,
                sparkColor: .miSana.heart,
                sparkStyle: .line,
                isLive: true,
                onTap: onHeartTap
            )

            // Sleep
            MetricCard(
                icon: "moon.fill",
                iconColor: .miSana.sleep,
                iconBackground: .miSana.cardSoftBlue,
                label: t("Sueño", "Sleep"),
                value: sleepValueText,
                unit: t("anoche", "last night"),
                valueText: sleepRichText,
                history: sleepHistory,
                sparkColor: .miSana.sleepSpark,
                sparkStyle: .bars,
                isLive: false,
                onTap: onSleepTap
            )

            // Steps
            MetricCard(
                icon: "figure.walk",
                iconColor: .miSana.active,
                iconBackground: .miSana.cardSoftSand,
                label: t("Pasos", "Steps"),
                value: steps.formatted(),
                unit: nil,
                history: stepsHistory,
                sparkColor: .miSana.active,
                sparkStyle: .line,
                isLive: true,
                onTap: onStepsTap
            )

            // Active energy
            MetricCard(
                icon: "flame.fill",
                iconColor: .miSana.energy,
                iconBackground: .miSana.cardSoftPeach,
                label: t("Energía activa", "Active energy"),
                value: "\(activeEnergy)",
                unit: "kcal",
                history: activeEnergyHistory,
                sparkColor: .miSana.energySpark,
                sparkStyle: .bars,
                isLive: true,
                onTap: onEnergyTap
            )
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.miSana.screenCream.ignoresSafeArea()
        HomeHealthSection(
            heartRate: 72,
            sleepHours: 6.2,
            steps: 8089,
            activeEnergy: 412,
            heartRateHistory: [68, 72, 74, 70, 76, 72, 75, 73],
            sleepHistory: [5.8, 6.4, 7.1, 6.0, 6.5, 5.9, 6.8, 6.2],
            stepsHistory: [6420, 7100, 5300, 9800, 8089, 4200, 7500],
            activeEnergyHistory: [320, 380, 420, 290, 440, 380, 412],
            language: "es"
        )
        .padding(16)
    }
}
