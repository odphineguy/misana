//
//  DoctorBriefView.swift
//  MiSana
//
//  A clean, PDF-style brief the user can show their doctor.
//  Read-only document. All content is derived from SymptomLogStore,
//  medications.json, and SymptomPatternAnalyzer — nothing is fabricated.
//

import SwiftUI

struct DoctorBriefView: View {
    let selectedLanguage: AppLanguage
    let patientConcern: String?
    let visitTypeLabel: String?

    @Environment(\.dismiss) private var dismiss
    @State private var pdfURL: URL?

    private var data: DoctorBriefData {
        DoctorBriefData.assemble(
            language: selectedLanguage,
            patientConcern: patientConcern,
            visitTypeLabel: visitTypeLabel
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                DoctorBriefDocument(data: data, selectedLanguage: selectedLanguage)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
            }
            .background(Color.miSana.screenCream.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(selectedLanguage == .spanish ? "Cerrar" : "Close") { dismiss() }
                        .foregroundStyle(Color.miSana.brand)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let url = pdfURL {
                        ShareLink(item: url) {
                            Label(
                                selectedLanguage == .spanish ? "Compartir" : "Share",
                                systemImage: "square.and.arrow.up"
                            )
                            .labelStyle(.iconOnly)
                            .foregroundStyle(Color.miSana.brand)
                        }
                    } else {
                        Button {
                            pdfURL = renderPDF()
                        } label: {
                            Label(
                                selectedLanguage == .spanish ? "PDF" : "PDF",
                                systemImage: "doc.richtext"
                            )
                            .labelStyle(.iconOnly)
                            .foregroundStyle(Color.miSana.brand)
                        }
                    }
                }
            }
        }
        .onAppear { pdfURL = renderPDF() }
    }

    // MARK: - PDF rendering

    @MainActor
    private func renderPDF() -> URL? {
        let pageWidth: CGFloat = 612   // US Letter @ 72dpi
        let renderable = DoctorBriefDocument(data: data, selectedLanguage: selectedLanguage)
            .frame(width: pageWidth - 48)
            .padding(24)
            .background(Color.white)

        let renderer = ImageRenderer(content: renderable)
        renderer.scale = 2.0

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("MiSana-Doctor-Brief.pdf")

        var rendered = false
        renderer.render { size, context in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
            rendered = true
        }
        return rendered ? url : nil
    }
}

// MARK: - Document layout (used in-app AND for PDF export)

struct DoctorBriefDocument: View {
    let data: DoctorBriefData
    let selectedLanguage: AppLanguage

    private var isSpanish: Bool { selectedLanguage == .spanish }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            BriefDivider()
            dateRangeChip

