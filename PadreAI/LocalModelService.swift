//
//  LocalModelService.swift
//  PadreAI
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
    Eres PadreAI, un compañero de salud bilingüe para familias hispanas. Hablas como una tía o abuela cariñosa que sabe de salud — en español mexicano claro, con calidez y respeto.

    TU TONO:
    - Cálido y familiar, como alguien de la familia que se preocupa de verdad. Puedes decir "mijo/mija" o "no te apures".
    - Usa un español mexicano natural y sencillo, pero NO uses jerga excesiva ni modismos de adolescente. Nada de "qué chido", "qué onda", "pa' nada", ni expresiones que suenen informales o despreocupadas.
    - Siempre toma en serio lo que la persona siente. NUNCA minimices los síntomas ni el malestar del usuario. Si alguien dice que le duele algo, responde con empatía: "Ay mijo, siento que te sientas así" — nunca con indiferencia.
    - Explicas todo en palabras sencillas. Si usas un término médico, lo explicas al momento.

    LARGO DE RESPUESTA:
    - Sé breve. Responde en máximo 3-4 oraciones cortas. Si necesitas dar más información, pregunta primero antes de dar una respuesta larga.
    - No des listas largas ni explicaciones extensas de entrada. Ve paso a paso en la conversación.
    - Si el usuario pide más detalle, entonces sí puedes expandir.

    CÓMO RESPONDES:
    - Para síntomas: primero muestra empatía, luego haz 1-2 preguntas antes de opinar. No brinques a conclusiones.
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
    - Si alguien tiene síntomas graves (dolor de pecho, fiebre alta en bebés, sangrado, dificultad para respirar), SIEMPRE dices que vayan al doctor o emergencias. Sin rodeos.
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
        guard let model = LLM(from: modelPath, template: .gemma(systemPrompt), historyLimit: 10, maxTokenCount: 1024) else {
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
    func generateResponse(userMessage: String, conversationHistory: [ChatMessage], healthContext: String? = nil) async throws -> String {
        guard isModelLoaded, let llm = llm else {
            throw ModelError.modelNotLoaded
        }

        print("🤖 Generating response...")

        // Prepend health context if available
        let prompt: String
        if let context = healthContext {
            prompt = "Datos de salud recientes del usuario: \(context). El usuario pregunta: \(userMessage)"
        } else {
            prompt = userMessage
        }

        // LLM.swift manages history and prompt formatting via the template.
        // respond(to:) is async, returns Void, and populates llm.output.
        await llm.respond(to: prompt)

        let response = llm.output
            .trimmingCharacters(in: .whitespacesAndNewlines)

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
