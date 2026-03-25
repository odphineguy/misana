//
//  ModelDownloadView.swift
//  MiSana
//
//  Created by Abe Perez on 3/11/26.
//

import SwiftUI

struct ModelDownloadView: View {
    @ObservedObject var modelService: LocalModelService
    let selectedLanguage: AppLanguage
    @State private var isDownloading = false
    @State private var showDisclaimer = true
    @State private var showErrorAlert = false
    @State private var availableSpaceGB: Double = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let requiredSpaceGB: Double = 3.0 // 2.5GB model + buffer
    private var hasEnoughSpace: Bool { availableSpaceGB >= requiredSpaceGB }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if showDisclaimer {
                    disclaimerView
                } else {
                    downloadView
                }
            }
            .navigationTitle(selectedLanguage == .spanish ? "Configuración" : "Setup")
            .navigationBarTitleDisplayMode(.inline)
            .alert(selectedLanguage == .spanish ? "Error de Descarga" : "Download Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {
                    modelService.downloadError = nil
                }
            } message: {
                Text(modelService.downloadError ?? "Error desconocido")
            }
            .onChange(of: modelService.downloadError) { _, newError in
                if newError != nil {
                    showErrorAlert = true
                }
            }
        }
    }
    
    // MARK: - Disclaimer View
    
    private var disclaimerView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Logo
                Image(colorScheme == .dark ? "MiSanaLogoDark" : "MiSanaLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                    .padding(.top, 40)
                
                // Title
                VStack(spacing: 12) {
                    Text(selectedLanguage == .spanish ? 
                         "Bienvenido a MiSana" : 
                         "Welcome to MiSana")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(selectedLanguage == .spanish ?
                         "Tu compañero de salud familiar" :
                         "Your family health companion")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                // Disclaimer Box
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(selectedLanguage == .spanish ? 
                             "Descargo de Responsabilidad" : 
                             "Disclaimer")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Text(selectedLanguage == .spanish ? 
                         "MiSana no es un doctor ni reemplaza el consejo médico profesional.\n\nEste asistente de salud es solo para fines educativos e informativos. Siempre consulta con un profesional de salud certificado para diagnósticos, tratamientos, o cualquier decisión médica.\n\nSi experimentas una emergencia médica, llama al 911 inmediatamente." : 
                         "MiSana is not a doctor and does not replace professional medical advice.\n\nThis health assistant is for educational and informational purposes only. Always consult with a certified healthcare professional for diagnoses, treatments, or any medical decisions.\n\nIf you experience a medical emergency, call 911 immediately.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Features
                VStack(alignment: .leading, spacing: 12) {
                    Text(selectedLanguage == .spanish ? 
                         "MiSana puede ayudarte con:" : 
                         "MiSana can help you with:")
                        .font(.headline)
                    
                    FeatureRow(
                        icon: "pills.fill",
                        text: selectedLanguage == .spanish ? 
                            "Información sobre medicamentos" : 
                            "Medication information"
                    )
                    
                    FeatureRow(
                        icon: "stethoscope",
                        text: selectedLanguage == .spanish ? 
                            "Orientación sobre síntomas" : 
                            "Symptom guidance"
                    )
                    
                    FeatureRow(
                        icon: "leaf.fill",
                        text: selectedLanguage == .spanish ? 
                            "Validación de remedios caseros" : 
                            "Home remedy validation"
                    )
                    
                    FeatureRow(
                        icon: "list.clipboard.fill",
                        text: selectedLanguage == .spanish ? 
                            "Preparación para citas médicas" : 
                            "Medical appointment preparation"
                    )
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Privacy Badge
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.green)
                    Text(selectedLanguage == .spanish ? 
                         "100% privado • Funciona sin internet • Sin costos por uso" : 
                         "100% private • Works offline • No usage fees")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Spacer()
                
                // Continue Button
                Button {
                    withAnimation {
                        showDisclaimer = false
                    }
                } label: {
                    Text(selectedLanguage == .spanish ? 
                         "Entiendo y Acepto" : 
                         "I Understand and Accept")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
    }
    
    // MARK: - Download View
    
    private var downloadView: some View {
        ScrollView {
        VStack(spacing: 32) {
            
            // Icon
            Image(systemName: isDownloading ? "arrow.down.circle.fill" : "brain.fill")
                .font(.system(size: 80))
                .foregroundStyle(.brand)
                .symbolEffect(.bounce, value: isDownloading)
            
            // Title & Description
            VStack(spacing: 12) {
                Text(selectedLanguage == .spanish ? 
                     "Descargar Modelo de IA" : 
                     "Download AI Model")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(selectedLanguage == .spanish ?
                     "Para usar MiSana sin internet, necesitas descargar el modelo de inteligencia artificial (Gemma 3 4B)." :
                     "To use MiSana offline, you need to download the AI model (Gemma 3 4B).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
            }
            
            // Model Info
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.brand)
                    Text(selectedLanguage == .spanish ? 
                         "Información del Modelo" : 
                         "Model Information")
                        .font(.headline)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(label: selectedLanguage == .spanish ? "Modelo" : "Model", 
                           value: "Gemma 3 4B")
                    InfoRow(label: selectedLanguage == .spanish ? "Tamaño" : "Size", 
                           value: "~2.5 GB")
                    InfoRow(label: selectedLanguage == .spanish ? "Idiomas" : "Languages", 
                           value: selectedLanguage == .spanish ? "Español & Inglés" : "Spanish & English")
                    InfoRow(label: selectedLanguage == .spanish ? "Privacidad" : "Privacy", 
                           value: selectedLanguage == .spanish ? "100% en el dispositivo" : "100% on-device")
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            
            // Storage Info
            storageCard
                .padding(.horizontal)

            // Download Progress
            if isDownloading {
                VStack(spacing: 12) {
                    ProgressView(value: modelService.modelDownloadProgress)
                        .progressViewStyle(.linear)
                        .tint(.brand)
                    
                    Text("\(Int(modelService.modelDownloadProgress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let error = modelService.downloadError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 40)
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                if !isDownloading {
                    // Show retry message if there was an error
                    if modelService.downloadError != nil {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(selectedLanguage == .spanish ?
                                 "La descarga fallo. Verifica tu conexion e intenta de nuevo." :
                                 "Download failed. Check your connection and try again.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button {
                        modelService.downloadError = nil
                        startDownload()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                            Text(modelService.downloadError != nil ?
                                 (selectedLanguage == .spanish ? "Reintentar Descarga" : "Retry Download") :
                                 (selectedLanguage == .spanish ? "Descargar Modelo (2.5 GB)" : "Download Model (2.5 GB)"))
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hasEnoughSpace ? Color.brand : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!hasEnoughSpace)

                    Button {
                        dismiss()
                    } label: {
                        Text(selectedLanguage == .spanish ?
                             "Descargar Mas Tarde" :
                             "Download Later")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        cancelDownload()
                    } label: {
                        Text(selectedLanguage == .spanish ?
                             "Cancelar Descarga" :
                             "Cancel Download")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        }
    }

    // MARK: - Storage Card

    private var storageCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: hasEnoughSpace ? "internaldrive.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(hasEnoughSpace ? .blue : .orange)
                Text(selectedLanguage == .spanish ? "Almacenamiento" : "Storage")
                    .font(.headline)
                Spacer()
            }

            // Storage bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(hasEnoughSpace ? Color.brand : Color.orange)
                        .frame(width: max(0, min(geo.size.width, geo.size.width * (1 - availableSpaceGB / max(availableSpaceGB + 20, 1)))))
                }
            }
            .frame(height: 12)

            HStack {
                Text(selectedLanguage == .spanish ?
                     "Disponible: \(String(format: "%.1f", availableSpaceGB)) GB" :
                     "Available: \(String(format: "%.1f", availableSpaceGB)) GB")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(selectedLanguage == .spanish ?
                     "Necesario: ~\(String(format: "%.1f", requiredSpaceGB)) GB" :
                     "Required: ~\(String(format: "%.1f", requiredSpaceGB)) GB")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !hasEnoughSpace {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(selectedLanguage == .spanish ?
                         "No hay suficiente espacio. Libera al menos \(String(format: "%.1f", requiredSpaceGB - availableSpaceGB)) GB para continuar." :
                         "Not enough space. Free at least \(String(format: "%.1f", requiredSpaceGB - availableSpaceGB)) GB to continue.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(hasEnoughSpace ? Color.secondary.opacity(0.1) : Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear { checkStorage() }
    }

    // MARK: - Actions

    private func checkStorage() {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        if let values = try? home.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
           let bytes = values.volumeAvailableCapacityForImportantUsage {
            availableSpaceGB = Double(bytes) / 1_073_741_824
        }
    }

    private func startDownload() {
        isDownloading = true
        
        Task {
            do {
                print("🚀 Starting model download...")
                try await modelService.downloadModel()
                
                print("📦 Download complete, loading model...")
                // Auto-load model after download
                try modelService.loadModel()
                
                print("✅ Model loaded, closing sheet...")
                // Close the view
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("❌ Download/Load error: \(error)")
                await MainActor.run {
                    modelService.downloadError = "Error: \(error.localizedDescription)"
                    isDownloading = false
                }
            }
        }
    }
    
    private func cancelDownload() {
        print("🛑 Canceling download...")
        modelService.cancelDownload()
        isDownloading = false
    }
}

// MARK: - Helper Views

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.brand)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    ModelDownloadView(
        modelService: LocalModelService(),
        selectedLanguage: .spanish
    )
}
