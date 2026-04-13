//
//  MedicationReminderService.swift
//  MiSana
//
//  Created by Abe Perez on 4/13/26.
//

import Foundation
import UserNotifications

/// Manages local push notifications for medication reminders.
/// All notifications are local — no server, no account, fully private.
@MainActor
class MedicationReminderService {

    static let shared = MedicationReminderService()

    // MARK: - Authorization

    /// Request notification permission. Call on first medication save with a schedule.
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            print("🔔 Notification permission: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            print("🔔 Notification permission error: \(error)")
            return false
        }
    }

    // MARK: - Schedule Reminders

    /// Schedule notifications for a medication based on its frequency and time.
    /// Replaces any existing notifications for this medication.
    func scheduleReminders(for medication: Medication, language: String) {
        // Remove existing reminders for this medication first
        removeReminders(for: medication)

        guard let frequency = medication.scheduleFrequency,
              frequency != .asNeeded,
              let scheduleTime = medication.scheduleTime else {
            return
        }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: scheduleTime)
        let minute = calendar.component(.minute, from: scheduleTime)
        let isSpanish = language == "es"

        // Build notification content
        let content = UNMutableNotificationContent()
        content.title = isSpanish ? "Hora de tu medicina" : "Time for your medication"
        content.body = isSpanish ?
            "\(medication.name) — \(medication.dosage)" :
            "\(medication.name) — \(medication.dosage)"
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"

        // Schedule based on frequency
        switch frequency {
        case .daily:
            // Every day at the scheduled time
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: reminderID(for: medication, suffix: "daily"),
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)

        case .twiceDaily:
            // At scheduled time and 12 hours later
            for (i, h) in [hour, (hour + 12) % 24].enumerated() {
                var dateComponents = DateComponents()
                dateComponents.hour = h
                dateComponents.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(
                    identifier: reminderID(for: medication, suffix: "twice-\(i)"),
                    content: content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(request)
            }

        case .threeTimesDaily:
            // At scheduled time, +8h, +16h
            for (i, h) in [hour, (hour + 8) % 24, (hour + 16) % 24].enumerated() {
                var dateComponents = DateComponents()
                dateComponents.hour = h
                dateComponents.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(
                    identifier: reminderID(for: medication, suffix: "thrice-\(i)"),
                    content: content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(request)
            }

        case .everyOtherDay:
            // Use a 48-hour interval trigger
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 48 * 3600, repeats: true)
            let request = UNNotificationRequest(
                identifier: reminderID(for: medication, suffix: "eod"),
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)

        case .weekly:
            // Same day of the week at the scheduled time
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.weekday = calendar.component(.weekday, from: Date())
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: reminderID(for: medication, suffix: "weekly"),
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)

        case .asNeeded:
            break // No reminders for as-needed
        }

        print("🔔 Scheduled reminders for \(medication.name) (\(frequency.rawValue) at \(hour):\(minute))")
    }

    // MARK: - Remove Reminders

    /// Remove all notifications for a specific medication
    func removeReminders(for medication: Medication) {
        let prefix = "med-\(medication.id.uuidString)"
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let idsToRemove = requests
                .filter { $0.identifier.hasPrefix(prefix) }
                .map(\.identifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
            if !idsToRemove.isEmpty {
                print("🔔 Removed \(idsToRemove.count) reminders for medication \(medication.name)")
            }
        }
    }

    /// Remove all medication reminders
    func removeAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🔔 Removed all medication reminders")
    }

    // MARK: - Sync All

    /// Re-schedule reminders for all medications (call after load or edit)
    func syncReminders(for medications: [Medication], language: String) {
        // Remove all existing, then re-schedule
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for med in medications {
            scheduleReminders(for: med, language: language)
        }
        print("🔔 Synced reminders for \(medications.count) medications")
    }

    // MARK: - Helpers

    private func reminderID(for medication: Medication, suffix: String) -> String {
        "med-\(medication.id.uuidString)-\(suffix)"
    }
}
