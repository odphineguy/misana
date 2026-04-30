//
//  DrugLookupService.swift
//  MiSana
//
//  Created by Abe Perez on 3/19/26.
//

import Foundation
import Combine

// MARK: - Models

struct DrugSearchResult: Identifiable, Codable {
    let rxcui: String
    let name: String
    var id: String { rxcui }
}

struct SpanishDrugInfo: Codable {
    let title: String
    let summary: String
    let url: String?
}

struct DrugInteraction: Identifiable, Codable {
    var id: String { "\(drug1Rxcui)-\(drug2Rxcui)" }
    let drug1Name: String
    let drug1Rxcui: String
    let drug2Name: String
    let drug2Rxcui: String
    let description: String
    let severity: String?
}

struct CachedDrugInfo: Codable {
    let rxcui: String
    let name: String
    let spanishInfo: SpanishDrugInfo?
    let cachedDate: Date
}

// MARK: - Service

@MainActor
class DrugLookupService: ObservableObject {
    @Published var searchResults: [DrugSearchResult] = []
    @Published var isSearching = false
    @Published var interactions: [DrugInteraction] = []
    @Published var interactionCheckFailed = false
    @Published var lookupFailed = false

    private var cache: [String: CachedDrugInfo] = [:]
    private var searchTask: Task<Void, Never>?

