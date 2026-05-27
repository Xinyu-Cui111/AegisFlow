import SwiftUI
import Combine
import Combine

// MARK: - 核心数据管理器
// 负责管理应用全局状态，包括用户数据、健康指标、设置等
class DataManager: ObservableObject {
    
    // MARK: - 单例
    static let shared = DataManager()
    
    // MARK: - 用户信息
    @Published var userId: String = ""
    @Published var userName: String = "用户"
    @Published var userEmail: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var onboardingCompleted: Bool = false
    
    // MARK: - 今日健康数据
    @Published var dailySteps: Int = 0
    @Published var dailyStepsGoal: Int = 10000
    @Published var waterIntakeMl: Int = 0
    @Published var waterGoalMl: Int = 3000
    @Published var caloriesBurned: Int = 0
    @Published var caloriesGoal: Int = 2000
    @Published var sleepMinutes: Int = 0
    @Published var sleepGoalMinutes: Int = 480
    @Published var stressLevel: Int = 0
    @Published var heartRateAvg: Int = 0
    
    // MARK: - 用户身体数据
    @Published var heightCm: Float = 170
    @Published var weightKg: Float = 65
    @Published var bmi: Float = 0
    @Published var bodyFatPercent: Float = 0
    
    // MARK: - 设置状态
    @Published var isNotificationEnabled: Bool = true
    @Published var isWaterReminderEnabled: Bool = true
    @Published var isExerciseReminderEnabled: Bool = true
    @Published var isSleepReminderEnabled: Bool = true
    @Published var isPrivacyPublic: Bool = false
    // 桌宠全局状态（用于个人中心和悬浮球联动）
    @Published var deskPetEnabled: Bool = true
    @Published var deskPetMascotName: String = "DeskPetMascot"
    @Published var deskPetPositionX: Double = Double(UIScreen.main.bounds.width - 52)
    @Published var deskPetPositionY: Double = Double(UIScreen.main.bounds.height * 0.58)
    @Published var deskPetShowBubble: Bool = false
    
    // MARK: - 周趋势数据
    @Published var weeklyStepData: [StepDataPoint] = []
    @Published var weeklyWaterData: [WaterDataPoint] = []
    @Published var weeklySleepData: [SleepDataPoint] = []
    
    // MARK: - 选中日期
    @Published var selectedDate: Date = Date()
    
    // MARK: - 加载状态
    @Published var isLoading: Bool = false
    @Published var isSyncing: Bool = false
    
    // MARK: - 计算属性
    var bmiValue: Float {
        guard heightCm > 0 else { return 0 }
        let heightM = heightCm / 100
        return weightKg / (heightM * heightM)
    }
    
    var stepProgress: Double {
        guard dailyStepsGoal > 0 else { return 0 }
        return min(Double(dailySteps) / Double(dailyStepsGoal), 1.0)
    }
    
    var waterProgress: Double {
        guard waterGoalMl > 0 else { return 0 }
        return min(Double(waterIntakeMl) / Double(waterGoalMl), 1.0)
    }
    
    var caloriesProgress: Double {
        guard caloriesGoal > 0 else { return 0 }
        return min(Double(caloriesBurned) / Double(caloriesGoal), 1.0)
    }
    
    var sleepProgress: Double {
        guard sleepGoalMinutes > 0 else { return 0 }
        return min(Double(sleepMinutes) / Double(sleepGoalMinutes), 1.0)
    }
    
    // MARK: - 初始化
    init() {
        loadSettings()
        loadMockData()
    }

