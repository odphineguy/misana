//
//  HealthChatView.swift
//  MiSana
//
//  Created by Abe Perez on 3/11/26.
//

import SwiftUI
import Combine

struct HealthChatView: View {
    let selectedLanguage: AppLanguage
    var initialContext: String? = nil
    @EnvironmentObject private var modelService: ModelCoordinator
    @EnvironmentObject private var healthKitService: HealthKitService
    @State private var messages: [ChatMessage] = []
    @State private var isGenerating = false
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @State private var showDownloadSheet = false
    @State private var hassentInitialContext = false
    @State private var lastFailedMessage: String?
    @State private var citations: [String: [HealthCitation]] = [:] // messageID -> citations
    @State private var lastSourceContext: String = ""      // carry forward for follow-ups like "Si"
    @State private var lastCitations: [HealthCitation] = []
    @State private var showEmergencyBanner = false
    private let citationService = HealthCitationService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Model Status Banner
                if !modelService.isModelDownloaded {
                    modelStatusBanner
                }

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Health info banner at top
                            HealthInfoBanner(selectedLanguage: selectedLanguage)

                            ForEach(messages) { message in
                                ChatBubbleView(
                                    message: message,
                                    selectedLanguage: selectedLanguage,
                                    citations: citations[message.id.uuidString] ?? []
                                )
                            }

                            // Emergency 911 banner
                            if showEmergencyBanner {
                                EmergencyBannerView(selectedLanguage: selectedLanguage)
                            }

                            // Thinking indicator
                            if isGenerating {
                                HStack(spacing: 10) {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.brand)
                                        .frame(width: 28, height: 28)
                                        .background(Color.brand.opacity(0.1))
                                        .clipShape(Circle())

                                    HStack(spacing: 6) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text(selectedLanguage == .spanish ?
                                             "MiSana esta pensando..." :
                                             "MiSana is thinking...")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }

