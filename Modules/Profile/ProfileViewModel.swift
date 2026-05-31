import Combine
import SwiftUI

// MARK: - ProfileViewModel
class ProfileViewModel: ObservableObject {

    // MARK: - 网络请求配置
    private let baseURL = APIConfig.baseURL
    private var token: String? {
        UserDefaults.standard.string(forKey: APIConfig.accessTokenKey)
    }

    // MARK: - 用户信息
    @Published var userName: String = ""
    @Published var email: String = ""
    @Published var isPremium: Bool = false
    @Published var avatarLocalPath: String? = nil
    @Published var avatarInitials: String = "--"

    // MARK: - 身体数据
    @Published var heightCm: Float = 170 {
        didSet { recalculateBMI() }
    }
    @Published var weightKg: Float = 60 {
        didSet { recalculateBMI() }
    }
    @Published var bmi: Float = 20.8
    @Published var bodyFatPercent: Float = 18.5

    private func recalculateBMI() {
        guard heightCm > 0 else { return }
        let h = heightCm / 100.0
        bmi = weightKg / (h * h)
    }

    // MARK: - 设备管理
    @Published var boundDevices: [BoundDevice] = []
    @Published var isScanning: Bool = false
    @Published var isSyncingDevice: Bool = false
    @Published var realtimeSteps: Int = 0
    @Published var realtimeHeartRate: Int = 0
    @Published var todaySleepMinutes: Int = 0

    // MARK: - 健康画像
    @Published var userInsightProfile: ProfileSummaryUI? = nil
    @Published var personalizationScore: Int = 0
    @Published var isLoadingUserInsight: Bool = false

    // MARK: - 设置项
    @Published var settingsItems: [SettingsItem] = SettingsItem.defaultItems

    // MARK: - 弹窗与对话框
    @Published var showEditProfile: Bool = false
    @Published var showLogoutDialog: Bool = false
    @Published var showSwitchAccountDialog: Bool = false
    @Published var showUnbindDialog: String? = nil
    @Published var showPermissionDeniedDialog: Bool = false
    @Published var showScanDialog: Bool = false
    @Published var showHeightEditor: Bool = false
    @Published var showWeightEditor: Bool = false
    @Published var error: String? = nil

    // MARK: - 编辑资料
    @Published var editName: String = ""
    @Published var editGender: String? = nil
    @Published var editBirthDate: String? = nil
    @Published var editBio: String = ""
    @Published var isSavingProfile: Bool = false
    @Published var nameError: String? = nil

    // MARK: - 设备扫描
    @Published var scannedDevices: [ScannedDevice] = []

    // MARK: - 账号切换
    @Published var switchAccountRequested: Bool = false
    @Published var addAccountRequested: Bool = false
    @Published var logoutRequested: Bool = false

    // MARK: - Computed Properties
    // MARK: - 异步任务管理
    private var insightWorkItem: DispatchWorkItem?
    private var scanningWorkItem: DispatchWorkItem?
    private var syncingWorkItem: DispatchWorkItem?
    private var premiumStatusObserver: NSObjectProtocol?

    // MARK: - Computed Properties
    var userInitials: String {
        let names = userName.split(separator: " ")
        let initials = names.prefix(2).compactMap { $0.first }.map(String.init).joined()
        return initials.isEmpty ? "SC" : initials
    }

    // MARK: - 初始化
    init() {
        if APIConfig.shouldAllowMockData {
            loadMockData()
        } else {
            applyPlaceholderProfile()
        }

        premiumStatusObserver = NotificationCenter.default.addObserver(
            forName: .premiumStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isPremium = true
        }
    }

    deinit {
        // 清理：在视图销毁时取消所有待处理的异步任务
        insightWorkItem?.cancel()
        scanningWorkItem?.cancel()
        syncingWorkItem?.cancel()
        if let premiumStatusObserver {
            NotificationCenter.default.removeObserver(premiumStatusObserver)
        }
    }

