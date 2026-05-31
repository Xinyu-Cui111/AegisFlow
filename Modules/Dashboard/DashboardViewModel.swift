import Combine
import SwiftUI

// MARK: - Dashboard视图模型
class DashboardViewModel: ObservableObject {

    // MARK: - 网络请求配置
    private let baseURL = APIConfig.baseURL
    private var token: String? {
        UserDefaults.standard.string(forKey: APIConfig.accessTokenKey)
    }

    // MARK: - 日期选择
    @Published var selectedDate: Date = Date()
    @Published var weekDates: [Date] = []
    @Published var isLoading: Bool = false
    @Published var showLogSheet: Bool = false
    @Published var currentLogType: LogType?
    @Published var showTypePicker: Bool = false

    // MARK: - 今日健康数据
    @Published var dailySteps: Int = 0
    @Published var stepsGoal: Int = 8000
    @Published var waterIntake: Int = 0
    @Published var waterGoal: Int = 2000
    @Published var caloriesBurned: Int = 0
    @Published var caloriesGoal: Int = 500
    @Published var sleepMinutes: Int = 0
    @Published var stressLevel: Int = 0
    @Published var heartRate: Int = 0
    @Published var bloodOxygen: Int = 0
    @Published var bodyTemperature: Double = 0

    // MARK: - 周数据
    @Published var weeklyStepsData: [StepDataPoint] = []
    @Published var weeklyWaterData: [WaterDataPoint] = []
    @Published var weeklySleepData: [SleepDataPoint] = []

    // MARK: - 健康见解
    @Published var todayInsights: [InsightItem] = []
    @Published var todayMotivation: MotivationItem?

    /// 对齐 Android：`LocalDate.dayOfWeek.value` → 周一至周日 1…7。
    /// 用于主题色、膳食关怀等与日期相关的映射。
    @Published private(set) var weeklyDietaryCare: [Int: DietaryCareMessage] = [:]

    // MARK: - 通知相关
    @Published var unreadNotificationCount: Int = 0
    @Published var notificationPreview: [NotificationPreviewItem] = []

    // MARK: - 错误处理
    @Published var error: String? = nil

    // MARK: - 计算属性
    var stepProgress: Double {
        guard stepsGoal > 0 else { return 0 }
        return min(Double(dailySteps) / Double(stepsGoal), 1.0)
    }

    var waterProgress: Double {
        guard waterGoal > 0 else { return 0 }
        return min(Double(waterIntake) / Double(waterGoal), 1.0)
    }

    var caloriesProgress: Double {
        guard caloriesGoal > 0 else { return 0 }
        return min(Double(caloriesBurned) / Double(caloriesGoal), 1.0)
    }

