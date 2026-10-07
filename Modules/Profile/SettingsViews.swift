import Combine
import SwiftUI

// MARK: - 健康目标设置视图模型
class HealthGoalsSettingsViewModel: ObservableObject {
    private let baseURL = APIConfig.baseURL
    private var token: String? {
        UserDefaults.standard.string(forKey: APIConfig.accessTokenKey)
    }

    @Published var stepsGoal: Double = 10000
    @Published var waterGoal: Double = 3000
    @Published var sleepGoal: Double = 480
    @Published var weightGoal: Double = 65.0
    @Published var caloriesGoal: Double = 2000
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var error: String? = nil

    init() {
        fetchGoals()
    }

    func fetchGoals() {
        guard let token = token, let url = URL(string: "\(baseURL)/users/preferences") else {
            loadMockGoals()
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let data = data,
                    let result = try? JSONDecoder().decode(UserPreferencesResponse.self, from: data)
                {
                    if result.success, let preferences = result.data {
                        if let goals = preferences.goals {
                            self.stepsGoal = Double(goals.steps ?? 10000)
                            self.waterGoal = Double(goals.waterMl ?? 3000)
                            self.sleepGoal = Double(goals.sleepMin ?? 480)
                            self.caloriesGoal = Double(goals.calories ?? 2000)
                        }
                        if let targetWeight = preferences.targetWeight {
                            self.weightGoal = targetWeight
                        }
                        return
                    }
                }
                self.loadMockGoals()
            }
        }.resume()
    }

    func saveGoals() {
        isSaving = true

        guard let token = token, let url = URL(string: "\(baseURL)/users/preferences") else {
            isSaving = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "stepsGoal": Int(stepsGoal),
            "waterGoalMl": Int(waterGoal),
            "sleepGoalMin": Int(sleepGoal),
            "caloriesGoal": Int(caloriesGoal),
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { [weak self] _, _, error in
            DispatchQueue.main.async {
                self?.isSaving = false
                if let error = error {
                    self?.error = error.localizedDescription
                }
            }
        }.resume()
    }

    private func loadMockGoals() {
        stepsGoal = 10000
        waterGoal = 3000
        sleepGoal = 480
        weightGoal = 65.0
        caloriesGoal = 2000
    }
}

// MARK: - 通知设置视图模型
class NotificationSettingsViewModel: ObservableObject {
    private let baseURL = APIConfig.baseURL
    private var token: String? {
        UserDefaults.standard.string(forKey: APIConfig.accessTokenKey)
    }

    @Published var notificationEnabled: Bool = true
    @Published var waterReminderEnabled: Bool = true
    @Published var exerciseReminderEnabled: Bool = true
    @Published var sleepReminderEnabled: Bool = true
    @Published var weeklyReportEnabled: Bool = true
    @Published var soundEnabled: Bool = true
    @Published var vibrateEnabled: Bool = true

    @Published var waterReminderTime: Date =
        Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @Published var lastWaterReminderTime: Date =
        Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    @Published var exerciseReminderTime: Date =
        Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
    @Published var sleepReminderTime: Date =
        Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()

    @Published var isLoading: Bool = false
    @Published var error: String? = nil

    init() {
        fetchSettings()
    }

    func fetchSettings() {
        guard let token = token, let url = URL(string: "\(baseURL)/users/preferences") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let data = data,
                    let result = try? JSONDecoder().decode(UserPreferencesResponse.self, from: data)
                {
                    if result.success, let settings = result.data, let n = settings.notifications {
                        self.notificationEnabled = n.enabled ?? true
                        self.waterReminderEnabled = n.enabled ?? true
                        self.exerciseReminderEnabled = n.enabled ?? true
                        self.sleepReminderEnabled = n.enabled ?? true
                        self.weeklyReportEnabled = n.enabled ?? true
                        let startHour = n.startHour ?? 8
                        let endHour = n.endHour ?? 22
                        self.waterReminderTime =
                            Calendar.current.date(from: DateComponents(hour: startHour, minute: 0))
                            ?? self.waterReminderTime
                        self.lastWaterReminderTime =
                            Calendar.current.date(from: DateComponents(hour: endHour, minute: 0))
                            ?? self.lastWaterReminderTime
                        self.exerciseReminderTime = self.waterReminderTime
                        self.sleepReminderTime = self.lastWaterReminderTime
                    }
                }
            }
        }.resume()
    }

    func saveSettings() {
        guard let token = token, let url = URL(string: "\(baseURL)/users/preferences") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let startHour = Calendar.current.component(.hour, from: waterReminderTime)
        let endHour = Calendar.current.component(.hour, from: lastWaterReminderTime)

        let body: [String: Any] = [
            "notificationsEnabled": notificationEnabled,
            "reminderStartHour": startHour,
            "reminderEndHour": endHour,
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { _, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = error.localizedDescription
                }
            }
        }.resume()
    }
}

