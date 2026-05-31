import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    @Published var isNotificationEnabled: Bool = true
    @Published var isWaterReminderEnabled: Bool = true
    @Published var isExerciseReminderEnabled: Bool = true
    @Published var isSleepReminderEnabled: Bool = true
    @Published var reminderStartHour: Int = 8
    @Published var reminderEndHour: Int = 22
    @Published var reminderInterval: Int = 60
    @Published var isPrivacyPublic: Bool = false
    @Published var isDataSharingEnabled: Bool = false
    @Published var isLocationEnabled: Bool = false
    @Published var error: String? = nil
    
    func loadSettings() {
        let defaults = UserDefaults.standard
        isNotificationEnabled = defaults.bool(forKey: "notificationEnabled")
        isWaterReminderEnabled = defaults.bool(forKey: "waterReminder")
        isExerciseReminderEnabled = defaults.bool(forKey: "exerciseReminder")
        isSleepReminderEnabled = defaults.bool(forKey: "sleepReminder")
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isNotificationEnabled, forKey: "notificationEnabled")
        defaults.set(isWaterReminderEnabled, forKey: "waterReminder")
        defaults.set(isExerciseReminderEnabled, forKey: "exerciseReminder")
        defaults.set(isSleepReminderEnabled, forKey: "sleepReminder")
    }
}
