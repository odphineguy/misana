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
            ScrollView {
                VStack(spacing: 24) {
                    if questions.isEmpty {
                        headerSection
                        appointmentTypeSection
                        actionButtons
                    } else {
                        questionListSection
                    }
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(selectedLanguage == .spanish ? "Preparar Cita" : "Prepare Appointment")
            .toolbar {
                if !questions.isEmpty {
                    ToolbarItem(placement: .automatic) {
                        Menu {
                            Button {
                                showingAddQuestion = true
                            } label: {
                                Label(selectedLanguage == .spanish ? "Agregar pregunta" : "Add question",
                                      systemImage: "plus")
                            }
                            Button(role: .destructive) {
                                questions.removeAll()
                            } label: {
                                Label(selectedLanguage == .spanish ? "Empezar de nuevo" : "Start over",
                                      systemImage: "arrow.counterclockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
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

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "list.clipboard.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
                .padding(.bottom, 4)

            Text(selectedLanguage == .spanish ?
                 "Preparate para tu cita" :
                 "Get ready for your visit")
                .font(.title2)
                .fontWeight(.bold)

            Text(selectedLanguage == .spanish ?
                 "Elige el tipo de cita y MiSana te ayuda a prepararte." :
                 "Choose your appointment type and MiSana helps you prepare.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 8)
    }

    // MARK: - Appointment Type Grid

    private var appointmentTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedLanguage == .spanish ? "Tipo de cita" : "Appointment type")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(AppointmentType.allCases) { type in
                    Button {
                        selectedAppointmentType = type
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: type.icon)
                                .font(.body)
                                .foregroundStyle(selectedAppointmentType == type ? .white : .green)
                                .frame(width: 32, height: 32)
                                .background(selectedAppointmentType == type ? Color.green : Color.green.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            Text(type.name(for: selectedLanguage))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(selectedAppointmentType == type ? .white : .primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                                .multilineTextAlignment(.leading)

                            Spacer()
                        }
                        .padding(10)
                        .background(selectedAppointmentType == type ? Color.green : Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary: AI Prep
            Button {
                navigateToChat = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .font(.body)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedLanguage == .spanish ?
                             "Preparar con MiSana" :
                             "Prepare with MiSana")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(selectedLanguage == .spanish ?
                             "La IA te genera preguntas y consejos" :
                             "AI generates questions and tips for you")
                            .font(.caption)
                            .opacity(0.8)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .padding(14)
                .background(Color.green.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // Secondary: Quick questions
            Button {
                loadSuggestedQuestions()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "list.bullet")
                        .font(.body)
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedLanguage == .spanish ?
                             "Usar preguntas sugeridas" :
                             "Use suggested questions")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(selectedLanguage == .spanish ?
                             "Lista rapida de preguntas comunes" :
                             "Quick list of common questions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            // Tertiary: Add own question
            Button {
                showingAddQuestion = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                        .foregroundStyle(.green)
                    Text(selectedLanguage == .spanish ?
                         "Agregar mi propia pregunta" :
                         "Add my own question")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    // MARK: - Question List (after questions are added)

    private var questionListSection: some View {
        VStack(spacing: 16) {
            // Appointment type badge
            HStack(spacing: 8) {
                Image(systemName: selectedAppointmentType.icon)
                    .foregroundStyle(.green)
                Text(selectedAppointmentType.name(for: selectedLanguage))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(questions.filter(\.isAsked).count)/\(questions.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.horizontal)

            // Tip
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text(selectedLanguage == .spanish ?
                     "Lleva esta lista a tu cita. Marca cada pregunta cuando la hagas." :
                     "Bring this list to your visit. Check off each question as you ask it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.yellow.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)

            // Questions
            VStack(spacing: 8) {
                ForEach(questions) { question in
                    QuestionRowView(
                        question: question,
                        selectedLanguage: selectedLanguage,
                        onToggle: {
                            if let index = questions.firstIndex(where: { $0.id == question.id }) {
                                withAnimation(.spring(response: 0.25)) {
                                    questions[index].isAsked.toggle()
                                }
                            }
                        },
                        onDelete: {
                            if let index = questions.firstIndex(where: { $0.id == question.id }) {
                                let _ = withAnimation {
                                    questions.remove(at: index)
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)

            // AI Prep button (always accessible)
            Button {
                navigateToChat = true
            } label: {
                HStack {
                    Image(systemName: "brain.head.profile")
                    Text(selectedLanguage == .spanish ?
                         "Preparar con MiSana" :
                         "Prepare with MiSana")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.green.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Helpers

    private func buildAppointmentContext() -> String {
        let typeName = selectedAppointmentType.name(for: selectedLanguage)
        if selectedLanguage == .spanish {
            return "Tengo una cita medica por: \(typeName). Dame 3 consejos cortos para prepararme. Se breve."
        } else {
            return "I have a medical appointment for: \(typeName). Give me 3 short tips to prepare. Keep it brief."
        }
    }

    private func loadSuggestedQuestions() {
        let suggested = selectedAppointmentType.questions(for: selectedLanguage)
        questions = suggested.map { Question(text: $0) }
    }
}

// MARK: - Models

struct Question: Identifiable {
    let id = UUID()
    let text: String
    var isAsked: Bool = false
}

enum AppointmentType: String, CaseIterable, Identifiable {
    case checkup, pain, followUp, specialist, pediatric, emergency

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .checkup: return "stethoscope"
        case .pain: return "bolt.heart.fill"
        case .followUp: return "arrow.triangle.2.circlepath"
        case .specialist: return "person.badge.clock"
        case .pediatric: return "figure.and.child.holdinghands"
        case .emergency: return "cross.case.fill"
        }
    }

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
            return language == .spanish ? "Pediatra (ninos)" : "Pediatrician"
        case .emergency:
            return language == .spanish ? "Urgencia" : "Urgent care"
        }
    }

    func questions(for lang: AppLanguage) -> [String] {
        switch self {
        case .checkup:
            return lang == .spanish ? [
                "Como esta mi presion arterial y colesterol?",
                "Estoy al dia con mis vacunas?",
                "Necesito hacerme algun examen de laboratorio?",
                "Debo hacer algun cambio en mi dieta?",
                "Mis medicinas actuales siguen siendo las correctas?",
                "Cuando debo regresar para mi proximo chequeo?"
            ] : [
                "How are my blood pressure and cholesterol?",
                "Am I up to date on my vaccinations?",
                "Do I need any lab tests?",
                "Should I make any changes to my diet?",
                "Are my current medications still the right ones?",
                "When should I come back for my next checkup?"
            ]
        case .pain:
            return lang == .spanish ? [
                "Que puede estar causando este dolor?",
                "Necesito algun estudio o radiografia?",
                "Que puedo tomar para el dolor mientras tanto?",
                "Hay algo que deba evitar hacer?",
                "Cuando deberia preocuparme si el dolor empeora?",
                "Necesito ver a un especialista?"
            ] : [
                "What could be causing this pain?",
                "Do I need any tests or X-rays?",
                "What can I take for the pain in the meantime?",
                "Is there anything I should avoid doing?",
                "When should I worry if the pain gets worse?",
                "Do I need to see a specialist?"
            ]
        case .followUp:
            return lang == .spanish ? [
                "Mis resultados de laboratorio estan bien?",
                "El tratamiento esta funcionando?",
                "Necesito cambiar la dosis de mi medicina?",
                "Hay efectos secundarios que deba reportar?",
                "Cuando es mi proxima cita de seguimiento?",
                "Hay algo nuevo que deba vigilar?"
            ] : [
                "Are my lab results looking good?",
                "Is the treatment working?",
                "Do I need to change my medication dose?",
                "Are there side effects I should report?",
                "When is my next follow-up?",
                "Is there anything new I should watch for?"
            ]
        case .specialist:
            return lang == .spanish ? [
                "Cual es su diagnostico?",
                "Que opciones de tratamiento tengo?",
                "Cuanto tiempo dura el tratamiento?",
                "Necesito algun procedimiento o cirugia?",
                "Que riesgos tiene este tratamiento?",
                "Mi doctor de cabecera recibira un reporte?"
            ] : [
                "What is your diagnosis?",
                "What treatment options do I have?",
                "How long will the treatment last?",
                "Do I need any procedures or surgery?",
                "What are the risks of this treatment?",
                "Will my primary doctor receive a report?"
            ]
        case .pediatric:
            return lang == .spanish ? [
                "Mi hijo esta creciendo y desarrollandose bien?",
                "Que vacunas le tocan hoy?",
                "Es normal este comportamiento para su edad?",
                "Cuanto debe estar comiendo y durmiendo?",
                "Hay algo que deba vigilar en su desarrollo?",
                "Cuando es su proxima cita?"
            ] : [
                "Is my child growing and developing well?",
                "What vaccines are due today?",
                "Is this behavior normal for their age?",
                "How much should they be eating and sleeping?",
                "Is there anything to watch in their development?",
                "When is their next appointment?"
            ]
        case .emergency:
            return lang == .spanish ? [
                "Que tan grave es mi situacion?",
                "Necesito algun estudio urgente?",
                "Que medicamento me van a dar y para que es?",
                "Hay algo que no deba comer o tomar?",
                "Necesito regresar o ir con otro doctor?",
                "Cuando debo ir a emergencias si empeoro?"
            ] : [
                "How serious is my situation?",
                "Do I need any urgent tests?",
                "What medication will I get and what is it for?",
                "Is there anything I shouldn't eat or take?",
                "Do I need to come back or see another doctor?",
                "When should I go to the ER if I get worse?"
            ]
        }
    }
}

// MARK: - Question Row

struct QuestionRowView: View {
    let question: Question
    let selectedLanguage: AppLanguage
    let onToggle: () -> Void
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: question.isAsked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(question.isAsked ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Text(question.text)
                .font(.subheadline)
                .strikethrough(question.isAsked)
                .foregroundStyle(question.isAsked ? .secondary : .primary)

            Spacer()
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label(selectedLanguage == .spanish ? "Eliminar" : "Delete", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Add Question Sheet

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
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()

                Spacer()

                Button {
                    guard !questionText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onAdd(questionText)
                } label: {
                    Text(selectedLanguage == .spanish ? "Agregar pregunta" : "Add question")
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
                    Button(selectedLanguage == .spanish ? "Cancelar" : "Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AppointmentPrepView(selectedLanguage: .spanish)
}