    var sleepHours: Double {
        Double(sleepMinutes) / 60.0
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "早上好"
        case 12..<14: return "中午好"
        case 14..<18: return "下午好"
        default: return "晚上好"
        }
    }

    /// Swift `weekday`: 周日=1…周六=7；返回 Kotlin/Java 风格：周一=1…周日=7
    static func javaDayOfWeek(for date: Date) -> Int {
        let swift = Calendar.current.component(.weekday, from: date)
        return swift == 1 ? 7 : swift - 1
    }

    var javaDayOfWeekForSelectedDate: Int {
        Self.javaDayOfWeek(for: selectedDate)
    }

    var dayTheme: DayTheme {
        DayTheme.forJavaWeekday(javaDayOfWeekForSelectedDate)
    }

    var dietaryCareMessage: DietaryCareMessage? {
        weeklyDietaryCare[javaDayOfWeekForSelectedDate]
    }

    // MARK: Hero 关怀区（对齐 `V2HeroBlob`）

    var heroSubtitleText: String? {
        guard let t = dietaryCareMessage?.title?.trimmingCharacters(in: .whitespacesAndNewlines),
            !t.isEmpty
        else { return nil }
        return t
    }

    var heroPrimaryBodyText: String {
        if let body = dietaryCareMessage?.body?.trimmingCharacters(in: .whitespacesAndNewlines),
            !body.isEmpty
        {
            return body
        }
        if let m = todayMotivation {
            return m.body
        }
        return "保持节奏，今天也是充实的一天！"
    }

    var heroMealAdviceTrimmed: String? {
        guard
            let v = dietaryCareMessage?.mealAdvice?.trimmingCharacters(in: .whitespacesAndNewlines),
            !v.isEmpty
        else { return nil }
        return v
    }

    var heroFocusNutrientTrimmed: String? {
        guard
            let v = dietaryCareMessage?.focusNutrient?.trimmingCharacters(
                in: .whitespacesAndNewlines), !v.isEmpty
        else { return nil }
        return v
    }

    var heroCareBadgeText: String {
        if dietaryCareMessage != nil { return "✨ AI 每日关怀" }
        if let m = todayMotivation, m.isAIGenerated { return "AI 生成" }
        return "每日更新"
    }

    var heroIsLongBody: Bool {
        heroPrimaryBodyText.count > 24
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: selectedDate)
    }

    var formattedDateTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: selectedDate)
    }

    var isFutureDate: Bool {
        Calendar.current.startOfDay(for: selectedDate) > Calendar.current.startOfDay(for: Date())
    }

    /// 是否为「今天」（用于首页文案：查看历史日 / 今日）
    var isSelectedDateToday: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: Date())
    }

    /// 记录表单顶部情境说明（与首页周历 `selectedDate` 对齐；今日无需占用版面）
    var logSheetDateContextLine: String? {
        if isFutureDate {
            return "所选为未来日（\(formattedDateTitle)）；保存后将在当日纳入闭环与统计。"
        }
        if !isSelectedDateToday {
            return "正在为 \(formattedDateTitle) 补记，记录写入该日。"
        }
        return nil
    }

    /// 首页「今日提醒」情境文案（优先日期上下文，其次行为提示）
    var contextualReminderText: String {
        if isFutureDate {
            return "你在查看未来日期；记录与健康闭环将在当日到来后更新。"
        }
        if !isSelectedDateToday {
            return "正在回顾 \(formattedDateTitle) 的数据；左右滑动周历或点日历图标可切换。"
        }
        let hour = Calendar.current.component(.hour, from: Date())
        if waterProgress < 0.35 {
            return "今日饮水仍偏低，下一杯安排在午休前后更容易养成节奏。"
        }
        if stepProgress < 0.3 && hour >= 15 {
            return "活动闭环还差一截，晚饭后散步 15 分钟往往就能补上进度。"
        }
        if sleepHours > 0 && sleepHours < 6 && hour >= 20 {
            return "昨夜睡眠偏短，今晚试试提前 30 分钟放下屏幕，入睡会更顺。"
        }
        return "根据节律，建议今晚 23:30 前入睡，深度睡眠比例通常更稳定。"
    }

    var exerciseReminderCardText: String {
        "轻运动提醒"
    }

    /// 问候语下方的辅助一行：星期主题标签
    var greetingSubtitle: String {
        let theme = dayTheme
        let weekdayName = weekDayName
        let tag = Self.sanitizedSingleLine(theme.tag)
        return "\(weekdayName) · \(tag)"
    }

    var weekDayName: String {
        Self.weekdayChinese(for: selectedDate)
    }

    /// 固定中文星期，避免部分机型 `DateFormatter` + `EEEE` 异常输出问号或替换字符。
    private static func weekdayChinese(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "EEEE"
        let formatted = formatter.string(from: date).trimmingCharacters(in: .whitespacesAndNewlines)
        if !formatted.isEmpty,
            !formatted.contains("?"),
            !formatted.contains("？"),
            !formatted.unicodeScalars.contains(where: { $0.value == 0xFFFD })
        {
            return formatted
        }
        let java = Self.javaDayOfWeek(for: date)
        let names = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let idx = java % 7
        return names[idx]
    }

    // MARK: - 方法
    func selectDate(_ date: Date) {
        selectedDate = date
        buildWeekDates()
        fetchDailyData()
        fetchWeeklyData()
        fetchUnreadNotificationCount()
    }

    func openLogSheet(type: LogType) {
        currentLogType = type
        showLogSheet = true
        showTypePicker = false
    }

    func toggleTypePicker() {
        showTypePicker.toggle()
    }

    func loadData() {
        isLoading = true
        error = nil
        buildWeekDates()
        loadLocalDietaryCareFallback()
        fetchDailyData()
        fetchWeeklyData()
        fetchInsights()
        fetchUnreadNotificationCount()
    }

    /// 下拉刷新：统一触发各数据源（网络回调异步完成）
    @MainActor
    func refreshDashboard() async {
        error = nil
        buildWeekDates()
        loadLocalDietaryCareFallback()
        fetchDailyData()
        fetchWeeklyData()
        fetchInsights()
        fetchUnreadNotificationCount()
        try? await Task.sleep(nanoseconds: 450_000_000)
    }

    /// 与 Android `V2WeekStrip` 一致：默认以「今天」为中心 `±3` 天。
    /// 若当前选中日在该窗口外（例如从日历弹层选了较远日期），则以选中日为锚点居中，保证高亮可见。
    func buildWeekDates() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        let windowAroundToday = (-3...3).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
        let anchor =
            windowAroundToday.contains(where: { calendar.isDate($0, inSameDayAs: selected) })
            ? today : selected
        weekDates = (-3...3).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: anchor)
        }
    }

    /// 与 Android DashboardViewModel.kt 兜底池一致（按周一至周日索引 1…7）。
    func loadLocalDietaryCareFallback() {
        weeklyDietaryCare = [
            1: DietaryCareMessage(
                title: "新的一周从今天开始", body: "早餐加颜色，一片番茄就够\n维C比周一焦虑更解压", mealAdvice: "全麦吐司+鸡蛋+彩色蔬菜",
                focusNutrient: "维生素C"),
            2: DietaryCareMessage(
                title: "离午餐还有一段", body: "一把坚果续命就够\n别让肚子开始抗议", mealAdvice: "午餐多加一份深色蔬菜",
                focusNutrient: "膳食纤维"),
            3: DietaryCareMessage(
                title: "周三能量中点站", body: "午餐主食握拳、蛋白质手掌大\n下午清醒三小时", mealAdvice: "杂粮饭半碗+瘦肉+两份蔬菜",
                focusNutrient: "复合碳水"),
            4: DietaryCareMessage(
                title: "周四水分补够了吗", body: "每小时一小口，不用等渴了再喝\n喝够了午餐自然少吃", mealAdvice: "午餐选清淡汤品代替饮料",
                focusNutrient: "水分"),
            5: DietaryCareMessage(
                title: "周五别放纵太早", body: "晚餐轻一点，7点前吃完\n周末好状态今晚订", mealAdvice: "清蒸或水煮为主，主食减半",
                focusNutrient: "维生素B"),
            6: DietaryCareMessage(
                title: "周末动起来", body: "站起来走8首歌的距离\n腿不沉、脑子也清醒", mealAdvice: "午餐少油高蛋白，为运动储能",
                focusNutrient: "健康脂肪"),
            7: DietaryCareMessage(
                title: "周日轻松收尾", body: "今天主动选一顿轻食\n给明天的自己留点状态", mealAdvice: "沙拉或汤+蛋白质，少主食",
                focusNutrient: "膳食纤维"),
        ]
    }

    func displayNameForGreeting() -> String {
        Self.sanitizedPersonName(PreferencesStorage.shared.userName)
    }

    /// 去掉空白、孤立问号、替换字符；异常时回退「用户」，避免刘海问候区出现「?」占位。
    private static func sanitizedPersonName(_ raw: String?) -> String {
        guard var s = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else {
            return "用户"
        }
        s = String(s.unicodeScalars.filter { $0.value != 0xFFFD })
        s = s.trimmingCharacters(in: CharacterSet(charactersIn: "?？"))
        s = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return "用户" }
        if s.allSatisfy({ $0 == "?" || $0 == "？" }) {
            return "用户"
        }
        return String(s.prefix(36))
    }

    private static func sanitizedSingleLine(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = String(t.unicodeScalars.filter { $0.value != 0xFFFD })
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - 网络请求: 获取今日数据
    func fetchDailyData() {
        guard let token = token, let url = URL(string: "\(baseURL)/health/daily") else {
            handleDataUnavailable("请先登录以同步健康数据")
            return
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "date", value: Self.backendDateFormatter.string(from: selectedDate))
        ]

        guard let requestURL = components?.url else {
            handleDataUnavailable("健康数据地址无效")
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, requestError in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                if let requestError = requestError {
                    self.handleDataUnavailable(requestError.localizedDescription)
                    return
                }

                guard let data = data else {
                    self.handleDataUnavailable("服务器无响应")
                    return
                }

                do {
                    let result = try JSONDecoder().decode(DailyHealthResponse.self, from: data)
                    guard result.success, let healthData = result.data else {
                        self.handleDataUnavailable(result.message)
                        return
                    }
                    self.error = nil
                    self.updateWithDailyData(healthData)
                    self.fetchMotivation()
                } catch {
                    self.handleDataUnavailable("解析健康数据失败")
                }
            }
        }.resume()
    }

    // MARK: - 网络请求: 获取周数据
    func fetchWeeklyData() {
        guard let token = token, let url = URL(string: "\(baseURL)/health/weekly") else {
            weeklyStepsData = []
            weeklyWaterData = []
            weeklySleepData = []
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, requestError in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let requestError = requestError {
                    self.error = requestError.localizedDescription
                    self.weeklyStepsData = []
                    self.weeklyWaterData = []
                    self.weeklySleepData = []
                    return
                }

                guard let data = data else { return }

                do {
                    let result = try JSONDecoder().decode(WeeklyHealthResponse.self, from: data)
                    guard result.success, let weeklyData = result.data else {
                        self.error = result.message
                        return
                    }

                    self.weeklyStepsData = weeklyData.daily.map {
                        StepDataPoint(
                            day: Self.displayDayFormatter.string(from: $0.dateValue),
                            value: $0.steps)
                    }
                    self.weeklyWaterData = weeklyData.daily.map {
                        WaterDataPoint(
                            day: Self.displayDayFormatter.string(from: $0.dateValue),
                            value: $0.waterMl)
                    }
                    self.weeklySleepData = weeklyData.daily.map {
                        SleepDataPoint(
                            day: Self.displayDayFormatter.string(from: $0.dateValue),
                            value: $0.sleepMinutes)
                    }
                } catch {
                    self.error = "解析周数据失败"
                }
            }
        }.resume()
    }

    // MARK: - 网络请求: 获取健康见解
    func fetchInsights() {
        guard let token = token, let url = URL(string: "\(baseURL)/insights/today") else {
            todayInsights = []
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, requestError in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let requestError = requestError {
                    self.error = requestError.localizedDescription
                    self.todayInsights = []
                    return
                }

                guard let data = data else { return }

                do {
                    let result = try JSONDecoder().decode(InsightsResponse.self, from: data)
                    guard result.success, let insights = result.data else {
                        self.error = result.message
                        self.todayInsights = []
                        return
                    }

                    self.todayInsights = insights.insights.map { insight in
                        InsightItem(
                            icon: self.iconForCategory(insight.category),
                            title: insight.title,
                            description: insight.body,
                            color: self.colorForCategory(insight.category)
                        )
                    }
                } catch {
                    self.error = "解析健康见解失败"
                    self.todayInsights = []
                }
            }
        }.resume()
    }

    // MARK: - 网络请求: 获取激励语
    private func fetchMotivation() {
        guard let url = URL(string: "\(baseURL)/insights/motivation") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "steps": dailySteps,
            "stepsGoal": stepsGoal,
            "waterMl": waterIntake,
            "waterGoal": waterGoal,
            "calories": caloriesBurned,
            "sleepMinutes": sleepMinutes,
            "timeOfDay": currentTimeOfDay,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self = self, let data = data else { return }

            DispatchQueue.main.async {
                if let result = try? JSONDecoder().decode(MotivationResponse.self, from: data),
                    result.success,
                    let motivation = result.data,
                    motivation.generated,
                    let title = motivation.title,
                    let body = motivation.body
                {
                    self.todayMotivation = MotivationItem(
                        emoji: self.motivationEmoji(for: body),
                        title: title,
                        body: body,
                        isAIGenerated: motivation.generated
                    )
                } else {
                    self.todayMotivation = nil
                }
            }
        }.resume()
    }

    // MARK: - 网络请求: 获取未读通知数
    func fetchUnreadNotificationCount() {
        guard let token = token, let url = URL(string: "\(baseURL)/notifications") else {
            applyNotificationPreviewFallback()
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self = self, let data = data else { return }

            DispatchQueue.main.async {
                if let result = try? JSONDecoder().decode(NotificationsResponse.self, from: data),
                    result.success,
                    let notifications = result.data
                {
                    self.unreadNotificationCount = notifications.unreadCount
                    self.notificationPreview = notifications.notifications.prefix(3).map {
                        NotificationPreviewItem(
                            title: $0.title,
                            body: $0.body,
                            timeText: "刚刚"
                        )
                    }
                    if self.notificationPreview.count < 3 {
                        self.notificationPreview.append(
                            contentsOf: Self.notificationPreviewFallbackItems.prefix(
                                3 - self.notificationPreview.count))
                    }
                } else {
                    self.applyNotificationPreviewFallback()
                }
            }
        }.resume()
    }

    // MARK: - 网络请求: 记录饮水
    func logWater(amount: Int) {
        createLog(type: "water", value: amount, unit: "ml", note: "饮水记录") {
            [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    self?.waterIntake += amount
                } else {
                    self?.error = message
                }
            }
        }
    }

    // MARK: - 网络请求: 同步步数
    func logSteps(count: Int) {
        syncHealthMetric(["date": Self.backendDateFormatter.string(from: Date()), "steps": count]) {
            [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    self?.dailySteps = count
                } else {
                    self?.error = message
                }
            }
        }
    }

    // MARK: - 网络请求: 同步睡眠
    func logSleep(minutes: Int) {
        syncHealthMetric([
            "date": Self.backendDateFormatter.string(from: Date()), "sleepMinutes": minutes,
        ]) { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    self?.sleepMinutes = minutes
                } else {
                    self?.error = message
                }
            }
        }
    }

    // MARK: - 请求辅助方法
    private func createLog(
        type: String, value: Int, unit: String, note: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        guard let token = token, let url = URL(string: "\(baseURL)/logs") else {
            completion(false, "请先登录")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "type": type,
            "value": value,
            "unit": unit,
            "notes": note,
            "recordedAt": ISO8601DateFormatter().string(from: Date()),
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, requestError in
            if let requestError = requestError {
                completion(false, requestError.localizedDescription)
                return
            }

            guard let data = data,
                let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                completion(false, "记录失败")
                return
            }

            let success = payload["success"] as? Bool ?? false
            let message = payload["message"] as? String ?? "记录失败"
            completion(success, message)
        }.resume()
    }

    private func syncHealthMetric(
        _ metric: [String: Any], completion: @escaping (Bool, String?) -> Void
    ) {
        guard let token = token, let url = URL(string: "\(baseURL)/health/sync") else {
            completion(false, "请先登录")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "health_metrics": [metric],
            "activity_logs": [],
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, requestError in
            if let requestError = requestError {
                completion(false, requestError.localizedDescription)
                return
            }

            guard let data = data,
                let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                completion(false, "同步失败")
                return
            }

            let success = payload["success"] as? Bool ?? false
            let message = payload["message"] as? String ?? "同步失败"
            completion(success || message == "部分条目同步失败", message)
        }.resume()
    }

    // MARK: - 辅助方法
    private func updateWithDailyData(_ data: DailyHealthData) {
        dailySteps = data.steps
        stepsGoal = data.goals.stepsGoal
        waterIntake = data.waterIntakeMl
        waterGoal = data.goals.waterGoal
        caloriesBurned = data.caloriesBurned
        caloriesGoal = data.goals.caloriesGoal
        sleepMinutes = data.sleepMinutes
        stressLevel = data.stressLevel
        heartRate = data.heartRateAvg ?? 0
        bloodOxygen = 0
        bodyTemperature = 0
    }

    private func handleDataUnavailable(_ message: String?) {
        error = message ?? "暂无可同步数据"
        todayInsights = []
        todayMotivation = nil
        unreadNotificationCount = 0
        if APIConfig.shouldAllowMockData {
            loadPreviewMockData()
        } else {
            clearHealthData()
        }
    }

    private func clearHealthData() {
        dailySteps = 0
        waterIntake = 0
        caloriesBurned = 0
        sleepMinutes = 0
        stressLevel = 0
        heartRate = 0
        bloodOxygen = 0
        bodyTemperature = 0
        weeklyStepsData = []
        weeklyWaterData = []
        weeklySleepData = []
    }

    private func loadPreviewMockData() {
        dailySteps = 6789
        stepsGoal = 10000
        waterIntake = 1200
        waterGoal = 3000
        caloriesBurned = 450
        caloriesGoal = 2000
        sleepMinutes = 420
        stressLevel = 35
        heartRate = 72

        let days = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        let stepValues = [8500, 12000, 6800, 9200, 10500, 7800, 0]
        let waterValues = [1800, 2200, 1500, 2000, 2500, 1200, 0]
        let sleepValues = [420, 480, 360, 450, 390, 420, 0]

        weeklyStepsData = zip(days, stepValues).map { StepDataPoint(day: $0, value: $1) }
        weeklyWaterData = zip(days, waterValues).map { WaterDataPoint(day: $0, value: $1) }
        weeklySleepData = zip(days, sleepValues).map { SleepDataPoint(day: $0, value: $1) }
        notificationPreview = [
            NotificationPreviewItem(
                title: "轻运动提醒", body: "试试一组 3 分钟拉伸，让身体状态更轻盈。", timeText: "22分钟前"),
            NotificationPreviewItem(title: "今日饮水提醒", body: "你今天的饮水量还没达标，喝一杯温水吧。", timeText: "7小时前"),
            NotificationPreviewItem(
                title: "久坐提醒", body: "已经坐了很久，起来活动 2 分钟，放松肩颈。", timeText: "11小时前"),
        ]
        if todayInsights.isEmpty {
            todayInsights = [
                InsightItem(
                    icon: "leaf.fill",
                    title: "从轻习惯开始",
                    description: "连续记录几天即可看到趋势与个性化提示。",
                    color: .tealDeep
                ),
                InsightItem(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "闭环更清晰",
                    description: "步数、饮水与睡眠联动分析会在数据充足后解锁。",
                    color: .sageBright
                ),
            ]
        }
    }

    private func applyNotificationPreviewFallback() {
        let fallbackItems = Self.notificationPreviewFallbackItems
        unreadNotificationCount = fallbackItems.count
        notificationPreview = fallbackItems
    }

    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "exercise": return "figure.walk"
        case "sleep": return "moon.fill"
        case "nutrition": return "fork.knife"
        case "stress": return "brain"
        case "heart", "health": return "heart.fill"
        default: return "lightbulb.fill"
        }
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "exercise": return .tealDeep
        case "sleep": return .purpleSoft
        case "nutrition": return .orangeWarm
        case "stress": return .errorRed
        case "heart", "health": return .errorRed
        default: return .sageBright
        }
    }

    private func motivationEmoji(for body: String) -> String {
        if body.contains("睡") { return "😴" }
        if body.contains("水") { return "💧" }
        if body.contains("动") || body.contains("步") { return "🏃" }
        return "💪"
    }

    private var currentTimeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<18: return "afternoon"
        default: return "evening"
        }
    }

    static let backendDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let displayDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private static let notificationPreviewFallbackItems: [NotificationPreviewItem] = [
        NotificationPreviewItem(
            title: "轻运动提醒",
            body: "试试一组 3 分钟拉伸，让身体状态更轻盈。",
            timeText: "22分钟前"
        ),
        NotificationPreviewItem(
            title: "今日饮水提醒",
            body: "你今天的饮水量还没达标，喝一杯温水吧。",
            timeText: "7小时前"
        ),
        NotificationPreviewItem(
            title: "久坐提醒",
            body: "已经坐了很久，起来活动 2 分钟，放松肩颈。",
            timeText: "11小时前"
        ),
    ]
}

