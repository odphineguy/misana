//
//  SymptomLogService.swift
//  MiSana
//
//  Created by Abe Perez on 4/13/26.
//

import Foundation

// MARK: - Data Model

struct SymptomLogEntry: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let symptoms: [String]
    let severity: Int                    // 1-5 scale
    let notes: String

    // Auto-captured health context
    let heartRate: Int?                  // BPM from HealthKit
    let bloodPressure: String?           // "128/82" from HealthKit
    let bloodOxygen: Int?                // percentage
    let steps: Int?                      // today's steps
    let sleepHours: Double?              // last night

    // Medication adherence
    let medicationsTaken: [MedAdherence]

    struct MedAdherence: Codable, Identifiable {
        var id = UUID()
        let name: String
        let dosage: String
        let taken: Bool
    }
}

// MARK: - Pattern Insights

struct SymptomPatternInsight: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let doctorQuestion: String
    let count: Int
}

enum SymptomPatternAnalyzer {
    static func insights(from entries: [SymptomLogEntry], language: String) -> [SymptomPatternInsight] {
        guard entries.count >= 3 else { return [] }

        let isSpanish = language == "es"
        var insights: [SymptomPatternInsight] = []
        insights.append(contentsOf: frequentSymptomInsights(from: entries, isSpanish: isSpanish))
        insights.append(contentsOf: headacheContextInsights(from: entries, isSpanish: isSpanish))
        insights.append(contentsOf: medicationAdherenceInsights(from: entries, isSpanish: isSpanish))

        return Array(insights.prefix(4))
    }

    private static func frequentSymptomInsights(from entries: [SymptomLogEntry], isSpanish: Bool) -> [SymptomPatternInsight] {
        var counts: [String: Int] = [:]
        for entry in entries {
            for symptom in entry.symptoms {
                counts[symptom, default: 0] += 1
            }
        }

        return counts
            .filter { $0.value >= 3 }
            .sorted { $0.value > $1.value }
            .prefix(2)
            .map { symptom, count in
                SymptomPatternInsight(
                    title: isSpanish ? "Síntoma repetido" : "Repeated symptom",
                    detail: isSpanish ?
                        "\(symptom) aparece en \(count) registros." :
                        "\(symptom) appears in \(count) entries.",
                    doctorQuestion: isSpanish ?
                        "Pregunta para tu doctor: ¿deberíamos revisar qué puede estar relacionado con estos episodios?" :
                        "Question for your doctor: should we review what may be related to these episodes?",
                    count: count
                )
            }
    }

    private static func headacheContextInsights(from entries: [SymptomLogEntry], isSpanish: Bool) -> [SymptomPatternInsight] {
        let headacheEntries = entries.filter { entry in
            entry.symptoms.contains { symptom in
                symptom.localizedStandardContains("headache") ||
                symptom.localizedStandardContains("dolor de cabeza")
            }
        }

        guard headacheEntries.count >= 2 else { return [] }

        var insights: [SymptomPatternInsight] = []

        let lowSleepEntries = headacheEntries.filter { entry in
            guard let sleepHours = entry.sleepHours else { return false }
            return sleepHours < 6
        }
        if lowSleepEntries.count >= 2 {
            insights.append(
                SymptomPatternInsight(
                    title: isSpanish ? "Dolor de cabeza y sueño" : "Headache and sleep",
                    detail: isSpanish ?
                        "\(lowSleepEntries.count) registros de dolor de cabeza ocurrieron después de menos de 6 horas de sueño." :
                        "\(lowSleepEntries.count) headache entries happened after less than 6 hours of sleep.",
                    doctorQuestion: isSpanish ?
                        "Pregunta para tu doctor: ¿deberíamos revisar sueño, ronquidos o descanso alrededor de estos dolores?" :
                        "Question for your doctor: should we review sleep, snoring, or rest around these headaches?",
                    count: lowSleepEntries.count
                )
            )
        }

        let elevatedBPEntries = headacheEntries.filter { entry in
            guard let bloodPressure = entry.bloodPressure else { return false }
            return isElevatedBloodPressure(bloodPressure)
        }
        if elevatedBPEntries.count >= 2 {
            insights.append(
                SymptomPatternInsight(
                    title: isSpanish ? "Dolor de cabeza y presión" : "Headache and blood pressure",
                    detail: isSpanish ?
                        "\(elevatedBPEntries.count) registros de dolor de cabeza tuvieron presión arterial elevada." :
                        "\(elevatedBPEntries.count) headache entries included elevated blood pressure readings.",
                    doctorQuestion: isSpanish ?
                        "Pregunta para tu doctor: ¿deberíamos revisar tus lecturas de presión cuando aparece el dolor?" :
                        "Question for your doctor: should we review your blood pressure readings when headaches happen?",
                    count: elevatedBPEntries.count
                )
            )
        }

        return insights
    }