            if let concern = data.patientConcern, !concern.isEmpty {
                section(title: isSpanish ? "MOTIVO DE LA VISITA" : "VISIT CONCERN") {
                    if let visitType = data.visitTypeLabel {
                        Text(visitType)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.miSana.fg)
                    }
                    BriefBody(concern)
                }
            }

            section(title: isSpanish ? "SÍNTOMAS PRINCIPALES" : "TOP SYMPTOMS") {
                if data.topSymptoms.isEmpty {
                    BriefBody(
                        isSpanish
                            ? "Aún no hay síntomas registrados en este rango."
                            : "No symptoms logged in this range yet."
                    )
                } else {
                    ForEach(Array(data.topSymptoms.enumerated()), id: \.offset) { idx, row in
                        if idx > 0 { BriefDivider() }
                        BriefRow(left: row.name, right: row.detail, rightMuted: true)
                    }
                }
            }

            section(title: isSpanish ? "PATRONES" : "PATTERNS") {
                if data.patterns.isEmpty {
                    BriefBody(
                        isSpanish
                            ? "Todavía no hay patrones claros. Sigue registrando."
                            : "No clear patterns yet. Keep logging."
                    )
                } else {
                    ForEach(Array(data.patterns.enumerated()), id: \.offset) { _, line in
                        BriefBullet(line)
                    }
                }
            }

            if !data.medications.isEmpty {
                section(title: isSpanish ? "MEDICAMENTOS" : "MEDICATIONS") {
                    ForEach(Array(data.medications.enumerated()), id: \.offset) { idx, row in
                        if idx > 0 { BriefDivider() }
                        BriefRow(left: row.name, right: row.detail, rightMuted: true)
                    }
                }
            }

            if !data.contextNotes.isEmpty {
                section(title: isSpanish ? "NOTAS DEL PACIENTE" : "PATIENT NOTES") {
                    ForEach(Array(data.contextNotes.enumerated()), id: \.offset) { idx, note in
                        if idx > 0 { BriefDivider() }
                        BriefNote(date: note.dateLabel, text: note.text)
                    }
                }
            }

            if !data.healthSnapshot.isEmpty {
                section(title: isSpanish ? "INSTANTÁNEA DE SALUD" : "HEALTH SNAPSHOT") {
                    ForEach(Array(data.healthSnapshot.enumerated()), id: \.offset) { idx, row in
                        if idx > 0 { BriefDivider() }
                        BriefRow(left: row.name, right: row.detail, rightMuted: true)
                    }
                }
            }

            if !data.questions.isEmpty {
                section(title: isSpanish ? "PREGUNTAS PARA TU DOCTOR" : "QUESTIONS FOR YOUR DOCTOR") {
                    ForEach(Array(data.questions.enumerated()), id: \.offset) { _, q in
                        BriefBullet(q)
                    }
                }
            }

            footer
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.miSana.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.miSana.hairline, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
    }

    // MARK: Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.miSana.cardSoftBlue)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "list.clipboard.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.miSana.brand)
                    )

                Text(isSpanish ? "Resumen para el doctor" : "Doctor Brief")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.miSana.fg)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 8)

                Text("PDF")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.miSana.brand)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.miSana.cardSoftBlue))
            }

            Text(generatedLine)
                .font(.footnote)
                .foregroundColor(.miSana.fg2)
                .padding(.leading, 52)
        }
    }

    private var generatedLine: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.locale = Locale(identifier: isSpanish ? "es" : "en")
        let date = df.string(from: data.generatedAt)
        return isSpanish ? "MiSana · Generado \(date)" : "MiSana · Generated \(date)"
    }

    private var dateRangeChip: some View {
        Group {
            if let range = data.dateRangeLabel {
                Text(range)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.miSana.brand)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.miSana.cardSoftBlue))
            } else {
                EmptyView()
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            BriefDivider()
            Text(isSpanish ? "FUENTES" : "SOURCES")
                .font(.caption2)
                .fontWeight(.semibold)
                .tracking(1.2)
                .foregroundColor(.miSana.fg3)
            Text(
                isSpanish
                    ? "MedlinePlus · American Heart Association (presión arterial) · CDC (sueño)"
                    : "MedlinePlus · American Heart Association (blood pressure) · CDC (sleep)"
            )
            .font(.caption2)
            .foregroundColor(.miSana.fg2)
            Text(
                isSpanish
                    ? "Resumen observacional generado por MiSana. No es un diagnóstico. Siempre consulta a tu doctor."
                    : "Observational summary generated by MiSana. Not a diagnosis. Always consult your doctor."
            )
            .font(.caption2)
            .foregroundColor(.miSana.fg3)
            .padding(.top, 2)
        }
    }

    // MARK: Section helper
    @ViewBuilder
    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .tracking(1.2)
                .foregroundColor(.miSana.fg3)
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
        }
    }
}

// MARK: - Atoms

private struct BriefDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.miSana.hairline)
            .frame(height: 1)
    }
}

private struct BriefRow: View {
    let left: String
    let right: String
    var rightMuted: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(left)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.miSana.fg)
            Spacer(minLength: 8)
            Text(right)
                .font(.subheadline)
                .foregroundColor(rightMuted ? .miSana.fg2 : .miSana.fg)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct BriefBullet: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("•")
                .font(.subheadline)
                .foregroundColor(.miSana.fg2)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.miSana.fg)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

private struct BriefBody: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.miSana.fg)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BriefNote: View {
    let date: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(date)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.miSana.fg3)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.miSana.fg)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Data assembly

struct DoctorBriefData {
    let generatedAt: Date
    let dateRangeLabel: String?
    let patientConcern: String?
    let visitTypeLabel: String?
    let topSymptoms: [LabeledRow]
    let patterns: [String]
    let medications: [LabeledRow]
    let contextNotes: [DatedNote]
    let healthSnapshot: [LabeledRow]
    let questions: [String]

    struct LabeledRow { let name: String; let detail: String }
    struct DatedNote { let dateLabel: String; let text: String }