struct NotificationPreviewItem: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let timeText: String
}

// MARK: - 数据模型
struct InsightItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct DietaryCareMessage: Equatable {
    let title: String?
    let body: String?
    let mealAdvice: String?
    let focusNutrient: String?
}

struct MotivationItem {
    let emoji: String
    let title: String
    let body: String
    let isAIGenerated: Bool

    init(emoji: String, title: String, body: String, isAIGenerated: Bool = false) {
        self.emoji = emoji
        self.title = title
        self.body = body
        self.isAIGenerated = isAIGenerated
    }
}

// MARK: - 网络响应结构
struct DailyHealthResponse: Codable {
    let success: Bool
    let message: String
    let data: DailyHealthData?
}

struct DailyHealthData: Codable {
    let date: String
    let steps: Int
    let waterIntakeMl: Int
    let caloriesBurned: Int
    let sleepMinutes: Int
    let stressLevel: Int
    let heartRateAvg: Int?
    let goals: DailyGoalsData
}

struct DailyGoalsData: Codable {
    let stepsGoal: Int
    let stepsProgress: Double
    let waterGoal: Int
    let waterProgress: Double
    let sleepGoal: Int
    let sleepProgress: Double
    let caloriesGoal: Int
    let caloriesProgress: Double
}

struct WeeklyHealthResponse: Codable {
    let success: Bool
    let message: String
    let data: WeeklyHealthData?
}