                            // Retry button when response fails
                            if let failedMsg = lastFailedMessage, !isGenerating {
                                HStack(spacing: 10) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(selectedLanguage == .spanish ?
                                             "No se pudo generar una respuesta." :
                                             "Could not generate a response.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button {
                                        lastFailedMessage = nil
                                        isGenerating = true
                                        let msg = failedMsg
                                        Task {
                                            let lang = selectedLanguage == .spanish ? "es" : "en"
                                            let retrieval = await citationService.retrieveSources(for: msg, language: lang)
                                            do {
                                                let response = try await modelService.generateResponse(
                                                    userMessage: msg,
                                                    conversationHistory: [],
                                                    healthContext: healthKitService.summary.generateContextString(),
                                                    sourceContext: retrieval.sourceContext
                                                )
                                                let responseMsg = ChatMessage(text: response, isUser: false)
                                                messages.append(responseMsg)
                                                if !retrieval.citations.isEmpty {
                                                    citations[responseMsg.id.uuidString] = retrieval.citations
                                                }
                                            } catch {
                                                lastFailedMessage = msg
                                            }
                                            isGenerating = false
                                        }
                                    } label: {
                                        Text(selectedLanguage == .spanish ? "Reintentar" : "Retry")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.brand)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(12)
                                .background(Color.orange.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onTapGesture {
                        isInputFocused = false
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input area
                HStack(spacing: 10) {
                    TextField(
                        selectedLanguage == .spanish ?
                        "Escribe tu duda medica..." :
                        "Type your health question...",
                        text: $inputText,
                        axis: .vertical
                    )
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .focused($isInputFocused)
                    .lineLimit(1...5)
                    .disabled(!modelService.isModelLoaded || isGenerating)

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(canSend ? .blue : .gray.opacity(0.4))
                    }
                    .disabled(!canSend)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .liquidGlass(cornerRadii: .init(topLeading: 16, topTrailing: 16))
            }
            .navigationTitle(selectedLanguage == .spanish ? "Pregunta a MiSana" : "Ask MiSana")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        clearMessages()
                    } label: {
                        Image(systemName: "plus.message")
                    }
                }
            }
            .sheet(isPresented: $showDownloadSheet) {
                ModelDownloadView(
                    modelService: modelService,
                    selectedLanguage: selectedLanguage
                )
            }
            .onAppear {
                initializeMessages()
                checkModelStatus()
            }
        }
    }

    // MARK: - Model Status Banner

    private var modelStatusBanner: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                Text(selectedLanguage == .spanish ?
                     "Modelo de IA no disponible" :
                     "AI Model not available")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }

            Button {
                showDownloadSheet = true
            } label: {
                Text(selectedLanguage == .spanish ?
                     "Descargar Modelo" :
                     "Download Model")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
    }

    // MARK: - Computed Properties

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty &&
        modelService.isModelLoaded &&
        !isGenerating
    }

    // MARK: - Methods

    private func initializeMessages() {
        if messages.isEmpty {
            addWelcomeMessage()
        }
    }

    private func addWelcomeMessage() {
        let welcomeText: String
        if selectedLanguage == .spanish {
            welcomeText = """
            Hola! Soy MiSana, tu asistente de salud personal.

            En que puedo ayudarte hoy? Puedo asistirte con:
            \u{2022} Chequear tus sintomas
            \u{2022} Explicar tus medicinas
            \u{2022} Preparar citas medicas
            """
        } else {
            welcomeText = """
            Hello! I'm MiSana, your personal health assistant.

            How can I help you today? I can assist with:
            \u{2022} Check your symptoms
            \u{2022} Explain your medications
            \u{2022} Prepare doctor appointments
            """
        }

        messages.append(ChatMessage(text: welcomeText, isUser: false))
    }

    private func clearMessages() {
        messages.removeAll()
        modelService.resetConversation()
        showEmergencyBanner = false
        addWelcomeMessage()
    }

    /// Detect emergency symptoms that require immediate 911 guidance
    private func detectEmergency(_ message: String) -> Bool {
        let lowered = message.lowercased()
        let emergencyPhrases = [
            // Chest pain / heart
            "dolor de pecho", "chest pain", "dolor en el pecho",
            "heart attack", "ataque al corazón", "ataque cardiaco", "infarto",
            // Breathing
            "no puedo respirar", "can't breathe", "cannot breathe",
            "dificultad para respirar", "difficulty breathing", "trouble breathing",
            "me ahogo", "me estoy ahogando", "choking",
            // Stroke
            "stroke", "derrame cerebral", "embolia",
            // Suicide / self-harm
            "quiero morir", "want to die", "suicidarme", "kill myself",
            "no quiero vivir", "matarme", "hacerme daño",
            // Severe bleeding
            "mucha sangre", "no para de sangrar", "bleeding a lot", "won't stop bleeding",
            // Baby/infant emergency
            "fiebre alta en bebe", "fiebre alta en bebé", "baby high fever",
            "mi bebe no respira", "mi bebé no respira", "baby not breathing",
            // Overdose / poisoning
            "sobredosis", "overdose", "envenenamiento", "poisoning", "se tomo veneno",
            // Loss of consciousness
            "no responde", "unconscious", "inconsciente", "se desmayo", "se desmayó",
            "unresponsive"
        ]
        return emergencyPhrases.contains { lowered.contains($0) }
    }

    private func checkModelStatus() {
        if !modelService.isModelDownloaded {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showDownloadSheet = true
            }
        } else if !modelService.isModelLoaded {
            Task {
                try? modelService.loadModel()
                await sendInitialContextIfNeeded()
            }
        } else {
            Task {
                await sendInitialContextIfNeeded()
            }
        }
    }

    private func sendInitialContextIfNeeded() async {
        guard let context = initialContext, !hassentInitialContext, modelService.isModelLoaded else { return }
        hassentInitialContext = true
        messages.append(ChatMessage(text: context, isUser: true))
        isGenerating = true

        // STEP 1: Retrieve verified sources BEFORE generating
        let lang = selectedLanguage == .spanish ? "es" : "en"
        let retrieval = await citationService.retrieveSources(for: context, language: lang)

        do {
            // STEP 2: Generate with source context
            let response = try await modelService.generateResponse(
                userMessage: context,
                conversationHistory: messages,
                healthContext: healthKitService.summary.generateContextString(),
                sourceContext: retrieval.sourceContext
            )
            let responseMsg = ChatMessage(text: response, isUser: false)
            messages.append(responseMsg)
            if !retrieval.citations.isEmpty {
                citations[responseMsg.id.uuidString] = retrieval.citations
            }
        } catch {
            let errorText = selectedLanguage == .spanish ?
                "Lo siento, hubo un error. Por favor intenta de nuevo." :
                "Sorry, there was an error. Please try again."
            messages.append(ChatMessage(text: errorText, isUser: false))
        }
        isGenerating = false
    }

    private func sendMessage() {
        let messageText = inputText.trimmingCharacters(in: .whitespaces)
        guard !messageText.isEmpty else { return }

        messages.append(ChatMessage(text: messageText, isUser: true))
        inputText = ""

        // Check for emergency symptoms BEFORE generating — banner appears immediately
        showEmergencyBanner = detectEmergency(messageText)

        isGenerating = true

        Task {
            // STEP 1: Retrieve verified sources BEFORE generating response
            let lang = selectedLanguage == .spanish ? "es" : "en"
            let retrieval = await citationService.retrieveSources(for: messageText, language: lang)

            // For short follow-ups ("Si", "Yes", "Tell me more"), carry forward previous sources
            let sourceContext = retrieval.hasVerifiedSources ? retrieval.sourceContext : lastSourceContext
            let activeCitations = retrieval.hasVerifiedSources ? retrieval.citations : lastCitations

            do {
                // STEP 2: Generate response with source context
                let response = try await modelService.generateResponse(
                    userMessage: messageText,
                    conversationHistory: messages,
                    healthContext: healthKitService.summary.generateContextString(),
                    sourceContext: sourceContext
                )

                // STEP 3: Display response with retrieved citations
                await MainActor.run {
                    lastFailedMessage = nil
                    let responseMsg = ChatMessage(text: response, isUser: false)
                    messages.append(responseMsg)
                    if !activeCitations.isEmpty {
                        citations[responseMsg.id.uuidString] = activeCitations
                    }
                    // Store successful retrieval for future follow-ups
                    if retrieval.hasVerifiedSources {
                        lastSourceContext = retrieval.sourceContext
                        lastCitations = retrieval.citations
                    }
                    isGenerating = false
                }

            } catch {
                await MainActor.run {
                    lastFailedMessage = messageText
                    isGenerating = false
                }
            }
        }
    }
}

