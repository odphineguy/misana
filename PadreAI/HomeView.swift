//
//  HomeView.swift
//  MiSana
//
//  Created by Abe Perez on 3/11/26.
//

import SwiftUI
import HealthKit

struct HomeView: View {
    @Binding var selectedLanguage: AppLanguage
    @EnvironmentObject private var healthKitService: HealthKitService
    @EnvironmentObject private var modelService: ModelCoordinator
    @AppStorage("appTheme") private var appTheme: AppTheme = .light
    @Environment(\.colorScheme) private var colorScheme
    @State private var showStepsDetail = false
    @State private var showHeartDetail = false
    @State private var showSleepDetail = false
    @State private var showEnergyDetail = false
    @State private var showAboutSources = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showModelDownloadSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Logo + Settings row
                    ZStack {
                        Image("MiSanaLogoDark")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 44)
                        HStack {
                            Spacer()
                            settingsMenu
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    MiSanaPageHeader(
                        title: selectedLanguage == .spanish ? "Hola!" : "Hello!",
                        subtitle: selectedLanguage == .spanish ?
                            "Tu puente de salud familiar." :
                            "Your family health bridge.",
                        illustration: "hero_home"
                    )

                    // Health Dashboard
                    if healthKitService.isAvailable {
                        healthDashboardCard
                            .padding(.horizontal)
                    }

                    // Quick Actions (2x2 grid)
                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedLanguage == .spanish ? "¿Qué necesitas?" : "What do you need?")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            NavigationLink(destination: SymptomLogView(selectedLanguage: selectedLanguage)) {
                                QuickActionTile(
                                    icon: "list.clipboard.fill",
                                    iconColor: .brand,
                                    title: selectedLanguage == .spanish ? "Registrar\nsíntomas" : "Log\nsymptoms",
                                    selectedLanguage: selectedLanguage
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: MyVisitView(selectedLanguage: selectedLanguage)) {
                                QuickActionTile(
                                    icon: "calendar.badge.clock",
                                    iconColor: .brand,
                                    title: selectedLanguage == .spanish ? "Preparar\nmi cita" : "Prepare\nmy visit",
                                    selectedLanguage: selectedLanguage
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: MedicationView(selectedLanguage: selectedLanguage)) {
                                QuickActionTile(
                                    icon: "camera.viewfinder",
                                    iconColor: .brand,
                                    title: selectedLanguage == .spanish ? "Escanear\nmedicina" : "Scan\nmedication",
                                    selectedLanguage: selectedLanguage
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: LookUpView(selectedLanguage: selectedLanguage)) {
                                QuickActionTile(
                                    icon: "text.magnifyingglass",
                                    iconColor: .brand,
                                    title: selectedLanguage == .spanish ? "Buscar\ncondición" : "Look up\ncondition",
                                    selectedLanguage: selectedLanguage
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 20)
                }
            }
            .scrollContentBackground(.hidden)
            .miSanaBlueHeaderBackground()
            .navigationBarHidden(true)
            .sheet(isPresented: $showAboutSources) {
                AboutHealthSourcesView(selectedLanguage: selectedLanguage)
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView(selectedLanguage: selectedLanguage)
            }
            .sheet(isPresented: $showTermsOfService) {
                TermsOfServiceView(selectedLanguage: selectedLanguage)
            }
            .sheet(isPresented: $showModelDownloadSheet) {
                ModelDownloadView(
                    modelService: modelService,
                    selectedLanguage: selectedLanguage
                )
            }
        }
    }

    // MARK: - Settings Menu

