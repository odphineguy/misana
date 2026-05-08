//
//  MyVisitView.swift
//  MiSana
//
//  Created by Abe Perez on 4/12/26.
//

import SwiftUI

struct MyVisitView: View {
    let selectedLanguage: AppLanguage
    @State private var symptomText = ""
    @State private var generatedSummary: VisitSummary?
    @State private var isGenerating = false
    @State private var selectedType: VisitType = .general
    @FocusState private var isTextFocused: Bool

    enum VisitType: String, CaseIterable, Identifiable {
        case general, pain, followUp, pediatric

        var id: String { rawValue }

        func label(for lang: AppLanguage) -> String {
            switch self {
            case .general: return lang == .spanish ? "Chequeo general" : "General checkup"
            case .pain: return lang == .spanish ? "Dolor o molestia" : "Pain or discomfort"
            case .followUp: return lang == .spanish ? "Seguimiento" : "Follow-up"
            case .pediatric: return lang == .spanish ? "Pediatra (mi hijo/a)" : "Pediatric (my child)"
            }
        }

        var icon: String {
            switch self {
            case .general: return "stethoscope"
            case .pain: return "bandage.fill"
            case .followUp: return "arrow.triangle.2.circlepath"
            case .pediatric: return "figure.and.child.holdinghands"
            }
        }
    }

