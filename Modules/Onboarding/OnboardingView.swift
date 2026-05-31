import Combine
import SwiftUI
import UIKit

// MARK: - Onboarding视图
struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                // 进度指示器
                ProgressIndicator(current: viewModel.currentStep, total: viewModel.totalSteps)
                    .padding(.top, 20)
                    .padding(.horizontal, AegisSpacing.pageHorizontal)

                // 内容
                TabView(selection: $viewModel.currentStep) {
                    WelcomeStep()
                        .tag(0)

                    GenderStep(selectedGender: $viewModel.selectedGender)
                        .tag(1)

                    HealthGoalsStep(selectedGoals: $viewModel.selectedHealthGoals)
                        .tag(2)

                    ActivityLevelStep(selectedLevel: $viewModel.selectedActivityLevel)
                        .tag(3)

                    OccupationStep(selectedOccupation: $viewModel.selectedOccupation)
                        .tag(4)

                    HobbiesStep(selectedHobbies: $viewModel.selectedHobbies)
                        .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)

                // 按钮
                OnboardingBottomButtons(viewModel: viewModel)
            }
        }
    }
}

// MARK: - 进度指示器
struct ProgressIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? Color.sageBright : Color.grayLight)
                    .frame(height: 4)
            }
        }
    }
}

// MARK: - 底部按钮
struct OnboardingBottomButtons: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 16) {
            // 主按钮
            Button(action: {
                if viewModel.currentStep < viewModel.totalSteps - 1 {
                    withAnimation {
                        viewModel.currentStep += 1
                    }
                } else {
                    viewModel.completeOnboarding()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(viewModel.currentStep < viewModel.totalSteps - 1 ? "下一步" : "开始使用")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.canProceed ? Color.sageBright : Color.grayLight)
                .cornerRadius(AegisCornerRadius.medium)
            }
            .disabled(!viewModel.canProceed || viewModel.isLoading)

            // 跳过按钮
            if viewModel.currentStep < viewModel.totalSteps - 1 {
                Button(action: {
                    withAnimation {
                        viewModel.currentStep = viewModel.totalSteps - 1
                    }
                }) {
                    Text("跳过")
                        .font(.system(size: 15))
                        .foregroundColor(.grayMid)
                }
            }
        }
        .padding(.horizontal, AegisSpacing.pageHorizontal)
        .padding(.bottom, 40)
    }
}

// MARK: - 欢迎步骤
struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo
            BrandLogoBadge(size: 120)

            VStack(spacing: 12) {
                Text("欢迎使用 AegisFlow")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.grayDark)

                Text("你的智能健康管理助手")
                    .font(.system(size: 17))
                    .foregroundColor(.grayMid)
            }

            Spacer()

            // 特性介绍
            VStack(alignment: .leading, spacing: 20) {
                OnboardingFeatureRow(
                    icon: "chart.bar.fill", title: "智能数据分析", description: "全面追踪你的健康指标")
                OnboardingFeatureRow(
                    icon: "brain.head.profile", title: "AI健康建议", description: "个性化健康指导")
                OnboardingFeatureRow(icon: "bell.fill", title: "智能提醒", description: "不错过任何健康习惯")
            }
            .padding(.horizontal, AegisSpacing.pageHorizontal)

            Spacer()
        }
    }
}

// MARK: - 品牌 Logo 徽章
private struct BrandLogoBadge: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.sageBright, .tealDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: .sageBright.opacity(0.3), radius: 20, x: 0, y: 10)

            if let uiImage = UIImage(named: "AppIcon") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.62, height: size * 0.62)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.14, style: .continuous))
            } else {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: size * 0.46))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - 特性行
struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.sageBright.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.sageBright)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.grayDark)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.grayMid)
            }

            Spacer()
        }
    }
}

// MARK: - 性别选择步骤
struct GenderStep: View {
    @Binding var selectedGender: String?

