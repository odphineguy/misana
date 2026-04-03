//
//  HealthDetailViews.swift
//  MiSana
//
//  Created by Abe Perez on 3/20/26.
//

import SwiftUI

// MARK: - Shared Components

struct WeeklyBarChart: View {
    let samples: [DailySample]
    let color: Color
    let selectedLanguage: AppLanguage

    var body: some View {
        let maxVal = samples.map(\.value).max() ?? 1
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(samples) { sample in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: max(8, CGFloat(sample.value / maxVal) * 140))
                        .shadow(color: color.opacity(0.25), radius: 4, y: 3)
                    Text(dayAbbrev(sample.date))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 160)
    }

    private func dayAbbrev(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        df.locale = Locale(identifier: selectedLanguage == .spanish ? "es" : "en")
        return String(df.string(from: date).prefix(1)).uppercased()
    }
}

struct InsightCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var progress: Double? = nil
    var progressColor: Color = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            if let progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(uiColor: .systemGray5))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(progressColor.gradient)
                            .frame(width: geo.size.width * min(progress, 1.0), height: 6)
                    }
                }
                .frame(height: 6)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 140)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.08), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: iconColor.opacity(0.10), radius: 8, y: 4)
    }
}

struct HighlightRow: View {
    let icon: String
    let iconBgColor: Color
    let title: String
    let subtitle: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(
                        colors: [iconBgColor, iconBgColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: iconBgColor.opacity(0.3), radius: 4, y: 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(value)
                .font(.headline)
                .foregroundStyle(valueColor)
        }
        .padding(14)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [iconBgColor.opacity(0.05), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
}

// MARK: - Sleep Detail View

struct SleepDetailView: View {
    let selectedLanguage: AppLanguage
    let summary: HealthSummary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero: Avg Sleep
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedLanguage == .spanish ?
                             "Tiempo promedio dormido" :
                             "Avg. time asleep")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        let avg = summary.avgSleep
                        let hours = Int(avg)
                        let mins = Int((avg - Double(hours)) * 60)
                        Text("\(hours)h \(mins)min")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.indigo)

