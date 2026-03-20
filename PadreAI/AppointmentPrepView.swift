//
//  AppointmentPrepView.swift
//  MiSana
//
//  Created by Abe Perez on 3/11/26.
//

import SwiftUI

struct AppointmentPrepView: View {
    let selectedLanguage: AppLanguage
    @State private var questions: [Question] = []
    @State private var newQuestionText = ""
    @State private var showingAddQuestion = false
    @State private var selectedAppointmentType: AppointmentType = .checkup
    @State private var navigateToChat = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if questions.isEmpty {
                    emptyStateView
                } else {
                    questionListView
                }
            }
            .navigationTitle(selectedLanguage == .spanish ? "Preparar Cita" : "Prepare Appointment")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingAddQuestion = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToChat) {
                HealthChatView(
                    selectedLanguage: selectedLanguage,
                    initialContext: buildAppointmentContext()
                )
            }
            .sheet(isPresented: $showingAddQuestion) {
                AddQuestionView(
                    selectedLanguage: selectedLanguage,
                    onAdd: { questionText in
                        questions.append(Question(text: questionText))
                        showingAddQuestion = false
                    }
                )
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text(selectedLanguage == .spanish ?
                 "Prepara tu cita" :
                 "Prepare your appointment")
                .font(.title2)
                .fontWeight(.semibold)

            Text(selectedLanguage == .spanish ?
                 "MiSana te ayuda a llegar listo a tu cita" :
                 "MiSana helps you arrive ready for your appointment")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            aiPrepSection

            Button {
                loadSuggestedQuestions()
            } label: {
                Text(selectedLanguage == .spanish ?
                     "O usa preguntas b\u{00e1}sicas" :
                     "Or use basic questions")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
        }
    }
    
    private var questionListView: some View {
        VStack(spacing: 0) {
            // AI Prep (primary action)
            aiPrepSection

            // Header tip for the static questions below
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text(selectedLanguage == .spanish ?
                         "Consejo:" :
                         "Tip:")
                        .fontWeight(.semibold)
                    Spacer()
                }

                Text(selectedLanguage == .spanish ?
                     "Lleva esta lista impresa o en tu teléfono a tu cita médica. No tengas miedo de hacer preguntas." :
                     "Bring this list printed or on your phone to your medical appointment. Don't be afraid to ask questions.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))

            // Questions list
            List {
                ForEach(questions) { question in
                    QuestionRowView(
                        question: question,
                        selectedLanguage: selectedLanguage,
                        onToggle: {
                            if let index = questions.firstIndex(where: { $0.id == question.id }) {
                                questions[index].isAsked.toggle()
                            }
                        }
                    )
                }
                .onDelete { indexSet in
                    questions.remove(atOffsets: indexSet)
                }
                .onMove { source, destination in
                    questions.move(fromOffsets: source, toOffset: destination)
                }
            }
            .listStyle(.plain)
        }
    }
    
    private var aiPrepSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain")
                    .foregroundStyle(.green)
                Text(selectedLanguage == .spanish ?
                     "Prepárate con IA" :
                     "Prepare with AI")
                    .font(.headline)
                Spacer()
            }

            Picker(selectedLanguage == .spanish ? "Tipo de cita" : "Appointment type",
                   selection: $selectedAppointmentType) {
                ForEach(AppointmentType.allCases) { type in
                    Text(type.name(for: selectedLanguage)).tag(type)
                }
            }
            .pickerStyle(.menu)

            Button {
                navigateToChat = true
            } label: {
                Label(
                    selectedLanguage == .spanish ?
                        "Preparar con MiSana" :
                        "Prepare with MiSana",
                    systemImage: "message.fill"
                )
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(Color.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func buildAppointmentContext() -> String {
        let typeName = selectedAppointmentType.name(for: selectedLanguage)
        if selectedLanguage == .spanish {
            return "Tengo una cita médica por: \(typeName). Ayúdame a prepararme — qué síntomas mencionar, qué preguntas hacerle al doctor, qué llevar (tarjeta de seguro, lista de medicinas, resultados), y qué esperar en la cita."
        } else {
            return "I have a medical appointment for: \(typeName). Help me prepare — what symptoms to mention, what questions to ask the doctor, what to bring (insurance card, medication list, prior results), and what to expect."
        }
    }

    private func loadSuggestedQuestions() {
        let suggested: [String] = selectedLanguage == .spanish ? [
            "¿Qué debo hacer si mis síntomas empeoran?",
            "¿Cuáles son los efectos secundarios de este medicamento?",
            "¿Necesito hacer algún cambio en mi dieta?",
            "¿Cuándo debería volver para seguimiento?",
            "¿Hay alternativas a este tratamiento?",
            "¿Qué síntomas debo vigilar?",
            "¿Puedo hacer ejercicio normalmente?",
            "¿Este medicamento interactúa con mis otras medicinas?"
        ] : [
            "What should I do if my symptoms get worse?",
            "What are the side effects of this medication?",
            "Do I need to make any changes to my diet?",
            "When should I come back for follow-up?",
            "Are there alternatives to this treatment?",
            "What symptoms should I watch for?",
            "Can I exercise normally?",
            "Does this medication interact with my other medicines?"
        ]
        
        questions = suggested.map { Question(text: $0) }
    }
}

struct Question: Identifiable {
    let id = UUID()
    let text: String
    var isAsked: Bool = false
}

enum AppointmentType: String, CaseIterable, Identifiable {
    case checkup
    case pain
    case followUp
    case specialist
    case pediatric
    case emergency

    var id: String { rawValue }

    func name(for language: AppLanguage) -> String {
        switch self {
        case .checkup:
            return language == .spanish ? "Chequeo general" : "General checkup"
        case .pain:
            return language == .spanish ? "Dolor o molestia" : "Pain or discomfort"
        case .followUp:
            return language == .spanish ? "Seguimiento" : "Follow-up"
        case .specialist:
            return language == .spanish ? "Especialista" : "Specialist"
        case .pediatric:
            return language == .spanish ? "Pediatra (niños)" : "Pediatrician (children)"
        case .emergency:
            return language == .spanish ? "Urgencia" : "Urgent care"
        }
    }
}

struct QuestionRowView: View {
    let question: Question
    let selectedLanguage: AppLanguage
    let onToggle: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                onToggle()
            } label: {
                Image(systemName: question.isAsked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(question.isAsked ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            Text(question.text)
                .font(.body)
                .strikethrough(question.isAsked)
                .foregroundStyle(question.isAsked ? .secondary : .primary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AddQuestionView: View {
    let selectedLanguage: AppLanguage
    let onAdd: (String) -> Void
    
    @State private var questionText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedLanguage == .spanish ? "Tu pregunta:" : "Your question:")
                        .font(.headline)
                    
                    TextEditor(text: $questionText)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
                
                Spacer()
                
                Button {
                    guard !questionText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onAdd(questionText)
                } label: {
                    Text(selectedLanguage == .spanish ? "Añadir pregunta" : "Add question")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(questionText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(questionText.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding()
            }
            .navigationTitle(selectedLanguage == .spanish ? "Nueva pregunta" : "New question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selectedLanguage == .spanish ? "Cancelar" : "Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AppointmentPrepView(selectedLanguage: .spanish)
}