    private let genders: [(value: String, label: String, emoji: String)] = [
        ("male", "男", "👨"),
        ("female", "女", "👩"),
        ("other", "其他", "🌈"),
    ]

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text("你的性别是？")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.grayDark)

                Text("帮助我们为你提供更准确的分析")
                    .font(.system(size: 15))
                    .foregroundColor(.grayMid)
            }
            .padding(.top, 40)

            Spacer()

            // 性别选项
            HStack(spacing: 20) {
                ForEach(genders, id: \.value) { gender in
                    OnboardingGenderOption(
                        emoji: gender.emoji,
                        label: gender.label,
                        isSelected: selectedGender == gender.value
                    ) {
                        selectedGender = gender.value
                    }
                }
            }

            Spacer()
        }
    }
}

// MARK: - 性别选项
struct OnboardingGenderOption: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 48))

                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.grayDark)
            }
            .frame(width: 100, height: 120)
            .background(isSelected ? Color.sageBright.opacity(0.15) : Color.white)
            .cornerRadius(AegisCornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AegisCornerRadius.large)
                    .stroke(isSelected ? Color.sageBright : Color.grayLight, lineWidth: 2)
            )
        }
    }
}

// MARK: - 健康目标选择步骤
struct HealthGoalsStep: View {
    @Binding var selectedGoals: Set<String>

    private let goals: [(value: String, label: String, emoji: String, description: String)] = [
        ("weight_loss", "减重", "🎯", "控制体重，塑造身材"),
        ("muscle", "增肌", "💪", "增强力量，塑形健体"),
        ("endurance", "提高耐力", "🏃", "增强心肺功能"),
        ("sleep", "改善睡眠", "😴", "提高睡眠质量"),
        ("stress", "缓解压力", "🧘", "放松身心"),
        ("nutrition", "均衡营养", "🥗", "健康饮食习惯"),
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("你的健康目标是什么？")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.grayDark)

                Text("可多选")
                    .font(.system(size: 15))
                    .foregroundColor(.grayMid)
            }
            .padding(.top, 40)

            // 目标网格
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(goals, id: \.value) { goal in
                    OnboardingGoalOption(
                        emoji: goal.emoji,
                        title: goal.label,
                        description: goal.description,
                        isSelected: selectedGoals.contains(goal.value)
                    ) {
                        if selectedGoals.contains(goal.value) {
                            selectedGoals.remove(goal.value)
                        } else {
                            selectedGoals.insert(goal.value)
                        }
                    }
                }
            }
            .padding(.horizontal, AegisSpacing.pageHorizontal)

            Spacer()
        }
    }
}

// MARK: - 目标选项
struct OnboardingGoalOption: View {
    let emoji: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(emoji)
                    .font(.system(size: 28))

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.grayDark)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.grayMid)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(isSelected ? Color.sageBright.opacity(0.15) : Color.white)
            .cornerRadius(AegisCornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AegisCornerRadius.large)
                    .stroke(isSelected ? Color.sageBright : Color.grayLight, lineWidth: 2)
            )
        }
    }
}

// MARK: - 活动水平选择步骤
struct ActivityLevelStep: View {
    @Binding var selectedLevel: String?

    private let levels: [(value: String, label: String, emoji: String, description: String)] = [
        ("sedentary", "久坐", "🪑", "很少运动"),
        ("light", "轻度", "🚶", "偶尔运动"),
        ("moderate", "中度", "🏃", "经常运动"),
        ("active", "活跃", "💪", "每天运动"),
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("你的活动水平是？")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.grayDark)

                Text("这帮助我们为你制定合适的计划")
                    .font(.system(size: 15))
                    .foregroundColor(.grayMid)
            }
            .padding(.top, 40)

            Spacer()

            // 活动水平选项
            VStack(spacing: 12) {
                ForEach(levels, id: \.value) { level in
                    OnboardingActivityLevelRow(
                        emoji: level.emoji,
                        title: level.label,
                        description: level.description,
                        isSelected: selectedLevel == level.value
                    ) {
                        selectedLevel = level.value
                    }
                }
            }
            .padding(.horizontal, AegisSpacing.pageHorizontal)

            Spacer()
        }
    }
}

