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
                        .padding(.horizontal)

                        // Symptom Categories
                        VStack(spacing: 20) {
                            symptomCategory(
                                title: selectedLanguage == .spanish ? "Comunes" : "Common",
                                symptoms: filteredSymptoms(commonSymptoms)
                            )

                            symptomCategory(
                                title: selectedLanguage == .spanish ? "Respiratorios" : "Respiratory",
                                symptoms: filteredSymptoms(respiratorySymptoms)
                            )

                            symptomCategory(
                                title: selectedLanguage == .spanish ? "Digestivos" : "Digestive",
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

                // Floating CTA
                if !selectedSymptoms.isEmpty {
                    Button {
                        navigateToChat = true
                    } label: {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.body)
                            Text(selectedLanguage == .spanish ?
                                 "Revisar \(selectedSymptoms.count) sintoma\(selectedSymptoms.count == 1 ? "" : "s") con IA" :
                                 "Check \(selectedSymptoms.count) symptom\(selectedSymptoms.count == 1 ? "" : "s") with AI")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
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

    private func symptomCategory(title: String, symptoms: [Symptom]) -> some View {
        Group {
            if !symptoms.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.headline)

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
            return "Tengo estos sintomas: \(symptomNames). Que me recomiendas? Deberia ir al doctor?"
        } else {
            return "I have these symptoms: \(symptomNames). What do you recommend? Should I see a doctor?"
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
            HStack(spacing: 8) {
                Image(systemName: symptom.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? .white : .primary)

                Text(symptom.name(for: selectedLanguage))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.red : Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SymptomCheckerView(selectedLanguage: .spanish)
}