// MARK: - 隐私设置视图模型
class PrivacySettingsViewModel: ObservableObject {
    private let baseURL = APIConfig.baseURL
    private var token: String? {
        UserDefaults.standard.string(forKey: APIConfig.accessTokenKey)
    }

    @Published var profileVisible: Bool = false
    @Published var healthDataVisible: Bool = false
    @Published var activityVisible: Bool = false
    @Published var locationEnabled: Bool = true
    @Published var dataSyncEnabled: Bool = true
    @Published var analyticsEnabled: Bool = true
    @Published var showDeleteAlert: Bool = false
    @Published var showDeleteConfirm: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String? = nil

    init() {
        fetchSettings()
    }

    func fetchSettings() {
        profileVisible = UserDefaults.standard.bool(forKey: "privacy_profileVisible")
        healthDataVisible = UserDefaults.standard.bool(forKey: "privacy_healthDataVisible")
        activityVisible = UserDefaults.standard.bool(forKey: "privacy_activityVisible")
        locationEnabled =
            UserDefaults.standard.object(forKey: "privacy_locationEnabled") as? Bool ?? true
        dataSyncEnabled =
            UserDefaults.standard.object(forKey: "privacy_dataSyncEnabled") as? Bool ?? true
        analyticsEnabled =
            UserDefaults.standard.object(forKey: "privacy_analyticsEnabled") as? Bool ?? true
    }

    func saveSettings() {
        UserDefaults.standard.set(profileVisible, forKey: "privacy_profileVisible")
        UserDefaults.standard.set(healthDataVisible, forKey: "privacy_healthDataVisible")
        UserDefaults.standard.set(activityVisible, forKey: "privacy_activityVisible")
        UserDefaults.standard.set(locationEnabled, forKey: "privacy_locationEnabled")
        UserDefaults.standard.set(dataSyncEnabled, forKey: "privacy_dataSyncEnabled")
        UserDefaults.standard.set(analyticsEnabled, forKey: "privacy_analyticsEnabled")
        error = nil
    }

    func deleteAccount() {
        guard let token = token, let url = URL(string: "\(baseURL)/users/account") else { return }

        isLoading = true

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] _, _, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if error != nil {
                    self?.error = error?.localizedDescription
                } else {
                    // 清理本地数据
                    TokenStorage.shared.clearTokens()
                    PreferencesStorage.shared.isLoggedIn = false
                    NotificationCenter.default.post(name: .userDidLogout, object: nil)
                }
            }
        }.resume()
    }
}

// MARK: - 设置页面
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        // 由 MainTabView 的 NavigationStack 承载，避免嵌套 NavigationStack 导致空白页
        ZStack {
            AegisDynamicBackground()

            List {
                // 健康目标
                Section {
                    NavigationLink {
                        HealthGoalsSettingsView()
                    } label: {
                        SettingsMenuRow(icon: "flag.fill", title: "健康目标", color: .sageBright)
                    }
                }

                // 通知设置
                Section {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        SettingsMenuRow(icon: "bell.fill", title: "通知设置", color: .androidBlue)
                    }
                }

                // 隐私设置
                Section {
                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        SettingsMenuRow(icon: "lock.fill", title: "隐私设置", color: .purpleSoft)
                    }
                }

                // 帮助与支持
                Section {
                    NavigationLink {
                        HelpSupportView()
                    } label: {
                        SettingsMenuRow(
                            icon: "questionmark.circle.fill", title: "帮助与支持", color: .orangeWarm
                        )
                    }

                    NavigationLink {
                        WebContentView(title: "用户协议", url: "https://aegisflow.com/terms")
                    } label: {
                        SettingsMenuRow(icon: "doc.text.fill", title: "用户协议", color: .grayMid)
                    }

                    NavigationLink {
                        WebContentView(title: "隐私政策", url: "https://aegisflow.com/privacy")
                    } label: {
                        SettingsMenuRow(
                            icon: "hand.raised.fill", title: "隐私政策", color: .grayMid)
                    }
                }

                // 关于
                Section {
                    HStack {
                        SettingsIcon(icon: "info.circle.fill", color: .tealDeep)
                        Text("版本")
                            .font(.system(size: 15))
                            .foregroundColor(.grayDark)
                        Spacer()
                        Text("2.0.0")
                            .font(.system(size: 14))
                            .foregroundColor(.grayMid)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - 设置菜单行（与 ProfileView 中基于 SettingsItem 的 SettingsRowContent 区分）
struct SettingsMenuRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            SettingsIcon(icon: icon, color: color)
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.grayDark)
        }
    }
}