    // MARK: - 清理任务
    func cancelPendingTasks() {
        // 取消所有待处理的异步任务
        insightWorkItem?.cancel()
        scanningWorkItem?.cancel()
        syncingWorkItem?.cancel()
    }

    // MARK: - 业务逻辑方法
    func openEditProfile() { showEditProfile = true }
    func closeEditProfile() { showEditProfile = false }

    func updateHeight(_ h: Float) {
        heightCm = h
        updateBMI()
        updateUserProfile()
    }

    func updateWeight(_ w: Float) {
        weightKg = w
        updateBMI()
        updateUserProfile()
    }

    func updateBMI() {
        guard heightCm > 0 else { return }
        let heightM = heightCm / 100
        bmi = weightKg / (heightM * heightM)
    }

    func updateEditName(_ name: String) {
        editName = name
        nameError = nil
    }

    func updateEditGender(_ gender: String?) {
        editGender = gender
    }

    func updateEditBirthDate(_ date: String?) {
        editBirthDate = date
    }

    func updateEditBio(_ bio: String) {
        editBio = bio
    }

    func saveEditProfile() {
        guard !editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            nameError = "昵称不能为空"
            return
        }
        updateUserProfile()
    }

    func persistAvatarData(_ data: Data?) {
        guard let data else { return }

        let fileName = "profile-avatar.jpg"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: [.atomic])
            avatarLocalPath = fileURL.path
        } catch {
            self.error = "头像保存失败"
        }
    }

    func switchAccount() { switchAccountRequested = true }
    func addAccount() { addAccountRequested = true }
    func consumeNavigationEvents() {
        switchAccountRequested = false
        addAccountRequested = false
        logoutRequested = false
    }

    func onSettingsItemClick(_ id: String) {
        switch id {
        case "logout":
            logoutRequested = true
            showLogoutDialog = true
        case "help":
            // 跳转到帮助页面
            break
        case "privacy":
            // 跳转到隐私政策
            break
        case "notifications":
            // 跳转到通知设置
            break
        case "goals":
            // 跳转到健康目标
            break
        default:
            break
        }
    }

    func clearError() { error = nil }

    func loadUserInsights() {
        // 取消之前的任务
        insightWorkItem?.cancel()

        isLoadingUserInsight = true
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.userInsightProfile = ProfileSummaryUI(
                activeTopics: ["基础健康知识"],
                preferredFoods: ["三文鱼", "西兰花", "糙米"],
                avoidedTopics: [],
                knowledgeGaps: ["睡眠质量", "心血管健康", "肠道健康"],
                knowledgeRadar: KnowledgeRadarUI(
                    labels: ["营养素", "食物", "运动", "睡眠", "心理"],
                    scores: [42, 38, 26, 20, 18]
                )
            )
            self.personalizationScore = 20
            self.isLoadingUserInsight = false
        }
        self.insightWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    // MARK: - 设备管理
    func startScanning() {
        // 取消之前的扫描任务
        scanningWorkItem?.cancel()

        isScanning = true
        // 模拟扫描到的设备
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.scannedDevices = [
                ScannedDevice(
                    id: UUID().uuidString, name: "Apple Watch Series 9", type: "Watch", rssi: -45),
                ScannedDevice(id: UUID().uuidString, name: "小米手环8", type: "Band", rssi: -60),
                ScannedDevice(id: UUID().uuidString, name: "华为体脂秤", type: "Scale", rssi: -70),
            ]
        }
        self.scanningWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
    }

    func stopScanning() {
        isScanning = false
        scannedDevices.removeAll()
    }

    func bindDevice(_ device: ScannedDevice) {
        let boundDevice = BoundDevice(
            id: device.id,
            name: device.name,
            type: device.type,
            batteryLevel: Int.random(in: 50...100),
            connectionState: "Connected",
            lastSyncTime: Date().timeIntervalSince1970
        )
        boundDevices.append(boundDevice)
    }

    func unbindDevice(deviceId: String) {
        boundDevices.removeAll { $0.id == deviceId }
    }

    func syncDeviceData() {
        guard !boundDevices.isEmpty else { return }

        isSyncingDevice = true

        // 取消之前的同步任务
        syncingWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.isSyncingDevice = false
            self.realtimeSteps = Int.random(in: 5000...10000)
            self.realtimeHeartRate = Int.random(in: 60...90)

            // 更新设备的最后同步时间
            if let index = self.boundDevices.indices.first {
                self.boundDevices[index].lastSyncTime = Date().timeIntervalSince1970
            }
        }
        self.syncingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
    }

    func logout() {
        // 清除本地存储
        UserDefaults.standard.removeObject(forKey: APIConfig.accessTokenKey)
        UserDefaults.standard.removeObject(forKey: APIConfig.refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: APIConfig.userIdKey)

        // 发送注销请求
        deleteAccount {
            // 清理完成后跳转
            DispatchQueue.main.async {
                self.clearUserData()
            }
        }
    }

    private func clearUserData() {
        userName = ""
        email = ""
        isPremium = false
        boundDevices.removeAll()
        // 通知 AppState 切换到登录页
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }

    // MARK: - 网络请求: 获取个人资料
    func fetchUserProfile() {
        guard let token = token, let url = URL(string: "\(baseURL)/users/profile") else {
            handleProfileUnavailable("请先登录以同步个人资料")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    self.error = error.localizedDescription
                    self.handleProfileUnavailable(error.localizedDescription)
                    return
                }

                guard let data = data else {
                    self.handleProfileUnavailable("服务器无响应")
                    return
                }

                do {
                    let result = try JSONDecoder().decode(UserProfileResponse.self, from: data)
                    if result.success, let user = result.data {
                        DispatchQueue.main.async {
                            self.userName = user.name
                            self.email = user.email
                            let fetchedHeight = Float(user.profile?.heightCm ?? 0)
                            self.heightCm = fetchedHeight > 0 ? fetchedHeight : 170

                            let fetchedWeight = Float(user.profile?.weightKg ?? 0)
                            self.weightKg = fetchedWeight > 0 ? fetchedWeight : 60
                            self.bmi = Float(user.profile?.bmi ?? 0)
                            self.editName = user.name
                            self.editGender = user.gender
                            self.editBirthDate = user.birthDate
                            self.bodyFatPercent = 0
                            self.isPremium = false
                            self.error = nil
                            self.updateAvatarInitials()
                        }
                    } else {
                        self.error = result.message
                        self.clearProfileData()
                    }
                } catch {
                    self.error = "解析用户信息失败"
                    self.clearProfileData()
                }
            }
        }.resume()
    }

    // MARK: - 网络请求: 更新个人资料
    func updateUserProfile() {
        guard let token = token, let url = URL(string: "\(baseURL)/users/profile") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any?] = [
            "name": editName,
            "birthDate": editBirthDate,
            "gender": editGender,
            "heightCm": heightCm > 0 ? heightCm : nil,
            "weightKg": weightKg > 0 ? weightKg : nil,
        ]

        request.httpBody = try? JSONSerialization.data(
            withJSONObject: body.compactMapValues { $0 }, options: [])

        isSavingProfile = true

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isSavingProfile = false

                if let error = error {
                    self.error = error.localizedDescription
                    return
                }

                guard let data = data else { return }

                do {
                    let result = try JSONDecoder().decode(UpdateProfileResponse.self, from: data)
                    if result.success {
                        DispatchQueue.main.async {
                            self.userName = self.editName
                            self.showEditProfile = false
                            self.updateAvatarInitials()
                        }
                    } else {
                        self.error = result.message
                    }
                } catch {
                    self.error = "资料更新失败"
                }
            }
        }.resume()
    }

    // MARK: - 网络请求: 获取偏好设置
    func fetchUserPreferences() {
        guard let token = token, let url = URL(string: "\(baseURL)/users/preferences") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }

                guard let data = data else { return }

                do {
                    let result = try JSONDecoder().decode(UserPreferencesResponse.self, from: data)
                    if result.success, let prefs = result.data {
                        DispatchQueue.main.async {
                            // 更新偏好设置数据
                            if let activityLevel = prefs.activityLevel {
                                // 更新活动水平
                            }
                            if let goals = prefs.goals {
                                // 更新目标
                                if let steps = goals.steps {
                                    // 更新步数目标
                                }
                            }
                        }
                    } else {
                        self.error = result.message
                    }
                } catch {
                    self.error = "解析偏好设置失败"
                }
            }
        }.resume()
    }

    // MARK: - 网络请求: 更新偏好设置
    func updateUserPreferences(prefs: [String: Any]) {
        guard let token = token, let url = URL(string: "\(baseURL)/users/preferences") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: prefs, options: [])

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }

                guard let data = data else { return }

                do {
                    let result = try JSONDecoder().decode(ProfileGenericResponse.self, from: data)
                    if result.success {
                        // 成功
                    } else {
                        self.error = result.message
                    }
                } catch {
                    self.error = "偏好设置更新失败"
                }
            }
        }.resume()
    }

    // MARK: - 网络请求: 注销账户
    func deleteAccount(completion: (() -> Void)? = nil) {
        guard let token = token, let url = URL(string: "\(baseURL)/users/account") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    self.error = error.localizedDescription
                    // 即使网络失败，也本地清理
                    completion?()
                    return
                }

                guard let data = data else {
                    completion?()
                    return
                }

                do {
                    let result = try JSONDecoder().decode(ProfileGenericResponse.self, from: data)
                    if result.success {
                        completion?()
                    } else {
                        self.error = result.message
                        // 继续本地清理
                        completion?()
                    }
                } catch {
                    self.error = "注销账户失败"
                    completion?()
                }
            }
        }.resume()
    }

    // MARK: - 辅助方法
    private func updateAvatarInitials() {
        avatarInitials = monogramText(for: userName)
    }

    private func monogramText(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "--" }

        let nameParts = trimmed.split(whereSeparator: { $0 == " " || $0 == "·" || $0 == "-" })
        if nameParts.count >= 2 {
            let letters = nameParts.prefix(2).compactMap { $0.first }.map(String.init).joined()
            return letters.isEmpty ? String(trimmed.prefix(2)) : letters.uppercased()
        }

        return String(trimmed.prefix(2))
    }

    private func applyPlaceholderProfile() {
        let placeholderNames = ["小鲸鱼", "风铃", "云朵", "星河", "橙子", "阿鹿", "木子", "海盐"]
        userName = placeholderNames.randomElement() ?? "星河"
        email = UserDefaults.standard.string(forKey: APIConfig.userEmailKey) ?? ""
        isPremium = false
        avatarLocalPath = nil
        avatarInitials = monogramText(for: userName)
        heightCm = 170
        weightKg = 60
        bmi = 20.8
        bodyFatPercent = 18.5
        editName = userName
        editGender = nil
        editBirthDate = nil
        editBio = ""
    }

    private func loadMockData() {
        userName = "Sarah Chen"
        email = "sarah.chen@email.com"
        isPremium = true
        avatarInitials = "SC"
        heightCm = 170
        weightKg = 60
        bmi = 20.8
        bodyFatPercent = 18.5

        boundDevices = [
            BoundDevice(
                id: "1",
                name: "Apple Watch Series 9",
                type: "Watch",
                batteryLevel: 85,
                connectionState: "Connected",
                lastSyncTime: Date().addingTimeInterval(-300).timeIntervalSince1970
            )
        ]

        realtimeSteps = 8542
        realtimeHeartRate = 72
        todaySleepMinutes = 420
        userInsightProfile = ProfileSummaryUI(
            activeTopics: ["基础健康知识"],
            preferredFoods: ["三文鱼", "西兰花", "糙米"],
            avoidedTopics: [],
            knowledgeGaps: ["睡眠质量", "心血管健康", "肠道健康"],
            knowledgeRadar: KnowledgeRadarUI(
                labels: ["营养素", "食物", "运动", "睡眠", "心理"],
                scores: [42, 38, 26, 20, 18]
            )
        )
        personalizationScore = 20

        editName = userName
        editGender = "female"
        editBirthDate = "1995-06-15"
        editBio = ""
    }

    private func handleProfileUnavailable(_ message: String?) {
        error = message ?? "资料暂不可用"
        if APIConfig.shouldAllowMockData {
            loadMockData()
        } else {
            applyPlaceholderProfile()
        }
    }

    private func clearProfileData() {
        userName = ""
        email = UserDefaults.standard.string(forKey: APIConfig.userEmailKey) ?? ""
        isPremium = false
        avatarLocalPath = nil
        avatarInitials = "--"
        heightCm = 0
        weightKg = 0
        bmi = 0
        bodyFatPercent = 0
        boundDevices = []
        realtimeSteps = 0
        realtimeHeartRate = 0
        editName = userName
        editGender = nil
        editBirthDate = nil
        editBio = ""
    }
}