    private static func medicationAdherenceInsights(from entries: [SymptomLogEntry], isSpanish: Bool) -> [SymptomPatternInsight] {
        let missedMedEntries = entries.filter { entry in
            entry.medicationsTaken.contains { !$0.taken }
        }

        guard missedMedEntries.count >= 2 else { return [] }

        return [
            SymptomPatternInsight(
                title: isSpanish ? "Síntomas y medicinas omitidas" : "Symptoms and missed medicines",
                detail: isSpanish ?
                    "\(missedMedEntries.count) registros incluyen una medicina marcada como no tomada." :
                    "\(missedMedEntries.count) entries include a medicine marked as missed.",
                doctorQuestion: isSpanish ?
                    "Pregunta para tu doctor: ¿deberíamos revisar si los síntomas cambian cuando se omite una medicina?" :
                    "Question for your doctor: should we review whether symptoms change when a medicine is missed?",
                count: missedMedEntries.count
            )
        ]
    }

    private static func isElevatedBloodPressure(_ value: String) -> Bool {
        let parts = value.split(separator: "/").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 2 else { return false }
        return parts[0] >= 130 || parts[1] >= 80
    }
}

// MARK: - Common Symptoms

enum CommonSymptom: String, CaseIterable, Identifiable {
    case headache, dizziness, fatigue, nausea, bodyPain, chestPain
    case cough, sorethroat, fever, shortBreath, stomachPain, backPain
    case insomnia, anxiety, heartPalpitations, swelling

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .headache: return "brain.head.profile"
        case .dizziness: return "figure.fall"
        case .fatigue: return "battery.25percent"
        case .nausea: return "stomach"
        case .bodyPain: return "figure.arms.open"
        case .chestPain: return "heart.slash.fill"
        case .cough: return "mouth.fill"
        case .sorethroat: return "waveform.path"
        case .fever: return "thermometer.high"
        case .shortBreath: return "lungs.fill"
        case .stomachPain: return "stomach"
        case .backPain: return "figure.walk"
        case .insomnia: return "moon.zzz.fill"
        case .anxiety: return "brain"
        case .heartPalpitations: return "heart.fill"
        case .swelling: return "drop.triangle.fill"
        }
    }

    func label(for lang: AppLanguage) -> String {
        switch self {
        case .headache: return lang == .spanish ? "Dolor de cabeza" : "Headache"
        case .dizziness: return lang == .spanish ? "Mareos" : "Dizziness"
        case .fatigue: return lang == .spanish ? "Fatiga" : "Fatigue"
        case .nausea: return lang == .spanish ? "Náusea" : "Nausea"
        case .bodyPain: return lang == .spanish ? "Dolor de cuerpo" : "Body pain"
        case .chestPain: return lang == .spanish ? "Dolor de pecho" : "Chest pain"
        case .cough: return lang == .spanish ? "Tos" : "Cough"
        case .sorethroat: return lang == .spanish ? "Dolor de garganta" : "Sore throat"
        case .fever: return lang == .spanish ? "Fiebre" : "Fever"
        case .shortBreath: return lang == .spanish ? "Falta de aire" : "Shortness of breath"
        case .stomachPain: return lang == .spanish ? "Dolor de estómago" : "Stomach pain"
        case .backPain: return lang == .spanish ? "Dolor de espalda" : "Back pain"
        case .insomnia: return lang == .spanish ? "Insomnio" : "Insomnia"
        case .anxiety: return lang == .spanish ? "Ansiedad" : "Anxiety"
        case .heartPalpitations: return lang == .spanish ? "Palpitaciones" : "Heart palpitations"
        case .swelling: return lang == .spanish ? "Hinchazón" : "Swelling"
        }
    }
}