// MARK: - 设置图标
struct SettingsIcon: View {
    let icon: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.15))
                .frame(width: 32, height: 32)

            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

// MARK: - 健康目标设置
struct HealthGoalsSettingsView: View {
    @StateObject private var viewModel = HealthGoalsSettingsViewModel()

    var body: some View {
        ZStack {
            AegisDynamicBackground()

            ScrollView {
                VStack(spacing: AegisSpacing.sectionGap) {
                    // 步数目标
                    GoalSettingCard(
                        icon: "figure.walk",
                        title: "每日步数目标",
                        value: $viewModel.stepsGoal,
                        range: 3000...20000,
                        step: 1000,
                        unit: "步",
                        color: .tealDeep
                    )

                    // 饮水量目标
                    GoalSettingCard(
                        icon: "drop.fill",
                        title: "每日饮水量目标",
                        value: $viewModel.waterGoal,
                        range: 1000...5000,
                        step: 100,
                        unit: "ml",
                        color: .androidBlue
                    )

                    // 睡眠目标
                    GoalSettingCard(
                        icon: "moon.fill",
                        title: "每日睡眠目标",
                        value: $viewModel.sleepGoal,
                        range: 360...600,
                        step: 30,
                        unit: "分钟",
                        color: .purpleSoft
                    )

                    // 卡路里目标
                    GoalSettingCard(
                        icon: "flame.fill",
                        title: "每日卡路里目标",
                        value: $viewModel.caloriesGoal,
                        range: 1000...5000,
                        step: 100,
                        unit: "kcal",
                        color: .orangeWarm
                    )

                    // 体重目标
                    GoalSettingCard(
                        icon: "scalemass.fill",
                        title: "目标体重",
                        value: $viewModel.weightGoal,
                        range: 40...150,
                        step: 0.5,
                        unit: "kg",
                        color: .sageBright,
                        isDecimal: true
                    )

                    // 保存按钮
                    Button(action: { viewModel.saveGoals() }) {
                        HStack {
                            if viewModel.isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("保存设置")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.sageBright)
                        .cornerRadius(AegisCornerRadius.medium)
                    }
                    .disabled(viewModel.isSaving)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, AegisSpacing.pageHorizontal)
                .padding(.top, 16)
            }
        }
        .navigationTitle("健康目标")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 目标设置卡片
struct GoalSettingCard: View {
    let icon: String
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let color: Color
    var isDecimal: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.grayDark)

                    HStack(alignment: .bottom, spacing: 4) {
                        Text(isDecimal ? String(format: "%.1f", value) : "\(Int(value))")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(color)

                        Text(unit)
                            .font(.system(size: 13))
                            .foregroundColor(.grayMid)
                            .padding(.bottom, 4)
                    }
                }

                Spacer()
            }

            Slider(value: $value, in: range, step: step)
                .tint(color)

            HStack {
                Text(
                    "\(isDecimal ? String(format: "%.0f", range.lowerBound) : "\(Int(range.lowerBound))")\(unit)"
                )
                .font(.system(size: 11))
                .foregroundColor(.grayMid)

                Spacer()

                Text(
                    "\(isDecimal ? String(format: "%.0f", range.upperBound) : "\(Int(range.upperBound))")\(unit)"
                )
                .font(.system(size: 11))
                .foregroundColor(.grayMid)
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
    }
}

// MARK: - 通知设置
struct NotificationSettingsView: View {
    @StateObject private var viewModel = NotificationSettingsViewModel()