                        if !summary.sleepHours.isEmpty {
                            WeeklyBarChart(
                                samples: summary.sleepHours,
                                color: .indigo,
                                selectedLanguage: selectedLanguage
                            )
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [.indigo.opacity(0.08), .clear, .indigo.opacity(0.04)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .indigo.opacity(0.12), radius: 10, y: 5)

                    // Bento: Quality + Deep Sleep
                    HStack(spacing: 12) {
                        InsightCard(
                            icon: "star.fill",
                            iconColor: .brand,
                            title: selectedLanguage == .spanish ? "Calidad de sueno" : "Sleep Quality",
                            value: "\(Int(summary.sleepQuality))%",
                            progress: summary.sleepQuality / 100,
                            progressColor: .brand
                        )

                        let avgDeep = summary.deepSleep.isEmpty ? 0 :
                            summary.deepSleep.map(\.value).reduce(0, +) / Double(summary.deepSleep.count)
                        let dH = Int(avgDeep)
                        let dM = Int((avgDeep - Double(dH)) * 60)
                        InsightCard(
                            icon: "waveform.path",
                            iconColor: .green,
                            title: selectedLanguage == .spanish ? "Sueno profundo" : "Deep Sleep",
                            value: "\(dH)h \(dM)m"
                        )
                    }

                    // Highlights
                    VStack(alignment: .leading, spacing: 10) {
                        Text(selectedLanguage == .spanish ? "Resumen" : "Highlights")
                            .font(.headline)

                        let avgInBed = summary.timeInBed.isEmpty ? 0 :
                            summary.timeInBed.map(\.value).reduce(0, +) / Double(summary.timeInBed.count)
                        let bH = Int(avgInBed)
                        let bM = Int((avgInBed - Double(bH)) * 60)
                        HighlightRow(
                            icon: "bed.double.fill",
                            iconBgColor: .brand,
                            title: selectedLanguage == .spanish ? "Tiempo en cama" : "Time in Bed",
                            subtitle: selectedLanguage == .spanish ? "Promedio semanal" : "Weekly average",
                            value: "\(bH)h \(bM)m"
                        )

                        let deficit = summary.sleepDeficit
                        let deficitAbs = abs(deficit)
                        let defH = Int(deficitAbs)
                        let defM = Int((deficitAbs - Double(defH)) * 60)
                        let sign = deficit < 0 ? "-" : "+"
                        HighlightRow(
                            icon: "exclamationmark.triangle.fill",
                            iconBgColor: deficit < 0 ? .red : .green,
                            title: selectedLanguage == .spanish ? "Deficit de sueno" : "Sleep Deficit",
                            subtitle: selectedLanguage == .spanish ? "Ultimos 7 dias" : "Last 7 days",
                            value: "\(sign)\(defH)h \(defM)m",
                            valueColor: deficit < 0 ? .red : .green
                        )

                        if summary.lastRestingHR > 0 {
                            HighlightRow(
                                icon: "heart.fill",
                                iconBgColor: .red,
                                title: selectedLanguage == .spanish ? "Ritmo cardiaco en reposo" : "Resting Heart Rate",
                                subtitle: selectedLanguage == .spanish ? "Durante el sueno" : "During sleep",
                                value: "\(summary.lastRestingHR) BPM"
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(selectedLanguage == .spanish ? "Sueno" : "Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selectedLanguage == .spanish ? "Cerrar" : "Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Heart Rate Detail View

struct HeartRateDetailView: View {
    let selectedLanguage: AppLanguage
    let summary: HealthSummary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero: Avg HR
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedLanguage == .spanish ?
                             "Ritmo cardiaco promedio" :
                             "Avg. heart rate")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        let avg = summary.heartRate.isEmpty ? 0 :
                            Int(summary.heartRate.map(\.value).reduce(0, +) / Double(summary.heartRate.count))
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(avg)")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(.red)
                            Text("BPM")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }

                        if !summary.heartRate.isEmpty {
                            WeeklyBarChart(
                                samples: summary.heartRate,
                                color: .red,
                                selectedLanguage: selectedLanguage
                            )
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [.red.opacity(0.08), .clear, .red.opacity(0.04)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .red.opacity(0.12), radius: 10, y: 5)

                    // Bento: Resting HR + Range
                    HStack(spacing: 12) {
                        let restAvg = summary.restingHeartRate.isEmpty ? 0 :
                            Int(summary.restingHeartRate.map(\.value).reduce(0, +) / Double(summary.restingHeartRate.count))
                        InsightCard(
                            icon: "heart.circle.fill",
                            iconColor: .red,
                            title: selectedLanguage == .spanish ? "En reposo" : "Resting",
                            value: restAvg > 0 ? "\(restAvg) BPM" : "--"
                        )

                        let minHR = summary.heartRateMin.map(\.value).min().map { Int($0) }
                        let maxHR = summary.heartRateMax.map(\.value).max().map { Int($0) }
                        InsightCard(
                            icon: "arrow.up.arrow.down",
                            iconColor: .orange,
                            title: selectedLanguage == .spanish ? "Rango semanal" : "Weekly Range",
                            value: (minHR != nil && maxHR != nil) ? "\(minHR!)-\(maxHR!) BPM" : "--"
                        )
                    }

                    // Highlights
                    VStack(alignment: .leading, spacing: 10) {
                        Text(selectedLanguage == .spanish ? "Resumen" : "Highlights")
                            .font(.headline)

                        HighlightRow(
                            icon: "heart.fill",
                            iconBgColor: .red,
                            title: selectedLanguage == .spanish ? "Ultimo registro" : "Latest Reading",
                            subtitle: selectedLanguage == .spanish ? "Ritmo cardiaco" : "Heart rate",
                            value: summary.lastHeartRate > 0 ? "\(summary.lastHeartRate) BPM" : "--"
                        )

                        if let minVal = summary.heartRateMin.last {
                            HighlightRow(
                                icon: "arrow.down.circle.fill",
                                iconBgColor: .brand,
                                title: selectedLanguage == .spanish ? "Minimo hoy" : "Today's Low",
                                subtitle: selectedLanguage == .spanish ? "Ritmo mas bajo" : "Lowest rate",
                                value: "\(Int(minVal.value)) BPM",
                                valueColor: .brand
                            )
                        }

                        if let maxVal = summary.heartRateMax.last {
                            HighlightRow(
                                icon: "arrow.up.circle.fill",
                                iconBgColor: .orange,
                                title: selectedLanguage == .spanish ? "Maximo hoy" : "Today's High",
                                subtitle: selectedLanguage == .spanish ? "Ritmo mas alto" : "Highest rate",
                                value: "\(Int(maxVal.value)) BPM",
                                valueColor: .orange
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(selectedLanguage == .spanish ? "Ritmo Cardiaco" : "Heart Rate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selectedLanguage == .spanish ? "Cerrar" : "Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Steps Detail View

struct StepsDetailView: View {
    let selectedLanguage: AppLanguage
    let summary: HealthSummary
    @Environment(\.dismiss) private var dismiss

    private var avgDistKm: Double {
        guard !summary.distance.isEmpty else { return 0 }
        let total = summary.distance.map(\.value).reduce(0, +)
        return (total / Double(summary.distance.count)) / 1000
    }

    private var avgFlights: Int {
        guard !summary.flightsClimbed.isEmpty else { return 0 }
        return Int(summary.flightsClimbed.map(\.value).reduce(0, +) / Double(summary.flightsClimbed.count))
    }

    private var avgEnergy: Int {
        guard !summary.activeEnergy.isEmpty else { return 0 }
        return Int(summary.activeEnergy.map(\.value).reduce(0, +) / Double(summary.activeEnergy.count))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    stepsHeroCard
                    stepsBentoCards
                    stepsHighlights
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(selectedLanguage == .spanish ? "Pasos" : "Steps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selectedLanguage == .spanish ? "Cerrar" : "Close") { dismiss() }
                }
            }
        }
    }

    private var stepsHeroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedLanguage == .spanish ? "Pasos promedio diarios" : "Avg. daily steps")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(summary.avgSteps)")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.brand)
            if !summary.steps.isEmpty {
                WeeklyBarChart(samples: summary.steps, color: .brand, selectedLanguage: selectedLanguage)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.brand.opacity(0.08), .clear, Color.brand.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.brand.opacity(0.12), radius: 10, y: 5)
    }

    private var stepsBentoCards: some View {
        HStack(spacing: 12) {
            InsightCard(
                icon: "figure.walk",
                iconColor: .brand,
                title: selectedLanguage == .spanish ? "Distancia diaria" : "Daily Distance",
                value: String(format: "%.1f km", avgDistKm)
            )
            InsightCard(
                icon: "arrow.up.right",
                iconColor: .green,
                title: selectedLanguage == .spanish ? "Pisos subidos" : "Flights Climbed",
                value: "\(avgFlights)"
            )
        }
    }

    private var stepsHighlights: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedLanguage == .spanish ? "Resumen" : "Highlights")
                .font(.headline)

            HighlightRow(
                icon: "flame.fill",
                iconBgColor: .orange,
                title: selectedLanguage == .spanish ? "Energia activa" : "Active Energy",
                subtitle: selectedLanguage == .spanish ? "Promedio diario" : "Daily average",
                value: "\(avgEnergy) kcal"
            )

            HighlightRow(
                icon: "shoe.fill",
                iconBgColor: .brand,
                title: selectedLanguage == .spanish ? "Pasos hoy" : "Today's Steps",
                subtitle: selectedLanguage == .spanish ? "Conteo actual" : "Current count",
                value: "\(summary.todaySteps)"
            )

            bestDayRow
        }
    }

    @ViewBuilder
    private var bestDayRow: some View {
        if let bestDay = summary.steps.max(by: { $0.value < $1.value }) {
            let df = DateFormatter()
            let _ = df.dateFormat = "EEEE"
            let _ = df.locale = Locale(identifier: selectedLanguage == .spanish ? "es" : "en")
            HighlightRow(
                icon: "trophy.fill",
                iconBgColor: .yellow,
                title: selectedLanguage == .spanish ? "Mejor dia" : "Best Day",
                subtitle: df.string(from: bestDay.date).capitalized,
                value: "\(Int(bestDay.value))",
                valueColor: .green
            )
        }
    }
}
