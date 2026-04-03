//
//  MedicationView.swift
//  MiSana
//
//  Created by Abe Perez on 3/11/26.
//

import SwiftUI
import VisionKit
import Vision

// MARK: - Model

enum MedicationType: String, Codable, CaseIterable {
    case tablet, capsule, liquid, cream, injection, drops, inhaler, patch

    var icon: String {
        switch self {
        case .tablet: return "pill.fill"
        case .capsule: return "capsule.fill"
        case .liquid: return "drop.fill"
        case .cream: return "hand.point.up.fill"
        case .injection: return "syringe.fill"
        case .drops: return "drop.circle.fill"
        case .inhaler: return "wind"
        case .patch: return "bandage.fill"
        }
    }

    func label(for lang: AppLanguage) -> String {
        switch self {
        case .tablet: return lang == .spanish ? "Tableta" : "Tablet"
        case .capsule: return lang == .spanish ? "Cápsula" : "Capsule"
        case .liquid: return lang == .spanish ? "Líquido" : "Liquid"
        case .cream: return lang == .spanish ? "Crema" : "Cream"
        case .injection: return lang == .spanish ? "Inyección" : "Injection"
        case .drops: return lang == .spanish ? "Gotas" : "Drops"
        case .inhaler: return lang == .spanish ? "Inhalador" : "Inhaler"
        case .patch: return lang == .spanish ? "Parche" : "Patch"
        }
    }
}

enum PillShape: String, Codable, CaseIterable {
    case round, oval, capsule, rectangle, diamond, triangle

    var icon: String {
        switch self {
        case .round: return "circle.fill"
        case .oval: return "oval.fill"
        case .capsule: return "capsule.fill"
        case .rectangle: return "rectangle.fill"
        case .diamond: return "diamond.fill"
        case .triangle: return "triangle.fill"
        }
    }
}

enum PillColor: String, Codable, CaseIterable {
    case white, cream, yellow, orange, pink, red, blue, green, purple, brown

    var color: Color {
        switch self {
        case .white: return .white
        case .cream: return Color(red: 0.96, green: 0.93, blue: 0.82)
        case .yellow: return .yellow
        case .orange: return .orange
        case .pink: return .pink
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .brown: return .brown
        }
    }
}

enum MedFrequency: String, Codable, CaseIterable {
    case daily, twiceDaily, threeTimesDaily, everyOtherDay, weekly, asNeeded

    func label(for lang: AppLanguage) -> String {
        switch self {
        case .daily: return lang == .spanish ? "Cada día" : "Every day"
        case .twiceDaily: return lang == .spanish ? "2 veces al día" : "Twice daily"
        case .threeTimesDaily: return lang == .spanish ? "3 veces al día" : "3 times daily"
        case .everyOtherDay: return lang == .spanish ? "Cada tercer día" : "Every other day"
        case .weekly: return lang == .spanish ? "Cada semana" : "Weekly"
        case .asNeeded: return lang == .spanish ? "Según necesite" : "As needed"
        }
    }
}

struct Medication: Identifiable, Codable {
    var id = UUID()
    let name: String
    let dosage: String
    let frequency: String
    let instructions: String
    var rxcui: String?
    var type: MedicationType?
    var shape: PillShape?
    var pillColor: PillColor?
    var scheduleFrequency: MedFrequency?
    var scheduleTime: Date?
}

// MARK: - Main View

struct MedicationView: View {
    let selectedLanguage: AppLanguage
    @EnvironmentObject private var modelService: LocalModelService
    @State private var medications: [Medication] = []
    @State private var showingScanChoice = false
    @State private var showingAddSheet = false
    @State private var showingDocumentScanner = false
    @State private var showingBarcodeScanner = false
    @State private var isProcessingScan = false
    @State private var scannedText: String = ""
    @State private var prefillName: String = ""
    @State private var prefillDosage: String = ""
    @State private var prefillRxcui: String?
    @StateObject private var drugService = DrugLookupService()