    struct VisitSummary {
        let forYou: String
        let forDoctor: String
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Header with gradient
                    VStack(alignment: .leading, spacing: 6) {
                        Text(selectedLanguage == .spanish ?
                             "Prepara tu cita" :
                             "Prepare your visit")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(selectedLanguage == .spanish ?
                             "Organiza lo que sientes para que tu doctor te entienda mejor." :
                             "Organize how you feel so your doctor understands you better.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.brand.opacity(0.15), Color.brand.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .padding(.horizontal)

                    // MARK: - Visit type selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text(selectedLanguage == .spanish ? "Tipo de cita" : "Visit type")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(VisitType.allCases) { type in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedType = type
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: type.icon)
                                                .font(.caption)
                                            Text(type.label(for: selectedLanguage))
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(selectedType == type ? Color.brand : Color.clear)
                                        .foregroundStyle(selectedType == type ? .white : .primary)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(selectedType == type ? Color.clear : Color.primary.opacity(0.2), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // MARK: - Symptom input card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.line")
                                .foregroundStyle(.brand)
                            Text(selectedLanguage == .spanish ? "¿Qué te molesta?" : "What's bothering you?")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        TextEditor(text: $symptomText)
                            .focused($isTextFocused)
                            .frame(minHeight: 130)
                            .padding(12)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .background(Color(uiColor: .systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(isTextFocused ? Color.brand : Color.primary.opacity(0.15), lineWidth: isTextFocused ? 2 : 1)
                            )
                            .overlay(alignment: .topLeading) {
                                if symptomText.isEmpty {
                                    Text(selectedLanguage == .spanish ?
                                         "Escribe en español o inglés.\nEjemplo: Me duele la cabeza desde el lunes, también tengo mareos cuando me levanto..." :
                                         "Write in Spanish or English.\nExample: I've had a headache since Monday, I also feel dizzy when I stand up...")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.primary.opacity(0.35))
                                        .padding(16)
                                        .allowsHitTesting(false)
                                }
                            }
                            .onChange(of: symptomText) { _, _ in
                                generatedSummary = nil
                            }

                        if shouldAskForSymptoms {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(.orange)
                                Text(selectedLanguage == .spanish ?
                                     "Agrega síntomas o preocupaciones específicas antes de crear la nota." :
                                     "Add specific symptoms or concerns before creating the note.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // MARK: - Generate button
                    Button {
                        isTextFocused = false
                        generateSummary()
                    } label: {
                        HStack(spacing: 8) {
                            if isGenerating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "doc.text.fill")
                            }
                            Text(selectedLanguage == .spanish ?
                                 "Crear nota para doctor" :
                                 "Create note for doctor")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            !canGenerateSummary
                            ? Color.gray.opacity(0.5)
                            : Color.brand
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: canGenerateSummary ? Color.brand.opacity(0.4) : .clear, radius: 8, y: 4)
                    }
                    .disabled(!canGenerateSummary)
                    .padding(.horizontal)

                    // MARK: - Generated summary
                    if let summary = generatedSummary {
                        VStack(spacing: 16) {
                            SummaryCard(
                                title: selectedLanguage == .spanish ? "Para ti" : "For you",
                                subtitle: selectedLanguage == .spanish ?
                                    "Tu nota en palabras sencillas" :
                                    "Your note in simple words",
                                icon: "person.fill",
                                iconColor: .brand,
                                accentColor: .brand,
                                content: summary.forYou,
                                selectedLanguage: selectedLanguage
                            )

                            SummaryCard(
                                title: selectedLanguage == .spanish ? "Para tu doctor" : "For your doctor",
                                subtitle: selectedLanguage == .spanish ?
                                    "Muestra esto en tu cita" :
                                    "Show this at your appointment",
                                icon: "stethoscope",
                                iconColor: .white,
                                accentColor: .green,
                                content: summary.forDoctor,
                                selectedLanguage: selectedLanguage
                            )
                        }
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // MARK: - Symptom Log link
                    symptomLogSection

                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .navigationTitle(selectedLanguage == .spanish ? "Mi Cita" : "My Visit")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture { isTextFocused = false }
            .onAppear { recentLogs = SymptomLogStore.shared.load().prefix(5).map { $0 } }
        }
    }

    @State private var recentLogs: [SymptomLogEntry] = []

    private var trimmedSymptomText: String {
        symptomText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var shouldAskForSymptoms: Bool {
        !trimmedSymptomText.isEmpty && needsMoreDetail(extractedConcern(from: trimmedSymptomText))
    }

    private var canGenerateSummary: Bool {
        !trimmedSymptomText.isEmpty && !shouldAskForSymptoms && !isGenerating
    }

    private var symptomLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.brand)
                Text(selectedLanguage == .spanish ? "Registro de síntomas" : "Symptom log")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if !recentLogs.isEmpty {
                    ShareLink(item: SymptomLogStore.shared.generateExport(
                        entries: SymptomLogStore.shared.load(),
                        language: selectedLanguage == .spanish ? "es" : "en"
                    )) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                            Text(selectedLanguage == .spanish ? "Exportar" : "Export")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.brand)
                    }
                }
            }

            if recentLogs.isEmpty {
                NavigationLink(destination: SymptomLogView(selectedLanguage: selectedLanguage)) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.brand)
                        Text(selectedLanguage == .spanish ?
                             "Empieza a registrar cómo te sientes para compartir con tu doctor." :
                             "Start logging how you feel to share with your doctor.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            } else {
                let allEntries = SymptomLogStore.shared.load()
                let insights = SymptomPatternAnalyzer.insights(
                    from: allEntries,
                    language: selectedLanguage == .spanish ? "es" : "en"
                )

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: insights.isEmpty ? "eye" : "sparkle.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.brand)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pattern Watch")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(patternWatchSummary(entryCount: allEntries.count, insights: insights))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                // Show last few entries as compact rows
                ForEach(recentLogs.prefix(3)) { entry in
                    HStack(spacing: 8) {
                        // Severity dot
                        Circle()
                            .fill(entry.severity <= 2 ? Color.green : entry.severity <= 3 ? Color.orange : Color.red)
                            .frame(width: 8, height: 8)

                        // Date
                        Text(shortDate(entry.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 45, alignment: .leading)

                        // Symptoms
                        Text(entry.symptoms.prefix(3).joined(separator: ", "))
                            .font(.caption)
                            .lineLimit(1)

                        Spacer()

                        // Missed meds indicator
                        let missed = entry.medicationsTaken.filter { !$0.taken }.count
                        if missed > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                                Text("\(missed)")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                NavigationLink(destination: SymptomLogView(selectedLanguage: selectedLanguage)) {
                    Text(selectedLanguage == .spanish ? "Ver todo el registro →" : "View full log →")
                        .font(.caption)
                        .foregroundStyle(.brand)
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func patternWatchSummary(entryCount: Int, insights: [SymptomPatternInsight]) -> String {
        if let firstInsight = insights.first {
            return firstInsight.detail
        }

        if entryCount < 3 {
            return selectedLanguage == .spanish ?
                "Agrega \(3 - entryCount) registro(s) más para empezar a notar patrones." :
                "Add \(3 - entryCount) more entry/entries to start noticing patterns."
        }

        return selectedLanguage == .spanish ?
            "Observando tus registros. Todavía no hay un patrón claro." :
            "Watching your logs. No clear pattern yet."
    }

    private func shortDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = selectedLanguage == .spanish ? "d MMM" : "MMM d"
        df.locale = Locale(identifier: selectedLanguage == .spanish ? "es" : "en")
        return df.string(from: date)
    }

    // MARK: - Generate Summary

    private func generateSummary() {
        let input = trimmedSymptomText
        guard canGenerateSummary else {
            generatedSummary = nil
            isTextFocused = true
            return
        }

        isGenerating = true

        let summary = makeVisitSummary(from: input)
        withAnimation {
            generatedSummary = summary
        }
        isGenerating = false
    }

    private func makeVisitSummary(from input: String) -> VisitSummary {
        let concern = extractedConcern(from: input)

        if needsMoreDetail(concern) {
            return VisitSummary(
                forYou: selectedLanguage == .spanish ?
                    "Escribe los síntomas o preocupaciones específicas que quieres comentar, por ejemplo cuándo empezaron, qué los mejora o empeora, y cualquier medicina que tomas." :
                    "Add the specific symptoms or concerns you want to discuss, such as when they started, what makes them better or worse, and any medicines you take.",
                forDoctor: "Patient is preparing for a \(selectedType.label(for: .english).lowercased()) visit but has not entered specific symptoms or concerns yet."
            )
        }

        let visitType = selectedType.label(for: selectedLanguage).lowercased()
        let forYou = selectedLanguage == .spanish ?
            "Para tu \(visitType), dile a tu doctor sobre: \(concern)" :
            "For your \(visitType), tell your doctor about: \(concern)"

        let forDoctor = """
        Visit type: \(selectedType.label(for: .english)).
        Patient concern: \(concern)
        """

        return VisitSummary(forYou: forYou, forDoctor: forDoctor)
    }

    private func extractedConcern(from input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowered = trimmed.lowercased()
        let prefixes = [
            "doctor visit for ", "doctor appointment for ", "dr visit for ", "dr appointment for ",
            "visit for ", "appointment for ", "checkup for ", "check-up for ",
            "doctor visit about ", "doctor appointment about ", "visit about ", "appointment about ",
            "doctor visit regarding ", "doctor appointment regarding ", "visit regarding ", "appointment regarding ",
            "doctor visit ", "doctor appointment ", "dr visit ", "dr appointment ",
            "visit ", "appointment ", "checkup ", "check-up ",
            "cita por ", "cita para ", "cita sobre ", "consulta por ", "consulta para ", "consulta sobre "
        ]

        for prefix in prefixes where lowered.hasPrefix(prefix) {
            return String(trimmed.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return trimmed
    }

    private func needsMoreDetail(_ input: String) -> Bool {
        let lowered = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let genericEntries = [
            "doctor visit", "dr visit", "visit", "appointment", "checkup", "check-up",
            "cita", "cita medica", "cita médica", "doctor", "doctora", "medico", "médico"
        ]

        if genericEntries.contains(lowered) {
            return true
        }

        let words = lowered
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 }

        return words.isEmpty
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let accentColor: Color
    let content: String
    let selectedLanguage: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with colored icon badge
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(accentColor.opacity(iconColor == .white ? 1.0 : 0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()

            Text((try? AttributedString(markdown: content)) ?? AttributedString(content))
                .font(.subheadline)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)

            Link(destination: sourceURL) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                    Text(selectedLanguage == .spanish ? "Fuente: MedlinePlus" : "Source: MedlinePlus")
                }
                .font(.caption)
                .foregroundStyle(accentColor)
            }

            Text(selectedLanguage == .spanish ?
                 "Siempre consulta a tu doctor. Always consult your doctor." :
                 "Always consult your doctor.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .italic()

            Divider()

            // Action bar
            HStack(spacing: 16) {
                Button {
                    UIPasteboard.general.string = content
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text(selectedLanguage == .spanish ? "Copiar" : "Copy")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(accentColor)
                }

                ShareLink(item: content) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text(selectedLanguage == .spanish ? "Compartir" : "Share")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(accentColor)
                }

                Spacer()
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var sourceURL: URL {
        URL(string: selectedLanguage == .spanish ?
            "https://medlineplus.gov/spanish/talkingwithyourdoctor.html" :
            "https://medlineplus.gov/talkingwithyourdoctor.html")!
    }
}
