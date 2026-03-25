//
//  HealthCitationService.swift
//  MiSana
//
//  Created by Abe Perez on 3/24/26.
//

import Foundation

// MARK: - Models

struct HealthCitation: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let url: URL
    let source: String
    let topicID: String

    static func == (lhs: HealthCitation, rhs: HealthCitation) -> Bool {
        lhs.topicID == rhs.topicID
    }
}

struct HealthTopicRecord: Codable {
    let id: String
    let en: String
    let es: String
    let url_en: String
    let url_es: String
    let synonyms: [String]
    let categories: [String]
}

/// Result of the retrieval step — passed to the LLM as context
struct RetrievalResult {
    let citations: [HealthCitation]
    let sourceContext: String // Text to prepend to the LLM prompt
    let hasVerifiedSources: Bool
}

// MARK: - Service

@MainActor
class HealthCitationService {

    private var topics: [HealthTopicRecord] = []
    private var searchIndex: [String: Int] = [:]
    private var isLoaded = false

    init() {
        loadLocalTopicMap()
    }

    // MARK: - Load Local Topic Map

    private func loadLocalTopicMap() {
        guard let topicsURL = Bundle.main.url(forResource: "health_topics", withExtension: "json"),
              let indexURL = Bundle.main.url(forResource: "health_search_index", withExtension: "json") else {
            print("Warning: Health topic map files not found in bundle")
            return
        }

        do {
            let topicsData = try Data(contentsOf: topicsURL)
            let indexData = try Data(contentsOf: indexURL)
            topics = try JSONDecoder().decode([HealthTopicRecord].self, from: topicsData)
            searchIndex = try JSONDecoder().decode([String: Int].self, from: indexData)
            isLoaded = true
            print("Loaded \(topics.count) health topics, \(searchIndex.count) search terms")
        } catch {
            print("Error loading health topic map: \(error)")
        }
    }

    // MARK: - Retrieval Pipeline

    /// Main entry point: retrieve verified sources for a user message BEFORE generating a response.
    /// Returns citations + context string to feed to the LLM.
    func retrieveSources(for userMessage: String, language: String) async -> RetrievalResult {
        // Step 1: Try local topic map (fast, deterministic, offline)
        let localMatches = matchLocalTopics(message: userMessage, language: language)

        if !localMatches.isEmpty {
            let citations = localMatches.map { makeCitation(from: $0, language: language) }
            let context = buildSourceContext(topics: localMatches, language: language)
            return RetrievalResult(citations: citations, sourceContext: context, hasVerifiedSources: true)
        }

        // Step 2: Fallback to MedlinePlus Web Service API (requires network)
        let apiMatches = await searchMedlinePlusAPI(query: userMessage, language: language)

        if !apiMatches.isEmpty {
            return RetrievalResult(citations: apiMatches, sourceContext: buildAPIContext(citations: apiMatches, language: language), hasVerifiedSources: true)
        }

        // Step 3: No sources found
        return RetrievalResult(citations: [], sourceContext: "", hasVerifiedSources: false)
    }

    // MARK: - Local Topic Matching

    /// Search the local bilingual topic map for matching health topics
    private func matchLocalTopics(message: String, language: String) -> [HealthTopicRecord] {
        guard isLoaded else { return [] }

        let lowered = message.lowercased()
        // Tokenize into whole words + stemmed variants for plural handling (headaches→headache, dolores→dolor)
        let stopWords: Set<String> = ["doctor", "doctora", "medico", "medica"]
        var messageWords = Set<String>()
        for word in lowered.components(separatedBy: CharacterSet.alphanumerics.inverted) {
            guard !word.isEmpty && !stopWords.contains(word) else { continue }
            messageWords.insert(word)
            // English plurals: headaches → headache
            if word.count >= 4 && word.hasSuffix("s") {
                messageWords.insert(String(word.dropLast()))
            }
            // Spanish plurals: dolores → dolor
            if word.count >= 5 && word.hasSuffix("es") {
                messageWords.insert(String(word.dropLast(2)))
            }
        }

        // Score each topic by relevance — longer/phrase matches score higher
        var scores: [Int: Int] = [:]

        for (term, index) in searchIndex {
            guard term.count >= 3 else { continue }

            if term.contains(" ") {
                // Multi-word phrase: check if full phrase appears in message
                if lowered.contains(term) {
                    scores[index, default: 0] += term.count * 3
                }
            } else {
                // Single word: O(1) Set lookup (messageWords already includes stemmed variants)
                if messageWords.contains(term) {
                    scores[index, default: 0] += term.count
                }
            }
        }

        // Filter out sensitive/stigmatizing topics unless the user explicitly mentioned them
        let sensitiveTerms = [
            // Cancer
            "cancer", "cáncer", "tumor", "tumores", "leukemia", "leucemia",
            "lymphoma", "linfoma", "melanoma", "carcinoma", "sarcoma",
            // Alcohol / substance abuse
            "alcohol", "alcoholismo", "alcoholism", "adicción", "addiction",
            "substance abuse", "abuso de sustancias", "drinking", "drug abuse",
            "abuso de drogas", "sobredosis", "overdose",
            // Suicide / self-harm
            "suicide", "suicidio", "self-harm", "autolesión", "suicidal",
            // HIV / AIDS
            "vih", "hiv", "sida", "aids",
            // STIs
            "herpes", "sífilis", "syphilis", "gonorrea", "gonorrhea",
            "chlamydia", "clamidia",
            // Eating disorders
            "anorexia", "bulimia", "eating disorder", "trastorno alimenticio",
            // Domestic violence / abuse
            "violencia doméstica", "domestic violence", "abuso sexual", "sexual abuse"
        ]
        let userMentionedSensitive = sensitiveTerms.contains { lowered.contains($0) }

        // Return up to 2 topics sorted by relevance (highest score first)
        let sorted = scores.sorted { $0.value > $1.value }
        return sorted.prefix(4).compactMap { entry -> HealthTopicRecord? in
            guard entry.key < topics.count else { return nil }
            let topic = topics[entry.key]
            // Skip cancer/tumor topics unless user brought it up
            if !userMentionedSensitive {
                let topicLower = "\(topic.en) \(topic.es)".lowercased()
                if sensitiveTerms.contains(where: { topicLower.contains($0) }) {
                    return nil
                }
            }
            return topic
        }.prefix(2).map { $0 }
    }