    var body: some View {
        ZStack {
            AegisDynamicBackground()

            List {
                // 全局开关
                Section {
                    Toggle(isOn: $viewModel.notificationEnabled) {
                        HStack(spacing: 16) {
                            SettingsIcon(icon: "bell.fill", color: .androidBlue)
                            Text("允许通知")
                                .font(.system(size: 15))
                        }
                    }
                    .toggleStyle(AegisSwitchToggleStyle(tint: .aegisFreshGreen))
                }

                // 提醒类型
                if viewModel.notificationEnabled {
                    Section("提醒类型") {
                        NotificationToggleRow(
                            icon: "drop.fill",
                            title: "饮水提醒",
                            subtitle: "提醒你及时补充水分",
                            isOn: $viewModel.waterReminderEnabled,
                            color: .androidBlue
                        )

                        NotificationToggleRow(
                            icon: "figure.walk",
                            title: "运动提醒",
                            subtitle: "提醒你起身活动",
                            isOn: $viewModel.exerciseReminderEnabled,
                            color: .tealDeep
                        )

                        NotificationToggleRow(
                            icon: "moon.fill",
                            title: "睡眠提醒",
                            subtitle: "提醒你按时休息",
                            isOn: $viewModel.sleepReminderEnabled,
                            color: .purpleSoft
                        )

                        NotificationToggleRow(
                            icon: "chart.bar.fill",
                            title: "每周报告",
                            subtitle: "每周日发送健康报告",
                            isOn: $viewModel.weeklyReportEnabled,
                            color: .orangeWarm
                        )
                    }

                    // 提醒时间
                    if viewModel.waterReminderEnabled {
                        Section("饮水提醒时间") {
                            DatePicker(
                                "首次提醒", selection: $viewModel.waterReminderTime,
                                displayedComponents: .hourAndMinute)
                            DatePicker(
                                "末次提醒", selection: $viewModel.lastWaterReminderTime,
                                displayedComponents: .hourAndMinute)
                        }
                    }

                    if viewModel.exerciseReminderEnabled {
                        Section("运动提醒时间") {
                            DatePicker(
                                "提醒时间", selection: $viewModel.exerciseReminderTime,
                                displayedComponents: .hourAndMinute)
                        }
                    }

                    if viewModel.sleepReminderEnabled {
                        Section("睡眠提醒时间") {
                            DatePicker(
                                "提醒时间", selection: $viewModel.sleepReminderTime,
                                displayedComponents: .hourAndMinute)
                        }
                    }

                    // 通知样式
                    Section("通知样式") {
                        NotificationToggleRow(
                            icon: "speaker.wave.2.fill",
                            title: "声音",
                            subtitle: "播放通知声音",
                            isOn: $viewModel.soundEnabled,
                            color: .sageBright
                        )

                        NotificationToggleRow(
                            icon: "iphone.radiowaves.left.and.right",
                            title: "震动",
                            subtitle: "设备震动提醒",
                            isOn: $viewModel.vibrateEnabled,
                            color: .orangeWarm
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("通知设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.aegisFreshGreen.opacity(0.10), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(.aegisFreshGreen)
        .onChange(of: viewModel.notificationEnabled) { _, _ in
            viewModel.saveSettings()
        }
        .onChange(of: viewModel.waterReminderEnabled) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.exerciseReminderEnabled) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.sleepReminderEnabled) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.weeklyReportEnabled) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.soundEnabled) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.vibrateEnabled) { _, _ in viewModel.saveSettings() }
    }
}

// MARK: - 通知开关行
struct NotificationToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                SettingsIcon(icon: icon, color: color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15))
                        .foregroundColor(.grayDark)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.grayMid)
                }
            }
        }
        .toggleStyle(AegisSwitchToggleStyle(tint: .aegisFreshGreen))
    }
}

// MARK: - 隐私设置
struct PrivacySettingsView: View {
    @StateObject private var viewModel = PrivacySettingsViewModel()

