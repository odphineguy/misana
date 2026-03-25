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
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @Environment(\.colorScheme) private var colorScheme
    @State private var showStepsDetail = false
    @State private var showHeartDetail = false
    @State private var showSleepDetail = false
    @State private var showAboutSources = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Logo + Settings row
                    HStack {
                        Image(colorScheme == .dark ? "MiSanaLogoDark" : "MiSanaLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 44)
                        Spacer()
                        settingsMenu
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Welcome Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedLanguage == .spanish ? "Hola!" : "Hello!")
                            .font(.system(size: 28, weight: .bold))
                        Text(selectedLanguage == .spanish ?
                             "Bienvenido a tu santuario de salud." :
                             "Welcome back to your health sanctuary.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Health Dashboard
                    if healthKitService.isAvailable {
                        healthDashboardCard
                            .padding(.horizontal)
                    }

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedLanguage == .spanish ? "Acciones" : "Quick Actions")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            NavigationLink(destination: MedicationView(selectedLanguage: selectedLanguage)) {
                                ActionCard(
                                    icon: "camera.viewfinder",
                                    iconColor: .brand,
                                    title: selectedLanguage == .spanish ? "Escanear Receta" : "Scan Prescription",
                                    subtitle: selectedLanguage == .spanish ?
                                        "Escanea la etiqueta para agregarla automaticamente." :
                                        "Scan your medication label to add it automatically."
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: SymptomCheckerView(selectedLanguage: selectedLanguage)) {
                                ActionCard(
                                    icon: "stethoscope",
                                    iconColor: .red,
                                    title: selectedLanguage == .spanish ? "Revisar Sintomas" : "Check Symptoms",
                                    subtitle: selectedLanguage == .spanish ?
                                        "Revisa lo que sientes con tu asistente de IA." :
                                        "Check what you are feeling with your AI assistant."
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: AppointmentPrepView(selectedLanguage: selectedLanguage)) {
                                ActionCard(
                                    icon: "list.clipboard.fill",
                                    iconColor: .brand,
                                    title: selectedLanguage == .spanish ? "Preparar Cita" : "Prepare Appointment",
                                    subtitle: selectedLanguage == .spanish ?
                                        "Organiza tus preguntas para tu proxima cita." :
                                        "Organize your questions for your next doctor visit."
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 20)
                }
            }
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
                Link(destination: URL(string: "mailto:misana.app.privacy@gmail.com")!) {
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
        }
    }

    // MARK: - Health Dashboard Card

    @ViewBuilder
    private var healthDashboardCard: some View {
        if healthKitService.isAuthorized {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Steps card
                    Button { showStepsDetail = true } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "figure.walk")
                                    .font(.caption)
                                    .foregroundStyle(.brand)
                                Text(selectedLanguage == .spanish ? "PASOS" : "STEPS")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            Text("\(healthKitService.summary.todaySteps)")
                                .font(.system(size: 28, weight: .bold))
                            Text(selectedLanguage == .spanish ? "pasos diarios" : "daily steps")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.brand.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 12) {
                        // Heart Rate card
                        Button { showHeartDetail = true } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.red)
                                    Text(selectedLanguage == .spanish ? "CORAZON" : "HEART RATE")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    Text(healthKitService.summary.lastHeartRate > 0 ?
                                         "\(healthKitService.summary.lastHeartRate)" : "--")
                                        .font(.system(size: 20, weight: .bold))
                                    Text("BPM")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        // Sleep card
                        Button { showSleepDetail = true } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "moon.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.indigo)
                                    Text(selectedLanguage == .spanish ? "SUENO" : "SLEEP")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    if healthKitService.summary.lastNightSleep > 0 {
                                        let hours = Int(healthKitService.summary.lastNightSleep)
                                        let mins = Int((healthKitService.summary.lastNightSleep - Double(hours)) * 60)
                                        Text("\(hours)h \(mins)m")
                                            .font(.system(size: 20, weight: .bold))
                                    } else {
                                        Text("--")
                                            .font(.system(size: 20, weight: .bold))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(Color.indigo.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .sheet(isPresented: $showStepsDetail) {
                StepsDetailView(selectedLanguage: selectedLanguage, summary: healthKitService.summary)
            }
            .sheet(isPresented: $showHeartDetail) {
                HeartRateDetailView(selectedLanguage: selectedLanguage, summary: healthKitService.summary)
            }
            .sheet(isPresented: $showSleepDetail) {
                SleepDetailView(selectedLanguage: selectedLanguage, summary: healthKitService.summary)
            }
        } else {
            // Permission not yet granted
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .font(.title2)
                        .foregroundStyle(.brand)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedLanguage == .spanish ? "Conectar datos de salud" : "Connect health data")
                            .font(.headline)
                        Text(selectedLanguage == .spanish ?
                             "Permite acceso a Apple Salud para recomendaciones personalizadas. Tus datos nunca salen del dispositivo." :
                             "Allow Apple Health access for personalized recommendations. Your data never leaves the device.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Button {
                    Task { await healthKitService.requestAuthorization() }
                } label: {
                    Text(selectedLanguage == .spanish ? "Conectar Apple Salud" : "Connect Apple Health")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.brand.opacity(0.05))
            )
        }
    }
}

// MARK: - Action Card (Stitch-inspired)

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
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))

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
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