// MARK: - 活动水平行
struct OnboardingActivityLevelRow: View {
    let emoji: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(emoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.grayDark)

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.grayMid)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.sageBright)
                }
            }
            .padding(16)
            .background(isSelected ? Color.sageBright.opacity(0.15) : Color.white)
            .cornerRadius(AegisCornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AegisCornerRadius.large)
                    .stroke(isSelected ? Color.sageBright : Color.grayLight, lineWidth: 2)
            )
        }
    }
}

// MARK: - 职业选择步骤
struct OccupationStep: View {
    @Binding var selectedOccupation: String?

    private let occupations: [(value: String, label: String, emoji: String)] = [
        ("student", "学生", "📚"),
        ("office", "办公室", "💼"),
        ("physical", "体力工作", "🏗️"),
        ("freelance", "自由职业", "🎨"),
        ("retired", "退休", "🌅"),
        ("other", "其他", "📋"),
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("你的职业是？")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.grayDark)

                Text("帮助我们了解你的日常作息")
                    .font(.system(size: 15))
                    .foregroundColor(.grayMid)
            }
            .padding(.top, 40)

            Spacer()

            // 职业网格
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 16
            ) {
                ForEach(occupations, id: \.value) { occupation in
                    OnboardingOccupationOption(
                        emoji: occupation.emoji,
                        label: occupation.label,
                        isSelected: selectedOccupation == occupation.value
                    ) {
                        selectedOccupation = occupation.value
                    }
                }
            }
            .padding(.horizontal, AegisSpacing.pageHorizontal)

            Spacer()
        }
    }
}

// MARK: - 职业选项
struct OnboardingOccupationOption: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 32))

                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.grayDark)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Color.sageBright.opacity(0.15) : Color.white)
            .cornerRadius(AegisCornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AegisCornerRadius.large)
                    .stroke(isSelected ? Color.sageBright : Color.grayLight, lineWidth: 2)
            )
        }
    }
}

// MARK: - 爱好选择步骤
struct HobbiesStep: View {
    @Binding var selectedHobbies: Set<String>

    private let hobbies: [(value: String, label: String, emoji: String)] = [
        ("reading", "阅读", "📖"),
        ("music", "音乐", "🎵"),
        ("travel", "旅行", "✈️"),
        ("cooking", "烹饪", "🍳"),
        ("gaming", "游戏", "🎮"),
        ("sports", "运动", "⚽"),
        ("art", "艺术", "🎨"),
        ("nature", "自然", "🌿"),
        ("photography", "摄影", "📷"),
        ("social", "社交", "👥"),
        ("yoga", "瑜伽", "🧘"),
        ("meditation", "冥想", "🕉️"),
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("你有哪些爱好？")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.grayDark)

                Text("可多选")
                    .font(.system(size: 15))
                    .foregroundColor(.grayMid)
            }
            .padding(.top, 40)

            // 爱好网格
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                ForEach(hobbies, id: \.value) { hobby in
                    OnboardingHobbyOption(
                        emoji: hobby.emoji,
                        label: hobby.label,
                        isSelected: selectedHobbies.contains(hobby.value)
                    ) {
                        if selectedHobbies.contains(hobby.value) {
                            selectedHobbies.remove(hobby.value)
                        } else {
                            selectedHobbies.insert(hobby.value)
                        }
                    }
                }
            }
            .padding(.horizontal, AegisSpacing.pageHorizontal)

            Spacer()
        }
    }
}

// MARK: - 爱好选项
struct OnboardingHobbyOption: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 28))

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.grayDark)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.sageBright.opacity(0.15) : Color.white)
            .cornerRadius(AegisCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AegisCornerRadius.medium)
                    .stroke(isSelected ? Color.sageBright : Color.grayLight, lineWidth: 2)
            )
        }
    }
}

// MARK: - Onboarding视图模型
class OnboardingViewModel: ObservableObject {

    // 网络请求配置
    private let baseURL = APIConfig.baseURL
    private var token: String? {
        UserDefaults.standard.string(forKey: APIConfig.accessTokenKey)
    }

    // 步骤状态
    @Published var currentStep: Int = 0
    @Published var selectedGender: String? = nil
    @Published var selectedHealthGoals: Set<String> = []
    @Published var selectedActivityLevel: String? = nil
    @Published var selectedOccupation: String? = nil
    @Published var selectedHobbies: Set<String> = []