    private var settingsMenu: some View {
        Menu {
            Section(selectedLanguage == .spanish ? "Idioma" : "Language") {
                Button {
                    selectedLanguage = .spanish
                } label: {
                    HStack {
                        Text("Espanol")
                        if selectedLanguage == .spanish { Image(systemName: "checkmark") }
                    }
                }
                Button {
                    selectedLanguage = .english
                } label: {
                    HStack {
                        Text("English")
                        if selectedLanguage == .english { Image(systemName: "checkmark") }
                    }
                }
            }

            Section(selectedLanguage == .spanish ? "Modelo de IA" : "AI Model") {
                ForEach(ModelCoordinator.ModelEngine.allCases) { engine in
                    Button {
                        if engine == .qwen && !modelService.isModelDownloaded {
                            modelService.activeEngine = engine
                            showModelDownloadSheet = true
                        } else {
                            modelService.activeEngine = engine
                        }
                    } label: {
                        HStack {
                            Text(engine.rawValue)
                            if engine == .foundation && !modelService.isFoundationAvailable {
                                Text(selectedLanguage == .spanish ? "(No disponible)" : "(Not available)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            } else if engine == .qwen && !modelService.isModelDownloaded {
                                Text(selectedLanguage == .spanish ? "(Requiere descarga)" : "(Needs download)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if modelService.activeEngine == engine {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .disabled(engine == .foundation && !modelService.isFoundationAvailable)
                }
            }

            Section(selectedLanguage == .spanish ? "Informacion" : "Information") {
                Button {
                    showAboutSources = true
                } label: {
                    Label(selectedLanguage == .spanish ?
                          "Sobre la informacion de salud" :
                          "About health information",
                          systemImage: "book.closed")
                }
            }

            Section(selectedLanguage == .spanish ? "Legal" : "Legal") {
                Button {
                    showPrivacyPolicy = true
                } label: {
                    Label(selectedLanguage == .spanish ?
                          "Política de privacidad" :
                          "Privacy Policy",
                          systemImage: "lock.shield")
                }
                Button {
                    showTermsOfService = true
                } label: {
                    Label(selectedLanguage == .spanish ?
                          "Términos de servicio" :
                          "Terms of Service",
                          systemImage: "doc.text")
                }
                Link(destination: URL(string: "mailto:support@misana.app")!) {
                    Label(selectedLanguage == .spanish ?
                          "Contactar soporte" :
                          "Contact Support",
                          systemImage: "envelope")
                }
            }

            Section(selectedLanguage == .spanish ? "Tema" : "Theme") {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Button {
                        appTheme = theme
                    } label: {
                        HStack {
                            Label(theme.label(for: selectedLanguage), systemImage: theme.icon)
                            if appTheme == theme { Image(systemName: "checkmark") }
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
        }
    }

    // MARK: - Health Dashboard Card

    @ViewBuilder
    private var healthDashboardCard: some View {
        if healthKitService.isAuthorized {
            HomeHealthSection(
                heartRate:           healthKitService.summary.lastHeartRate,
                sleepHours:          healthKitService.summary.lastNightSleep,
                steps:               healthKitService.summary.todaySteps,
                activeEnergy:        Int(healthKitService.summary.activeEnergy.last?.value ?? 0),
                heartRateHistory:    healthKitService.summary.heartRate.map(\.value),
                sleepHistory:        healthKitService.summary.sleepHours.map(\.value),
                stepsHistory:        healthKitService.summary.steps.map(\.value),
                activeEnergyHistory: healthKitService.summary.activeEnergy.map(\.value),
                language:            selectedLanguage.rawValue,
                onHeartTap:  { showHeartDetail = true },
                onSleepTap:  { showSleepDetail = true },
                onStepsTap:  { showStepsDetail = true },
                onEnergyTap: { showEnergyDetail = true }
            )
            .sheet(isPresented: $showStepsDetail) {
                StepsDetailView(selectedLanguage: selectedLanguage, summary: healthKitService.summary)
            }
            .sheet(isPresented: $showHeartDetail) {
                HeartRateDetailView(selectedLanguage: selectedLanguage, summary: healthKitService.summary)
            }
            .sheet(isPresented: $showSleepDetail) {
                SleepDetailView(selectedLanguage: selectedLanguage, summary: healthKitService.summary)
            }
            .sheet(isPresented: $showEnergyDetail) {
                ActiveEnergyDetailView(selectedLanguage: selectedLanguage, summary: healthKitService.summary)
            }
        } else {
            // Permission not yet granted — crisp white card, matches the welcome card
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.title2)
                        .foregroundColor(.brand)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedLanguage == .spanish ? "Conectar datos de salud" : "Connect health data")
                            .font(.headline)
                            .foregroundColor(.miSana.fg)
                        Text(selectedLanguage == .spanish ?
                             "Permite acceso a Apple Salud para recomendaciones personalizadas. Tus datos nunca salen del dispositivo." :
                             "Allow Apple Health access for personalized recommendations. Your data never leaves the device.")
                            .font(.caption)
                            .foregroundColor(.miSana.fg2)
                    }
                    Spacer()
                }

                Button {
                    Task { await healthKitService.requestAuthorization() }
                } label: {
                    Text(selectedLanguage == .spanish ? "Conectar Apple Salud" : "Connect Apple Health")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.brand, Color.brand.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.brand.opacity(0.30), radius: 6, y: 3)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20).fill(Color.miSana.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.miSana.hairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        }
    }
}

// MARK: - Quick Action Tile (2x2 grid)

struct QuickActionTile: View {
    let icon: String
    let iconColor: Color   // retained for API compatibility; not used in inverted style
    let title: String
    let selectedLanguage: AppLanguage

    var body: some View {
        VStack(spacing: 12) {
            // White icon chip with brand-blue glyph
            Image(systemName: icon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.brand)
                .frame(width: 56, height: 56)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.10), radius: 4, y: 2)

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.brand, Color.brand.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.brand.opacity(0.30), radius: 10, y: 5)
    }
}

// MARK: - Action Card (used by sub-views)

struct ActionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    LinearGradient(
                        colors: [iconColor, iconColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: iconColor.opacity(0.4), radius: 6, y: 3)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.15), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.10), radius: 10, y: 5)
    }
}