    private var cacheFileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("drug_cache.json")
    }

    init() {
        loadCache()
    }

    // MARK: - RxNorm Drug Search

    func searchDrug(name: String) {
        searchTask?.cancel()
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else {
            searchResults = []
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }

            let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            let urlString = "https://rxnav.nlm.nih.gov/REST/approximateTerm.json?term=\(encoded)&maxEntries=6"
            guard let url = URL(string: urlString) else {
                isSearching = false
                return
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled else { return }

                let results = parseApproximateTermResponse(data)
                searchResults = results
            } catch {
                if !Task.isCancelled {
                    searchResults = []
                }
            }
            isSearching = false
        }
    }

    private func parseApproximateTermResponse(_ data: Data) -> [DrugSearchResult] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let group = json["approximateGroup"] as? [String: Any],
              let candidates = group["candidate"] as? [[String: Any]] else {
            return []
        }

        var seen = Set<String>()
        var results: [DrugSearchResult] = []
        for candidate in candidates {
            guard let rxcui = candidate["rxcui"] as? String,
                  let name = candidate["name"] as? String,
                  !seen.contains(rxcui) else { continue }
            seen.insert(rxcui)
            results.append(DrugSearchResult(rxcui: rxcui, name: name))
        }
        return results
    }

    // MARK: - NDC to RxCUI Lookup

    func lookupByNDC(ndc: String) async -> DrugSearchResult? {
        let cleaned = ndc.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        let urlString = "https://rxnav.nlm.nih.gov/REST/rxcui.json?idtype=NDC&id=\(cleaned)"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            lookupFailed = false
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let group = json["idGroup"] as? [String: Any],
                  let rxnormId = group["rxnormId"] as? [String],
                  let rxcui = rxnormId.first else { return nil }

            // Get the drug name from the RxCUI
            let name = await fetchDrugName(rxcui: rxcui)
            return DrugSearchResult(rxcui: rxcui, name: name ?? cleaned)
        } catch {
            lookupFailed = true
            return nil
        }
    }

    private func fetchDrugName(rxcui: String) async -> String? {
        let urlString = "https://rxnav.nlm.nih.gov/REST/rxcui/\(rxcui)/properties.json"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let props = json["properties"] as? [String: Any],
                  let name = props["name"] as? String else { return nil }
            return name
        } catch {
            return nil
        }
    }

    // MARK: - OpenFDA UPC Lookup (fallback for OTC products RxNorm misses)

    /// Look up a drug by its UPC barcode via OpenFDA drug label API.
    /// Works for OTC products that RxNorm's NDC database doesn't cover.
    func lookupByUPC(barcode: String) async -> DrugSearchResult? {
        let cleaned = barcode.filter(\.isNumber)
        let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleaned
        let urlString = "https://api.fda.gov/drug/label.json?search=openfda.upc:%22\(encoded)%22&limit=1"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            lookupFailed = false
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let first = results.first,
                  let openfda = first["openfda"] as? [String: Any] else { return nil }

            // Get brand name, fall back to generic
            let brandNames = openfda["brand_name"] as? [String]
            let genericNames = openfda["generic_name"] as? [String]
            let name = brandNames?.first ?? genericNames?.first ?? ""
            guard !name.isEmpty else { return nil }

            // Get RxCUI if available
            let rxcuis = openfda["rxcui"] as? [String]
            let rxcui = rxcuis?.first ?? ""

            return DrugSearchResult(rxcui: rxcui, name: name)
        } catch {
            lookupFailed = true
            return nil
        }
    }

    // MARK: - MedlinePlus Spanish Drug Info

    func fetchSpanishInfo(rxcui: String) async -> SpanishDrugInfo? {
        if let cached = cache[rxcui], cached.spanishInfo != nil {
            return cached.spanishInfo
        }

        let urlString = "https://connect.medlineplus.gov/service?mainSearchCriteria.v.cs=2.16.840.1.113883.6.88&mainSearchCriteria.v.c=\(rxcui)&informationRecipient.languageCode.c=es&knowledgeResponseType=application/json"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let info = parseMedlinePlusResponse(data)
            if let info {
                updateCache(rxcui: rxcui, spanishInfo: info)
            }
            return info
        } catch {
            return nil
        }
    }

    private func parseMedlinePlusResponse(_ data: Data) -> SpanishDrugInfo? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let feed = json["feed"] as? [String: Any],
              let entries = feed["entry"] as? [[String: Any]],
              let first = entries.first else {
            return nil
        }

        let title = (first["title"] as? [String: Any])?["_value"] as? String ?? ""
        let summary = (first["summary"] as? [String: Any])?["_value"] as? String ?? ""
        var url: String?
        if let links = first["link"] as? [[String: Any]], let firstLink = links.first {
            url = firstLink["href"] as? String
        }

        let cleaned = summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        guard !title.isEmpty else { return nil }
        return SpanishDrugInfo(title: title, summary: cleaned, url: url)
    }

    // MARK: - Interaction Checking

    func checkInteractions(rxcuis: [String]) async -> [DrugInteraction] {
        guard rxcuis.count >= 2 else { return [] }
        let joined = rxcuis.joined(separator: "+")
        let urlString = "https://rxnav.nlm.nih.gov/REST/interaction/list.json?rxcuis=\(joined)"
        guard let url = URL(string: urlString) else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            interactionCheckFailed = false
            return parseInteractionResponse(data)
        } catch {
            interactionCheckFailed = true
            return []
        }
    }

    private func parseInteractionResponse(_ data: Data) -> [DrugInteraction] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let groups = json["fullInteractionTypeGroup"] as? [[String: Any]] else {
            return []
        }

        var results: [DrugInteraction] = []
        for group in groups {
            guard let types = group["fullInteractionType"] as? [[String: Any]] else { continue }
            for type in types {
                guard let pairs = type["interactionPair"] as? [[String: Any]] else { continue }
                for pair in pairs {
                    let desc = pair["description"] as? String ?? ""
                    let severity = pair["severity"] as? String
                    var drug1Name = "", drug1Rxcui = "", drug2Name = "", drug2Rxcui = ""
                    if let concepts = pair["interactionConcept"] as? [[String: Any]] {
                        if concepts.count >= 2 {
                            if let item1 = concepts[0]["minConceptItem"] as? [String: Any] {
                                drug1Name = item1["name"] as? String ?? ""
                                drug1Rxcui = item1["rxcui"] as? String ?? ""
                            }
                            if let item2 = concepts[1]["minConceptItem"] as? [String: Any] {
                                drug2Name = item2["name"] as? String ?? ""
                                drug2Rxcui = item2["rxcui"] as? String ?? ""
                            }
                        }
                    }
                    results.append(DrugInteraction(
                        drug1Name: drug1Name, drug1Rxcui: drug1Rxcui,
                        drug2Name: drug2Name, drug2Rxcui: drug2Rxcui,
                        description: desc, severity: severity
                    ))
                }
            }
        }
        return results
    }

    // MARK: - Cache

    func getCachedInfo(rxcui: String) -> CachedDrugInfo? {
        cache[rxcui]
    }

    private func updateCache(rxcui: String, spanishInfo: SpanishDrugInfo) {
        if var existing = cache[rxcui] {
            existing = CachedDrugInfo(rxcui: existing.rxcui, name: existing.name, spanishInfo: spanishInfo, cachedDate: Date())
            cache[rxcui] = existing
        } else {
            cache[rxcui] = CachedDrugInfo(rxcui: rxcui, name: "", spanishInfo: spanishInfo, cachedDate: Date())
        }
        saveCache()
    }

    func cacheSearchResult(_ result: DrugSearchResult) {
        if cache[result.rxcui] == nil {
            cache[result.rxcui] = CachedDrugInfo(rxcui: result.rxcui, name: result.name, spanishInfo: nil, cachedDate: Date())
            saveCache()
        }
    }

    private func loadCache() {
        guard let url = cacheFileURL,
              let data = try? Data(contentsOf: url),
              let loaded = try? JSONDecoder().decode([String: CachedDrugInfo].self, from: data) else { return }
        cache = loaded
    }

    private func saveCache() {
        guard let url = cacheFileURL,
              let data = try? JSONEncoder().encode(cache) else { return }
        try? data.write(to: url)
    }
}
