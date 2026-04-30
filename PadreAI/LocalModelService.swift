//
//  LocalModelService.swift
//  MiSana
//
//  Created by Abe Perez on 3/11/26.
//

import Foundation
import Combine
import LLM  // LLM.swift package

/// Service that manages local LLM model loading, inference, and lifecycle
@MainActor
class LocalModelService: ObservableObject {
    
    // MARK: - Published State
    
    @Published var modelDownloadProgress: Double = 0.0
    @Published var isModelDownloaded: Bool = false
    @Published var isModelLoaded: Bool = false
    @Published var downloadError: String?
    
    // MARK: - Properties
    
    private var modelPath: URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        return documentsPath.appendingPathComponent("Qwen_Qwen3-4B-Q4_K_M.gguf")
    }
    
    private var downloadTask: URLSessionDownloadTask?
    private var downloadSession: URLSession?
    private var downloadContinuation: CheckedContinuation<Void, Error>?

    // Model instance - LLM.swift
    private var llm: LLM?
    
    // MARK: - System Prompt
    
    private var systemPrompt: String {
        let isEnglish = UserDefaults.standard.string(forKey: "selectedLanguage") == "en"
        return isEnglish ? ModelPrompts.english : ModelPrompts.spanish
    }
    
    // MARK: - Initialization
    
    /// When `deferLoading` is true, the model file existence is checked but
    /// the model is NOT loaded into memory. Use this when another engine
    /// (e.g. Foundation Models) is active to avoid blocking the main thread.
    init(deferLoading: Bool = false) {
        checkIfModelExists()
        if !deferLoading && isModelDownloaded {
            try? loadModel()
        }
    }
    
    // MARK: - Model Download
    
    /// Check if model already exists in Documents directory
    func checkIfModelExists() {
        guard let modelPath = modelPath else { return }
        
        isModelDownloaded = FileManager.default.fileExists(atPath: modelPath.path)
        
        if isModelDownloaded {
            print("✅ Model found at: \(modelPath.path)")
        } else {
            print("⚠️ Model not found. User needs to download.")
        }
    }
    
    /// Download model from Hugging Face
    func downloadModel() async throws {
        guard let modelPath = modelPath else {
            throw ModelError.invalidPath
        }
        
        let modelURL = URL(string: "https://huggingface.co/bartowski/Qwen_Qwen3-4B-GGUF/resolve/main/Qwen_Qwen3-4B-Q4_K_M.gguf?download=true")!
        
        print("📡 Attempting download from: \(modelURL.absoluteString)")
        print("📁 Saving to: \(modelPath.path)")
        
        return try await withCheckedThrowingContinuation { continuation in
            self.downloadContinuation = continuation

            var request = URLRequest(url: modelURL)
            request.timeoutInterval = 600
            request.httpMethod = "GET"

            let delegate = DownloadDelegate(service: self, destinationPath: modelPath)
            let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            self.downloadSession = session

            downloadTask = session.downloadTask(with: request)
            downloadTask?.resume()
        }
    }
    
    /// Cancel ongoing download
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        downloadSession?.invalidateAndCancel()
        downloadSession = nil
        downloadContinuation?.resume(throwing: CancellationError())
        downloadContinuation = nil
        modelDownloadProgress = 0.0
    }

    /// Called by the delegate when download finishes successfully
    fileprivate func downloadDidComplete() {
        downloadContinuation?.resume()
        downloadContinuation = nil
    }

    /// Called by the delegate when download fails
    fileprivate func downloadDidFail(_ error: Error) {
        downloadContinuation?.resume(throwing: error)
        downloadContinuation = nil
    }
    
    // MARK: - Model Loading
    
    /// Load the model into memory for inference
    func loadModel() throws {
        guard isModelDownloaded, let modelPath = modelPath else {
            throw ModelError.modelNotDownloaded
        }

        print("📦 Loading model from: \(modelPath.path)")

        guard let model = LLM(from: modelPath, template: .chatML(systemPrompt), historyLimit: 6, maxTokenCount: 2048) else {
            throw ModelError.modelNotLoaded
        }

        llm = model
        isModelLoaded = true
        print("✅ Model loaded successfully")
    }
    
    /// Unload model from memory
    func unloadModel() {
        llm = nil
        isModelLoaded = false
        print("🗑️ Model unloaded")
    }
    
    // MARK: - Inference
    
    /// Generate a response from the model
    func generateResponse(userMessage: String, conversationHistory: [ChatMessage], healthContext: String? = nil, sourceContext: String? = nil) async throws -> String {
        guard isModelLoaded, let llm = llm else {
            throw ModelError.modelNotLoaded
        }

        print("🤖 Generating response...")

        // Build prompt: source context + user message (keep it short for the 4B model)
        let trimmedMessage = String(userMessage.prefix(500))
        var prompt = trimmedMessage

        if let source = sourceContext, !source.isEmpty {
            prompt = "\(source)\n\n\(trimmedMessage)"
        }

        // LLM.swift manages conversation history internally (historyLimit: 6).
        // Do NOT call llm.reset() — it fires a non-awaited Task that races with respond().
        await llm.respond(to: prompt)

        #if DEBUG
        print("🤖 Model done, output: \(llm.output.prefix(100))")
        #endif

        var response = llm.output
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip <think>...</think> reasoning blocks (model thinking mode)
        response = ModelPostProcessor.stripThinkingTags(response)

        #if DEBUG
        // Check for empty or garbage responses
        print("🔍 Raw output (\(response.count) chars): \(String(response.prefix(200)))")
        #endif
        if response.isEmpty || response == "..." || response.count < 3 {
            print("⚠️ Empty or garbage response, resetting conversation")
            llm.reset()
            throw ModelError.inferenceError
        }

        // Post-process: enforce max 3 sentences (small models ignore prompt-based length constraints)
        response = ModelPostProcessor.truncateToSentences(response, max: 3)

        print("✅ Response generated (\(response.count) chars)")
        return response
    }
    
    // MARK: - Medication Extraction

    /// Extract structured medication info from raw OCR text using the LLM
    func extractMedicationFromOCR(_ ocrText: String) async -> ExtractedMedication {
        guard isModelLoaded, let llm = llm else {
            print("⚠️ OCR extraction skipped — model not loaded")
            return ExtractedMedication()
        }

        // Truncate OCR text to avoid overwhelming the model's context
        let truncatedOCR = String(ocrText.prefix(300))

        let prompt = """
        Extract the medication info from this scanned label text. Return ONLY these 3 lines, nothing else:
        DRUG: [medication name]
        DOSAGE: [dosage amount]
        NDC: [NDC code if found, or NONE]

        Scanned text:
        \(truncatedOCR)
        """

        #if DEBUG
        print("💊 OCR extraction prompt (\(truncatedOCR.count) chars of OCR text)")
        #endif

        llm.reset()
        // Small delay to ensure reset completes
        try? await Task.sleep(for: .milliseconds(100))

        await llm.respond(to: prompt)
        var response = llm.output.trimmingCharacters(in: .whitespacesAndNewlines)
        #if DEBUG
        print("💊 OCR raw response (\(response.count) chars): \(response.prefix(200))")
        #endif

        response = ModelPostProcessor.stripThinkingTags(response)
        #if DEBUG
        print("💊 After strip: \(response.prefix(200))")
        #endif

        llm.reset()

        let result = ModelPostProcessor.parseExtraction(response)
        #if DEBUG
        print("💊 Extracted: name='\(result.name)' dosage='\(result.dosage)' ndc='\(result.ndc)'")
        #endif
        return result
    }

    // Post-processing methods are now in ModelPostProcessor (shared with Foundation Models)

    // MARK: - Conversation Management

    /// Reset the LLM's internal conversation history for a fresh chat
    func resetConversation() {
        llm?.reset()
    }

    // MARK: - Cleanup

    deinit {
        // Note: Can't call @MainActor methods in deinit
        // Model cleanup will happen automatically when the object is deallocated
        print("🗑️ LocalModelService deinitialized")
    }
}