// MARK: - Health Detail View (7-day trends)

struct HealthDetailView: View {
    let selectedLanguage: AppLanguage
    let summary: HealthSummary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if !summary.steps.isEmpty {
                    trendSection(
                        title: selectedLanguage == .spanish ? "Pasos" : "Steps",
                        icon: "figure.walk",
                        color: .brand,
                        samples: summary.steps,
                        format: { "\(Int($0))" }
                    )
                }

                if !summary.heartRate.isEmpty {
                    trendSection(
                        title: selectedLanguage == .spanish ? "Ritmo Cardiaco (BPM)" : "Heart Rate (BPM)",
                        icon: "heart.fill",
                        color: .red,
                        samples: summary.heartRate,
                        format: { "\(Int($0))" }
                    )
                }

                if !summary.sleepHours.isEmpty {
                    trendSection(
                        title: selectedLanguage == .spanish ? "Horas de Sueno" : "Sleep Hours",
                        icon: "moon.fill",
                        color: .indigo,
                        samples: summary.sleepHours,
                        format: { String(format: "%.1fh", $0) }
                    )
                }

                if !summary.activeEnergy.isEmpty {
                    trendSection(
                        title: selectedLanguage == .spanish ? "Energia Activa (kcal)" : "Active Energy (kcal)",
                        icon: "flame.fill",
                        color: .orange,
                        samples: summary.activeEnergy,
                        format: { "\(Int($0))" }
                    )
                }

                if !summary.systolic.isEmpty {
                    Section {
                        ForEach(Array(zip(summary.systolic, summary.diastolic)), id: \.0.id) { sys, dia in
                            HStack {
                                Text(dayLabel(sys.date))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, alignment: .leading)
                                Spacer()
                                Text("\(Int(sys.value))/\(Int(dia.value)) mmHg")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    } header: {
                        Label(selectedLanguage == .spanish ? "Presion Arterial" : "Blood Pressure", systemImage: "waveform.path.ecg")
                    }
                }

                if !summary.bloodOxygen.isEmpty {
                    trendSection(
                        title: selectedLanguage == .spanish ? "Oxigeno en Sangre (%)" : "Blood Oxygen (%)",
                        icon: "lungs.fill",
                        color: .cyan,
                        samples: summary.bloodOxygen,
                        format: { "\(Int($0 * 100))%" }
                    )
                }

                if let mass = summary.bodyMass {
                    Section {
                        LabeledContent(
                            selectedLanguage == .spanish ? "Peso" : "Weight",
                            value: String(format: "%.1f kg", mass)
                        )
                    } header: {
                        Label(selectedLanguage == .spanish ? "Cuerpo" : "Body", systemImage: "figure")
                    }
                }
            }
            .navigationTitle(selectedLanguage == .spanish ? "Tu Salud - 7 Dias" : "Your Health - 7 Days")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selectedLanguage == .spanish ? "Cerrar" : "Close") { dismiss() }
                }
            }
        }
    }

    private func trendSection(title: String, icon: String, color: Color, samples: [DailySample], format: @escaping (Double) -> String) -> some View {
        Section {
            ForEach(samples) { sample in
                HStack {
                    Text(dayLabel(sample.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .leading)
                    Spacer()
                    Text(format(sample.value))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        } header: {
            Label(title, systemImage: icon)
                .foregroundStyle(color)
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        df.locale = Locale(identifier: selectedLanguage == .spanish ? "es" : "en")
        return df.string(from: date)
    }
}

#Preview {
    HomeView(selectedLanguage: .constant(.spanish))
}