    // MARK: - 设置加载/保存
    private func loadSettings() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "deskPetEnabled") != nil {
            deskPetEnabled = defaults.bool(forKey: "deskPetEnabled")
        }
        if let name = defaults.string(forKey: "deskPetMascotName") {
            deskPetMascotName = name
        }
        let px = defaults.double(forKey: "deskPetPositionX")
        let py = defaults.double(forKey: "deskPetPositionY")
        if px != 0 && py != 0 {
            deskPetPositionX = px
            deskPetPositionY = py
        }
        if defaults.object(forKey: "deskPetShowBubble") != nil {
            deskPetShowBubble = defaults.bool(forKey: "deskPetShowBubble")
        }
    }

    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(deskPetEnabled, forKey: "deskPetEnabled")
        defaults.set(deskPetMascotName, forKey: "deskPetMascotName")
        defaults.set(deskPetPositionX, forKey: "deskPetPositionX")
        defaults.set(deskPetPositionY, forKey: "deskPetPositionY")
        defaults.set(deskPetShowBubble, forKey: "deskPetShowBubble")
    }
    
    // MARK: - 方法
    
    /// 增加饮水量
    func addWater(amountMl: Int) {
        waterIntakeMl += amountMl
    }
    
    /// 更新步数
    func updateSteps(_ steps: Int) {
        dailySteps = steps
    }
    
    /// 更新选中的日期
    func selectDate(_ date: Date) {
        selectedDate = date
    }
    
    /// 获取问候语
    func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "早上好"
        case 12..<14:
            return "中午好"
        case 14..<18:
            return "下午好"
        default:
            return "晚上好"
        }
    }
    
    /// 获取当前星期几 (1=周日, 2=周一, ..., 7=周六)
    func getDayOfWeek() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday
    }
    
    /// 加载模拟数据
    private func loadMockData() {
        // 模拟周数据
        let days = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        let stepValues = [8500, 12000, 6800, 9200, 10500, 7800, 0]
        let waterValues = [1800, 2200, 1500, 2000, 2500, 1200, 0]
        let sleepValues = [420, 480, 360, 450, 390, 420, 0]
        
        weeklyStepData = zip(days, stepValues).map { StepDataPoint(day: $0, value: $1) }
        weeklyWaterData = zip(days, waterValues).map { WaterDataPoint(day: $0, value: $1) }
        weeklySleepData = zip(days, sleepValues).map { SleepDataPoint(day: $0, value: $1) }
        
        // 模拟今日数据
        dailySteps = 6789
        waterIntakeMl = 1200
        caloriesBurned = 450
        sleepMinutes = 420
        stressLevel = 35
        heartRateAvg = 72
    }
}

// MARK: - 数据模型

struct StepDataPoint: Identifiable {
    let id = UUID()
    let day: String
    let value: Int
}

struct WaterDataPoint: Identifiable {
    let id = UUID()
    let day: String
    let value: Int
}

struct SleepDataPoint: Identifiable {
    let id = UUID()
    let day: String
    let value: Int
}

// MARK: - 记录类型枚举
enum LogType: String, CaseIterable, Identifiable {
    case meal = "meal"
    case water = "water"
    case mood = "mood"
    case exercise = "exercise"
    case headache = "headache"
    case bloodPressure = "blood_pressure"
    case bloodSugar = "blood_sugar"
    case meditation = "meditation"
    case sleep = "sleep"
    case menstrual = "menstrual"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .meal: return "饮食"
        case .water: return "饮水"
        case .mood: return "心情"
        case .exercise: return "运动"
        case .headache: return "症状"
        case .bloodPressure: return "血压"
        case .bloodSugar: return "血糖"
        case .meditation: return "冥想"
        case .sleep: return "睡眠"
        case .menstrual: return "经期"
        }
    }
    
    var icon: String {
        switch self {
        case .meal: return "fork.knife"
        case .water: return "drop.fill"
        case .mood: return "face.smiling"
        case .exercise: return "figure.run"
        case .headache: return "cross.case.fill"
        case .bloodPressure: return "waveform.path.ecg"
        case .bloodSugar: return "drop.triangle.fill"
        case .meditation: return "brain.head.profile"
        case .sleep: return "bed.double.fill"
        case .menstrual: return "heart.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .meal: return .orangeWarm
        case .water: return .androidBlue
        case .mood: return .yellowBright
        case .exercise: return .successGreen
        case .headache: return .errorRed
        case .bloodPressure: return .errorRed
        case .bloodSugar: return .orangeWarm
        case .meditation: return .tealDeep
        case .sleep: return .purpleSoft
        case .menstrual: return Color(hex: "#E91E63")
        }
    }
    
    var emoji: String {
        switch self {
        case .meal: return "🍽️"
        case .water: return "💧"
        case .mood: return "😊"
        case .exercise: return "🏃"
        case .headache: return "🤕"
        case .bloodPressure: return "❤️"
        case .bloodSugar: return "🩸"
        case .meditation: return "🧘"
        case .sleep: return "😴"
        case .menstrual: return "🌸"
        }
    }
}

// MARK: - AI模式枚举
enum AiMode: String, CaseIterable {
    case order = "ORDER"
    case chat = "CHAT"
    case page = "PAGE"
    
    var title: String {
        switch self {
        case .order: return "下单"
        case .chat: return "对话"
        case .page: return "页面"
        }
    }
}

// MARK: - 导航路由
enum AppRoute: Hashable {
    case splash
    case onboarding
    case auth
    case main
    case dashboard
    case plan
    case healthData
    case chat
    case profile
    case settings
    case notificationSettings
    case privacySettings
    case editProfile
    case deviceManagement
    case logRecord(type: LogType)
    case exercisePlanDetail(planId: String)
    case microExerciseGuide(exerciseId: String)
    case generatedPage(html: String)
    case statistics
    case twin3D
    case avatar
    case notificationCenter
    case knowledgeGraph
    case foodAnalysis
    case healthGoals
    case helpSupport
    case level
    case rewards
    case premium
    case insightDetail(category: String, title: String)
    case elemeOrder(url: String)
}