// MARK: - 通知名称
extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
    static let premiumStatusDidChange = Notification.Name("premiumStatusDidChange")
}

// MARK: - 网络响应数据结构

// 用户资料响应
struct UserProfileResponse: Codable {
    let success: Bool
    let message: String
    let data: UserProfileData?
}

struct UserProfileData: Codable {
    let id: String
    let email: String
    let name: String
    let birthDate: String?
    let age: Int?
    let gender: String?
    let profile: UserProfileDetail?
    let createdAt: String?
}

struct UserProfileDetail: Codable {
    let heightCm: Double?
    let weightKg: Double?
    let bmi: Double?
}

// 更新资料响应
struct UpdateProfileResponse: Codable {
    let success: Bool
    let message: String
    let data: UpdateProfileData?
}

struct UpdateProfileData: Codable {
    let name: String?
    let birthDate: String?
    let gender: String?
    let profile: UserProfileDetail?
}

// 偏好设置响应
struct UserPreferencesResponse: Codable {
    let success: Bool
    let message: String
    let data: UserPreferencesData?
}

struct UserPreferencesData: Codable {
    let occupation: String?
    let hobbies: [String]?
    let healthGoals: [String]?
    let activityLevel: String?
    let goals: UserGoals?
    let notifications: UserNotifications?
    let targetWeight: Double?
}

