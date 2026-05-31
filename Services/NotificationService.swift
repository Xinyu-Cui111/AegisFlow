import Foundation
import UIKit
import UserNotifications

// MARK: - 通知服务
class NotificationService {
    static let shared = NotificationService()

    private init() {}

    // MARK: - 请求权限
    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: options)

            if granted {
                await MainActor.run {
                    registerForRemoteNotifications()
                }
            }

            return granted
        } catch {
            print("通知权限请求失败: \(error)")
            return false
        }
    }

    // MARK: - 注册远程通知
    @MainActor
    private func registerForRemoteNotifications() {
        #if !targetEnvironment(simulator)
            UIApplication.shared.registerForRemoteNotifications()
        #endif
    }

    // MARK: - 获取权限状态
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - 安排本地通知

    /// 立即测试通知（默认 3 秒后触发）
    func scheduleInstantTestNotification(after seconds: TimeInterval = 3) async {
        let content = UNMutableNotificationContent()
        content.title = "提醒测试成功"
        content.body = "AegisFlow 已接入系统通知，后续提醒会按你的设置准时送达。"
        content.sound = .default
        content.categoryIdentifier = "INSTANT_TEST"
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .active
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: "instant_test_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("安排测试通知失败: \(error)")
        }
    }

    /// 安排补水提醒
    func scheduleWaterReminder(at time: DateComponents, identifier: String = "water_reminder") async
    {
        let content = UNMutableNotificationContent()
        content.title = "💧 补水提醒"
        content.body = "该喝水了！保持身体水分对健康很重要。"
        content.sound = .default
        content.categoryIdentifier = "WATER_REMINDER"

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(
            identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("补水提醒已安排: \(time.hour ?? 0):\(time.minute ?? 0)")
        } catch {
            print("安排补水提醒失败: \(error)")
        }
    }

    /// 安排运动提醒
    func scheduleExerciseReminder(at time: DateComponents, identifier: String = "exercise_reminder")
        async
    {
        let content = UNMutableNotificationContent()
        content.title = "🏃 运动时间到"
        content.body = "是时候活动一下了！短暂的运动可以提升精力。"
        content.sound = .default
        content.categoryIdentifier = "EXERCISE_REMINDER"

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(
            identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("运动提醒已安排: \(time.hour ?? 0):\(time.minute ?? 0)")
        } catch {
            print("安排运动提醒失败: \(error)")
        }
    }

    /// 安排睡眠提醒
    func scheduleSleepReminder(at time: DateComponents, identifier: String = "sleep_reminder") async
    {
        let content = UNMutableNotificationContent()
        content.title = "😴 该休息了"
        content.body = "早睡早起对身体更健康，良好的睡眠是健康的基石。"
        content.sound = .default
        content.categoryIdentifier = "SLEEP_REMINDER"

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(
            identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("睡眠提醒已安排: \(time.hour ?? 0):\(time.minute ?? 0)")
        } catch {
            print("安排睡眠提醒失败: \(error)")
        }
    }

    /// 安排每日总结通知
    func scheduleDailySummary(at time: DateComponents) async {
        let content = UNMutableNotificationContent()
        content.title = "📊 今日健康总结"
        content.body = "查看今天的健康数据和分析报告。"
        content.sound = .default
        content.categoryIdentifier = "DAILY_SUMMARY"

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_summary", content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("安排每日总结失败: \(error)")
        }
    }

    /// 安排固定时段提醒（可配置工作日）
    func scheduleFixedSlotReminders(
        items: [FixedSlotReminderItem],
        weekdaysOnly: Bool,
        identifierPrefix: String = "fixed_slot"
    ) async {
        await cancelNotifications(matchingPrefix: identifierPrefix)

        let weekdays = weekdaysOnly ? [2, 3, 4, 5, 6] : [1, 2, 3, 4, 5, 6, 7]
        for item in items {
            let time = Calendar.current.dateComponents([.hour, .minute], from: item.time)
            for weekday in weekdays {
                var date = DateComponents()
                date.weekday = weekday
                date.hour = time.hour
                date.minute = time.minute

                let content = UNMutableNotificationContent()
                content.title = "固定时段提醒"
                content.subtitle = item.note.trimmingCharacters(in: .whitespacesAndNewlines)
                content.body =
                    item.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "到你设定的健康关注时段了，花 1 分钟完成记录与回顾。"
                    : "\(item.note) · 花 1 分钟完成记录与回顾。"
                content.sound = .default
                content.categoryIdentifier = "FIXED_SLOT"
                if #available(iOS 15.0, *) {
                    content.interruptionLevel = .active
                }

                let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
                let identifier =
                    "\(identifierPrefix)_w\(weekday)_\(time.hour ?? 0)_\(time.minute ?? 0)"
                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )

                do {
                    try await UNUserNotificationCenter.current().add(request)
                } catch {
                    print("安排固定时段提醒失败: \(error)")
                }
            }
        }
    }

    // MARK: - 取消通知
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            identifier
        ])
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func cancelNotifications(matchingPrefix prefix: String) async {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let identifiers =
            pending
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }
        guard !identifiers.isEmpty else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: identifiers)
    }

    // MARK: - 获取待发送通知
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    // MARK: - 设置通知类别和操作
    func setupNotificationCategories() {
        // 补水提醒类别
        let waterCategory = UNNotificationCategory(
            identifier: "WATER_REMINDER",
            actions: [
                UNNotificationAction(identifier: "DRINK_NOW", title: "立即记录", options: .foreground),
                UNNotificationAction(identifier: "SNOOZE", title: "稍后提醒", options: []),
            ],
            intentIdentifiers: [],
            options: []
        )

        // 运动提醒类别
        let exerciseCategory = UNNotificationCategory(
            identifier: "EXERCISE_REMINDER",
            actions: [
                UNNotificationAction(
                    identifier: "START_EXERCISE", title: "开始运动", options: .foreground),
                UNNotificationAction(identifier: "SNOOZE", title: "稍后提醒", options: []),
            ],
            intentIdentifiers: [],
            options: []
        )

        // 睡眠提醒类别
        let sleepCategory = UNNotificationCategory(
            identifier: "SLEEP_REMINDER",
            actions: [
                UNNotificationAction(
                    identifier: "GO_TO_SLEEP", title: "准备睡觉", options: .foreground),
                UNNotificationAction(identifier: "SNOOZE", title: "稍后提醒", options: []),
            ],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            waterCategory,
            exerciseCategory,
            sleepCategory,
        ])
    }
}