// MARK: - Download Delegate

private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    weak var service: LocalModelService?
    let destinationPath: URL

    init(service: LocalModelService, destinationPath: URL) {
        self.service = service
        self.destinationPath = destinationPath
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        Task { @MainActor in
            self.service?.modelDownloadProgress = progress
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            if FileManager.default.fileExists(atPath: destinationPath.path) {
                try FileManager.default.removeItem(at: destinationPath)
            }
            try FileManager.default.moveItem(at: location, to: destinationPath)
            Task { @MainActor in
                self.service?.isModelDownloaded = true
                self.service?.modelDownloadProgress = 1.0
                self.service?.downloadDidComplete()
                print("✅ Model downloaded successfully")
            }
        } catch {
            Task { @MainActor in
                self.service?.downloadError = error.localizedDescription
                self.service?.downloadDidFail(error)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        guard let error else { return }
        Task { @MainActor in
            self.service?.downloadError = error.localizedDescription
            self.service?.downloadDidFail(error)
        }
    }
}

// MARK: - Errors

enum ModelError: LocalizedError {
    case invalidPath
    case modelNotDownloaded
    case modelNotLoaded
    case downloadFailed
    case inferenceError
    
    var errorDescription: String? {
        switch self {
        case .invalidPath:
            return "No se pudo encontrar la ruta de documentos"
        case .modelNotDownloaded:
            return "El modelo no está descargado. Por favor descarga el modelo primero."
        case .modelNotLoaded:
            return "El modelo no está cargado en memoria. Por favor carga el modelo primero."
        case .downloadFailed:
            return "La descarga del modelo falló"
        case .inferenceError:
            return "Error al generar respuesta"
        }
    }
}