struct UserGoals: Codable {
    let steps: Int?
    let waterMl: Int?
    let sleepMin: Int?
    let calories: Int?
    let exerciseMin: Int?
}

struct UserNotifications: Codable {
    let enabled: Bool?
    let startHour: Int?
    let endHour: Int?
}

// 通用响应
struct ProfileGenericResponse: Codable {
    let success: Bool
    let message: String
    let data: String?
}

// MARK: - 数据结构

// 已绑定设备
struct BoundDevice: Identifiable {
    let id: String
    let name: String
    let type: String
    let batteryLevel: Int
    let connectionState: String
    var lastSyncTime: TimeInterval
}

// 扫描到的设备
struct ScannedDevice: Identifiable {
    let id: String
    let name: String
    let type: String
    let rssi: Int
}

// 设置项
struct SettingsItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let iconName: String
    let iconColor: Color

    static let defaultItems: [SettingsItem] = [
        SettingsItem(
            id: "goals",
            title: "健康目标",
            subtitle: "设定每日目标",
            iconName: "flag.fill",
            iconColor: .sageBright
        ),
        SettingsItem(
            id: "notifications",
            title: "通知",
            subtitle: "管理提醒",
            iconName: "bell.fill",
            iconColor: .androidBlue
        ),
        SettingsItem(
            id: "privacy",
            title: "隐私设置",
            subtitle: "数据与安全",
            iconName: "lock.fill",
            iconColor: .purpleSoft
        ),
        SettingsItem(
            id: "help",
            title: "帮助与支持",
            subtitle: "常见问题与联系",
            iconName: "questionmark.circle.fill",
            iconColor: .orangeWarm
        ),
        SettingsItem(
            id: "logout",
            title: "退出登录",
            subtitle: nil,
            iconName: "rectangle.portrait.and.arrow.right",
            iconColor: .errorRed
        ),
    ]
}

// MARK: - 预览
#Preview {
    ProfileView()
}
