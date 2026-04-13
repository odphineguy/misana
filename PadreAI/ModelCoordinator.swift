//
//  ModelCoordinator.swift
//  MiSana
//
//  Created by Abe Perez on 4/12/26.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Shared System Prompts

/// System prompts shared between Qwen and Foundation Models engines
enum ModelPrompts {

    static let spanish = """
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
    - NUNCA recomiendes medicamentos específicos por nombre (ni marcas como Tylenol, Advil, etc. ni nombres genéricos como acetaminofén, ibuprofeno, etc.) a menos que la información venga de una fuente verificada. En su lugar di "pregúntale a tu doctor o farmacéutico sobre opciones sin receta."
    - Si alguien reporta dolor de pecho, dificultad para respirar, sangrado fuerte, o fiebre alta en bebes, tu PRIMERA oracion debe ser: "Ve a urgencias o llama al 911 ahora." Sin rodeos, sin preguntas, sin "quieres que te explique mas".

    FUENTES:
    - Si recibes contexto con fuentes verificadas, basa tu respuesta en esa informacion.
    - Si NO recibes contexto de fuentes, responde con consejos generales de bienestar o di que consulten a su doctor.
    - NUNCA inventes informacion medica.
    - NUNCA incluyas links, URLs, ni nombres de fuentes en tu respuesta. Las fuentes se muestran automaticamente.
    - NUNCA interpretes datos de salud (frecuencia cardiaca, oxigeno, presion) sin fuentes verificadas.
    """

    static let english = """
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
    - NEVER recommend specific medications by name (no brand names like Tylenol, Advil, etc. and no drug names like acetaminophen, ibuprofen, etc.) unless the information comes from a verified source provided to you. Instead say "ask your doctor or pharmacist about over-the-counter options."
    - If someone reports chest pain, difficulty breathing, heavy bleeding, or high fever in babies, your FIRST sentence must be: "Go to the ER or call 911 now." No hesitation.

    SOURCES:
    - If you receive verified source context, base your response on that information.
    - If you do NOT receive source context, respond with general wellness advice or tell them to consult their doctor.
    - NEVER make up medical information.
    - NEVER include links, URLs, or source names in your response. Sources are shown automatically.
    - NEVER interpret health data (heart rate, oxygen, blood pressure) without verified sources.
    """
}

// MARK: - Shared Post-Processing

/// Post-processing utilities shared between Qwen and Foundation Models engines
enum ModelPostProcessor {