    // 加载状态
    @Published var isLoading: Bool = false
    @Published var error: String? = nil

    let totalSteps = 6

    var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1: return selectedGender != nil
        case 2: return !selectedHealthGoals.isEmpty
        case 3: return selectedActivityLevel != nil
        case 4: return selectedOccupation != nil
        case 5: return !selectedHobbies.isEmpty
        default: return true
        }
    }

    func completeOnboarding() {
        guard let token = token else {
            finishOnboardingLocally()
            return
        }

        isLoading = true

        let group = DispatchGroup()
        var lastError: String? = nil

        if let preferencesURL = URL(string: "\(baseURL)/users/preferences") {
            group.enter()
            var request = URLRequest(url: preferencesURL)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(
                withJSONObject: [
                    "occupation": selectedOccupation ?? "",
                    "hobbies": Array(selectedHobbies),
                    "healthGoals": Array(selectedHealthGoals),
                    "activityLevel": selectedActivityLevel ?? "",
                    "notificationsEnabled": true,
                ], options: [])

            URLSession.shared.dataTask(with: request) { data, _, error in
                defer { group.leave() }
                if let error = error {
                    lastError = error.localizedDescription
                    return
                }
                if let data = data,
                    let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let success = payload["success"] as? Bool,
                    !success
                {
                    lastError = payload["message"] as? String ?? "偏好提交失败"
                }
            }.resume()
        }

        if let selectedGender,
            let profileURL = URL(string: "\(baseURL)/users/profile")
        {
            group.enter()
            var request = URLRequest(url: profileURL)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(
                withJSONObject: [
                    "gender": selectedGender
                ], options: [])

            URLSession.shared.dataTask(with: request) { data, _, error in
                defer { group.leave() }
                if let error = error {
                    lastError = error.localizedDescription
                    return
                }
                if let data = data,
                    let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let success = payload["success"] as? Bool,
                    !success
                {
                    lastError = payload["message"] as? String ?? "资料提交失败"
                }
            }.resume()
        }

        group.notify(queue: .main) {
            self.isLoading = false
            self.error = lastError
            self.finishOnboardingLocally()
        }
    }

    private func saveOnboardingDataLocally() {
        // 保存到本地存储
        UserDefaults.standard.set(selectedGender, forKey: "onboarding_gender")
        UserDefaults.standard.set(Array(selectedHealthGoals), forKey: "onboarding_healthGoals")
        UserDefaults.standard.set(selectedActivityLevel, forKey: "onboarding_activityLevel")
        UserDefaults.standard.set(selectedOccupation, forKey: "onboarding_occupation")
        UserDefaults.standard.set(Array(selectedHobbies), forKey: "onboarding_hobbies")
    }

    private func finishOnboardingLocally() {
        saveOnboardingDataLocally()
        PreferencesStorage.shared.onboardingCompleted = true
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
    }

    func loadSavedData() {
        // 从本地加载已保存的数据
        if let gender = UserDefaults.standard.string(forKey: "onboarding_gender") {
            selectedGender = gender
        }
        if let goals = UserDefaults.standard.stringArray(forKey: "onboarding_healthGoals") {
            selectedHealthGoals = Set(goals)
        }
        if let activityLevel = UserDefaults.standard.string(forKey: "onboarding_activityLevel") {
            selectedActivityLevel = activityLevel
        }
        if let occupation = UserDefaults.standard.string(forKey: "onboarding_occupation") {
            selectedOccupation = occupation
        }
        if let hobbies = UserDefaults.standard.stringArray(forKey: "onboarding_hobbies") {
            selectedHobbies = Set(hobbies)
        }
    }
}

// MARK: - 网络响应结构
struct OnboardingResponse: Codable {
    let success: Bool
    let message: String
    let data: OnboardingData?
}

struct OnboardingData: Codable {
    let recommendedGoals: [String]?
    let suggestedPlans: [String]?
}

// MARK: - 通知名称
extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}

// MARK: - 预览
#Preview {
    OnboardingView()
}
