//
//  SymptomCheckerView.swift
//  MiSana
//
//  Created by Abe Perez on 3/11/26.
//

import SwiftUI

struct SymptomCheckerView: View {
    let selectedLanguage: AppLanguage
    @State private var selectedSymptoms: Set<Symptom> = []
    @State private var navigateToChat = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedLanguage == .spanish ?
                                 "Que estas sintiendo?" :
                                 "What are you feeling?")
                                .font(.system(size: 28, weight: .bold))
                            Text(selectedLanguage == .spanish ?
                                 "Selecciona tus sintomas" :
                                 "Select your symptoms")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                        // Search bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField(
                                selectedLanguage == .spanish ?
                                    "Buscar sintomas" :
                                    "Search symptoms",
                                text: $searchText
                            )
                            .font(.subheadline)
                        }
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
                        .padding(.horizontal)

                        // Symptom Categories
                        VStack(spacing: 20) {
                            symptomCategory(
                                title: selectedLanguage == .spanish ? "Comunes" : "Common",
                                icon: "heart.text.square.fill",
                                symptoms: filteredSymptoms(commonSymptoms)
                            )

                            symptomCategory(
                                title: selectedLanguage == .spanish ? "Respiratorios" : "Respiratory",
                                icon: "lungs.fill",
                                symptoms: filteredSymptoms(respiratorySymptoms)
                            )

                            symptomCategory(
                                title: selectedLanguage == .spanish ? "Digestivos" : "Digestive",
                                icon: "cross.case.fill",
                                symptoms: filteredSymptoms(digestiveSymptoms)
                            )
                        }
                        .padding(.horizontal)

                        // Bottom spacer for floating button
                        if !selectedSymptoms.isEmpty {
                            Spacer().frame(height: 80)
                        }
                    }
                    .padding(.top, 8)
                }
                .background(Color(uiColor: .systemGroupedBackground))

                // Floating CTA
                if !selectedSymptoms.isEmpty {
                    VStack(spacing: 6) {
                    Text(selectedLanguage == .spanish ?
                         "Informacion educativa, no un diagnostico." :
                         "Educational information, not a diagnosis.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Button {
                        navigateToChat = true
                    } label: {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.body)
                            Text(selectedLanguage == .spanish ?
                                 "Revisar \(selectedSymptoms.count) sintoma\(selectedSymptoms.count == 1 ? "" : "s") con IA" :
                                 "Review \(selectedSymptoms.count) symptom\(selectedSymptoms.count == 1 ? "" : "s") with AI")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.brand.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .liquidGlass(cornerRadius: 20)
                    .padding(.bottom, 4)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.3), value: selectedSymptoms.isEmpty)
                }
            }
            .navigationTitle(selectedLanguage == .spanish ? "Sintomas" : "Symptoms")
            .navigationDestination(isPresented: $navigateToChat) {
                HealthChatView(
                    selectedLanguage: selectedLanguage,
                    initialContext: buildSymptomContext()
                )
            }
        }
    }

    private func filteredSymptoms(_ symptoms: [Symptom]) -> [Symptom] {
        guard !searchText.isEmpty else { return symptoms }
        return symptoms.filter {
            $0.nameES.localizedCaseInsensitiveContains(searchText) ||
            $0.nameEN.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func symptomCategory(title: String, icon: String, symptoms: [Symptom]) -> some View {
        Group {
            if !symptoms.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .foregroundStyle(.brand)
                        Text(title)
                            .font(.headline)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(symptoms) { symptom in
                            SymptomChip(
                                symptom: symptom,
                                isSelected: selectedSymptoms.contains(symptom),
                                selectedLanguage: selectedLanguage
                            ) {
                                withAnimation(.spring(response: 0.25)) {
                                    if selectedSymptoms.contains(symptom) {
                                        selectedSymptoms.remove(symptom)
                                    } else {
                                        selectedSymptoms.insert(symptom)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Symptom data
    private var commonSymptoms: [Symptom] {
        [
            Symptom(nameES: "Fiebre", nameEN: "Fever", icon: "thermometer"),
            Symptom(nameES: "Dolor de cabeza", nameEN: "Headache", icon: "brain.head.profile"),
            Symptom(nameES: "Fatiga", nameEN: "Fatigue", icon: "bed.double.fill"),
            Symptom(nameES: "Mareos", nameEN: "Dizziness", icon: "arrow.triangle.2.circlepath")
        ]
    }

    private var respiratorySymptoms: [Symptom] {
        [
            Symptom(nameES: "Tos", nameEN: "Cough", icon: "wind"),
            Symptom(nameES: "Congestion", nameEN: "Congestion", icon: "nose"),
            Symptom(nameES: "Dificultad respirar", nameEN: "Shortness of breath", icon: "lungs.fill"),
            Symptom(nameES: "Garganta", nameEN: "Sore Throat", icon: "mouth")
        ]
    }

    private var digestiveSymptoms: [Symptom] {
        [
            Symptom(nameES: "Nausea", nameEN: "Nausea", icon: "drop.fill"),
            Symptom(nameES: "Dolor de estomago", nameEN: "Stomach pain", icon: "cross.case.fill"),
            Symptom(nameES: "Diarrea", nameEN: "Diarrhea", icon: "toilet.fill"),
            Symptom(nameES: "Vomito", nameEN: "Vomiting", icon: "xmark.circle.fill")
        ]
    }

    private func buildSymptomContext() -> String {
        let symptomNames = selectedSymptoms
            .map { $0.name(for: selectedLanguage) }
            .joined(separator: ", ")

        if selectedLanguage == .spanish {
            return "Estoy sintiendo: \(symptomNames). Ayudame a organizar lo que le diria al doctor."
        } else {
            return "I'm feeling: \(symptomNames). Help me organize what I'd tell my doctor."
        }
    }
}

struct Symptom: Identifiable, Hashable {
    var id: String { nameEN }
    let nameES: String
    let nameEN: String
    let icon: String

    func name(for language: AppLanguage) -> String {
        language == .spanish ? nameES : nameEN
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(nameEN)
    }

    static func == (lhs: Symptom, rhs: Symptom) -> Bool {
        lhs.nameEN == rhs.nameEN
    }
}

struct SymptomChip: View {
    let symptom: Symptom
    let isSelected: Bool
    let selectedLanguage: AppLanguage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symptom.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? .white : .brand)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Color.brand : Color.brand.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(symptom.name(for: selectedLanguage))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()
            }
            .padding(10)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.brand.gradient)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.brand.opacity(0.08), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: isSelected ? Color.brand.opacity(0.3) : .black.opacity(0.06), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SymptomCheckerView(selectedLanguage: .spanish)
}
