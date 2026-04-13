//
//  SymptomLogView.swift
//  MiSana
//
//  Created by Abe Perez on 4/13/26.
//

import SwiftUI

struct SymptomLogView: View {
    let selectedLanguage: AppLanguage
    @EnvironmentObject private var healthKitService: HealthKitService
    @State private var logEntries: [SymptomLogEntry] = []
    @State private var showNewEntry = false
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(selectedLanguage == .spanish ?
                             "Registro de síntomas" :
                             "Symptom tracker")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(selectedLanguage == .spanish ?
                             "Registra cómo te sientes. Tu doctor verá los patrones." :
                             "Log how you feel. Your doctor will see the patterns.")
                            .font(.subheadline)
                            .foregroundStyle(.primary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.brand.opacity(0.20), Color.brand.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.brand.opacity(0.15), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)

                    // New entry button
                    Button { showNewEntry = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text(selectedLanguage == .spanish ?
                                 "¿Cómo te sientes hoy?" :
                                 "How do you feel today?")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color.brand.opacity(0.4), radius: 8, y: 4)
                    }
                    .padding(.horizontal)

                    // History
                    if logEntries.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text(selectedLanguage == .spanish ?
                                 "Todavía no hay registros.\nEmpieza a registrar cómo te sientes." :
                                 "No entries yet.\nStart logging how you feel.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                    } else {
                        // Export button
                        HStack {
                            Text(selectedLanguage == .spanish ?
                                 "\(logEntries.count) registros" :
                                 "\(logEntries.count) entries")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                showClearConfirm = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                    Text(selectedLanguage == .spanish ? "Borrar todo" : "Clear all")
                                }
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.red)
                            }
                            ShareLink(item: SymptomLogStore.shared.generateExport(
                                entries: logEntries,
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
                        .padding(.horizontal)

                        // Log entries (compact rows with long-press to delete)
                        VStack(spacing: 2) {
                            ForEach(logEntries) { entry in
                                CompactLogRow(entry: entry, selectedLanguage: selectedLanguage)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            withAnimation { deleteEntry(entry) }
                                        } label: {
                                            Label(selectedLanguage == .spanish ? "Eliminar" : "Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .navigationTitle(selectedLanguage == .spanish ? "Síntomas" : "Symptoms")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showNewEntry) {
                NewSymptomLogSheet(
                    selectedLanguage: selectedLanguage,
                    healthSummary: healthKitService.summary,
                    onSave: { entry in
                        SymptomLogStore.shared.add(entry)
                        logEntries = SymptomLogStore.shared.load()
                    }
                )
            }
            .onAppear {
                logEntries = SymptomLogStore.shared.load()
            }
            .alert(
                selectedLanguage == .spanish ? "¿Borrar todo?" : "Clear all entries?",
                isPresented: $showClearConfirm
            ) {
                Button(selectedLanguage == .spanish ? "Borrar" : "Clear", role: .destructive) {
                    logEntries.removeAll()
                    SymptomLogStore.shared.save([])
                }
                Button(selectedLanguage == .spanish ? "Cancelar" : "Cancel", role: .cancel) {}
            } message: {
                Text(selectedLanguage == .spanish ?
                     "Se eliminarán todos los registros de síntomas." :
                     "All symptom log entries will be deleted.")
            }
        }
    }

    private func deleteEntry(_ entry: SymptomLogEntry) {
        logEntries.removeAll { $0.id == entry.id }
        SymptomLogStore.shared.save(logEntries)
    }
}

// MARK: - Compact Log Row

struct CompactLogRow: View {
    let entry: SymptomLogEntry
    let selectedLanguage: AppLanguage

    private var severityColor: Color {
        switch entry.severity {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        default: return .red
        }
    }

    private var shortDate: String {
        let df = DateFormatter()
        df.dateFormat = selectedLanguage == .spanish ? "d MMM, h:mm a" : "MMM d, h:mm a"
        df.locale = Locale(identifier: selectedLanguage == .spanish ? "es" : "en")
        return df.string(from: entry.date)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Severity indicator
            Circle()
                .fill(severityColor)
                .frame(width: 10, height: 10)

            // Date
            Text(shortDate)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)

            // Symptoms (inline)
            Text(entry.symptoms.joined(separator: ", "))
                .font(.caption)
                .lineLimit(1)

            Spacer()

            // Missed meds indicator
            let missed = entry.medicationsTaken.filter { !$0.taken }.count
            if missed > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "pill.fill")
                        .font(.system(size: 8))
                    Text("×\(missed)")
                        .font(.caption2)
                }
                .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Log Entry Card (detail, kept for future expansion)