// MARK: - Persistence

class SymptomLogStore {
    static let shared = SymptomLogStore()

    private var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("symptom_log.json")
    }

    func load() -> [SymptomLogEntry] {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([SymptomLogEntry].self, from: data) else {
            return []
        }
        return entries.sorted { $0.date > $1.date }
    }

    func save(_ entries: [SymptomLogEntry]) {
        guard let url = fileURL,
              let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url)
    }

    func add(_ entry: SymptomLogEntry) {
        var entries = load()
        entries.insert(entry, at: 0)
        save(entries)
    }

    // MARK: - Export

    func generateExport(entries: [SymptomLogEntry], language: String) -> String {
        let isSpanish = language == "es"
        let title = isSpanish ? "Registro de Síntomas — MiSana" : "Symptom Log — MiSana"
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)

        var lines: [String] = []
        lines.append(title)
        lines.append(isSpanish ? "Exportado: \(dateStr)" : "Exported: \(dateStr)")
        lines.append(isSpanish ? "Entradas: \(entries.count)" : "Entries: \(entries.count)")
        lines.append(String(repeating: "─", count: 40))

        let insights = SymptomPatternAnalyzer.insights(from: entries, language: language)
        if !insights.isEmpty {
            lines.append("")
            lines.append(isSpanish ? "Patrones notados (no diagnóstico)" : "Patterns noticed (not a diagnosis)")
            for insight in insights {
                lines.append("• \(insight.detail)")
                lines.append("  \(insight.doctorQuestion)")
            }
            lines.append(String(repeating: "─", count: 40))
        }

        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short

        for entry in entries {
            lines.append("")
            lines.append("📅 \(df.string(from: entry.date))")
            lines.append(isSpanish ?
                "   Síntomas: \(entry.symptoms.joined(separator: ", "))" :
                "   Symptoms: \(entry.symptoms.joined(separator: ", "))")
            lines.append(isSpanish ?
                "   Severidad: \(entry.severity)/5" :
                "   Severity: \(entry.severity)/5")

            // Health data
            var healthParts: [String] = []
            if let hr = entry.heartRate { healthParts.append("\(isSpanish ? "Corazón" : "HR"): \(hr) bpm") }
            if let bp = entry.bloodPressure { healthParts.append("\(isSpanish ? "Presión" : "BP"): \(bp)") }
            if let o2 = entry.bloodOxygen { healthParts.append("O₂: \(o2)%") }
            if let sleep = entry.sleepHours { healthParts.append("\(isSpanish ? "Sueño" : "Sleep"): \(String(format: "%.1f", sleep))h") }
            if let steps = entry.steps { healthParts.append("\(isSpanish ? "Pasos" : "Steps"): \(steps)") }

            if !healthParts.isEmpty {
                lines.append("   \(isSpanish ? "Salud" : "Health"): \(healthParts.joined(separator: " | "))")
            }

            // Medication adherence
            if !entry.medicationsTaken.isEmpty {
                let taken = entry.medicationsTaken.filter(\.taken).map(\.name)
                let missed = entry.medicationsTaken.filter { !$0.taken }.map(\.name)
                if !taken.isEmpty {
                    lines.append("   ✅ \(isSpanish ? "Tomó" : "Took"): \(taken.joined(separator: ", "))")
                }
                if !missed.isEmpty {
                    lines.append("   ❌ \(isSpanish ? "No tomó" : "Missed"): \(missed.joined(separator: ", "))")
                }
            }

            if !entry.notes.isEmpty {
                lines.append("   \(isSpanish ? "Notas" : "Notes"): \(entry.notes)")
            }
        }

        lines.append("")
        lines.append(String(repeating: "─", count: 40))
        lines.append(isSpanish ?
            "Generado por MiSana — Comparte con tu doctor." :
            "Generated by MiSana — Share with your doctor.")

        return lines.joined(separator: "\n")
    }
}
