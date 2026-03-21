//
//  HealthKitService.swift
//  MiSana
//
//  Created by Abe Perez on 3/20/26.
//

import Foundation
import Combine
import HealthKit

// MARK: - Health Summary

struct DailySample: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct HealthSummary {
    var steps: [DailySample] = []
    var heartRate: [DailySample] = []
    var activeEnergy: [DailySample] = []
    var sleepHours: [DailySample] = []
    var systolic: [DailySample] = []
    var diastolic: [DailySample] = []
    var bloodOxygen: [DailySample] = []
    var bodyMass: Double?

    // Detailed data for detail views
    var deepSleep: [DailySample] = []
    var remSleep: [DailySample] = []
    var timeInBed: [DailySample] = []
    var restingHeartRate: [DailySample] = []
    var heartRateMin: [DailySample] = []
    var heartRateMax: [DailySample] = []
    var distance: [DailySample] = []
    var flightsClimbed: [DailySample] = []

    var todaySteps: Int {
        Int(steps.last?.value ?? 0)
    }

    var lastHeartRate: Int {
        Int(heartRate.last?.value ?? 0)
    }

    var lastNightSleep: Double {
        sleepHours.last?.value ?? 0
    }

    var lastRestingHR: Int {
        Int(restingHeartRate.last?.value ?? 0)
    }

    var avgSleep: Double {
        guard !sleepHours.isEmpty else { return 0 }
        return sleepHours.map(\.value).reduce(0, +) / Double(sleepHours.count)
    }

    var avgSteps: Int {
        guard !steps.isEmpty else { return 0 }
        return Int(steps.map(\.value).reduce(0, +) / Double(steps.count))
    }

    var sleepQuality: Double {
        guard !sleepHours.isEmpty, !timeInBed.isEmpty else { return 0 }
        let totalAsleep = sleepHours.map(\.value).reduce(0, +)
        let totalInBed = timeInBed.map(\.value).reduce(0, +)
        guard totalInBed > 0 else { return 0 }
        return min((totalAsleep / totalInBed) * 100, 100)
    }

    var sleepDeficit: Double {
        let target = 8.0 * Double(sleepHours.count)
        let actual = sleepHours.map(\.value).reduce(0, +)
        return actual - target
    }

    var isEmpty: Bool {
        steps.isEmpty && heartRate.isEmpty && activeEnergy.isEmpty &&
        sleepHours.isEmpty && systolic.isEmpty && bloodOxygen.isEmpty && bodyMass == nil
    }

    /// Generate a concise plain-text summary for LLM context (max ~200 words)
    func generateContextString() -> String? {
        guard !isEmpty else { return nil }

        var parts: [String] = []
        let df = DateFormatter()
        df.dateFormat = "d/M"

        if !steps.isEmpty {
            let avg = Int(steps.map(\.value).reduce(0, +) / Double(steps.count))
            let today = todaySteps
            parts.append("Pasos: hoy \(today), promedio 7 dias \(avg)")
        }

        if !heartRate.isEmpty {
            let values = heartRate.map(\.value)
            let min = Int(values.min() ?? 0)
            let max = Int(values.max() ?? 0)
            let last = lastHeartRate
            parts.append("Ritmo cardiaco: ultimo \(last) bpm, rango 7 dias \(min)-\(max) bpm")
        }

        if !activeEnergy.isEmpty {
            let avg = Int(activeEnergy.map(\.value).reduce(0, +) / Double(activeEnergy.count))
            parts.append("Energia activa: promedio \(avg) kcal/dia")
        }

        if !sleepHours.isEmpty {
            let avg = sleepHours.map(\.value).reduce(0, +) / Double(sleepHours.count)
            let last = lastNightSleep
            parts.append("Sueno: anoche \(String(format: "%.1f", last))h, promedio \(String(format: "%.1f", avg))h")
        }

        if let lastSys = systolic.last?.value, let lastDia = diastolic.last?.value {
            parts.append("Presion arterial: ultima \(Int(lastSys))/\(Int(lastDia)) mmHg")
        }

        if let lastO2 = bloodOxygen.last?.value {
            parts.append("Oxigeno en sangre: ultimo \(Int(lastO2 * 100))%")
        }

        if let mass = bodyMass {
            parts.append("Peso: \(String(format: "%.1f", mass)) kg")
        }

        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: ". ") + "."
    }
}

