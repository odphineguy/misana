//
//  ContentView.swift
//  MiSana
//
//  Created by Abe Perez on 3/11/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("selectedLanguage") private var selectedLanguage: AppLanguage = .spanish
    @State private var selectedTab: Tab = .home
    @AppStorage("hasAcceptedDisclaimer") private var hasAcceptedDisclaimer = false
    @AppStorage("appTheme") private var appTheme: AppTheme = .system

    enum Tab {
        case home
        case medications
        case symptoms
        case appointments
        case chat
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedLanguage: $selectedLanguage)
                .tabItem {
                    Label(selectedLanguage == .spanish ? "Inicio" : "Home",
                          systemImage: "house.fill")
                }
                .tag(Tab.home)

            MedicationView(selectedLanguage: selectedLanguage)
                .tabItem {
                    Label(selectedLanguage == .spanish ? "Medicinas" : "Medications",
                          systemImage: "pill.fill")
                }
                .tag(Tab.medications)

            SymptomCheckerView(selectedLanguage: selectedLanguage)
                .tabItem {
                    Label(selectedLanguage == .spanish ? "Sintomas" : "Symptoms",
                          systemImage: "heart.text.square.fill")
                }
                .tag(Tab.symptoms)

            AppointmentPrepView(selectedLanguage: selectedLanguage)
                .tabItem {
                    Label(selectedLanguage == .spanish ? "Citas" : "Appointments",
                          systemImage: "calendar.badge.clock")
                }
                .tag(Tab.appointments)

            HealthChatView(selectedLanguage: selectedLanguage)
                .tabItem {
                    Label(selectedLanguage == .spanish ? "Pregunta" : "Ask",
                          systemImage: "message.fill")
                }
                .tag(Tab.chat)
        }
        .preferredColorScheme(appTheme.colorScheme)
        .fullScreenCover(isPresented: .constant(!hasAcceptedDisclaimer)) {
            HealthDisclaimerView(
                selectedLanguage: $selectedLanguage,
                onAccept: { hasAcceptedDisclaimer = true }
            )
        }
    }
}

// MARK: - Health Disclaimer View

struct HealthDisclaimerView: View {
    @Binding var selectedLanguage: AppLanguage
    let onAccept: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                // Logo
                Image(colorScheme == .dark ? "MiSanaLogoDark" : "MiSanaLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)

                Text(selectedLanguage == .spanish ?
                     "Tu compañero de salud familiar" :
                     "Your family health companion")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                // Language toggle
                Picker("Language", selection: $selectedLanguage) {
                    Text("Español").tag(AppLanguage.spanish)
                    Text("English").tag(AppLanguage.english)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)

                // Disclaimer box
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.orange)

                    Text(selectedLanguage == .spanish ?
                         "Aviso Importante de Salud" :
                         "Important Health Notice")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(selectedLanguage == .spanish ?
                         """
                         MiSana NO es un doctor ni un profesional médico. Esta aplicación:

                         • No diagnostica enfermedades
                         • No reemplaza la opinión de un médico
                         • No debe usarse en emergencias médicas
                         • Ofrece información educativa general

                         Si tienes una emergencia, llama al 911 o ve a la sala de emergencias más cercana.

                         Siempre consulta con un profesional de salud antes de tomar decisiones médicas.
                         """ :
                         """
                         MiSana is NOT a doctor or medical professional. This application:

                         • Does not diagnose diseases
                         • Does not replace a doctor's opinion
                         • Should not be used in medical emergencies
                         • Provides general educational information

                         If you have an emergency, call 911 or go to the nearest emergency room.

                         Always consult a healthcare professional before making medical decisions.
                         """)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Features
                VStack(alignment: .leading, spacing: 12) {
                    featureRow(icon: "lock.shield.fill", color: .brand,
                               text: selectedLanguage == .spanish ?
                               "100% privado — todo se procesa en tu dispositivo" :
                               "100% private — everything is processed on your device")
                    featureRow(icon: "wifi.slash", color: .green,
                               text: selectedLanguage == .spanish ?
                               "La IA funciona sin internet" :
                               "AI works without internet")
                    featureRow(icon: "building.columns.fill", color: .blue,
                               text: selectedLanguage == .spanish ?
                               "Medicinas consultan bases de datos del NIH (RxNorm/MedlinePlus) — solo se envían nombres de medicamentos, sin datos personales" :
                               "Medications use NIH databases (RxNorm/MedlinePlus) — only drug names are sent, no personal data")
                    featureRow(icon: "dollarsign.circle", color: .orange,
                               text: selectedLanguage == .spanish ?
                               "Sin costo por uso" :
                               "No usage fees")
                }
                .padding()

                // Accept button
                Button {
                    onAccept()
                } label: {
                    Text(selectedLanguage == .spanish ?
                         "Entiendo y Acepto" :
                         "I Understand and Accept")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)

                Spacer().frame(height: 20)
            }
            .padding()
        }
    }

    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    ContentView()
}