    static func assemble(
        language: AppLanguage,
        patientConcern: String?,
        visitTypeLabel: String?
    ) -> DoctorBriefData {
        let isSpanish = language == .spanish
        let langCode = isSpanish ? "es" : "en"
        let entries = SymptomLogStore.shared.load()

        return DoctorBriefData(
            generatedAt: Date(),
            dateRangeLabel: dateRange(for: entries, isSpanish: isSpanish),
            patientConcern: patientConcern?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? patientConcern : nil,
            visitTypeLabel: visitTypeLabel,
            topSymptoms: topSymptoms(from: entries, isSpanish: isSpanish),
            patterns: SymptomPatternAnalyzer
                .insights(from: entries, language: langCode)
                .map(\.detail),
            medications: medicationRows(entries: entries, isSpanish: isSpanish),
            contextNotes: contextNotes(from: entries, isSpanish: isSpanish),
            healthSnapshot: healthSnapshot(from: entries, isSpanish: isSpanish),
            questions: questions(from: entries, isSpanish: isSpanish)
        )
    }

    private static func dateRange(for entries: [SymptomLogEntry], isSpanish: Bool) -> String? {
        guard let earliest = entries.map(\.date).min(),
              let latest = entries.map(\.date).max() else {
            return nil
        }
        let df = DateFormatter()
        df.locale = Locale(identifier: isSpanish ? "es" : "en")
        df.setLocalizedDateFormatFromTemplate("MMM d")

        let yearFmt = DateFormatter()
        yearFmt.locale = df.locale
        yearFmt.dateFormat = "yyyy"
        let year = yearFmt.string(from: latest)

        let left = df.string(from: earliest)
        let right = df.string(from: latest)
        if left == right {
            return "\(left), \(year)"
        }
        return "\(left) – \(right), \(year)"
    }

    private static func topSymptoms(
        from entries: [SymptomLogEntry],
        isSpanish: Bool
    ) -> [LabeledRow] {
        guard !entries.isEmpty else { return [] }

        var counts: [String: Int] = [:]
        var severities: [String: [Int]] = [:]
        for entry in entries {
            for symptom in entry.symptoms {
                counts[symptom, default: 0] += 1
                severities[symptom, default: []].append(entry.severity)
            }
        }

        let sorted = counts.sorted { lhs, rhs in
            lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
        }

        return sorted.prefix(4).map { name, count in
            let sev = severities[name] ?? []
            let entriesWord: String
            if isSpanish {
                entriesWord = count == 1 ? "1 registro" : "\(count) registros"
            } else {
                entriesWord = count == 1 ? "1 entry" : "\(count) entries"
            }

            var detail = entriesWord
            if let lo = sev.min(), let hi = sev.max() {
                let sevLabel = isSpanish ? "severidad" : "severity"
                if lo == hi {
                    detail += " · \(sevLabel) \(lo)"
                } else {
                    detail += " · \(sevLabel) \(lo)–\(hi)"
                }
            }
            return LabeledRow(name: name, detail: detail)
        }
    }

    private static func medicationRows(
        entries: [SymptomLogEntry],
        isSpanish: Bool
    ) -> [LabeledRow] {
        let stored = loadStoredMedications()

        // Tally adherence across log entries.
        var taken: [String: Int] = [:]
        var missed: [String: Int] = [:]
        for entry in entries {
            for med in entry.medicationsTaken {
                let key = med.name.lowercased()
                if med.taken {
                    taken[key, default: 0] += 1
                } else {
                    missed[key, default: 0] += 1
                }
            }
        }

        // Prefer the user's saved medication list; fall back to whatever appears in the log.
        var rows: [LabeledRow] = []
        var consumedKeys = Set<String>()

        for med in stored {
            let key = med.name.lowercased()
            consumedKeys.insert(key)
            let display = formatMedName(med.name, dosage: med.dosage)
            rows.append(
                LabeledRow(
                    name: display,
                    detail: adherenceDetail(
                        taken: taken[key] ?? 0,
                        missed: missed[key] ?? 0,
                        isSpanish: isSpanish
                    )
                )
            )
        }

        // Anything logged but not in the stored list.
        let extraKeys = Set(taken.keys).union(missed.keys).subtracting(consumedKeys)
        for key in extraKeys.sorted() {
            // Recover original casing from a log entry.
            let original = entries
                .flatMap { $0.medicationsTaken }
                .first { $0.name.lowercased() == key }
            let display = formatMedName(
                original?.name ?? key,
                dosage: original?.dosage ?? ""
            )
            rows.append(
                LabeledRow(
                    name: display,
                    detail: adherenceDetail(
                        taken: taken[key] ?? 0,
                        missed: missed[key] ?? 0,
                        isSpanish: isSpanish
                    )
                )
            )
        }

        return rows
    }

