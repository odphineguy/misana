//
//  FoundationModelService.swift
//  MiSana
//
//  Created by Abe Perez on 4/12/26.
//

import Foundation
import Combine

#if canImport(FoundationModels)
import FoundationModels

/// Service that wraps Apple's on-device Foundation Models framework for chat and OCR extraction.
/// Available on iOS 26+ devices with Apple Intelligence enabled (A17 Pro / M1 or later).
@available(iOS 26, *)
@MainActor
class FoundationModelService: ObservableObject {

    // MARK: - Published State

    @Published var isAvailable: Bool = false

    // MARK: - Private

    /// Persistent session for chat (keeps transcript/history across turns)
    private var chatSession: LanguageModelSession?

    // MARK: - Initialization

    init() {
        checkAvailability()
    }

    func checkAvailability() {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            isAvailable = true
            print("✅ Apple Foundation Models: AVAILABLE")
        case .unavailable(let reason):
            isAvailable = false
            print("❌ Apple Foundation Models: UNAVAILABLE — \(reason)")
        @unknown default:
            isAvailable = false
            print("❌ Apple Foundation Models: UNAVAILABLE — unknown reason")
        }
    }

    // MARK: - Chat

    /// Create a fresh chat session with the current language's system prompt
    func createChatSession() {
        let prompt = currentSystemPrompt
        chatSession = LanguageModelSession {
            prompt
        }
    }

    /// Generate a response using Foundation Models
    func generateResponse(
        userMessage: String,
        conversationHistory: [ChatMessage],
        healthContext: String? = nil,
        sourceContext: String? = nil
    ) async throws -> String {
        guard isAvailable else {
            throw ModelError.modelNotLoaded
        }

        // Create session if needed (first message or after reset)
        if chatSession == nil {
            createChatSession()
        }

        guard let session = chatSession else {
            throw ModelError.modelNotLoaded
        }

        // Build prompt: source context + user message
        let trimmedMessage = String(userMessage.prefix(500))
        var prompt = trimmedMessage

        if let source = sourceContext, !source.isEmpty {
            prompt = "\(source)\n\n\(trimmedMessage)"
        }

        let options = GenerationOptions(maximumResponseTokens: 300)
        let result = try await session.respond(to: prompt, options: options)
        var response = result.content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip markdown formatting (Apple's model outputs markdown unlike Qwen)
        response = response
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "# ", with: "")
            .replacingOccurrences(of: "- ", with: "• ")

        // Apple's model likes to add bullet lists after a double newline — trim those
        if let listBreak = response.range(of: "\n\n") {
            let beforeList = String(response[..<listBreak.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            // Keep the paragraph text only if it has at least 2 sentences
            if beforeList.filter({ $0 == "." || $0 == "?" || $0 == "!" }).count >= 2 {
                response = beforeList
            }
        }

        #if DEBUG
        print("🍎 Foundation raw (\(response.count) chars): \(response.prefix(300))")
        #endif

        // Post-process: enforce max 4 sentences
        response = ModelPostProcessor.truncateToSentences(response, max: 4)

        #if DEBUG
        print("🍎 After truncation (\(response.count) chars): \(response.prefix(300))")
        #endif

        return response
    }

    // MARK: - OCR Extraction

    /// Extract structured medication info from raw OCR text
    func extractMedicationFromOCR(_ ocrText: String) async -> ExtractedMedication {
        guard isAvailable else {
            return ExtractedMedication()
        }

        let truncatedOCR = String(ocrText.prefix(300))

        let prompt = """
        Extract the medication info from this scanned label text. Return ONLY these 3 lines, nothing else:
        DRUG: [medication name]
        DOSAGE: [dosage amount]
        NDC: [NDC code if found, or NONE]

        Scanned text:
        \(truncatedOCR)
        """

        // Use a separate session for OCR (no conversation history needed)
        let session = LanguageModelSession()

        do {
            let result = try await session.respond(to: prompt)
            let response = result.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return ModelPostProcessor.parseExtraction(response)
        } catch {
            print("⚠️ Foundation Models OCR extraction failed: \(error)")
            return ExtractedMedication()
        }
    }

    // MARK: - Conversation Management

    func resetConversation() {
        chatSession = nil
    }

    // MARK: - System Prompt

    private var currentSystemPrompt: String {
        let isEnglish = UserDefaults.standard.string(forKey: "selectedLanguage") == "en"
        return isEnglish ? ModelPrompts.english : ModelPrompts.spanish
    }
}
#endif
