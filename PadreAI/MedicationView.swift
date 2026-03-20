//
//  MedicationView.swift
//  PadreAI
//
//  Created by Abe Perez on 3/11/26.
//

import SwiftUI
import VisionKit
import Vision

// MARK: - Model

struct Medication: Identifiable, Codable {
    var id = UUID()
    let name: String
    let dosage: String
    let frequency: String
    let instructions: String
    var rxcui: String?
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
                selectedLanguage == .spanish ? "Escanear con cámara" : "Scan with camera",
                isPresented: $showingScanChoice,
                titleVisibility: .visible
            ) {
                Button(selectedLanguage == .spanish ? "Escanear código de barras" : "Scan barcode") {
                    showingBarcodeScanner = true
                }
                Button(selectedLanguage == .spanish ? "Escanear etiqueta con cámara" : "Scan label with camera") {
                    showingDocumentScanner = true
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
                    VStack(spacing: 16) {
                        ProgressView()
                            .controlSize(.large)
                        Text(selectedLanguage == .spanish ?
                             "Analizando etiqueta..." :
                             "Analyzing label...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
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
                .foregroundStyle(.blue)

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
                    .background(Color.blue)
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
                    .foregroundStyle(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Medication List

    private var medicationListView: some View {
        List {
            if !drugService.interactions.isEmpty {
                Section {
                    ForEach(drugService.interactions) { interaction in
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(interaction.drug1Name) + \(interaction.drug2Name)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(interaction.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }
                        }
                    }
                } header: {
                    Text(selectedLanguage == .spanish ? "Interacciones" : "Interactions")
                }
            }

            Section {
                ForEach(medications) { medication in
                    NavigationLink {
                        MedicationDetailView(
                            medication: medication,
                            selectedLanguage: selectedLanguage,
                            drugService: drugService
                        )
                    } label: {
                        MedicationRowView(medication: medication, selectedLanguage: selectedLanguage)
                    }
                }
                .onDelete { indexSet in
                    medications.remove(atOffsets: indexSet)
                    saveMedications()
                    refreshInteractions()
                }
            }
        }
    }

    // MARK: - OCR

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
            scannedText = ocrText
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

        // No NDC matched — show barcode for manual entry
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

struct MedicationRowView: View {
    let medication: Medication
    let selectedLanguage: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(medication.name)
                .font(.headline)
            if !medication.dosage.isEmpty {
                HStack {
                    Label(medication.dosage, systemImage: "pills.fill")
                        .font(.subheadline)
                    Spacer()
                    if !medication.frequency.isEmpty {
                        Text(medication.frequency)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
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
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = ""
    @State private var instructions = ""
    @State private var selectedRxcui: String?
    @State private var showScannedText = false
    @State private var didApplyPrefill = false

    var body: some View {
        NavigationStack {
            Form {
                if !scannedText.isEmpty {
                    Section {
                        DisclosureGroup(
                            selectedLanguage == .spanish ? "Texto escaneado" : "Scanned text",
                            isExpanded: $showScannedText
                        ) {
                            Text(scannedText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(selectedLanguage == .spanish ? "Medicina" : "Medication") {
                    TextField(
                        selectedLanguage == .spanish ? "Nombre (ej. Ibuprofeno)" : "Name (e.g. Ibuprofen)",
                        text: $name
                    )
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
                                        .foregroundStyle(.secondary)
                                    Text(result.name)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                    }

                    if drugService.isSearching {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.trailing, 4)
                            Text(selectedLanguage == .spanish ? "Buscando en RxNorm..." : "Searching RxNorm...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let rxcui = selectedRxcui {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(selectedLanguage == .spanish ? "Medicina verificada (RxCUI: \(rxcui))" : "Verified drug (RxCUI: \(rxcui))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    TextField(
                        selectedLanguage == .spanish ? "Dosis (ej. 200mg)" : "Dosage (e.g. 200mg)",
                        text: $dosage
                    )
                }

                Section(selectedLanguage == .spanish ? "Instrucciones" : "Instructions") {
                    TextField(
                        selectedLanguage == .spanish ? "Frecuencia (ej. Cada 8 horas)" : "Frequency (e.g. Every 8 hours)",
                        text: $frequency
                    )
                    TextField(
                        selectedLanguage == .spanish ? "Notas (ej. Tomar con comida)" : "Notes (e.g. Take with food)",
                        text: $instructions
                    )
                }
            }
            .navigationTitle(selectedLanguage == .spanish ? "Añadir Medicina" : "Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selectedLanguage == .spanish ? "Cancelar" : "Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(selectedLanguage == .spanish ? "Guardar" : "Save") {
                        let medication = Medication(
                            name: name,
                            dosage: dosage,
                            frequency: frequency,
                            instructions: instructions,
                            rxcui: selectedRxcui
                        )
                        onSave(medication)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if !scannedText.isEmpty {
                    showScannedText = true
                }
                if !didApplyPrefill {
                    didApplyPrefill = true
                    if !prefillName.isEmpty { name = prefillName }
                    if !prefillDosage.isEmpty { dosage = prefillDosage }
                    if let rxcui = prefillRxcui { selectedRxcui = rxcui }
                }
            }
        }
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