struct LogEntryCard: View {
    let entry: SymptomLogEntry
    let selectedLanguage: AppLanguage

    private var dateLabel: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        df.locale = Locale(identifier: selectedLanguage == .spanish ? "es" : "en")
        return df.string(from: entry.date)
    }

    private var severityColor: Color {
        switch entry.severity {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        default: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Date + severity
            HStack {
                Text(dateLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { i in
                        Circle()
                            .fill(i <= entry.severity ? severityColor : Color.primary.opacity(0.1))
                            .frame(width: 8, height: 8)
                    }
                }
            }

            // Symptoms
            FlowLayout(spacing: 6) {
                ForEach(entry.symptoms, id: \.self) { symptom in
                    Text(symptom)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.brand.opacity(0.12))
                        .foregroundStyle(.brand)
                        .clipShape(Capsule())
                }
            }

            // Health snapshot
            let healthParts = buildHealthParts()
            if !healthParts.isEmpty {
                HStack(spacing: 0) {
                    ForEach(Array(healthParts.enumerated()), id: \.offset) { i, part in
                        if i > 0 {
                            Text(" · ")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Text(part)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Medication adherence
            if !entry.medicationsTaken.isEmpty {
                Divider()
                HStack(spacing: 8) {
                    ForEach(entry.medicationsTaken) { med in
                        HStack(spacing: 3) {
                            Image(systemName: med.taken ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(med.taken ? .green : .red)
                            Text(med.name)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                    }
                }
            }

            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func buildHealthParts() -> [String] {
        var parts: [String] = []
        if let hr = entry.heartRate { parts.append("❤️ \(hr) bpm") }
        if let bp = entry.bloodPressure { parts.append("🩺 \(bp)") }
        if let o2 = entry.bloodOxygen { parts.append("🫁 \(o2)%") }
        if let sleep = entry.sleepHours { parts.append("😴 \(String(format: "%.1f", sleep))h") }
        if let steps = entry.steps { parts.append("🚶 \(steps)") }
        return parts
    }
}

// MARK: - Flow Layout (wrapping chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}

// MARK: - New Entry Sheet

struct NewSymptomLogSheet: View {
    let selectedLanguage: AppLanguage
    let healthSummary: HealthSummary
    let onSave: (SymptomLogEntry) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSymptoms: Set<CommonSymptom> = []
    @State private var severity: Int = 0
    @State private var notes = ""
    @State private var medAdherence: [SymptomLogEntry.MedAdherence] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Symptom selection
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.text.square.fill")
                                .foregroundStyle(.brand)
                            Text(selectedLanguage == .spanish ? "¿Qué sientes?" : "What do you feel?")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        FlowLayout(spacing: 8) {
                            ForEach(CommonSymptom.allCases) { symptom in
                                Button {
                                    if selectedSymptoms.contains(symptom) {
                                        selectedSymptoms.remove(symptom)
                                    } else {
                                        selectedSymptoms.insert(symptom)
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: symptom.icon)
                                            .font(.caption2)
                                        Text(symptom.label(for: selectedLanguage))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(selectedSymptoms.contains(symptom) ? Color.brand : Color.clear)
                                    .foregroundStyle(selectedSymptoms.contains(symptom) ? .white : .primary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(selectedSymptoms.contains(symptom) ? Color.clear : Color.primary.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    // Severity
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "gauge.medium")
                                .foregroundStyle(.brand)
                            Text(selectedLanguage == .spanish ? "¿Qué tan fuerte?" : "How severe?")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        HStack(spacing: 0) {
                            ForEach(1...5, id: \.self) { level in
                                Button {
                                    severity = level
                                } label: {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(severity >= level ? severityColor(level) : Color.primary.opacity(0.1))
                                            .frame(width: 32, height: 32)
                                            .overlay {
                                                Text("\(level)")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(severity >= level ? .white : .secondary)
                                            }
                                        Text(severityLabel(level))
                                            .font(.system(size: 9))
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    // Medication adherence
                    if !medAdherence.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "pill.fill")
                                    .foregroundStyle(.brand)
                                Text(selectedLanguage == .spanish ? "¿Tomaste tus medicinas hoy?" : "Did you take your meds today?")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }

                            ForEach($medAdherence) { $med in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(med.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(med.dosage)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button {
                                        med = SymptomLogEntry.MedAdherence(
                                            id: med.id, name: med.name,
                                            dosage: med.dosage, taken: !med.taken
                                        )
                                    } label: {
                                        Image(systemName: med.taken ? "checkmark.circle.fill" : "circle")
                                            .font(.title2)
                                            .foregroundStyle(med.taken ? .green : Color.primary.opacity(0.2))
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }

                    // Health snapshot (auto-captured, read-only)
                    let healthParts = capturedHealthParts()
                    if !healthParts.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.text.square.fill")
                                    .foregroundStyle(.red)
                                Text(selectedLanguage == .spanish ? "Datos de salud (automático)" : "Health data (automatic)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }

                            HStack(spacing: 0) {
                                ForEach(Array(healthParts.enumerated()), id: \.offset) { i, part in
                                    if i > 0 {
                                        Text(" · ")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    Text(part)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.red.opacity(0.12), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "note.text")
                                .foregroundStyle(.brand)
                            Text(selectedLanguage == .spanish ? "Notas (opcional)" : "Notes (optional)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal)

                        TextField(
                            selectedLanguage == .spanish ?
                                "Algo más que quieras anotar..." :
                                "Anything else you want to note...",
                            text: $notes,
                            axis: .vertical
                        )
                        .lineLimit(3...5)
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }

                    // Save button
                    Button { saveEntry() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text(selectedLanguage == .spanish ? "Guardar registro" : "Save entry")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedSymptoms.isEmpty || severity == 0 ? Color.gray.opacity(0.5) : Color.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: selectedSymptoms.isEmpty || severity == 0 ? .clear : Color.brand.opacity(0.4), radius: 8, y: 4)
                    }
                    .disabled(selectedSymptoms.isEmpty || severity == 0)
                    .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                .padding(.top)
            }
            .navigationTitle(selectedLanguage == .spanish ? "Nuevo registro" : "New entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selectedLanguage == .spanish ? "Cancelar" : "Cancel") { dismiss() }
                }
            }
            .onAppear { loadMedications() }
        }
    }

    // MARK: - Helpers

    private func severityColor(_ level: Int) -> Color {
        switch level {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        case 5: return .red
        default: return .gray
        }
    }

    private func severityLabel(_ level: Int) -> String {
        let isSpanish = selectedLanguage == .spanish
        switch level {
        case 1: return isSpanish ? "Leve" : "Mild"
        case 2: return isSpanish ? "Algo" : "Some"
        case 3: return isSpanish ? "Medio" : "Moderate"
        case 4: return isSpanish ? "Fuerte" : "Severe"
        case 5: return isSpanish ? "Muy mal" : "Very bad"
        default: return ""
        }
    }

    private func capturedHealthParts() -> [String] {
        var parts: [String] = []
        if healthSummary.lastHeartRate > 0 { parts.append("❤️ \(healthSummary.lastHeartRate) bpm") }
        if let sys = healthSummary.systolic.last?.value, let dia = healthSummary.diastolic.last?.value {
            parts.append("🩺 \(Int(sys))/\(Int(dia))")
        }
        if let o2 = healthSummary.bloodOxygen.last?.value { parts.append("🫁 \(Int(o2 * 100))%") }
        if healthSummary.lastNightSleep > 0 { parts.append("😴 \(String(format: "%.1f", healthSummary.lastNightSleep))h") }
        if healthSummary.todaySteps > 0 { parts.append("🚶 \(healthSummary.todaySteps)") }
        return parts
    }

    private func loadMedications() {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("medications.json"),
              let data = try? Data(contentsOf: url),
              let meds = try? JSONDecoder().decode([Medication].self, from: data) else { return }

        medAdherence = meds
            .filter { $0.scheduleFrequency != nil && $0.scheduleFrequency != .asNeeded }
            .map { SymptomLogEntry.MedAdherence(name: $0.name, dosage: $0.dosage, taken: false) }
    }

    private func saveEntry() {
        let symptomLabels = selectedSymptoms.map { $0.label(for: selectedLanguage) }

        let entry = SymptomLogEntry(
            date: Date(),
            symptoms: symptomLabels,
            severity: severity,
            notes: notes,
            heartRate: healthSummary.lastHeartRate > 0 ? healthSummary.lastHeartRate : nil,
            bloodPressure: {
                if let sys = healthSummary.systolic.last?.value, let dia = healthSummary.diastolic.last?.value {
                    return "\(Int(sys))/\(Int(dia))"
                }
                return nil
            }(),
            bloodOxygen: healthSummary.bloodOxygen.last.map { Int($0.value * 100) },
            steps: healthSummary.todaySteps > 0 ? healthSummary.todaySteps : nil,
            sleepHours: healthSummary.lastNightSleep > 0 ? healthSummary.lastNightSleep : nil,
            medicationsTaken: medAdherence
        )

        onSave(entry)
        dismiss()
    }
}
