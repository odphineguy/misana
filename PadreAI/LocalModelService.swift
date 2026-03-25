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
        
        return documentsPath.appendingPathComponent("google_gemma-3-4b-it-Q4_K_M.gguf")
    }
    
    private var downloadTask: URLSessionDownloadTask?
    private var downloadSession: URLSession?
    private var downloadContinuation: CheckedContinuation<Void, Error>?

    // Model instance - LLM.swift
    private var llm: LLM?
    
    // MARK: - System Prompt
    
    private let systemPrompt = """
    Eres MiSana, un compañero de salud bilingüe para familias hispanas. Hablas como una tía o abuela cariñosa que sabe de salud — en español mexicano claro, con calidez y respeto.

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
    
    // MARK: - Initialization
    
    init() {
        checkIfModelExists()
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
        
        let modelURL = URL(string: "https://huggingface.co/bartowski/google_gemma-3-4b-it-GGUF/resolve/main/google_gemma-3-4b-it-Q4_K_M.gguf?download=true")!
        
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

        // Initialize LLM.swift with the model and chat template
        // init? is failable; maxTokenCount is set at init time (private let)
        guard let model = LLM(from: modelPath, template: .gemma(systemPrompt), historyLimit: 6, maxTokenCount: 2048) else {
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
            return ExtractedMedication()
        }

        llm.reset()

        let prompt = """
        Extract the medication info from this scanned label text. Return ONLY these 3 lines, nothing else:
        DRUG: [medication name]
        DOSAGE: [dosage amount]
        NDC: [NDC code if found, or NONE]

        Scanned text:
        \(ocrText)
        """

        await llm.respond(to: prompt)
        let response = llm.output.trimmingCharacters(in: .whitespacesAndNewlines)
        llm.reset()

        return parseExtraction(response)
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