// MARK: - Service

@MainActor
class HealthKitService: ObservableObject {
    @Published var isAuthorized = false
    @Published var summary = HealthSummary()
    @Published var isLoading = false

    private let store = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        if let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount) { types.insert(stepCount) }
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) { types.insert(heartRate) }
        if let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(activeEnergy) }
        if let sleepAnalysis = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleepAnalysis) }
        if let systolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic) { types.insert(systolic) }
        if let diastolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) { types.insert(diastolic) }
        if let bloodOxygen = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) { types.insert(bloodOxygen) }
        if let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass) { types.insert(bodyMass) }
        if let restingHR = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) { types.insert(restingHR) }
        if let distance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) { types.insert(distance) }
        if let flights = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) { types.insert(flights) }
        return types
    }

    func requestAuthorization() async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await fetchAll()
        } catch {
            print("HealthKit authorization failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Fetch All Data

    func fetchAll() async {
        guard isAvailable else { return }
        isLoading = true

        async let steps = fetchDailySum(identifier: .stepCount, unit: .count())
        async let hr = fetchDailySamples(identifier: .heartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let energy = fetchDailySum(identifier: .activeEnergyBurned, unit: .kilocalorie())
        async let sleep = fetchSleepData()
        async let sys = fetchDailySamples(identifier: .bloodPressureSystolic, unit: .millimeterOfMercury())
        async let dia = fetchDailySamples(identifier: .bloodPressureDiastolic, unit: .millimeterOfMercury())
        async let o2 = fetchDailySamples(identifier: .oxygenSaturation, unit: .percent())
        async let mass = fetchLatestQuantity(identifier: .bodyMass, unit: HKUnit.gramUnit(with: .kilo))
        async let restingHR = fetchDailySamples(identifier: .restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let hrMin = fetchDailyMinMax(identifier: .heartRate, unit: HKUnit.count().unitDivided(by: .minute()), option: .discreteMin)
        async let hrMax = fetchDailyMinMax(identifier: .heartRate, unit: HKUnit.count().unitDivided(by: .minute()), option: .discreteMax)
        async let dist = fetchDailySum(identifier: .distanceWalkingRunning, unit: .meter())
        async let flights = fetchDailySum(identifier: .flightsClimbed, unit: .count())
        async let sleepDetail = fetchDetailedSleepData()

        summary.steps = await steps
        summary.heartRate = await hr
        summary.activeEnergy = await energy
        summary.sleepHours = await sleep
        summary.systolic = await sys
        summary.diastolic = await dia
        summary.bloodOxygen = await o2
        summary.bodyMass = await mass
        summary.restingHeartRate = await restingHR
        summary.heartRateMin = await hrMin
        summary.heartRateMax = await hrMax
        summary.distance = await dist
        summary.flightsClimbed = await flights

        let detail = await sleepDetail
        summary.deepSleep = detail.deep
        summary.remSleep = detail.rem
        summary.timeInBed = detail.inBed

        isLoading = false
    }

    // MARK: - Query Helpers

    /// Fetch daily cumulative sums for the last 7 days (steps, active energy)
    private func fetchDailySum(identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> [DailySample] {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return [] }

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: endDate)) else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let interval = DateComponents(day: 1)
        let anchorDate = calendar.startOfDay(for: endDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, _ in
                var samples: [DailySample] = []
                results?.enumerateStatistics(from: startDate, to: endDate) { stats, _ in
                    let value = stats.sumQuantity()?.doubleValue(for: unit) ?? 0
                    samples.append(DailySample(date: stats.startDate, value: value))
                }
                continuation.resume(returning: samples)
            }

            store.execute(query)
        }
    }

    /// Fetch daily average samples for the last 7 days (heart rate, blood pressure, SpO2)
    private func fetchDailySamples(identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> [DailySample] {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return [] }

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: endDate)) else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let interval = DateComponents(day: 1)
        let anchorDate = calendar.startOfDay(for: endDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: anchorDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, _ in
                var samples: [DailySample] = []
                results?.enumerateStatistics(from: startDate, to: endDate) { stats, _ in
                    if let avg = stats.averageQuantity()?.doubleValue(for: unit) {
                        samples.append(DailySample(date: stats.startDate, value: avg))
                    }
                }
                continuation.resume(returning: samples)
            }

            store.execute(query)
        }
    }

    /// Fetch sleep analysis for the last 7 nights
    private func fetchSleepData() async -> [DailySample] {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: endDate)) else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, _ in
                guard let samples = results as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }

                // Group sleep samples by night (use the start date's calendar day)
                // Only count asleep stages (not inBed)
                var nightlyHours: [Date: Double] = [:]
                for sample in samples {
                    let value = sample.value
                    // HKCategoryValueSleepAnalysis: asleepUnspecified=1, asleepCore=3, asleepDeep=4, asleepREM=5
                    let isAsleep = value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                                   value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                                   value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                                   value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    guard isAsleep else { continue }

                    let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600.0
                    let nightDate = calendar.startOfDay(for: sample.startDate)
                    nightlyHours[nightDate, default: 0] += duration
                }

                let sorted = nightlyHours.sorted { $0.key < $1.key }
                    .map { DailySample(date: $0.key, value: $0.value) }
                continuation.resume(returning: sorted)
            }

            store.execute(query)
        }
    }

    /// Fetch daily min or max for the last 7 days
    private func fetchDailyMinMax(identifier: HKQuantityTypeIdentifier, unit: HKUnit, option: HKStatisticsOptions) async -> [DailySample] {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return [] }

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: endDate)) else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let interval = DateComponents(day: 1)
        let anchorDate = calendar.startOfDay(for: endDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: option,
                anchorDate: anchorDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, _ in
                var samples: [DailySample] = []
                results?.enumerateStatistics(from: startDate, to: endDate) { stats, _ in
                    let value: Double?
                    if option == .discreteMin {
                        value = stats.minimumQuantity()?.doubleValue(for: unit)
                    } else {
                        value = stats.maximumQuantity()?.doubleValue(for: unit)
                    }
                    if let v = value {
                        samples.append(DailySample(date: stats.startDate, value: v))
                    }
                }
                continuation.resume(returning: samples)
            }

            store.execute(query)
        }
    }

    /// Fetch detailed sleep data broken down by stage
    private func fetchDetailedSleepData() async -> (deep: [DailySample], rem: [DailySample], inBed: [DailySample]) {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return ([], [], []) }

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: endDate)) else { return ([], [], []) }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, _ in
                guard let samples = results as? [HKCategorySample] else {
                    continuation.resume(returning: ([], [], []))
                    return
                }

                var deepByNight: [Date: Double] = [:]
                var remByNight: [Date: Double] = [:]
                var inBedByNight: [Date: Double] = [:]

                for sample in samples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600.0
                    let nightDate = calendar.startOfDay(for: sample.startDate)

                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.inBed.rawValue:
                        inBedByNight[nightDate, default: 0] += duration
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        deepByNight[nightDate, default: 0] += duration
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        remByNight[nightDate, default: 0] += duration
                    case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                         HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                        // Count all asleep time as in-bed too if no explicit inBed samples
                        inBedByNight[nightDate, default: 0] += duration
                    default:
                        break
                    }
                }

                let deep = deepByNight.sorted { $0.key < $1.key }.map { DailySample(date: $0.key, value: $0.value) }
                let rem = remByNight.sorted { $0.key < $1.key }.map { DailySample(date: $0.key, value: $0.value) }
                let inBed = inBedByNight.sorted { $0.key < $1.key }.map { DailySample(date: $0.key, value: $0.value) }

                continuation.resume(returning: (deep, rem, inBed))
            }

            store.execute(query)
        }
    }

    /// Fetch most recent single value (body mass)
    private func fetchLatestQuantity(identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, results, _ in
                let value = (results?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }

            store.execute(query)
        }
    }
}
