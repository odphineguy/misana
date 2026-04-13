//
//  LookUpView.swift
//  MiSana
//
//  Created by Abe Perez on 4/12/26.
//

import SwiftUI

struct LookUpView: View {
    let selectedLanguage: AppLanguage
    @EnvironmentObject private var modelService: ModelCoordinator
    @EnvironmentObject private var healthKitService: HealthKitService
    @State private var searchText = ""
    @State private var resultCard: LookUpResult?
    @State private var isSearching = false
    @FocusState private var isSearchFocused: Bool

    private let citationService = HealthCitationService()

    struct LookUpResult {
        let title: String
        let explanation: String
        let citations: [HealthCitation]
        let healthContext: String?
    }

    // Each suggestion has: icon, display text (ES/EN), and a search query optimized for the citation engine
    private var suggestions: [(icon: String, es: String, en: String, queryES: String, queryEN: String)] {
        [
            ("drop.fill",      "¿Qué es la diabetes?",         "What is diabetes?",            "diabetes",             "diabetes"),
            ("heart.fill",     "¿Qué es la hipertensión?",     "What is high blood pressure?", "presión arterial alta", "high blood pressure"),
            ("allergens.fill", "Remedios para la gripe",        "Flu remedies",                 "gripe",                "flu"),
            ("leaf.fill",      "¿Son seguros los remedios caseros?", "Are home remedies safe?", "herbal medicine",      "herbal medicine"),
            ("pills.fill",     "¿Cómo funcionan las medicinas para diabetes?", "How do diabetes medicines work?", "diabetes medicinas", "diabetes medicines"),
            ("lungs.fill",     "Síntomas de asma",             "Asthma symptoms",              "asma",                 "asthma"),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.brand)
                            .fontWeight(.medium)
                        TextField(
                            selectedLanguage == .spanish ?
                                "Condición, medicina, o remedio..." :
                                "Condition, medication, or remedy...",
                            text: $searchText
                        )
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .onSubmit { performSearch() }

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                resultCard = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.primary.opacity(0.3))
                            }
                        }
                    }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isSearchFocused ? Color.brand : Color.primary.opacity(0.12), lineWidth: isSearchFocused ? 2 : 1)
                    )
                    .padding(.horizontal)

                    if isSearching {
                        VStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.large)
                            Text(selectedLanguage == .spanish ? "Buscando fuentes verificadas..." : "Searching verified sources...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 40)
                    } else if let result = resultCard {
                        resultView(result)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        suggestionsView
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .navigationTitle(selectedLanguage == .spanish ? "Buscar" : "Look Up")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture { isSearchFocused = false }
        }
    }

    // MARK: - Suggestions

    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedLanguage == .spanish ? "Preguntas comunes" : "Common questions")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(suggestions, id: \.es) { suggestion in
                    Button {
                        searchText = selectedLanguage == .spanish ? suggestion.es : suggestion.en
                        performSearch(overrideQuery: selectedLanguage == .spanish ? suggestion.queryES : suggestion.queryEN)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: suggestion.icon)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.brand.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            Text(selectedLanguage == .spanish ? suggestion.es : suggestion.en)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Result View

    private func resultView(_ result: LookUpResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            // Title bar
            HStack(spacing: 10) {
                Image(systemName: "text.magnifyingglass")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(result.title)
                    .font(.headline)
                    .lineLimit(2)
            }
            .padding(.horizontal)

            // Main explanation card
            VStack(alignment: .leading, spacing: 12) {
                Text(result.explanation)
                    .font(.subheadline)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.brand.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal)

            // HealthKit context
            if let healthContext = result.healthContext, !healthContext.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedLanguage == .spanish ? "Tus datos de salud" : "Your health data")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text(healthContext)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.red.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal)
            }

            // Citations
            if !result.citations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedLanguage == .spanish ? "Fuentes verificadas:" : "Verified sources:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    ForEach(result.citations, id: \.title) { citation in
                        Link(destination: citation.url) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Text(citation.title)
                                    .font(.caption)
                                    .foregroundStyle(.brand)
                                    .underline()
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Text(selectedLanguage == .spanish ?
                         "Siempre consulta a tu doctor." :
                         "Always consult your doctor.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .italic()
                        .padding(.top, 2)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.green.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    if let text = resultCard?.explanation {
                        UIPasteboard.general.string = text
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text(selectedLanguage == .spanish ? "Copiar" : "Copy")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.brand)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.brand.opacity(0.12))
                    .clipShape(Capsule())
                }

                if let text = resultCard?.explanation {
                    ShareLink(item: text) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                            Text(selectedLanguage == .spanish ? "Compartir" : "Share")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.brand)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.brand.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Search

    private func performSearch(overrideQuery: String? = nil) {
        let displayQuery = searchText.trimmingCharacters(in: .whitespaces)
        let citationQuery = overrideQuery ?? displayQuery
        guard !displayQuery.isEmpty else { return }

        isSearchFocused = false
        isSearching = true

        Task {
            let lang = selectedLanguage == .spanish ? "es" : "en"
            let retrieval = await citationService.retrieveSources(for: citationQuery, language: lang)

            let prompt: String
            if retrieval.hasVerifiedSources {
                prompt = """
                \(retrieval.sourceContext)

                Based on the verified sources above, explain this in simple \(selectedLanguage == .spanish ? "Spanish" : "English") that a non-medical person can understand. Keep it to 3-4 sentences. Do not recommend specific medications by name unless the source mentions them.

                Question: \(displayQuery)
                """
            } else {
                prompt = """
                Answer this health question in simple \(selectedLanguage == .spanish ? "Spanish" : "English"). Keep it to 2-3 sentences. Do not diagnose. Do not recommend specific medications. If you're not sure, say to consult a doctor.

                Question: \(displayQuery)
                """
            }

            do {
                let explanation = try await modelService.generateResponse(
                    userMessage: prompt,
                    conversationHistory: []
                )

                let healthContext = getRelevantHealthContext(for: displayQuery)

                await MainActor.run {
                    withAnimation {
                        resultCard = LookUpResult(
                            title: displayQuery,
                            explanation: explanation,
                            citations: retrieval.citations,
                            healthContext: healthContext
                        )
                    }
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                }
            }
        }
    }

    // MARK: - HealthKit Context

    private func getRelevantHealthContext(for query: String) -> String? {
        let lowered = query.lowercased()
        let summary = healthKitService.summary

        if lowered.contains("presion") || lowered.contains("pressure") || lowered.contains("hipertension") || lowered.contains("hypertension") {
            if !summary.systolic.isEmpty, let sys = summary.systolic.last, let dia = summary.diastolic.last {
                return selectedLanguage == .spanish ?
                    "Tu ultima lectura: \(Int(sys.value))/\(Int(dia.value)) mmHg" :
                    "Your last reading: \(Int(sys.value))/\(Int(dia.value)) mmHg"
            }
        }

        if lowered.contains("corazon") || lowered.contains("heart") || lowered.contains("cardiaco") {
            if summary.lastHeartRate > 0 {
                return selectedLanguage == .spanish ?
                    "Tu ultimo ritmo cardiaco: \(summary.lastHeartRate) BPM" :
                    "Your last heart rate: \(summary.lastHeartRate) BPM"
            }
        }

        if lowered.contains("sueno") || lowered.contains("sleep") || lowered.contains("dormir") || lowered.contains("insomnia") {
            if summary.lastNightSleep > 0 {
                let hours = Int(summary.lastNightSleep)
                let mins = Int((summary.lastNightSleep - Double(hours)) * 60)
                return selectedLanguage == .spanish ?
                    "Anoche dormiste: \(hours)h \(mins)m" :
                    "Last night you slept: \(hours)h \(mins)m"
            }
        }

        if lowered.contains("paso") || lowered.contains("step") || lowered.contains("caminar") || lowered.contains("walk") {
            if summary.todaySteps > 0 {
                return selectedLanguage == .spanish ?
                    "Hoy llevas: \(summary.todaySteps) pasos" :
                    "Today so far: \(summary.todaySteps) steps"
            }
        }

        return nil
    }
}
