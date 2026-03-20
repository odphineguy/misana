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
    @State private var userName: String = ""
    @State private var showHealthDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Header
                    VStack(spacing: 8) {
                        Text(greeting)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(tagline)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Health Dashboard Card
                    if healthKitService.isAvailable {
                        healthDashboardCard
                            .padding(.horizontal)
                    }

                    // Quick Actions
                    VStack(spacing: 16) {
                        NavigationLink(destination: MedicationView(selectedLanguage: selectedLanguage)) {
                            QuickActionCard(
                                icon: "camera.fill",
                                title: selectedLanguage == .spanish ? "Escanear Receta" : "Scan Prescription",
                                subtitle: selectedLanguage == .spanish ? "Lee etiquetas de medicinas" : "Read medication labels",
                                color: .blue
                            )
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink(destination: SymptomCheckerView(selectedLanguage: selectedLanguage)) {
                            QuickActionCard(
                                icon: "stethoscope",
                                title: selectedLanguage == .spanish ? "Revisar Síntomas" : "Check Symptoms",
                                subtitle: selectedLanguage == .spanish ? "¿Qué estás sintiendo?" : "What are you feeling?",
                                color: .red
                            )
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink(destination: AppointmentPrepView(selectedLanguage: selectedLanguage)) {
                            QuickActionCard(
                                icon: "list.clipboard.fill",
                                title: selectedLanguage == .spanish ? "Preparar Cita" : "Prepare Appointment",
                                subtitle: selectedLanguage == .spanish ? "Preguntas para el doctor" : "Questions for the doctor",
                                color: .green
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle(selectedLanguage == .spanish ? "MiSana" : "MiSana")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        // Language
                        Section(selectedLanguage == .spanish ? "Idioma" : "Language") {
                            Button {
                                selectedLanguage = .spanish
                            } label: {
                                HStack {
                                    Text("Español")
                                    if selectedLanguage == .spanish {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button {
                                selectedLanguage = .english
                            } label: {
                                HStack {
                                    Text("English")
                                    if selectedLanguage == .english {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }

                        // Theme
                        Section(selectedLanguage == .spanish ? "Tema" : "Theme") {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Button {
                                    appTheme = theme
                                } label: {
                                    HStack {
                                        Label(theme.label(for: selectedLanguage), systemImage: theme.icon)
                                        if appTheme == theme {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                    }
                }
            }
        }
    }
    
    // MARK: - Health Dashboard Card

    @ViewBuilder
    private var healthDashboardCard: some View {
        if healthKitService.isAuthorized {
            Button {
                showHealthDetail = true
            } label: {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)
                        Text(selectedLanguage == .spanish ? "Tu Salud Hoy" : "Your Health Today")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 20) {
                        healthStat(
                            icon: "figure.walk",
                            value: "\(healthKitService.summary.todaySteps)",
                            label: selectedLanguage == .spanish ? "Pasos" : "Steps",
                            color: .green
                        )
                        healthStat(
                            icon: "heart.fill",
                            value: healthKitService.summary.lastHeartRate > 0 ? "\(healthKitService.summary.lastHeartRate)" : "--",
                            label: "BPM",
                            color: .red
                        )
                        healthStat(
                            icon: "moon.fill",
                            value: healthKitService.summary.lastNightSleep > 0 ? String(format: "%.1f", healthKitService.summary.lastNightSleep) : "--",
                            label: selectedLanguage == .spanish ? "Horas" : "Hours",
                            color: .indigo
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.primary.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showHealthDetail) {
                HealthDetailView(selectedLanguage: selectedLanguage, summary: healthKitService.summary)
            }
        } else {
            // Permission not yet granted
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .font(.title2)
                        .foregroundStyle(.pink)
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
                        .background(Color.pink)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.pink.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private func healthStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var greeting: String {
        selectedLanguage == .spanish ? "Hola! 👋" : "Hello! 👋"
    }

    private var tagline: String {
        selectedLanguage == .spanish ?
            "Tu doctor de bolsillo" :
            "Your pocket doctor"
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
                        color: .green,
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

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    HomeView(selectedLanguage: .constant(.spanish))
}
