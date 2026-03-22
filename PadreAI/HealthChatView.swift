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
    @EnvironmentObject private var modelService: LocalModelService
    @EnvironmentObject private var healthKitService: HealthKitService
    @State private var messages: [ChatMessage] = []
    @State private var isGenerating = false
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @State private var showDownloadSheet = false
    @State private var hassentInitialContext = false

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
                            ForEach(messages) { message in
                                ChatBubbleView(
                                    message: message,
                                    selectedLanguage: selectedLanguage
                                )
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

                Divider()

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
                modelService.resetConversation()
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
            \u{2022} Chequear tus sintomas / Check symptoms
            \u{2022} Explicar tus medicinas / Explain meds
            \u{2022} Preparar citas medicas / Prep appointments
            """
        } else {
            welcomeText = """
            Hello! I'm MiSana, your personal health assistant.

            How can I help you today? I can assist with:
            \u{2022} Check your symptoms / Chequear sintomas
            \u{2022} Explain your medications / Explicar medicinas
            \u{2022} Prepare doctor appointments / Preparar citas
            """
        }

        messages.append(ChatMessage(text: welcomeText, isUser: false))
    }

    private func clearMessages() {
        messages.removeAll()
        modelService.resetConversation()
        addWelcomeMessage()
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
        do {
            let response = try await modelService.generateResponse(
                userMessage: context,
                conversationHistory: messages,
                healthContext: healthKitService.summary.generateContextString()
            )
            messages.append(ChatMessage(text: response, isUser: false))
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
        isGenerating = true

        Task {
            do {
                let response = try await modelService.generateResponse(
                    userMessage: messageText,
                    conversationHistory: messages,
                    healthContext: healthKitService.summary.generateContextString()
                )

                await MainActor.run {
                    messages.append(ChatMessage(text: response, isUser: false))
                    isGenerating = false
                }

            } catch {
                let errorResponse = selectedLanguage == .spanish ?
                    "Lo siento, hubo un error al procesar tu mensaje. Por favor intenta de nuevo." :
                    "Sorry, there was an error processing your message. Please try again."

                await MainActor.run {
                    messages.append(ChatMessage(text: errorResponse, isUser: false))
                    isGenerating = false
                }
            }
        }
    }
}

// MARK: - Chat Bubble View

struct ChatBubbleView: View {
    let message: ChatMessage
    let selectedLanguage: AppLanguage

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
                    .background(message.isUser ? Color.brand : Color(uiColor: .secondarySystemGroupedBackground))
                    .foregroundStyle(message.isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

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

#Preview {
    HealthChatView(selectedLanguage: .spanish)
        .environmentObject(LocalModelService())
}