    var body: some View {
        ZStack {
            AegisDynamicBackground()

            List {
                Section("数据可见性") {
                    PrivacyToggleRow(
                        icon: "person.2.fill",
                        title: "个人资料可见",
                        subtitle: "允许其他人查看你的资料",
                        isOn: $viewModel.profileVisible,
                        color: .sageBright
                    )

                    PrivacyToggleRow(
                        icon: "heart.fill",
                        title: "健康数据可见",
                        subtitle: "允许其他人查看你的健康数据",
                        isOn: $viewModel.healthDataVisible,
                        color: .errorRed
                    )

                    PrivacyToggleRow(
                        icon: "figure.walk",
                        title: "活动数据可见",
                        subtitle: "允许其他人查看你的活动",
                        isOn: $viewModel.activityVisible,
                        color: .androidBlue
                    )
                }

                Section("位置与同步") {
                    PrivacyToggleRow(
                        icon: "location.fill",
                        title: "位置信息",
                        subtitle: "用于活动轨迹记录",
                        isOn: $viewModel.locationEnabled,
                        color: .orangeWarm
                    )

                    PrivacyToggleRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "数据同步",
                        subtitle: "同步数据到云端",
                        isOn: $viewModel.dataSyncEnabled,
                        color: .tealDeep
                    )

                    PrivacyToggleRow(
                        icon: "chart.bar.fill",
                        title: "数据分析",
                        subtitle: "允许应用分析数据以提供更好的建议",
                        isOn: $viewModel.analyticsEnabled,
                        color: .purpleSoft
                    )
                }

                Section {
                    Button(action: { viewModel.showDeleteConfirm = true }) {
                        HStack {
                            SettingsIcon(icon: "trash.fill", color: .errorRed)
                            Text("删除账户")
                                .font(.system(size: 15))
                                .foregroundColor(.errorRed)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("隐私设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.aegisFreshGreen.opacity(0.10), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(.aegisFreshGreen)
        .alert("删除账户", isPresented: $viewModel.showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                viewModel.deleteAccount()
            }
        } message: {
            Text("删除账户后，所有数据将被永久清除，此操作不可撤销。")
        }
        .onChange(of: viewModel.profileVisible) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.healthDataVisible) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.activityVisible) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.locationEnabled) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.dataSyncEnabled) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.analyticsEnabled) { _, _ in viewModel.saveSettings() }
    }
}

// MARK: - 隐私开关行
struct PrivacyToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                SettingsIcon(icon: icon, color: color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15))
                        .foregroundColor(.grayDark)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.grayMid)
                }
            }
        }
        .toggleStyle(AegisSwitchToggleStyle(tint: .aegisFreshGreen))
    }
}