    /// Create a citation from a local topic record
    private func makeCitation(from topic: HealthTopicRecord, language: String) -> HealthCitation {
        let urlString = language == "es" ? topic.url_es : topic.url_en
        let title = language == "es" ? (topic.es.isEmpty ? topic.en : topic.es) : topic.en
        let url = URL(string: urlString) ?? URL(string: topic.url_en)!

        return HealthCitation(
            title: title,
            url: url,
            source: "MedlinePlus (NIH)",
            topicID: topic.id
        )
    }

    /// Build context string for the LLM from matched local topics
    private func buildSourceContext(topics: [HealthTopicRecord], language: String) -> String {
        let topicNames = topics.map { topic in
            language == "es" ? (topic.es.isEmpty ? topic.en : topic.es) : topic.en
        }

        if language == "es" {
            return "Fuentes verificadas encontradas: \(topicNames.joined(separator: ", ")) (MedlinePlus/NIH). Basa tu respuesta en informacion de estas fuentes."
        } else {
            return "Verified sources found: \(topicNames.joined(separator: ", ")) (MedlinePlus/NIH). Base your response on information from these sources."
        }
    }

    // MARK: - MedlinePlus Web Service API Fallback

    /// Search MedlinePlus API when local map doesn't match
    private func searchMedlinePlusAPI(query: String, language: String) async -> [HealthCitation] {
        // Extract significant words for search
        let words = query.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 }
            .prefix(3)

        guard !words.isEmpty else { return [] }

        let searchTerm = words.joined(separator: "+")
        let db = language == "es" ? "healthTopicsSpanish" : "healthTopics"
        let urlString = "https://wsearch.nlm.nih.gov/ws/query?db=\(db)&term=\(searchTerm)&retmax=3"

        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString) else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return parseWebServiceXML(data)
        } catch {
            return []
        }
    }

    /// Parse the MedlinePlus Web Service XML response
    private func parseWebServiceXML(_ data: Data) -> [HealthCitation] {
        guard let xml = String(data: data, encoding: .utf8) else { return [] }

        var citations: [HealthCitation] = []

        let documents = xml.components(separatedBy: "<document ")
        for doc in documents.dropFirst() {
            guard let urlRange = doc.range(of: "url=\""),
                  let urlEnd = doc[urlRange.upperBound...].range(of: "\"") else { continue }
            let urlString = String(doc[urlRange.upperBound..<urlEnd.lowerBound])
            guard let url = URL(string: urlString) else { continue }

            guard let titleStart = doc.range(of: "<content name=\"title\">"),
                  let titleEnd = doc[titleStart.upperBound...].range(of: "</content>") else { continue }
            var title = String(doc[titleStart.upperBound..<titleEnd.lowerBound])
            title = title.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

            citations.append(HealthCitation(
                title: title,
                url: url,
                source: "MedlinePlus (NIH)",
                topicID: urlString
            ))

            if citations.count >= 2 { break }
        }

        return citations
    }

    /// Build context string from API citations
    private func buildAPIContext(citations: [HealthCitation], language: String) -> String {
        let names = citations.map(\.title)
        if language == "es" {
            return "Fuentes verificadas: \(names.joined(separator: ", ")) (MedlinePlus/NIH). Basa tu respuesta en estas fuentes."
        } else {
            return "Verified sources: \(names.joined(separator: ", ")) (MedlinePlus/NIH). Base your response on these sources."
        }
    }
}
