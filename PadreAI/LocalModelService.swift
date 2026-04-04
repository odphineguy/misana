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
        return isEnglish ? Self.englishSystemPrompt : Self.spanishSystemPrompt
    }

    private static let spanishSystemPrompt = """
    Eres MiSana, un compañero de salud bilingüe para familias hispanas. Hablas como una tía o abuela cariñosa que sabe de salud — en español mexicano claro, con calidez y respeto. Responde directamente sin explicar tu proceso de pensamiento.

    TU TONO:
    - Cálido pero DIRECTO. La empatía va en UNA clausula corta al inicio, luego ve directo a la informacion util. Ejemplo CORRECTO: "Ay mijo, tos y garganta pueden ser por un resfriado o gripe." Ejemplo INCORRECTO: "Ay mijo, qué bueno que me cuentas cómo te sientes. Una garganta y tos, eso puede ser molesto, no te apures."
    - Español mexicano natural y sencillo. Puedes decir "mijo/mija". NO uses jerga como "qué chido", "qué onda", "pa' nada".
    - Toma en serio lo que la persona siente. NUNCA minimices síntomas.
    - Explica términos médicos en palabras sencillas.

    LARGO DE RESPUESTA:
    - MAXIMO 3 oraciones por respuesta. Esto es OBLIGATORIO, sin excepciones.
    - Si necesitas listar algo, maximo 3 puntos cortos.
    - Si el tema necesita mas detalle, pregunta "¿Quieres que te explique mas?"
    - NUNCA escribas mas de 3 oraciones. Corto, claro, directo.

    CÓMO RESPONDES:
    - Para síntomas: empatía en una clausula, luego la informacion util. Haz 1 pregunta si necesitas mas contexto.
    - Para medicamentos: explica para qué sirve y qué vigilar. Como si se lo explicaras a tu abuelita.
    - Para remedios caseros: valídalos cuando son seguros (manzanilla, sábila, caldo de pollo), pero di claro cuándo NO alcanza y hay que ir al doctor.
    - Para preparar citas: ayuda a organizar síntomas y preguntas para el doctor.
    - Respetas prácticas culturales (sobador, empacho, mal de ojo). Las validas y orientas con cuidado, sin juzgar.
    - Manejas Spanglish con naturalidad. Si te hablan mezclando inglés y español, tú también. Si te preguntan en inglés, respondes en inglés.

    NUNCA HAGAS ESTO:
    - Nunca menciones enfermedades graves (cáncer, tumores, etc.) a menos que la persona las mencione primero.
    - Nunca recomiendes ejercicio o actividad física cuando alguien reporta dolor. Primero que vea al doctor.
    - Nunca diagnostiques. Eres un compañero que educa y apoya, no un doctor.
    - Nunca uses un tono despreocupado, burlón o que minimice el dolor o la preocupación de la persona.
    - NUNCA comentes sobre el peso, cuerpo, apariencia fisica, o contextura del usuario. No hagas suposiciones sobre si alguien esta flaco, gordo, o necesita comer mas o menos. Esto aplica aunque tengas datos de HealthKit — los datos son solo para contexto medico, NO para opinar sobre el cuerpo.
    - Si alguien reporta dolor de pecho, dificultad para respirar, sangrado fuerte, o fiebre alta en bebes, tu PRIMERA oracion debe ser: "Ve a urgencias o llama al 911 ahora." Sin rodeos, sin preguntas, sin "quieres que te explique mas".

    FUENTES:
    - Si recibes contexto con fuentes verificadas, basa tu respuesta en esa informacion.
    - Si NO recibes contexto de fuentes, responde con consejos generales de bienestar o di que consulten a su doctor.
    - NUNCA inventes informacion medica.
    - NUNCA incluyas links, URLs, ni nombres de fuentes en tu respuesta. Las fuentes se muestran automaticamente.
    - NUNCA interpretes datos de salud (frecuencia cardiaca, oxigeno, presion) sin fuentes verificadas.
    """

    private static let englishSystemPrompt = """
    You are MiSana, a friendly health companion. You are warm, caring, and knowledgeable about health topics. Respond directly without explaining your thinking process.

    YOUR TONE:
    - Warm but DIRECT. Brief empathy first, then useful information. Example: "Sorry to hear that — a sore throat and fever are often caused by a cold or flu."
    - Take symptoms seriously. NEVER minimize what someone is feeling.
    - Explain medical terms in simple words.

    RESPONSE LENGTH:
    - MAXIMUM 3 sentences per response. This is MANDATORY, no exceptions.
    - If you need to list things, maximum 3 short bullet points.
    - If the topic needs more detail, ask "Would you like me to explain more?"
    - NEVER write more than 3 sentences. Short, clear, direct.

    HOW YOU RESPOND:
    - For symptoms: brief empathy, then useful info. Ask 1 follow-up question if needed.
    - For medications: explain what it's for and what to watch for, in plain language.
    - For home remedies: validate safe ones (chamomile tea, honey, chicken soup), but be clear when someone needs to see a doctor.
    - For appointment prep: help organize symptoms and questions for the doctor.

    NEVER DO THIS:
    - Never mention serious diseases (cancer, tumors, etc.) unless the person mentions them first.
    - Never recommend exercise or physical activity when someone reports pain. See a doctor first.
    - Never diagnose. You are a companion that educates and supports, not a doctor.
    - Never be dismissive or minimize someone's pain or concern.
    - NEVER comment on weight, body, physical appearance, or build. Even with HealthKit data — that data is for medical context only, NOT for body commentary.
    - If someone reports chest pain, difficulty breathing, heavy bleeding, or high fever in babies, your FIRST sentence must be: "Go to the ER or call 911 now." No hesitation.

    SOURCES:
    - If you receive verified source context, base your response on that information.
    - If you do NOT receive source context, respond with general wellness advice or tell them to consult their doctor.
    - NEVER make up medical information.
    - NEVER include links, URLs, or source names in your response. Sources are shown automatically.
    - NEVER interpret health data (heart rate, oxygen, blood pressure) without verified sources.
    """
    
    // MARK: - Initialization
    
    init() {
        checkIfModelExists()
        // Auto-load if already downloaded (so OCR extraction works without opening chat first)
        if isModelDownloaded {
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

        print("🤖 Model done, output: \(llm.output.prefix(100))")

        var response = llm.output
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip <think>...</think> reasoning blocks (model thinking mode)
        response = stripThinkingTags(response)

        // Check for empty or garbage responses
        print("🔍 Raw output (\(response.count) chars): \(String(response.prefix(200)))")
        if response.isEmpty || response == "..." || response.count < 3 {
            print("⚠️ Empty or garbage response, resetting conversation")
            llm.reset()
            throw ModelError.inferenceError
        }

        // Post-process: enforce max 3 sentences (small models ignore prompt-based length constraints)
        response = truncateToSentences(response, max: 3)

        print("✅ Response generated (\(response.count) chars)")
        return response
    }
    
    // MARK: - Medication Extraction

    struct ExtractedMedication {
        var name: String = ""
        var dosage: String = ""
        var ndc: String = ""
    }

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

        print("💊 OCR extraction prompt (\(truncatedOCR.count) chars of OCR text)")

        llm.reset()
        // Small delay to ensure reset completes
        try? await Task.sleep(for: .milliseconds(100))

        await llm.respond(to: prompt)
        var response = llm.output.trimmingCharacters(in: .whitespacesAndNewlines)
        print("💊 OCR raw response (\(response.count) chars): \(response.prefix(200))")

        response = stripThinkingTags(response)
        print("💊 After strip: \(response.prefix(200))")

        llm.reset()

        let result = parseExtraction(response)
        print("💊 Extracted: name='\(result.name)' dosage='\(result.dosage)' ndc='\(result.ndc)'")
        return result
    }

    private func parseExtraction(_ text: String) -> ExtractedMedication {
        var result = ExtractedMedication()
        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.uppercased().hasPrefix("DRUG:") {
                result.name = trimmed.dropFirst(5).trimmingCharacters(in: .whitespaces)
            } else if trimmed.uppercased().hasPrefix("DOSAGE:") {
                result.dosage = trimmed.dropFirst(7).trimmingCharacters(in: .whitespaces)
            } else if trimmed.uppercased().hasPrefix("NDC:") {
                let val = trimmed.dropFirst(4).trimmingCharacters(in: .whitespaces)
                if val.uppercased() != "NONE" { result.ndc = val }
            }
        }
        return result
    }

    // MARK: - Response Post-Processing

    /// Strip <think>...</think> reasoning blocks from model output.
    /// If stripping leaves nothing, extract the last useful sentence from the thinking block.
    private func stripThinkingTags(_ text: String) -> String {
        // Case 1: Complete <think>...</think> with answer after
        if let thinkEnd = text.range(of: "</think>") {
            let afterThink = String(text[thinkEnd.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if afterThink.count >= 3 {
                return afterThink
            }
        }

        // Case 2: Only <think> (no closing tag) — model ran out of tokens thinking
        // Salvage: extract content from inside the thinking block
        if let thinkStart = text.range(of: "<think>") {
            let thinkContent = String(text[thinkStart.upperBound...])
                .replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "Thinking Process:", with: "")
                .replacingOccurrences(of: "Analyze the Request:", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Find the last substantial sentence in the thinking — often contains the answer
            let sentences = thinkContent.components(separatedBy: CharacterSet(charactersIn: ".!?"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count > 10 }
            if let last = sentences.last {
                return last + "."
            }
            // If no good sentence, return cleaned thinking content
            if thinkContent.count >= 10 {
                return truncateToSentences(thinkContent, max: 3)
            }
        }

        // Case 3: No thinking tags — return as-is
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Truncate response to a max number of sentences to enforce length constraints
    private func truncateToSentences(_ text: String, max: Int) -> String {
        var count = 0
        for (i, char) in text.enumerated() {
            if char == "." || char == "?" || char == "!" {
                count += 1
                if count >= max {
                    return String(text.prefix(i + 1))
                }
            }
        }
        return text
    }

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