// MARK: - 帮助与支持
struct HelpSupportView: View {
    var body: some View {
        ZStack {
            AegisDynamicBackground()

            List {
                Section("常用问题") {
                    NavigationLink {
                        FAQListView()
                    } label: {
                        HStack(spacing: 16) {
                            SettingsIcon(icon: "questionmark.circle.fill", color: .tealDeep)
                            Text("常见问题")
                                .font(.system(size: 15))
                                .foregroundColor(.grayDark)
                        }
                    }

                    NavigationLink {
                        UsageGuideView()
                    } label: {
                        HStack(spacing: 16) {
                            SettingsIcon(icon: "book.fill", color: .androidBlue)
                            Text("使用指南")
                                .font(.system(size: 15))
                                .foregroundColor(.grayDark)
                        }
                    }
                }

                Section("联系我们") {
                    Button(action: { openEmail() }) {
                        HStack(spacing: 16) {
                            SettingsIcon(icon: "envelope.fill", color: .sageBright)
                            Text("联系我们")
                                .font(.system(size: 15))
                                .foregroundColor(.grayDark)
                            Spacer()
                            Text("support@aegisflow.com")
                                .font(.system(size: 13))
                                .foregroundColor(.grayMid)
                        }
                    }

                    Button(action: { callSupport() }) {
                        HStack(spacing: 16) {
                            SettingsIcon(icon: "phone.fill", color: .orangeWarm)
                            Text("客服热线")
                                .font(.system(size: 15))
                                .foregroundColor(.grayDark)
                            Spacer()
                            Text("400-888-8888")
                                .font(.system(size: 13))
                                .foregroundColor(.grayMid)
                        }
                    }
                }

                Section("反馈") {
                    Button(action: { openFeedback() }) {
                        HStack(spacing: 16) {
                            SettingsIcon(icon: "square.and.pencil", color: .purpleSoft)
                            Text("意见反馈")
                                .font(.system(size: 15))
                                .foregroundColor(.grayDark)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.grayMid)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("帮助与支持")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openEmail() {
        if let url = URL(string: "mailto:support@aegisflow.com") {
            UIApplication.shared.open(url)
        }
    }

    private func callSupport() {
        if let url = URL(string: "tel:4008888888") {
            UIApplication.shared.open(url)
        }
    }

    private func openFeedback() {
        // 优先使用 mailto 打开系统邮件客户端，回退为打开支持页面
        let subject = "AegisFlow 意见反馈"
        let body = "请描述您遇到的问题或建议：\n\n"
        if let mailURL = URL(string: "mailto:support@aegisflow.com?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(mailURL)
            return
        }

        if let url = URL(string: "https://aegisflow.com/feedback") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - FAQ列表
struct FAQListView: View {
    let faqs: [FAQ] = [
        FAQ(question: "如何记录饮食？", answer: "点击首页的饮食记录按钮，可以手动输入或拍照识别食物。"),
        FAQ(question: "如何连接设备？", answer: "在个人中心-设备管理中，点击搜索设备，按照提示完成蓝牙配对。"),
        FAQ(question: "步数数据不准确怎么办？", answer: "确保手机随身携带，或者连接智能手环/手表以获得更准确的数据。"),
        FAQ(question: "数据同步失败怎么办？", answer: "请检查网络连接，确保应用有网络权限。也可以尝试重新登录账号。"),
        FAQ(question: "如何更改语言？", answer: "目前应用跟随系统语言设置，请前往手机设置更改语言偏好。"),
    ]

    var body: some View {
        ZStack {
            AegisDynamicBackground()

            List {
                ForEach(faqs) { faq in
                    FAQDetailRow(faq: faq)
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("常见问题")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct FAQDetailRow: View {
    let faq: FAQ
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text(faq.question)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.grayDark)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.grayMid)
                }
            }

            if isExpanded {
                Text(faq.answer)
                    .font(.system(size: 14))
                    .foregroundColor(.grayMid)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 使用指南
struct UsageGuideView: View {
    var body: some View {
        ZStack {
            AegisDynamicBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    GuideSection(
                        icon: "figure.walk",
                        title: "开始使用",
                        steps: [
                            "下载并安装AegisFlow应用",
                            "注册账号并完成新手引导",
                            "设置你的健康目标",
                            "开始记录你的日常健康数据",
                        ]
                    )

                    GuideSection(
                        icon: "bell.fill",
                        title: "接收提醒",
                        steps: [
                            "开启通知权限",
                            "设置饮水、运动提醒时间",
                            "根据提醒完成健康记录",
                        ]
                    )

                    GuideSection(
                        icon: "chart.bar.fill",
                        title: "查看数据",
                        steps: [
                            "首页查看今日健康概览",
                            "数据页面查看详细统计",
                            "定期查看周报告和趋势分析",
                        ]
                    )
                }
                .padding(.horizontal, AegisSpacing.pageHorizontal)
                .padding(.top, 16)
            }
        }
        .navigationTitle("使用指南")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GuideSection: View {
    let icon: String
    let title: String
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                SettingsIcon(icon: icon, color: .tealDeep)
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.grayDark)
            }

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.sageBright)
                            .frame(width: 24, height: 24)
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text(step)
                        .font(.system(size: 14))
                        .foregroundColor(.grayMid)
                }
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
    }
}

// MARK: - Web内容视图
struct WebContentView: View {
    let title: String
    let url: String

    var body: some View {
        VStack {
            Text("加载中...")
                .foregroundColor(.grayMid)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 网络响应结构

struct GoalsResponse: Codable {
    let success: Bool
    let message: String
    let data: GoalsData?
}

struct GoalsData: Codable {
    let steps: Int
    let waterMl: Int
    let sleepMin: Int
    let calories: Int
    let targetWeight: Double?
}

struct NotificationSettingsResponse: Codable {
    let success: Bool
    let message: String
    let data: NotificationSettingsData?
}

struct NotificationSettingsData: Codable {
    let enabled: Bool
    let waterReminder: Bool
    let exerciseReminder: Bool
    let sleepReminder: Bool
    let weeklyReport: Bool
    let sound: Bool
    let vibrate: Bool
}

struct PrivacySettingsResponse: Codable {
    let success: Bool
    let message: String
    let data: PrivacySettingsData?
}

struct PrivacySettingsData: Codable {
    let profileVisible: Bool
    let healthDataVisible: Bool
    let activityVisible: Bool
    let locationEnabled: Bool
    let dataSyncEnabled: Bool
    let analyticsEnabled: Bool
}

// MARK: - 预览
#Preview("Settings") {
    SettingsView()
}
