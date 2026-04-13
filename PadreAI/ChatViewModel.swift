//
//  ChatViewModel.swift
//  MiSana
//
//  Created by Abe Perez on 3/11/26.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel that manages chat conversation state and coordinates with ModelCoordinator
@MainActor
class ChatViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var messages: [ChatMessage] = []
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let modelService: ModelCoordinator

    // MARK: - Initialization

    init(modelService: ModelCoordinator) {
        self.modelService = modelService
        addWelcomeMessage()
    }
    
    // MARK: - Public Methods
    
    /// Send a user message and get AI response
    func sendMessage(_ text: String, language: AppLanguage) async {
        // Add user message
        let userMessage = ChatMessage(text: text, isUser: true)
        messages.append(userMessage)
        
        // Start generating
        isGenerating = true
        errorMessage = nil
        
        do {
            // Generate response from local model
            let response = try await modelService.generateResponse(
                userMessage: text,
                conversationHistory: messages
            )
            
            // Add AI response
            let aiMessage = ChatMessage(text: response, isUser: false)
            messages.append(aiMessage)
            
        } catch {
            // Handle error
            errorMessage = error.localizedDescription
            
            let errorResponse = ChatMessage(
                text: "Lo siento, hubo un error al procesar tu mensaje. Por favor intenta de nuevo.",
                isUser: false
            )
            messages.append(errorResponse)
        }
        
        isGenerating = false
    }
    
    /// Clear conversation history
    func clearMessages() {
        messages.removeAll()
        addWelcomeMessage()
    }
    
    // MARK: - Private Methods
    
    private func addWelcomeMessage() {
        let welcomeText = """
        ¡Hola! Soy MiSana, tu asistente de salud bilingüe. 👋
        
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
}