// MARK: - 通知设置管理器
class NotificationSettingsManager {
    static let shared = NotificationSettingsManager()

    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - 设置状态
    var isNotificationEnabled: Bool {
        get { defaults.bool(forKey: "notification_enabled") }
        set { defaults.set(newValue, forKey: "notification_enabled") }
    }

    var isWaterReminderEnabled: Bool {
        get { defaults.bool(forKey: "water_reminder_enabled") }
        set { defaults.set(newValue, forKey: "water_reminder_enabled") }
    }

    var isExerciseReminderEnabled: Bool {
        get { defaults.bool(forKey: "exercise_reminder_enabled") }
        set { defaults.set(newValue, forKey: "exercise_reminder_enabled") }
    }

    var isSleepReminderEnabled: Bool {
        get { defaults.bool(forKey: "sleep_reminder_enabled") }
        set { defaults.set(newValue, forKey: "sleep_reminder_enabled") }
    }

    var isWeeklyReportEnabled: Bool {
        get { defaults.bool(forKey: "weekly_report_enabled") }
        set { defaults.set(newValue, forKey: "weekly_report_enabled") }
    }

    // MARK: - 提醒时间
    var waterReminderTime: DateComponents {
        get {
            let hour = defaults.integer(forKey: "water_reminder_hour")
            let minute = defaults.integer(forKey: "water_reminder_minute")
            return DateComponents(hour: hour > 0 ? hour : 9, minute: minute)
        }
        set {
            defaults.set(newValue.hour ?? 9, forKey: "water_reminder_hour")
            defaults.set(newValue.minute ?? 0, forKey: "water_reminder_minute")
        }
    }

    var exerciseReminderTime: DateComponents {
        get {
            let hour = defaults.integer(forKey: "exercise_reminder_hour")
            let minute = defaults.integer(forKey: "exercise_reminder_minute")
            return DateComponents(hour: hour > 0 ? hour : 18, minute: minute)
        }
        set {
            defaults.set(newValue.hour ?? 18, forKey: "exercise_reminder_hour")
            defaults.set(newValue.minute ?? 0, forKey: "exercise_reminder_minute")
        }
    }

    var sleepReminderTime: DateComponents {
        get {
            let hour = defaults.integer(forKey: "sleep_reminder_hour")
            let minute = defaults.integer(forKey: "sleep_reminder_minute")
            return DateComponents(hour: hour > 0 ? hour : 22, minute: minute)
        }
        set {
            defaults.set(newValue.hour ?? 22, forKey: "sleep_reminder_hour")
            defaults.set(newValue.minute ?? 0, forKey: "sleep_reminder_minute")
        }
    }

    // MARK: - 应用设置
    func applySettings() async {
        let notificationService = NotificationService.shared

        // 取消所有现有通知
        notificationService.cancelAllNotifications()

        // 如果通知被禁用，直接返回
        guard isNotificationEnabled else { return }

        // 应用补水提醒
        if isWaterReminderEnabled {
            await notificationService.scheduleWaterReminder(at: waterReminderTime)
        }

        // 应用运动提醒
        if isExerciseReminderEnabled {
            await notificationService.scheduleExerciseReminder(at: exerciseReminderTime)
        }

        // 应用睡眠提醒
        if isSleepReminderEnabled {
            await notificationService.scheduleSleepReminder(at: sleepReminderTime)
        }

        // 应用每周报告
        if isWeeklyReportEnabled {
            await notificationService.scheduleDailySummary(at: DateComponents(hour: 20, minute: 0))
        }
    }
}
