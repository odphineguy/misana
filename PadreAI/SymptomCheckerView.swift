//
//  SymptomCheckerView.swift
//  PadreAI
//
//  Created by Abe Perez on 3/11/26.
//

import SwiftUI

struct SymptomCheckerView: View {
    let selectedLanguage: AppLanguage
    @State private var selectedSymptoms: Set<Symptom> = []
    @State private var navigateToChat = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.red)
                    
                    Text(selectedLanguage == .spanish ? 
                         "¿Qué estás sintiendo?" : 
                         "What are you feeling?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(selectedLanguage == .spanish ? 
                         "Selecciona tus síntomas" : 
                         "Select your symptoms")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 24)
                
                // Symptom Categories
                ScrollView {
                    VStack(spacing: 16) {
                        symptomCategory(
                            title: selectedLanguage == .spanish ? "Comunes" : "Common",
                            symptoms: commonSymptoms
                        )
                        
                        symptomCategory(
                            title: selectedLanguage == .spanish ? "Respiratorios" : "Respiratory",
                            symptoms: respiratorySymptoms
                        )
                        
                        symptomCategory(
                            title: selectedLanguage == .spanish ? "Digestivos" : "Digestive",
                            symptoms: digestiveSymptoms
                        )
                    }
                    .padding()
                }
                
                // Action Button
                if !selectedSymptoms.isEmpty {
                    Button {
                        navigateToChat = true
                    } label: {
                        Text(selectedLanguage == .spanish ?
                             "Revisar \(selectedSymptoms.count) síntoma(s) con IA" :
                             "Check \(selectedSymptoms.count) symptom(s) with AI")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding()
                }
            }
            .navigationTitle(selectedLanguage == .spanish ? "Síntomas" : "Symptoms")
            .navigationDestination(isPresented: $navigateToChat) {
                HealthChatView(
                    selectedLanguage: selectedLanguage,
                    initialContext: buildSymptomContext()
                )
            }
        }
    }
    
    private func symptomCategory(title: String, symptoms: [Symptom]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 12) {
                ForEach(symptoms) { symptom in
                    SymptomButton(
                        symptom: symptom,
                        isSelected: selectedSymptoms.contains(symptom),
                        selectedLanguage: selectedLanguage
                    ) {
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
    
    // Sample symptom data
    private var commonSymptoms: [Symptom] {
        [
            Symptom(nameES: "Fiebre", nameEN: "Fever", icon: "thermometer"),
            Symptom(nameES: "Dolor de cabeza", nameEN: "Headache", icon: "brain.head.profile"),
            Symptom(nameES: "Fatiga", nameEN: "Fatigue", icon: "bed.double.fill"),
            Symptom(nameES: "Dolor muscular", nameEN: "Muscle pain", icon: "figure.arms.open")
        ]
    }
    
    private var respiratorySymptoms: [Symptom] {
        [
            Symptom(nameES: "Tos", nameEN: "Cough", icon: "wind"),
            Symptom(nameES: "Dolor de garganta", nameEN: "Sore throat", icon: "mouth"),
            Symptom(nameES: "Nariz congestionada", nameEN: "Stuffy nose", icon: "nose"),
            Symptom(nameES: "Falta de aire", nameEN: "Shortness of breath", icon: "lungs.fill")
        ]
    }
    
    private var digestiveSymptoms: [Symptom] {
        [
            Symptom(nameES: "Náusea", nameEN: "Nausea", icon: "drop.fill"),
            Symptom(nameES: "Dolor de estómago", nameEN: "Stomach pain", icon: "cross.case.fill"),
            Symptom(nameES: "Diarrea", nameEN: "Diarrhea", icon: "toilet.fill"),
            Symptom(nameES: "Vómito", nameEN: "Vomiting", icon: "xmark.circle.fill")
        ]
    }

    private func buildSymptomContext() -> String {
        let symptomNames = selectedSymptoms
            .map { $0.name(for: selectedLanguage) }
            .joined(separator: ", ")

        if selectedLanguage == .spanish {
            return "Tengo estos síntomas: \(symptomNames). ¿Qué me recomiendas? ¿Debería ir al doctor?"
        } else {
            return "I have these symptoms: \(symptomNames). What do you recommend? Should I see a doctor?"
        }
    }
}

struct Symptom: Identifiable, Hashable {
    let id = UUID()
    let nameES: String
    let nameEN: String
    let icon: String
    
    func name(for language: AppLanguage) -> String {
        language == .spanish ? nameES : nameEN
    }
}

struct SymptomButton: View {
    let symptom: Symptom
    let isSelected: Bool
    let selectedLanguage: AppLanguage
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: symptom.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : .primary)
                
                Text(symptom.name(for: selectedLanguage))
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.red : Color.secondary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.red : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SymptomCheckerView(selectedLanguage: .spanish)
}