    private var medicationsFileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("medications.json")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if medications.isEmpty {
                    emptyStateView
                } else {
                    medicationListView
                }
            }
            .navigationTitle(selectedLanguage == .spanish ? "Medicinas" : "Medications")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingScanChoice = true
                    } label: {
                        Label(
                            selectedLanguage == .spanish ? "Escanear" : "Scan",
                            systemImage: "camera.fill"
                        )
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        scannedText = ""
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .confirmationDialog(
                selectedLanguage == .spanish ? "Escanear medicamento" : "Scan medication",
                isPresented: $showingScanChoice,
                titleVisibility: .visible
            ) {
                Button(selectedLanguage == .spanish ? "Escanear etiqueta con cámara" : "Scan label with camera") {
                    showingDocumentScanner = true
                }
                Button(selectedLanguage == .spanish ? "Escanear código de barras" : "Scan barcode") {
                    showingBarcodeScanner = true
                }
            }
            .fullScreenCover(isPresented: $showingDocumentScanner) {
                DocumentScannerView(
                    onScan: { images in
                        showingDocumentScanner = false
                        Task { await processScannedImages(images) }
                    },
                    onCancel: { showingDocumentScanner = false }
                )
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView(
                    onBarcodeFound: { barcode in
                        showingBarcodeScanner = false
                        Task { await processBarcodeResult(barcode) }
                    },
                    onCancel: { showingBarcodeScanner = false }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showingAddSheet) {
                AddMedicationView(
                    selectedLanguage: selectedLanguage,
                    scannedText: scannedText,
                    prefillName: prefillName,
                    prefillDosage: prefillDosage,
                    prefillRxcui: prefillRxcui,
                    drugService: drugService,
                    onSave: { medication in
                        medications.append(medication)
                        saveMedications()
                        showingAddSheet = false
                        refreshInteractions()
                    }
                )
            }
            .overlay {
                if isProcessingScan {
                    ZStack {
                        Color.black.opacity(0.15)
                            .ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .controlSize(.large)
                            Text(selectedLanguage == .spanish ?
                                 "Analizando etiqueta..." :
                                 "Analyzing label...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(32)
                        .liquidGlass(cornerRadius: 20)
                    }
                }
            }
            .onAppear { loadMedications() }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "pill.circle")
                .font(.system(size: 64))
                .foregroundStyle(.brand)

            Text(selectedLanguage == .spanish ? "No hay medicinas" : "No medications")
                .font(.title2)
                .fontWeight(.semibold)

            Text(selectedLanguage == .spanish ?
                 "Escanea una receta o añade una medicina manualmente" :
                 "Scan a prescription or add a medication manually")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            HStack(spacing: 12) {
                Button {
                    showingScanChoice = true
                } label: {
                    Label(
                        selectedLanguage == .spanish ? "Escanear" : "Scan",
                        systemImage: "camera.fill"
                    )
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    clearPrefills()
                    showingAddSheet = true
                } label: {
                    Label(
                        selectedLanguage == .spanish ? "Añadir" : "Add",
                        systemImage: "plus"
                    )
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.brand)
                    .padding()
                    .background(Color.brand.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Medication List

    private var medicationListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Interaction Warning Banner
                if !drugService.interactions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.white)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selectedLanguage == .spanish ?
                                     "Alerta de Interaccion" :
                                     "Interaction Warning")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                Text(selectedLanguage == .spanish ?
                                     "ALERTA DE INTERACCION" :
                                     "INTERACTION WARNING")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            Spacer()
                        }
                        ForEach(drugService.interactions) { interaction in
                            Text("\(interaction.drug1Name) + \(interaction.drug2Name): \(interaction.description)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.9))
                                .lineLimit(2)
                        }
                        Link(destination: URL(string: "https://rxnav.nlm.nih.gov/")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.system(size: 9))
                                Text(selectedLanguage == .spanish ?
                                     "Fuente: RxNorm (NIH)" :
                                     "Source: RxNorm (NIH)")
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding()
                    .background(Color.red.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                // Network Error Banner
                if drugService.interactionCheckFailed && medications.count >= 2 {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.exclamationmark")
                            .foregroundStyle(.orange)
                        Text(selectedLanguage == .spanish ?
                             "No se pudo verificar interacciones. Revisa tu conexión." :
                             "Could not check interactions. Check your connection.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            refreshInteractions()
                        } label: {
                            Text(selectedLanguage == .spanish ? "Reintentar" : "Retry")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.brand)
                        }
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Medication Cards
                ForEach(medications) { medication in
                    NavigationLink {
                        MedicationDetailView(
                            medication: medication,
                            selectedLanguage: selectedLanguage,
                            drugService: drugService
                        )
                    } label: {
                        MedicationCardView(medication: medication, selectedLanguage: selectedLanguage)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            if let idx = medications.firstIndex(where: { $0.id == medication.id }) {
                                medications.remove(at: idx)
                                saveMedications()
                                refreshInteractions()
                            }
                        } label: {
                            Label(selectedLanguage == .spanish ? "Eliminar" : "Delete", systemImage: "trash")
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    // MARK: - OCR / Vision

    private func processScannedImages(_ images: [UIImage]) async {
        isProcessingScan = true

        // Step 1: OCR
        var allText = ""
        for image in images {
            guard let cgImage = image.cgImage else { continue }
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["es", "en"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])

            if let observations = request.results {
                for observation in observations {
                    if let text = observation.topCandidates(1).first?.string {
                        allText += text + "\n"
                    }
                }
            }
        }

        let ocrText = allText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ocrText.isEmpty else {
            await MainActor.run { isProcessingScan = false }
            return
        }

        // Step 2: LLM extraction
        let extracted = await modelService.extractMedicationFromOCR(ocrText)
        scannedText = ocrText

        // Step 3: NDC → RxCUI lookup (if NDC found)
        var rxcui: String?
        if !extracted.ndc.isEmpty {
            if let result = await drugService.lookupByNDC(ndc: extracted.ndc) {
                rxcui = result.rxcui
                drugService.cacheSearchResult(result)
            }
        }
        // Fallback: search by drug name if no NDC match
        if rxcui == nil && !extracted.name.isEmpty {
            let encoded = extracted.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? extracted.name
            if let url = URL(string: "https://rxnav.nlm.nih.gov/REST/rxcui.json?name=\(encoded)&search=2") {
                if let (data, _) = try? await URLSession.shared.data(from: url),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let group = json["idGroup"] as? [String: Any],
                   let ids = group["rxnormId"] as? [String],
                   let firstId = ids.first {
                    rxcui = firstId
                    drugService.cacheSearchResult(DrugSearchResult(rxcui: firstId, name: extracted.name))
                }
            }
        }

        // Step 4: Auto-fill form
        await MainActor.run {
            prefillName = extracted.name
            prefillDosage = extracted.dosage
            prefillRxcui = rxcui
            isProcessingScan = false
            showingAddSheet = true
        }
    }

    // MARK: - Barcode Lookup

    private func processBarcodeResult(_ barcode: String) async {
        isProcessingScan = true

        let candidates = extractNDCCandidates(from: barcode)

        // Try each NDC candidate against RxNorm until one matches
        for ndc in candidates {
            if let result = await drugService.lookupByNDC(ndc: ndc) {
                await MainActor.run {
                    scannedText = ""
                    prefillName = result.name
                    prefillDosage = ""
                    prefillRxcui = result.rxcui
                    drugService.cacheSearchResult(result)
                    isProcessingScan = false
                    showingAddSheet = true
                }
                return
            }
        }

        // NDC didn't match RxNorm — try OpenFDA UPC lookup (better for OTC products)
        if let result = await drugService.lookupByUPC(barcode: barcode) {
            await MainActor.run {
                scannedText = ""
                prefillName = result.name
                prefillDosage = ""
                prefillRxcui = result.rxcui.isEmpty ? nil : result.rxcui
                if !result.rxcui.isEmpty {
                    drugService.cacheSearchResult(result)
                }
                isProcessingScan = false
                showingAddSheet = true
            }
            return
        }

        // No match anywhere — show barcode for manual entry
        await MainActor.run {
            scannedText = "Barcode: \(barcode)"
            prefillName = ""
            prefillDosage = ""
            prefillRxcui = nil
            isProcessingScan = false
            showingAddSheet = true
        }
    }

    /// Extract possible NDC numbers from various pharmacy barcode formats
    /// Pharmacy barcodes (UPC-A / EAN-13) encode NDC as: packaging digit + NDC (10 digits) + check digit
    /// RxNorm expects 11-digit NDC, so we also generate all 3 zero-padded variants from any 10-digit NDC
    private func extractNDCCandidates(from barcode: String) -> [String] {
        let digits = barcode.filter(\.isNumber)
        var ndc10candidates: [String] = []

        // EAN-13 (13 digits, often starts with 0): strip leading 0 → UPC-A → strip packaging + check digit
        if digits.count == 13, digits.hasPrefix("0") {
            let upc = String(digits.dropFirst()) // 12-digit UPC-A
            let start = upc.index(upc.startIndex, offsetBy: 1)
            let end = upc.index(upc.startIndex, offsetBy: 11)
            ndc10candidates.append(String(upc[start..<end]))
        }

        // UPC-A (12 digits): strip packaging digit (first) + check digit (last)
        if digits.count == 12 {
            let start = digits.index(digits.startIndex, offsetBy: 1)
            let end = digits.index(digits.startIndex, offsetBy: 11)
            ndc10candidates.append(String(digits[start..<end]))
        }

        // Direct 10-11 digit barcode
        if digits.count == 10 {
            ndc10candidates.append(digits)
        }
        if digits.count == 11 {
            // Already 11 digits — could be the full NDC
            ndc10candidates.append(digits)
        }

        // Longer barcodes (GS1-128, DataMatrix): try slicing out NDC
        if digits.count > 13 {
            for offset in [2, 3, 4] {
                for length in [10, 11] {
                    if offset + length <= digits.count {
                        let start = digits.index(digits.startIndex, offsetBy: offset)
                        let end = digits.index(start, offsetBy: length)
                        ndc10candidates.append(String(digits[start..<end]))
                    }
                }
            }
        }

        // For every 10-digit NDC, generate all three 11-digit zero-padded variants
        // (10-digit NDC is ambiguous: could be 4-4-2, 5-3-2, or 5-4-1)
        var allCandidates: [String] = []
        for ndc in ndc10candidates {
            allCandidates.append(ndc)
            if ndc.count == 10 {
                allCandidates.append("0" + ndc)                     // 04444-4444-22 (prepend 0)
                allCandidates.append(String(ndc.prefix(5)) + "0" + String(ndc.suffix(5)))  // 55555-0333-22 (insert 0 at pos 5)
                allCandidates.append(ndc + "0")                     // 55555-4444-01 (append 0)
            }
        }

        return allCandidates
    }

    private func clearPrefills() {
        scannedText = ""
        prefillName = ""
        prefillDosage = ""
        prefillRxcui = nil
    }

    // MARK: - Persistence

    private func saveMedications() {
        guard let url = medicationsFileURL,
              let data = try? JSONEncoder().encode(medications) else { return }
        try? data.write(to: url)
    }

    private func loadMedications() {
        guard let url = medicationsFileURL,
              let data = try? Data(contentsOf: url),
              let loaded = try? JSONDecoder().decode([Medication].self, from: data) else { return }
        medications = loaded
        refreshInteractions()
    }

    private func refreshInteractions() {
        let rxcuis = medications.compactMap(\.rxcui)
        guard rxcuis.count >= 2 else {
            drugService.interactions = []
            return
        }
        Task {
            drugService.interactions = await drugService.checkInteractions(rxcuis: rxcuis)
        }
    }
}

// MARK: - Medication Row

struct MedicationCardView: View {
    let medication: Medication
    let selectedLanguage: AppLanguage

    var body: some View {
        HStack(spacing: 14) {
            // Pill icon
            ZStack {
                Circle()
                    .fill((medication.pillColor?.color ?? .brand).gradient)
                    .frame(width: 52, height: 52)
                    .shadow(color: (medication.pillColor?.color ?? .brand).opacity(0.3), radius: 4, y: 2)
                Image(systemName: medication.type?.icon ?? "pill.fill")
                    .font(.title3)
                    .foregroundStyle(medication.pillColor == .white ? .gray : .white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(medication.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Spacer()
                    // Schedule chip
                    if let freq = medication.scheduleFrequency {
                        Text(freq == .daily ? (selectedLanguage == .spanish ? "DIARIO" : "DAILY") :
                             freq.label(for: selectedLanguage).uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.brand.opacity(0.15))
                            .foregroundStyle(.brand)
                            .clipShape(Capsule())
                    }
                }

                if !medication.dosage.isEmpty || !medication.frequency.isEmpty {
                    HStack(spacing: 10) {
                        if !medication.dosage.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "pills.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                Text(medication.dosage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if let time = medication.scheduleTime {
                            HStack(spacing: 3) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                Text(time, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// Keep for backward compat with any other usage
struct MedicationRowView: View {
    let medication: Medication
    let selectedLanguage: AppLanguage
    var body: some View {
        MedicationCardView(medication: medication, selectedLanguage: selectedLanguage)
    }
}

// MARK: - Medication Detail View

struct MedicationDetailView: View {
    let medication: Medication
    let selectedLanguage: AppLanguage
    @ObservedObject var drugService: DrugLookupService
    @State private var spanishInfo: SpanishDrugInfo?
    @State private var isLoading = false

    var body: some View {
        List {
            // Pill header
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill((medication.pillColor?.color ?? .brand).gradient)
                                .frame(width: 72, height: 72)
                                .shadow(color: (medication.pillColor?.color ?? .brand).opacity(0.3), radius: 8, y: 4)
                            Image(systemName: medication.type?.icon ?? "pill.fill")
                                .font(.title)
                                .foregroundStyle(medication.pillColor == .white ? .gray : .white)
                        }
                        if let type = medication.type {
                            Text(type.label(for: selectedLanguage))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section(selectedLanguage == .spanish ? "Detalles" : "Details") {
                if !medication.dosage.isEmpty {
                    LabeledContent(selectedLanguage == .spanish ? "Dosis" : "Dosage", value: medication.dosage)
                }
                if !medication.frequency.isEmpty {
                    LabeledContent(selectedLanguage == .spanish ? "Frecuencia" : "Frequency", value: medication.frequency)
                }
                if !medication.instructions.isEmpty {
                    LabeledContent(selectedLanguage == .spanish ? "Notas" : "Notes", value: medication.instructions)
                }
            }

            if isLoading {
                Section(selectedLanguage == .spanish ? "Información en español" : "Spanish info") {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text(selectedLanguage == .spanish ? "Buscando información..." : "Looking up info...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if let info = spanishInfo {
                Section(selectedLanguage == .spanish ? "Información en español" : "Spanish info") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(info.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(info.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let url = info.url, let link = URL(string: url) {
                        Link(destination: link) {
                            Label(
                                selectedLanguage == .spanish ? "Ver más en MedlinePlus" : "Read more on MedlinePlus",
                                systemImage: "safari"
                            )
                            .font(.subheadline)
                        }
                    }
                }
            } else if medication.rxcui != nil {
                Section {
                    Text(selectedLanguage == .spanish ?
                         "No se encontró información en español para esta medicina." :
                         "No Spanish info found for this medication.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(medication.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fetchInfo() }
    }

    private func fetchInfo() {
        guard let rxcui = medication.rxcui else { return }
        if let cached = drugService.getCachedInfo(rxcui: rxcui), let info = cached.spanishInfo {
            spanishInfo = info
            return
        }
        isLoading = true
        Task {
            spanishInfo = await drugService.fetchSpanishInfo(rxcui: rxcui)
            isLoading = false
        }
    }
}

// MARK: - Add Medication Form

struct AddMedicationView: View {
    let selectedLanguage: AppLanguage
    let scannedText: String
    let prefillName: String
    let prefillDosage: String
    let prefillRxcui: String?
    @ObservedObject var drugService: DrugLookupService
    let onSave: (Medication) -> Void
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var name = ""
    @State private var dosage = ""
    @State private var instructions = ""
    @State private var selectedRxcui: String?
    @State private var showScannedText = false
    @State private var didApplyPrefill = false

    // New fields
    @State private var medType: MedicationType = .tablet
    @State private var pillShape: PillShape = .round
    @State private var pillColor: PillColor = .white
    @State private var scheduleFreq: MedFrequency = .daily
    @State private var scheduleTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Pill preview
                    pillPreview
                        .padding(.top, 16)

                    // Scanned text (collapsible)
                    if !scannedText.isEmpty {
                        scannedTextSection
                    }

                    // Name + RxNorm search
                    nameSection

                    // Medication type
                    typeSection

                    // Appearance (only for tablet/capsule)
                    if medType == .tablet || medType == .capsule {
                        appearanceSection
                    }

                    // Dosage
                    dosageSection

                    // Schedule
                    scheduleSection

                    // Notes
                    notesSection
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(selectedLanguage == .spanish ? "Añadir Medicina" : "Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selectedLanguage == .spanish ? "Cancelar" : "Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(selectedLanguage == .spanish ? "Guardar" : "Save") { saveMedication() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if !scannedText.isEmpty { showScannedText = true }
                if !didApplyPrefill {
                    didApplyPrefill = true
                    if !prefillName.isEmpty { name = prefillName }
                    if !prefillDosage.isEmpty { dosage = prefillDosage }
                    if let rxcui = prefillRxcui { selectedRxcui = rxcui }
                }
            }
        }
    }

    // MARK: - Pill Preview

    private var pillPreview: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(pillColor.color.gradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: pillColor.color.opacity(0.4), radius: 8, y: 4)
                Image(systemName: medType.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(pillColor == .white ? .gray : .white)
            }
            if !name.isEmpty {
                Text(name)
                    .font(.headline)
                    .lineLimit(1)
            }
            if !dosage.isEmpty {
                Text(dosage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Sections

    private var scannedTextSection: some View {
        formCard {
            DisclosureGroup(
                selectedLanguage == .spanish ? "Texto escaneado" : "Scanned text",
                isExpanded: $showScannedText
            ) {
                Text(scannedText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }

    private var nameSection: some View {
        formCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedLanguage == .spanish ? "Medicina" : "Medication")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                TextField(
                    selectedLanguage == .spanish ? "Nombre (ej. Ibuprofeno)" : "Name (e.g. Ibuprofen)",
                    text: $name
                )
                .font(.body)
                .padding(12)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onChange(of: name) { _, newValue in
                    selectedRxcui = nil
                    drugService.searchDrug(name: newValue)
                }

                if !drugService.searchResults.isEmpty && selectedRxcui == nil {
                    ForEach(drugService.searchResults) { result in
                        Button {
                            name = result.name
                            selectedRxcui = result.rxcui
                            drugService.cacheSearchResult(result)
                            drugService.searchResults = []
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.brand)
                                Text(result.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }

                if drugService.isSearching {
                    HStack {
                        ProgressView().controlSize(.small).padding(.trailing, 4)
                        Text(selectedLanguage == .spanish ? "Buscando..." : "Searching...")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                if let rxcui = selectedRxcui {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.brand)
                            Text(selectedLanguage == .spanish ? "Verificada (RxCUI: \(rxcui))" : "Verified (RxCUI: \(rxcui))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Link(destination: URL(string: "https://rxnav.nlm.nih.gov/")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.system(size: 9))
                                Text(selectedLanguage == .spanish ?
                                     "Fuente: RxNorm — NIH" :
                                     "Source: RxNorm — NIH")
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(.brand)
                        }
                    }
                }
            }
        }
    }

    private var typeSection: some View {
        formCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(selectedLanguage == .spanish ? "Tipo de Medicina" : "Medication Type")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                    ForEach(MedicationType.allCases, id: \.self) { type in
                        Button {
                            medType = type
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(medType == type ? Color.brand : Color(uiColor: .tertiarySystemGroupedBackground))
                                        .frame(width: 52, height: 52)
                                    Image(systemName: type.icon)
                                        .font(.title3)
                                        .foregroundStyle(medType == type ? .white : .primary)
                                }
                                Text(type.label(for: selectedLanguage))
                                    .font(.caption2)
                                    .foregroundStyle(medType == type ? .blue : .secondary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var appearanceSection: some View {
        formCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(selectedLanguage == .spanish ? "Apariencia" : "Appearance")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                // Shape
                Text(selectedLanguage == .spanish ? "Forma" : "Shape")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    ForEach(PillShape.allCases, id: \.self) { shape in
                        Button {
                            pillShape = shape
                        } label: {
                            Image(systemName: shape.icon)
                                .font(.title2)
                                .foregroundStyle(pillShape == shape ? .white : .primary)
                                .frame(width: 44, height: 44)
                                .background(pillShape == shape ? Color.brand : Color(uiColor: .tertiarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Color
                Text(selectedLanguage == .spanish ? "Color" : "Color")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                    ForEach(PillColor.allCases, id: \.self) { color in
                        Button {
                            pillColor = color
                        } label: {
                            Circle()
                                .fill(color.color.gradient)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(pillColor == color ? Color.brand : Color.clear, lineWidth: 3)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color(uiColor: .separator), lineWidth: color == .white ? 1 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var dosageSection: some View {
        formCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedLanguage == .spanish ? "Dosis" : "Dosage")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                TextField(
                    selectedLanguage == .spanish ? "ej. 40mg" : "e.g. 40mg",
                    text: $dosage
                )
                .font(.body)
                .padding(12)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var scheduleSection: some View {
        formCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(selectedLanguage == .spanish ? "Horario" : "Schedule")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                // Frequency picker
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedLanguage == .spanish ? "Frecuencia" : "Frequency")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MedFrequency.allCases, id: \.self) { freq in
                                Button {
                                    scheduleFreq = freq
                                } label: {
                                    Text(freq.label(for: selectedLanguage))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(scheduleFreq == freq ? Color.brand : Color(uiColor: .tertiarySystemGroupedBackground))
                                        .foregroundStyle(scheduleFreq == freq ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Time picker
                if scheduleFreq != .asNeeded {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.brand)
                        DatePicker(
                            selectedLanguage == .spanish ? "Hora" : "Time",
                            selection: $scheduleTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        formCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedLanguage == .spanish ? "Notas" : "Notes")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                TextField(
                    selectedLanguage == .spanish ? "ej. Tomar con comida" : "e.g. Take with food",
                    text: $instructions
                )
                .font(.body)
                .padding(12)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Helpers

    private func formCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func saveMedication() {
        let freqLabel = scheduleFreq.label(for: selectedLanguage)
        let timeStr: String
        if scheduleFreq != .asNeeded {
            let df = DateFormatter()
            df.timeStyle = .short
            timeStr = " - \(df.string(from: scheduleTime))"
        } else {
            timeStr = ""
        }

        let medication = Medication(
            name: name,
            dosage: dosage,
            frequency: "\(freqLabel)\(timeStr)",
            instructions: instructions,
            rxcui: selectedRxcui,
            type: medType,
            shape: (medType == .tablet || medType == .capsule) ? pillShape : nil,
            pillColor: pillColor,
            scheduleFrequency: scheduleFreq,
            scheduleTime: scheduleFreq != .asNeeded ? scheduleTime : nil
        )
        onSave(medication)
    }
}

// MARK: - Document Scanner (VisionKit)

struct DocumentScannerView: UIViewControllerRepresentable {
    let onScan: ([UIImage]) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onCancel: onCancel)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScan: ([UIImage]) -> Void
        let onCancel: () -> Void

        init(onScan: @escaping ([UIImage]) -> Void, onCancel: @escaping () -> Void) {
            self.onScan = onScan
            self.onCancel = onCancel
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            onScan(images)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onCancel()
        }
    }
}

#Preview {
    MedicationView(selectedLanguage: .spanish)
}