    private static func adherenceDetail(taken: Int, missed: Int, isSpanish: Bool) -> String {
        if taken == 0 && missed == 0 {
            return isSpanish ? "Sin registros" : "No log data"
        }
        let takenWord: String
        let missedWord: String
        if isSpanish {
            takenWord = taken == 1 ? "1 dosis tomada" : "\(taken) dosis tomadas"
            missedWord = missed == 1 ? "1 omitida" : "\(missed) omitidas"
        } else {
            takenWord = taken == 1 ? "1 dose taken" : "\(taken) doses taken"
            missedWord = missed == 1 ? "1 missed" : "\(missed) missed"
        }
        if taken > 0 && missed > 0 { return "\(takenWord) · \(missedWord)" }
        if missed > 0 { return missedWord }
        return takenWord
    }

    private static func formatMedName(_ name: String, dosage: String) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDose = dosage.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedDose.isEmpty { return trimmedName }
        if trimmedName.localizedCaseInsensitiveContains(trimmedDose) { return trimmedName }
        return "\(trimmedName) \(trimmedDose)"
    }

    private static func questions(
        from entries: [SymptomLogEntry],
        isSpanish: Bool
    ) -> [String] {
        let raw = SymptomPatternAnalyzer
            .insights(from: entries, language: isSpanish ? "es" : "en")
            .map { stripLeadingQuestionLabel($0.doctorQuestion, isSpanish: isSpanish) }
            .map { capitalizingFirst($0) }

        // Dedupe (case-insensitive) while preserving order.
        var seen = Set<String>()
        var unique: [String] = []
        for q in raw {
            let key = q.lowercased()
            if seen.insert(key).inserted { unique.append(q) }
        }
        return unique
    }

    private static func stripLeadingQuestionLabel(_ text: String, isSpanish: Bool) -> String {
        let prefixes = isSpanish
            ? ["Pregunta para tu doctor: ", "Pregunta: "]
            : ["Question for your doctor: ", "Question: "]
        for p in prefixes where text.hasPrefix(p) {
            return String(text.dropFirst(p.count))
        }
        return text
    }

    private static func capitalizingFirst(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }

    // MARK: Context notes

    private static func contextNotes(
        from entries: [SymptomLogEntry],
        isSpanish: Bool
    ) -> [DatedNote] {
        let df = DateFormatter()
        df.locale = Locale(identifier: isSpanish ? "es" : "en")
        df.setLocalizedDateFormatFromTemplate("MMM d")

        return entries
            .filter { !$0.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .prefix(4)
            .map { entry in
                DatedNote(
                    dateLabel: df.string(from: entry.date),
                    text: entry.notes.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
    }

    // MARK: Health snapshot

    private static func healthSnapshot(
        from entries: [SymptomLogEntry],
        isSpanish: Bool
    ) -> [LabeledRow] {
        guard !entries.isEmpty else { return [] }

        var rows: [LabeledRow] = []

        let heartRates = entries.compactMap(\.heartRate)
        if !heartRates.isEmpty {
            let avg = heartRates.reduce(0, +) / heartRates.count
            rows.append(LabeledRow(
                name: isSpanish ? "Ritmo cardíaco (prom.)" : "Heart rate (avg)",
                detail: "\(avg) bpm"
            ))
        }

        let bps = entries.compactMap(\.bloodPressure).filter { !$0.isEmpty }
        if let mostRecent = bps.first {
            let label = isSpanish ? "Presión arterial (reciente)" : "Blood pressure (recent)"
            rows.append(LabeledRow(name: label, detail: mostRecent))
        }

        let oxygens = entries.compactMap(\.bloodOxygen)
        if !oxygens.isEmpty {
            let avg = oxygens.reduce(0, +) / oxygens.count
            rows.append(LabeledRow(
                name: isSpanish ? "Oxígeno (prom.)" : "Blood oxygen (avg)",
                detail: "\(avg)%"
            ))
        }

        let sleeps = entries.compactMap(\.sleepHours)
        if !sleeps.isEmpty {
            let avg = sleeps.reduce(0, +) / Double(sleeps.count)
            rows.append(LabeledRow(
                name: isSpanish ? "Sueño (prom.)" : "Sleep (avg)",
                detail: String(format: "%.1fh", avg)
            ))
        }

        return rows
    }

    // MARK: Stored medications (read-only mirror of MedicationView's persistence)

    private static func loadStoredMedications() -> [StoredMed] {
        guard let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("medications.json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([StoredMed].self, from: data) else {
            return []
        }
        return decoded
    }

    /// Minimal mirror of the `Medication` model — only the fields the brief needs.
    /// Extra fields in the JSON are ignored by JSONDecoder.
    private struct StoredMed: Codable {
        let name: String
        let dosage: String
    }
}