    /// Truncate response to a max number of sentences to enforce length constraints
    static func truncateToSentences(_ text: String, max: Int) -> String {
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

    /// Strip <think>...</think> reasoning blocks from model output
    static func stripThinkingTags(_ text: String) -> String {
        // Case 1: Complete <think>...</think> with answer after
        if let thinkEnd = text.range(of: "</think>") {
            let afterThink = String(text[thinkEnd.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if afterThink.count >= 3 {
                return afterThink
            }
        }

        // Case 2: Only <think> (no closing tag) — model ran out of tokens thinking
        if let thinkStart = text.range(of: "<think>") {
            let thinkContent = String(text[thinkStart.upperBound...])
                .replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "Thinking Process:", with: "")
                .replacingOccurrences(of: "Analyze the Request:", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let sentences = thinkContent.components(separatedBy: CharacterSet(charactersIn: ".!?"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count > 10 }
            if let last = sentences.last {
                return last + "."
            }
            if thinkContent.count >= 10 {
                return truncateToSentences(thinkContent, max: 3)
            }
        }

        // Case 3: No thinking tags — return as-is
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Parse structured medication extraction from LLM response
    static func parseExtraction(_ text: String) -> ExtractedMedication {
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
}

// MARK: - Shared Types

/// Extracted medication info from OCR scan
struct ExtractedMedication {
    var name: String = ""
    var dosage: String = ""
    var ndc: String = ""
}

// MARK: - Model Coordinator

/// Central coordinator that manages both AI engines (Apple Foundation Models and Qwen).
/// This is the single `@EnvironmentObject` that all views use.
@MainActor
class ModelCoordinator: ObservableObject {

    // MARK: - Engine Selection

    enum ModelEngine: String, CaseIterable, Identifiable {
        case foundation = "Apple AI"
        case qwen = "Qwen 3"

        var id: String { rawValue }
    }

    @Published var activeEngine: ModelEngine = .qwen {
        didSet {
            UserDefaults.standard.set(activeEngine.rawValue, forKey: "selectedModelEngine")
            // Lazy-load Qwen if switching to it and it wasn't loaded yet
            if activeEngine == .qwen && qwenService.isModelDownloaded && !qwenService.isModelLoaded {
                try? qwenService.loadModel()
            }
            syncState()
        }
    }

    // MARK: - Published State (mirrors active engine)

    @Published var isModelDownloaded: Bool = false
    @Published var isModelLoaded: Bool = false
    @Published var modelDownloadProgress: Double = 0.0
    @Published var downloadError: String?
    @Published var isFoundationAvailable: Bool = false

    // MARK: - Services

    let qwenService: LocalModelService

    #if canImport(FoundationModels)
    private var _foundationService: AnyObject?
    @available(iOS 26, *)
    var foundationService: FoundationModelService? {
        _foundationService as? FoundationModelService
    }
    #endif

    // MARK: - Observation

    private var qwenObservers: [NSKeyValueObservation] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        // Check Foundation Models availability first (before deciding whether to load Qwen)
        var foundationAvailable = false
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            let service = FoundationModelService()
            _foundationService = service
            foundationAvailable = service.isAvailable
        }
        #endif
        isFoundationAvailable = foundationAvailable

        // If Foundation is available, defer Qwen loading to avoid blocking the main thread
        qwenService = LocalModelService(deferLoading: foundationAvailable)

        // Restore saved engine preference, or auto-select
        if let savedEngine = UserDefaults.standard.string(forKey: "selectedModelEngine"),
           let engine = ModelEngine(rawValue: savedEngine) {
            // Only use saved Foundation preference if still available
            if engine == .foundation && !isFoundationAvailable {
                activeEngine = .qwen
            } else {
                activeEngine = engine
            }
        } else {
            // First launch: prefer Foundation if available
            activeEngine = isFoundationAvailable ? .foundation : .qwen
        }

        observeQwenState()
        syncState()

        // Log which engine is active
        print("🧠 ModelCoordinator initialized")
        print("🧠 Foundation Models available: \(isFoundationAvailable)")
        print("🧠 Active engine: \(activeEngine.rawValue)")
        print("🧠 Qwen downloaded: \(qwenService.isModelDownloaded)")
    }

    // MARK: - State Sync

    /// Sync published state from the active engine
    func syncState() {
        switch activeEngine {
        case .foundation:
            #if canImport(FoundationModels)
            if #available(iOS 26, *), let fm = foundationService, fm.isAvailable {
                isModelDownloaded = true
                isModelLoaded = true
                modelDownloadProgress = 1.0
                downloadError = nil
                return
            }
            #endif
            // Foundation not actually available — fall back
            activeEngine = .qwen
            syncState()

        case .qwen:
            isModelDownloaded = qwenService.isModelDownloaded
            isModelLoaded = qwenService.isModelLoaded
            modelDownloadProgress = qwenService.modelDownloadProgress
            downloadError = qwenService.downloadError
        }
    }

    /// Observe Qwen service state changes and forward them
    private func observeQwenState() {
        qwenService.$isModelDownloaded
            .receive(on: RunLoop.main)
            .sink { [weak self] val in
                guard let self, self.activeEngine == .qwen else { return }
                self.isModelDownloaded = val
            }
            .store(in: &cancellables)

        qwenService.$isModelLoaded
            .receive(on: RunLoop.main)
            .sink { [weak self] val in
                guard let self, self.activeEngine == .qwen else { return }
                self.isModelLoaded = val
            }
            .store(in: &cancellables)

        qwenService.$modelDownloadProgress
            .receive(on: RunLoop.main)
            .sink { [weak self] val in
                guard let self, self.activeEngine == .qwen else { return }
                self.modelDownloadProgress = val
            }
            .store(in: &cancellables)

        qwenService.$downloadError
            .receive(on: RunLoop.main)
            .sink { [weak self] val in
                guard let self, self.activeEngine == .qwen else { return }
                self.downloadError = val
            }
            .store(in: &cancellables)
    }

    // MARK: - Delegated Methods

    func downloadModel() async throws {
        try await qwenService.downloadModel()
    }

    func loadModel() throws {
        try qwenService.loadModel()
        syncState()
    }

    func unloadModel() {
        qwenService.unloadModel()
        syncState()
    }

    func cancelDownload() {
        qwenService.cancelDownload()
    }

    func checkIfModelExists() {
        qwenService.checkIfModelExists()
        syncState()
    }

    func generateResponse(
        userMessage: String,
        conversationHistory: [ChatMessage],
        healthContext: String? = nil,
        sourceContext: String? = nil
    ) async throws -> String {
        switch activeEngine {
        case .foundation:
            #if canImport(FoundationModels)
            if #available(iOS 26, *), let fm = foundationService {
                return try await fm.generateResponse(
                    userMessage: userMessage,
                    conversationHistory: conversationHistory,
                    healthContext: healthContext,
                    sourceContext: sourceContext
                )
            }
            #endif
            throw ModelError.modelNotLoaded

        case .qwen:
            return try await qwenService.generateResponse(
                userMessage: userMessage,
                conversationHistory: conversationHistory,
                healthContext: healthContext,
                sourceContext: sourceContext
            )
        }
    }

    func extractMedicationFromOCR(_ ocrText: String) async -> ExtractedMedication {
        switch activeEngine {
        case .foundation:
            #if canImport(FoundationModels)
            if #available(iOS 26, *), let fm = foundationService {
                return await fm.extractMedicationFromOCR(ocrText)
            }
            #endif
            return ExtractedMedication()

        case .qwen:
            return await qwenService.extractMedicationFromOCR(ocrText)
        }
    }

    func resetConversation() {
        switch activeEngine {
        case .foundation:
            #if canImport(FoundationModels)
            if #available(iOS 26, *) {
                foundationService?.resetConversation()
            }
            #endif
        case .qwen:
            qwenService.resetConversation()
        }
    }
}
