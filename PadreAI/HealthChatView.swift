//
//  HealthChatView.swift
//  PadreAI
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
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                ChatBubbleView(
                                    message: message,
                                    selectedLanguage: selectedLanguage
                                )
                            }
                            
                            // Loading indicator
                            if isGenerating {
                                HStack {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                    Text(selectedLanguage == .spanish ? 
                                         "Pensando..." : 
                                         "Thinking...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                        .padding()
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
                HStack(spacing: 12) {
                    TextField(
                        selectedLanguage == .spanish ? 
                        "Pregunta sobre tu salud..." : 
                        "Ask about your health...",
                        text: $inputText,
                        axis: .vertical
                    )
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .focused($isInputFocused)
                    .lineLimit(1...5)
                    .disabled(!modelService.isModelLoaded || isGenerating)
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(canSend ? .blue : .gray)
                    }
                    .disabled(!canSend)
                }
                .padding()
            }
            .navigationTitle(selectedLanguage == .spanish ? "Pregunta a PadreAI" : "Ask PadreAI")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button {
                            clearMessages()
                        } label: {
                            Label(
                                selectedLanguage == .spanish ? "Nueva conversación" : "New conversation",
                                systemImage: "plus.message"
                            )
                        }
                        
                        if modelService.isModelLoaded {
                            Button(role: .destructive) {
                                modelService.unloadModel()
                            } label: {
                                Label(
                                    selectedLanguage == .spanish ? "Descargar modelo de memoria" : "Unload model from memory",
                                    systemImage: "trash"
                                )
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
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
                    .background(Color.blue)
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
        let welcomeText = """
        ¡Hola! Soy PadreAI, tu asistente de salud bilingüe. 👋
        
        Puedo ayudarte con preguntas sobre:
        • Medicamentos y dosis
        • Síntomas y cuándo ver al doctor
        • Remedios caseros
        • Preparación para citas médicas
        
        ⚠️ Importante: No soy un doctor. Siempre consulta con un profesional de salud para diagnósticos y tratamientos.
        
        ¿En qué puedo ayudarte hoy?
        """
        
        messages.append(ChatMessage(text: welcomeText, isUser: false))
    }
    
    private func clearMessages() {
        messages.removeAll()
        addWelcomeMessage()
    }
    
    private func checkModelStatus() {
        if !modelService.isModelDownloaded {
            // Show download sheet on first launch
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showDownloadSheet = true
            }
        } else if !modelService.isModelLoaded {
            // Auto-load model if downloaded
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
        // Simulate sending the context as a user message
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
        
        // Add user message
        messages.append(ChatMessage(text: messageText, isUser: true))
        inputText = ""
        isGenerating = true
        
        Task {
            do {
                // Generate response from local model
                let response = try await modelService.generateResponse(
                    userMessage: messageText,
                    conversationHistory: messages,
                    healthContext: healthKitService.summary.generateContextString()
                )
                
                // Add AI response
                await MainActor.run {
                    messages.append(ChatMessage(text: response, isUser: false))
                    isGenerating = false
                }
                
            } catch {
                // Handle error
                let errorResponse = """
                Lo siento, hubo un error al procesar tu mensaje. Por favor intenta de nuevo.
                
                Error: \(error.localizedDescription)
                """
                
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
        HStack {
            if message.isUser { Spacer(minLength: 60) }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.isUser ? AttributedString(message.text) : (try? AttributedString(markdown: message.text)) ?? AttributedString(message.text))
                    .padding(12)
                    .background(message.isUser ? Color.blue : Color.secondary.opacity(0.2))
                    .foregroundStyle(message.isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

#Preview {
    HealthChatView(selectedLanguage: .spanish)
        .environmentObject(LocalModelService())
}