// MARK: - iMessage Bubble Shape

struct MessageBubbleShape: Shape {
    let isFromUser: Bool

    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 18
        var path = Path()

        if isFromUser {
            // Tail on bottom-right
            path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                        radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
            path.addCurve(
                to: CGPoint(x: rect.maxX + 6, y: rect.maxY),
                control1: CGPoint(x: rect.maxX, y: rect.maxY - 4),
                control2: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.addCurve(
                to: CGPoint(x: rect.maxX - r, y: rect.maxY - 2),
                control1: CGPoint(x: rect.maxX + 6, y: rect.maxY),
                control2: CGPoint(x: rect.maxX - 2, y: rect.maxY - 2)
            )
            path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY - 2))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - 2 - r),
                        radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r),
                        radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            // Tail on bottom-left
            path.move(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + r, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r),
                        radius: r, startAngle: .degrees(-90), endAngle: .degrees(180), clockwise: true)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - r))
            path.addCurve(
                to: CGPoint(x: rect.minX - 6, y: rect.maxY),
                control1: CGPoint(x: rect.minX, y: rect.maxY - 4),
                control2: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.addCurve(
                to: CGPoint(x: rect.minX + r, y: rect.maxY - 2),
                control1: CGPoint(x: rect.minX - 6, y: rect.maxY),
                control2: CGPoint(x: rect.minX + 2, y: rect.maxY - 2)
            )
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.maxY - 2))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - 2 - r),
                        radius: r, startAngle: .degrees(90), endAngle: .degrees(0), clockwise: true)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + r))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                        radius: r, startAngle: .degrees(0), endAngle: .degrees(-90), clockwise: true)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Chat Bubble View

