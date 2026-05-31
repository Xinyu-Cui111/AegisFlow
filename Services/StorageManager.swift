import Foundation

// MARK: - Token存储管理器（与 APIClient 使用同一套 UserDefaults 键）
class TokenStorage {
    static let shared = TokenStorage()
    
    private let tokenExpiryDefaultsKey = "tokenExpiry"
    
    private init() {}
    
    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: APIConfig.accessTokenKey) }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: APIConfig.accessTokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: APIConfig.accessTokenKey)
            }
        }
    }
    
    var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: APIConfig.refreshTokenKey) }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: APIConfig.refreshTokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: APIConfig.refreshTokenKey)
            }
        }
    }
    
    var tokenExpiry: Date? {
        get { UserDefaults.standard.object(forKey: tokenExpiryDefaultsKey) as? Date }
        set {
            if let d = newValue {
                UserDefaults.standard.set(d, forKey: tokenExpiryDefaultsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: tokenExpiryDefaultsKey)
            }
        }
    }
    
    var isTokenValid: Bool {
        guard let token = accessToken, !token.isEmpty else { return false }
        guard let expiry = tokenExpiry else { return false }
        return expiry > Date()
    }
    
    func clearAll() {
        accessToken = nil
        refreshToken = nil
        tokenExpiry = nil
    }
    
    func clearTokens() {
        clearAll()
    }
    
    var isAuthenticated: Bool {
        accessToken != nil
    }
}

// MARK: - UserDefaults存储管理器
class PreferencesStorage {
    static let shared = PreferencesStorage()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Keys
    private enum Keys {
        static let isLoggedIn = "isLoggedIn"
        static let userId = "user_id"
        static let userName = "user_name"
        static let userEmail = "user_email"
        static let onboardingCompleted = "onboardingCompleted"
        static let isPremium = "is_premium"
        
        // 健康目标
        static let dailyStepsGoal = "daily_steps_goal"
        static let dailyWaterGoal = "daily_water_goal"
        static let dailySleepGoal = "daily_sleep_goal"
        static let dailyCaloriesGoal = "daily_calories_goal"
        
        // 通知设置
        static let notificationEnabled = "notification_enabled"
        static let waterReminderEnabled = "water_reminder_enabled"
        static let exerciseReminderEnabled = "exercise_reminder_enabled"
    }
    
    // MARK: - 用户状态
    var isLoggedIn: Bool {
        get { defaults.bool(forKey: Keys.isLoggedIn) }
        set { defaults.set(newValue, forKey: Keys.isLoggedIn) }
    }
    
    var userId: String? {
        get { defaults.string(forKey: Keys.userId) }
        set { defaults.set(newValue, forKey: Keys.userId) }
    }
    
    var userName: String? {
        get { defaults.string(forKey: Keys.userName) }
        set { defaults.set(newValue, forKey: Keys.userName) }
    }
    
    var userEmail: String? {
        get { defaults.string(forKey: Keys.userEmail) }
        set { defaults.set(newValue, forKey: Keys.userEmail) }
    }
    
    var onboardingCompleted: Bool {
        get { defaults.bool(forKey: Keys.onboardingCompleted) }
        set { defaults.set(newValue, forKey: Keys.onboardingCompleted) }
    }
    
    var isPremium: Bool {
        get { defaults.bool(forKey: Keys.isPremium) }
        set { defaults.set(newValue, forKey: Keys.isPremium) }
    }
    
    // MARK: - 健康目标
    var dailyStepsGoal: Int {
        get {
            let value = defaults.integer(forKey: Keys.dailyStepsGoal)
            return value > 0 ? value : 10000
        }
        set { defaults.set(newValue, forKey: Keys.dailyStepsGoal) }
    }
    
    var dailyWaterGoal: Int {
        get {
            let value = defaults.integer(forKey: Keys.dailyWaterGoal)
            return value > 0 ? value : 3000
        }
        set { defaults.set(newValue, forKey: Keys.dailyWaterGoal) }
    }
    
    var dailySleepGoal: Int {
        get {
            let value = defaults.integer(forKey: Keys.dailySleepGoal)
            return value > 0 ? value : 480
        }
        set { defaults.set(newValue, forKey: Keys.dailySleepGoal) }
    }
    
    var dailyCaloriesGoal: Int {
        get {
            let value = defaults.integer(forKey: Keys.dailyCaloriesGoal)
            return value > 0 ? value : 2000
        }
        set { defaults.set(newValue, forKey: Keys.dailyCaloriesGoal) }
    }
    
    // MARK: - 通知设置
    var notificationEnabled: Bool {
        get { defaults.bool(forKey: Keys.notificationEnabled) }
        set { defaults.set(newValue, forKey: Keys.notificationEnabled) }
    }
    
    var waterReminderEnabled: Bool {
        get { defaults.bool(forKey: Keys.waterReminderEnabled) }
        set { defaults.set(newValue, forKey: Keys.waterReminderEnabled) }
    }
    
    var exerciseReminderEnabled: Bool {
        get { defaults.bool(forKey: Keys.exerciseReminderEnabled) }
        set { defaults.set(newValue, forKey: Keys.exerciseReminderEnabled) }
    }
    
    // MARK: - 清除所有数据
    func clearAll() {
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
    }
}