struct WeeklyHealthData: Codable {
    let startDate: String
    let endDate: String
    let daily: [WeeklyHealthDay]
    let summary: WeeklyHealthSummary
}

struct WeeklyHealthDay: Codable {
    let date: String
    let steps: Int
    let waterMl: Int
    let calories: Int
    let sleepMinutes: Int
    let stressLevel: Int
    let heartRateAvg: Int?

    var dateValue: Date {
        DashboardViewModel.backendDateFormatter.date(from: date) ?? Date()
    }
}

struct WeeklyHealthSummary: Codable {
    let totalSteps: Int
    let totalWaterMl: Int
    let totalCalories: Int
    let totalSleepMinutes: Int
    let avgSteps: Int
    let avgWaterMl: Int
    let avgCalories: Int
    let avgSleepMinutes: Int
}

struct InsightsResponse: Codable {
    let success: Bool
    let message: String
    let data: InsightsData?
}

struct InsightsData: Codable {
    let date: String
    let insights: [InsightData]
    let count: Int
}

struct InsightData: Codable {
    let id: String
    let category: String
    let channel: String?
    let title: String
    let body: String
    let ctaText: String?
    let score: Double?
}

struct MotivationResponse: Codable {
    let success: Bool
    let message: String
    let data: MotivationResponseData?
}

struct MotivationResponseData: Codable {
    let title: String?
    let body: String?
    let generated: Bool
}

struct NotificationsResponse: Codable {
    let success: Bool
    let message: String
    let data: NotificationsData?
}

struct NotificationsData: Codable {
    let notifications: [NotificationListItem]
    let unreadCount: Int
    let page: Int
    let limit: Int
}

struct NotificationListItem: Codable {
    let id: String
    let type: String
    let title: String
    let body: String
    let isRead: Bool?
}

struct BasicAPIResponse: Codable {
    let success: Bool
    let message: String
}