struct ChatBubbleView: View {
    let message: ChatMessage
    let selectedLanguage: AppLanguage
    var citations: [HealthCitation] = []
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
            } else {
                // AI avatar
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.brand)
                    .clipShape(Circle())
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if !message.isUser {
                    HStack(spacing: 4) {
                        Text("MISANA")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.brand)
                        Text("\u{2022}")
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                        Text(message.timestamp, style: .time)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }

                Text(message.isUser ?
                     AttributedString(message.text) :
                     (try? AttributedString(markdown: message.text)) ?? AttributedString(message.text))
                    .font(.subheadline)
                    .padding(12)
                    .padding(message.isUser ? .trailing : .leading, 4)
                    .foregroundStyle(message.isUser ? .white : .primary)
                    .background(
                        MessageBubbleShape(isFromUser: message.isUser)
                            .fill(message.isUser ? Color.brand :
                                    (colorScheme == .light ? Color(uiColor: .systemGray6) : Color(uiColor: .secondarySystemGroupedBackground)))
                    )

                // Topic-specific citations for AI responses
                if !message.isUser && !citations.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedLanguage == .spanish ? "Fuentes:" : "Sources:")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                        ForEach(citations) { citation in
                            Link(destination: citation.url) {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                        .font(.system(size: 8))
                                    Text("\(citation.title) — \(citation.source)")
                                        .font(.system(size: 9))
                                        .lineLimit(1)
                                }
                                .foregroundStyle(.brand)
                            }
                        }
                        Text(selectedLanguage == .spanish ?
                             "Siempre consulta a tu doctor." :
                             "Always consult your doctor.")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)
                } else if !message.isUser {
                    // Fallback when no specific citations found
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedLanguage == .spanish ?
                             "Info educativa. Consulta a tu doctor." :
                             "Educational info. Consult your doctor.")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Link(destination: URL(string: selectedLanguage == .spanish ?
                            "https://medlineplus.gov/spanish/healthtopics.html" :
                            "https://medlineplus.gov/healthtopics.html")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.system(size: 8))
                                Text(selectedLanguage == .spanish ?
                                     "Fuente: MedlinePlus (NIH)" :
                                     "Source: MedlinePlus (NIH)")
                                    .font(.system(size: 9))
                            }
                            .foregroundStyle(.brand)
                        }
                    }
                    .padding(.top, 2)
                }

                if message.isUser {
                    HStack(spacing: 4) {
                        Text(selectedLanguage == .spanish ? "TU" : "YOU")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.brand)
                        Text("\u{2022}")
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                        Text(message.timestamp, style: .time)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            if !message.isUser {
                Spacer(minLength: 40)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Health Info Banner

struct HealthInfoBanner: View {
    let selectedLanguage: AppLanguage

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.brand)
                .font(.subheadline)
            Text(selectedLanguage == .spanish ?
                 "La informacion de salud de MiSana es solo educativa, basada en fuentes como MedlinePlus (NIH) y guias del CDC. No reemplaza a tu doctor." :
                 "MiSana's health info is educational only, based on sources like MedlinePlus (NIH) and CDC guidelines. It does not replace your doctor.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color.brand.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
}

// MARK: - Emergency 911 Banner

struct EmergencyBannerView: View {
    let selectedLanguage: AppLanguage

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                Text(selectedLanguage == .spanish ?
                     "Esto suena como una emergencia." :
                     "This sounds like an emergency.")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Spacer()
            }

            Text(selectedLanguage == .spanish ?
                 "Si tu o alguien cerca de ti esta en peligro, llama al 911 ahora." :
                 "If you or someone near you is in danger, call 911 now.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)

            Link(destination: URL(string: "tel://911")!) {
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .font(.headline)
                    Text(selectedLanguage == .spanish ? "Llamar al 911" : "Call 911")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Link(destination: URL(string: "tel:988")!) {
                Text(selectedLanguage == .spanish ?
                     "Linea de crisis y suicidio: 988" :
                     "Suicide & Crisis Lifeline: 988")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                    .underline()
            }
        }
        .padding(16)
        .background(Color.red)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - About Health Sources View

struct AboutHealthSourcesView: View {
    let selectedLanguage: AppLanguage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(selectedLanguage == .spanish ?
                         "MiSana utiliza un modelo de inteligencia artificial que funciona en tu dispositivo para proporcionar informacion educativa general sobre salud. Esta informacion NO reemplaza el consejo medico profesional." :
                         "MiSana uses an on-device AI model to provide general educational health information. This information does NOT replace professional medical advice.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section(selectedLanguage == .spanish ? "Fuentes de referencia" : "Reference sources") {
                    Link(destination: URL(string: selectedLanguage == .spanish ?
                        "https://medlineplus.gov/spanish/" :
                        "https://medlineplus.gov/")!) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("MedlinePlus")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(selectedLanguage == .spanish ?
                                     "Biblioteca Nacional de Medicina de EE.UU. (NIH)" :
                                     "U.S. National Library of Medicine (NIH)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "safari")
                                .foregroundStyle(.brand)
                        }
                    }

                    Link(destination: URL(string: "https://www.cdc.gov/")!) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("CDC")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(selectedLanguage == .spanish ?
                                     "Centros para el Control y Prevencion de Enfermedades" :
                                     "Centers for Disease Control and Prevention")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "safari")
                                .foregroundStyle(.brand)
                        }
                    }

                    Link(destination: URL(string: "https://www.who.int/")!) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selectedLanguage == .spanish ? "OMS" : "WHO")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(selectedLanguage == .spanish ?
                                     "Organizacion Mundial de la Salud" :
                                     "World Health Organization")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "safari")
                                .foregroundStyle(.brand)
                        }
                    }

                    Link(destination: URL(string: "https://rxnav.nlm.nih.gov/")!) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("RxNorm (NIH)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(selectedLanguage == .spanish ?
                                     "Base de datos de medicamentos del NIH" :
                                     "NIH drug database for medication lookup")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "safari")
                                .foregroundStyle(.brand)
                        }
                    }
                }

                Section(selectedLanguage == .spanish ? "Datos que se envían" : "Data sent from this app") {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(selectedLanguage == .spanish ? "Conversaciones de IA" : "AI conversations",
                              systemImage: "brain.head.profile")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(selectedLanguage == .spanish ?
                             "Se procesan completamente en tu dispositivo usando IA en el dispositivo. Ninguna conversación, dato de salud o información personal se envía a ningún servidor o servicio de IA de terceros." :
                             "Processed entirely on your device using on-device AI. No conversations, health data, or personal information are sent to any server or third-party AI service.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Label(selectedLanguage == .spanish ? "Búsqueda de medicamentos" : "Medication lookups",
                              systemImage: "pill.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(selectedLanguage == .spanish ?
                             "Al buscar o escanear un medicamento, solo el nombre del medicamento o código de barras se envía a RxNorm y MedlinePlus (Biblioteca Nacional de Medicina de EE.UU. / NIH). No se incluyen datos personales ni de salud." :
                             "When you search or scan a medication, only the drug name or barcode number is sent to RxNorm and MedlinePlus (U.S. National Library of Medicine / NIH). No personal or health data is included.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Label(selectedLanguage == .spanish ? "Datos de salud (Apple Health)" : "Health data (Apple Health)",
                              systemImage: "heart.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(selectedLanguage == .spanish ?
                             "Se leen localmente en tu dispositivo. Nunca se transmiten a ningún lugar." :
                             "Read locally on your device only. Never transmitted anywhere.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(selectedLanguage == .spanish ? "Importante" : "Important") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(selectedLanguage == .spanish ?
                              "MiSana NO es un doctor" :
                              "MiSana is NOT a doctor",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)

                        Text(selectedLanguage == .spanish ?
                             "Siempre consulta con un profesional de salud certificado para diagnosticos, tratamientos o decisiones medicas. En emergencias, llama al 911." :
                             "Always consult a certified healthcare professional for diagnoses, treatments, or medical decisions. In emergencies, call 911.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(selectedLanguage == .spanish ?
                             "Sobre la informacion de salud" :
                             "About health information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selectedLanguage == .spanish ? "Cerrar" : "Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    HealthChatView(selectedLanguage: .spanish)
        .environmentObject(ModelCoordinator())
        .environmentObject(HealthKitService())
}
