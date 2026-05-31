import Combine
import SwiftUI

// MARK: - 等级页面
struct LevelScreen: View {
    @StateObject private var viewModel = LevelViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AegisDynamicBackground()

                ScrollView {
                    VStack(spacing: AegisSpacing.sectionGap) {
                        // 当前等级卡片
                        CurrentLevelCard(
                            level: viewModel.currentLevel,
                            title: viewModel.levelTitle,
                            experience: viewModel.currentExp,
                            nextLevelExp: viewModel.nextLevelExp,
                            progress: viewModel.levelProgress
                        )

                        // 等级特权
                        PrivilegesSection(privileges: viewModel.privileges)

                        // 经验值获取途径
                        ExpSourcesSection(sources: viewModel.expSources)

                        // 等级历史
                        LevelHistorySection(history: viewModel.levelHistory)

                        Spacer(minLength: AegisSpacing.bottomSafe)
                    }
                    .padding(.horizontal, AegisSpacing.pageHorizontal)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("我的等级")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

// MARK: - 当前等级卡片
struct CurrentLevelCard: View {
    let level: Int
    let title: String
    let experience: Int
    let nextLevelExp: Int
    let progress: Double

    var body: some View {
        VStack(spacing: 20) {
            // 等级徽章
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.sageBright, .tealDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .sageBright.opacity(0.3), radius: 20, x: 0, y: 10)

                VStack(spacing: 4) {
                    Text("LV.\(level)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
            }

            // 等级称号
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.grayDark)

            // 经验值进度
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.grayLight.opacity(0.5))
                            .frame(height: 12)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.sageBright, .tealDeep],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 12)
                    }
                }
                .frame(height: 12)

                HStack {
                    Text("\(experience) 经验")
                        .font(.system(size: 12))
                        .foregroundColor(.grayMid)

                    Spacer()

                    Text("距离下一级还需 \(nextLevelExp - experience) 经验")
                        .font(.system(size: 12))
                        .foregroundColor(.sageBright)
                }
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 特权区
struct PrivilegesSection: View {
    let privileges: [PrivilegeItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前特权")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.grayDark)

            ForEach(privileges) { privilege in
                PrivilegeRow(privilege: privilege)
            }
        }
    }
}

// MARK: - 特权行
struct PrivilegeRow: View {
    let privilege: PrivilegeItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(privilege.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: privilege.icon)
                    .font(.system(size: 20))
                    .foregroundColor(privilege.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(privilege.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.grayDark)

                Text(privilege.description)
                    .font(.system(size: 13))
                    .foregroundColor(.grayMid)
            }

            Spacer()

            if privilege.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.successGreen)
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.medium)
    }
}

// MARK: - 经验来源区
struct ExpSourcesSection: View {
    let sources: [ExpSource]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("经验值获取途径")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.grayDark)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(sources) { source in
                    ExpSourceCard(source: source)
                }
            }
        }
    }
}

// MARK: - 经验来源卡片
struct ExpSourceCard: View {
    let source: ExpSource

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: source.icon)
                .font(.system(size: 28))
                .foregroundColor(source.color)

            Text(source.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.grayDark)

            Text("+\(source.exp) EXP")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.sageBright)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.medium)
    }
}

// MARK: - 等级历史区
struct LevelHistorySection: View {
    let history: [LevelHistoryItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("等级历程")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.grayDark)

            ForEach(history) { item in
                LevelHistoryRow(item: item)
            }
        }
    }
}

// MARK: - 等级历史行
struct LevelHistoryRow: View {
    let item: LevelHistoryItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.isLevelUp ? Color.sageBright : Color.grayLight)
                    .frame(width: 40, height: 40)

                Text("L\(item.level)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(item.isLevelUp ? .white : .grayMid)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.grayDark)

                Text(item.date)
                    .font(.system(size: 12))
                    .foregroundColor(.grayMid)
            }

            Spacer()

            if item.isLevelUp {
                Text("升级")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.sageBright)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.sageBright.opacity(0.15))
                    .cornerRadius(8)
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.medium)
    }
}

// MARK: - ViewModel
class LevelViewModel: ObservableObject {
    @Published var currentLevel: Int = 5
    @Published var levelTitle: String = "健康达人"
    @Published var currentExp: Int = 2450
    @Published var nextLevelExp: Int = 3000
    @Published var privileges: [PrivilegeItem] = []
    @Published var expSources: [ExpSource] = []
    @Published var levelHistory: [LevelHistoryItem] = []

    private let apiClient = APIClient.shared

    var levelProgress: Double {
        guard nextLevelExp > 0 else { return 0 }
        return Double(currentExp) / Double(nextLevelExp)
    }

    @MainActor
    func loadData() {
        Task {
            do {
                let response = try await apiClient.request(
                    endpoint: "/api/v1/gamification/level",
                    method: "GET"
                )

                if let data = response["data"] as? [String: Any] {
                    self.currentLevel = data["level"] as? Int ?? 5
                    self.levelTitle = data["title"] as? String ?? "健康达人"
                    self.currentExp = data["current_exp"] as? Int ?? 2450
                    self.nextLevelExp = data["next_level_exp"] as? Int ?? 3000

                    if let privilegesData = data["privileges"] as? [[String: Any]] {
                        self.privileges = privilegesData.compactMap { item in
                            guard let icon = item["icon"] as? String,
                                let title = item["title"] as? String,
                                let desc = item["description"] as? String,
                                let colorHex = item["color"] as? String
                            else { return nil }
                            return PrivilegeItem(
                                icon: icon,
                                title: title,
                                description: desc,
                                color: Color(hex: colorHex),
                                isActive: item["is_active"] as? Bool ?? false
                            )
                        }
                    }

                    if let sourcesData = data["exp_sources"] as? [[String: Any]] {
                        self.expSources = sourcesData.compactMap { item in
                            guard let icon = item["icon"] as? String,
                                let title = item["title"] as? String,
                                let exp = item["exp"] as? Int,
                                let colorHex = item["color"] as? String
                            else { return nil }
                            return ExpSource(
                                icon: icon,
                                title: title,
                                exp: exp,
                                color: Color(hex: colorHex)
                            )
                        }
                    }

                    if let historyData = data["level_history"] as? [[String: Any]] {
                        self.levelHistory = historyData.compactMap { item in
                            guard let level = item["level"] as? Int,
                                let title = item["title"] as? String,
                                let date = item["date"] as? String
                            else { return nil }
                            return LevelHistoryItem(
                                level: level,
                                title: title,
                                date: date,
                                isLevelUp: item["is_level_up"] as? Bool ?? false
                            )
                        }
                    }
                }
            } catch {
                print("Level API Error: \(error.localizedDescription)")
                loadMockData()
            }
        }
    }

    private func loadMockData() {
        privileges = [
            PrivilegeItem(
                icon: "star.fill", title: "专属徽章", description: "展示专属等级标识", color: .yellowBright,
                isActive: true),
            PrivilegeItem(
                icon: "chart.line.uptrend.xyaxis", title: "高级分析", description: "解锁深度数据分析",
                color: .tealDeep, isActive: true),
            PrivilegeItem(
                icon: "bell.badge.fill", title: "优先提醒", description: "享受优先推送通知", color: .orangeWarm,
                isActive: false),
            PrivilegeItem(
                icon: "crown.fill", title: "专属客服", description: "24小时专属客服", color: .purpleSoft,
                isActive: false),
        ]

        expSources = [
            ExpSource(icon: "figure.walk", title: "每日步数", exp: 50, color: .tealDeep),
            ExpSource(icon: "drop.fill", title: "饮水记录", exp: 30, color: .androidBlue),
            ExpSource(icon: "fork.knife", title: "饮食记录", exp: 40, color: .orangeWarm),
            ExpSource(icon: "moon.fill", title: "睡眠记录", exp: 35, color: .purpleSoft),
        ]

        levelHistory = [
            LevelHistoryItem(level: 5, title: "达到健康达人", date: "2026-04-01", isLevelUp: true),
            LevelHistoryItem(level: 4, title: "连续打卡7天", date: "2026-03-25", isLevelUp: true),
            LevelHistoryItem(level: 3, title: "完成新手任务", date: "2026-03-10", isLevelUp: true),
        ]
    }
}

// MARK: - 数据模型
struct PrivilegeItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isActive: Bool
}

struct ExpSource: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let exp: Int
    let color: Color
}

struct LevelHistoryItem: Identifiable {
    let id = UUID()
    let level: Int
    let title: String
    let date: String
    let isLevelUp: Bool
}

// MARK: - 奖励页面
struct RewardScreen: View {
    @StateObject private var viewModel = RewardViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AegisDynamicBackground()

                ScrollView {
                    VStack(spacing: AegisSpacing.sectionGap) {
                        // 积分余额卡片
                        PointsBalanceCard(
                            balance: viewModel.pointsBalance,
                            trend: viewModel.pointsTrend
                        )

                        // 可兑换奖励
                        AvailableRewardsSection(rewards: viewModel.availableRewards)

                        // 领取记录
                        RewardHistorySection(history: viewModel.rewardHistory)

                        Spacer(minLength: AegisSpacing.bottomSafe)
                    }
                    .padding(.horizontal, AegisSpacing.pageHorizontal)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("我的奖励")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

// MARK: - 积分余额卡片
struct PointsBalanceCard: View {
    let balance: Int
    let trend: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("我的积分")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.8))

                HStack(alignment: .bottom, spacing: 8) {
                    Text("\(balance)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("积分")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 8)
                }

                HStack(spacing: 4) {
                    Image(
                        systemName: trend >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    Text("\(trend >= 0 ? "+" : "")\(trend) 本月")
                        .font(.system(size: 13))
                }
                .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            // 积分图标
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "star.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.yellowBright)
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(
            LinearGradient(
                colors: [.orangeWarm, Color(hex: "#FF7043")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AegisCornerRadius.large)
    }
}

// MARK: - 可兑换奖励区
struct AvailableRewardsSection: View {
    let rewards: [RewardItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("可兑换奖励")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.grayDark)

            ForEach(rewards) { reward in
                RewardCard(reward: reward)
            }
        }
    }
}

// MARK: - 奖励卡片
struct RewardCard: View {
    let reward: RewardItem
    @State private var showExchange = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(reward.color.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: reward.icon)
                    .font(.system(size: 28))
                    .foregroundColor(reward.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(reward.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.grayDark)

                Text(reward.description)
                    .font(.system(size: 13))
                    .foregroundColor(.grayMid)

                Text("\(reward.points) 积分")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(reward.color)
            }

            Spacer()

            Button(action: { showExchange = true }) {
                Text("兑换")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(reward.canExchange ? reward.color : Color.grayLight)
                    .cornerRadius(8)
            }
            .disabled(!reward.canExchange)
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 领取记录区
struct RewardHistorySection: View {
    let history: [RewardHistoryItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("领取记录")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.grayDark)

            ForEach(history) { item in
                RewardHistoryRow(item: item)
            }
        }
    }
}

// MARK: - 领取记录行
struct RewardHistoryRow: View {
    let item: RewardHistoryItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 20))
                .foregroundColor(item.color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.grayDark)

                Text(item.date)
                    .font(.system(size: 12))
                    .foregroundColor(.grayMid)
            }

            Spacer()

            Text("-\(item.points)积分")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.errorRed)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - ViewModel
class RewardViewModel: ObservableObject {
    @Published var pointsBalance: Int = 1250
    @Published var pointsTrend: Int = 320
    @Published var availableRewards: [RewardItem] = []
    @Published var rewardHistory: [RewardHistoryItem] = []

    private let apiClient = APIClient.shared

    @MainActor
    func loadData() {
        Task {
            do {
                let response = try await apiClient.request(
                    endpoint: "/api/v1/gamification/points",
                    method: "GET"
                )

                if let data = response["data"] as? [String: Any] {
                    self.pointsBalance = data["balance"] as? Int ?? 1250
                    self.pointsTrend = data["monthly_trend"] as? Int ?? 320

                    if let rewardsData = data["available_rewards"] as? [[String: Any]] {
                        self.availableRewards = rewardsData.compactMap { item in
                            guard let icon = item["icon"] as? String,
                                let title = item["title"] as? String,
                                let desc = item["description"] as? String,
                                let points = item["points"] as? Int,
                                let colorHex = item["color"] as? String
                            else { return nil }
                            return RewardItem(
                                icon: icon,
                                title: title,
                                description: desc,
                                points: points,
                                color: Color(hex: colorHex),
                                canExchange: item["can_exchange"] as? Bool ?? true
                            )
                        }
                    }

                    if let historyData = data["reward_history"] as? [[String: Any]] {
                        self.rewardHistory = historyData.compactMap { item in
                            guard let icon = item["icon"] as? String,
                                let title = item["title"] as? String,
                                let date = item["date"] as? String,
                                let points = item["points"] as? Int,
                                let colorHex = item["color"] as? String
                            else { return nil }
                            return RewardHistoryItem(
                                icon: icon,
                                title: title,
                                date: date,
                                points: points,
                                color: Color(hex: colorHex)
                            )
                        }
                    }
                }
            } catch {
                print("Points API Error: \(error.localizedDescription)")
                loadMockData()
            }
        }
    }

    @MainActor
    func exchangeReward(rewardId: String, reward: RewardItem) async -> Bool {
        do {
            let response = try await apiClient.request(
                endpoint: "/api/v1/gamification/exchange",
                method: "POST",
                parameters: [
                    "reward_id": rewardId,
                    "points": reward.points,
                ]
            )

            if let success = response["success"] as? Bool, success {
                // 扣除积分并刷新余额
                self.pointsBalance -= reward.points
                self.availableRewards = self.availableRewards.map {
                    $0.id == reward.id
                        ? RewardItem(
                            icon: $0.icon,
                            title: $0.title,
                            description: $0.description,
                            points: $0.points,
                            color: $0.color,
                            canExchange: false
                        ) : $0
                }
                return true
            }
            return false
        } catch {
            print("Exchange Error: \(error.localizedDescription)")
            return false
        }
    }

    private func loadMockData() {
        availableRewards = [
            RewardItem(
                icon: "cup.and.saucer.fill", title: "健康饮品券", description: "指定饮品店兑换券", points: 500,
                color: .tealDeep, canExchange: true),
            RewardItem(
                icon: "figure.run", title: "运动装备", description: "运动手环9折券", points: 800,
                color: .orangeWarm, canExchange: true),
            RewardItem(
                icon: "bed.double.fill", title: "睡眠课程", description: "专业睡眠指导课", points: 1500,
                color: .purpleSoft, canExchange: false),
        ]

        rewardHistory = [
            RewardHistoryItem(
                icon: "cup.and.saucer.fill", title: "兑换健康饮品券", date: "2026-04-10", points: 500,
                color: .tealDeep),
            RewardHistoryItem(
                icon: "heart.fill", title: "兑换心率监测", date: "2026-03-28", points: 1200,
                color: .errorRed),
        ]
    }
}

// MARK: - 数据模型
struct RewardItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let points: Int
    let color: Color
    let canExchange: Bool
}

struct RewardHistoryItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let date: String
    let points: Int
    let color: Color
}

// MARK: - Premium会员页面
struct PremiumScreen: View {
    @StateObject private var viewModel = PremiumViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AegisDynamicBackground()

                ScrollView {
                    VStack(spacing: AegisSpacing.sectionGap) {
                        // Premium介绍
                        PremiumHeader(
                            isPremium: viewModel.isPremium, expiryDate: viewModel.expiryDate)

                        // 会员特权
                        PremiumPrivilegesSection(privileges: viewModel.privileges)

                        // 会员套餐
                        PremiumPlansSection(
                            plans: viewModel.plans, selectedPlan: $viewModel.selectedPlan)

                        // 常见问题
                        FAQSection(faqs: viewModel.faqs)

                        Spacer(minLength: AegisSpacing.bottomSafe)
                    }
                    .padding(.horizontal, AegisSpacing.pageHorizontal)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Premium会员")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

// MARK: - Premium头部
struct PremiumHeader: View {
    let isPremium: Bool
    let expiryDate: String

    var body: some View {
        VStack(spacing: 16) {
            // 会员图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellowBright, .orangeWarm],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .yellowBright.opacity(0.3), radius: 20, x: 0, y: 10)

                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text(isPremium ? "Premium会员" : "解锁Premium")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.grayDark)

                if isPremium {
                    Text("有效期至 \(expiryDate)")
                        .font(.system(size: 14))
                        .foregroundColor(.grayMid)
                } else {
                    Text("享受全部高级功能")
                        .font(.system(size: 14))
                        .foregroundColor(.grayMid)
                }
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Premium特权区
struct PremiumPrivilegesSection: View {
    let privileges: [PremiumPrivilege]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("会员特权")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.grayDark)

            ForEach(privileges) { privilege in
                PremiumPrivilegeRow(privilege: privilege)
            }
        }
    }
}

// MARK: - Premium特权行
struct PremiumPrivilegeRow: View {
    let privilege: PremiumPrivilege

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(privilege.color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: privilege.icon)
                    .font(.system(size: 22))
                    .foregroundColor(privilege.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(privilege.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.grayDark)

                Text(privilege.description)
                    .font(.system(size: 13))
                    .foregroundColor(.grayMid)
            }

            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 24))
                .foregroundColor(.yellowBright)
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.medium)
    }
}

// MARK: - Premium套餐区
struct PremiumPlansSection: View {
    let plans: [PremiumPlan]
    @Binding var selectedPlan: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择套餐")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.grayDark)

            ForEach(plans) { plan in
                PremiumPlanCard(plan: plan, isSelected: selectedPlan == plan.id) {
                    selectedPlan = plan.id
                }
            }
        }
    }
}

// MARK: - Premium套餐卡片
struct PremiumPlanCard: View {
    let plan: PremiumPlan
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.grayDark)

                        if plan.isPopular {
                            Text("推荐")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orangeWarm)
                                .cornerRadius(4)
                        }
                    }

                    Text(plan.originalPrice)
                        .font(.system(size: 13))
                        .foregroundColor(.grayMid)
                        .strikethrough()

                    Text(plan.currentPrice)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.orangeWarm)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.sageBright)
                }
            }
            .padding(AegisSpacing.cardPadding)
            .background(isSelected ? Color.sageBright.opacity(0.1) : Color.white)
            .cornerRadius(AegisCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AegisCornerRadius.medium)
                    .stroke(
                        isSelected ? Color.sageBright : Color.grayLight,
                        lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - FAQ区
struct FAQSection: View {
    let faqs: [FAQItem]
    @State private var expandedIndex: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("常见问题")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.grayDark)

            ForEach(Array(faqs.enumerated()), id: \.element.id) { index, faq in
                PremiumFAQRow(faq: faq, isExpanded: expandedIndex == index) {
                    withAnimation {
                        expandedIndex = expandedIndex == index ? nil : index
                    }
                }
            }
        }
    }
}

// MARK: - FAQ行（会员页专用，避免与 HelpSupport.FAQRow 重名）
struct PremiumFAQRow: View {
    let faq: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                HStack {
                    Text(faq.question)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.grayDark)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.grayMid)
                }
            }

            if isExpanded {
                Text(faq.answer)
                    .font(.system(size: 13))
                    .foregroundColor(.grayMid)
                    .padding(.top, 4)
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.medium)
    }
}

// MARK: - ViewModel
class PremiumViewModel: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var expiryDate: String = "2026-12-31"
    @Published var selectedPlan: String? = nil
    @Published var privileges: [PremiumPrivilege] = []
    @Published var plans: [PremiumPlan] = []
    @Published var faqs: [FAQItem] = []
    @Published var isPurchasing: Bool = false

    private let apiClient = APIClient.shared

    @MainActor
    func loadData() {
        Task {
            do {
                let response = try await apiClient.request(
                    endpoint: "/api/v1/gamification/premium",
                    method: "GET"
                )

                if let data = response["data"] as? [String: Any] {
                    self.isPremium = data["is_premium"] as? Bool ?? false
                    self.expiryDate = data["expiry_date"] as? String ?? "2026-12-31"

                    if let privilegesData = data["privileges"] as? [[String: Any]] {
                        self.privileges = privilegesData.compactMap { item in
                            guard let icon = item["icon"] as? String,
                                let title = item["title"] as? String,
                                let desc = item["description"] as? String,
                                let colorHex = item["color"] as? String
                            else { return nil }
                            return PremiumPrivilege(
                                icon: icon,
                                title: title,
                                description: desc,
                                color: Color(hex: colorHex)
                            )
                        }
                    }

                    if let plansData = data["plans"] as? [[String: Any]] {
                        self.plans = plansData.compactMap { item in
                            guard let id = item["id"] as? String,
                                let name = item["name"] as? String,
                                let originalPrice = item["original_price"] as? String,
                                let currentPrice = item["current_price"] as? String
                            else { return nil }
                            return PremiumPlan(
                                id: id,
                                name: name,
                                originalPrice: originalPrice,
                                currentPrice: currentPrice,
                                isPopular: item["is_popular"] as? Bool ?? false
                            )
                        }
                    }

                    if let faqsData = data["faqs"] as? [[String: Any]] {
                        self.faqs = faqsData.compactMap { item in
                            guard let question = item["question"] as? String,
                                let answer = item["answer"] as? String
                            else { return nil }
                            return FAQItem(question: question, answer: answer)
                        }
                    }
                }
            } catch {
                print("Premium API Error: \(error.localizedDescription)")
                loadMockData()
            }
        }
    }

    @MainActor
    func purchasePlan() async -> Bool {
        guard let planId = selectedPlan else { return false }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let response = try await apiClient.request(
                endpoint: "/api/v1/gamification/premium/purchase",
                method: "POST",
                parameters: ["plan_id": planId]
            )

            if let success = response["success"] as? Bool, success {
                self.isPremium = true
                self.expiryDate = response["expiry_date"] as? String ?? "2027-04-14"
                NotificationCenter.default.post(name: .premiumStatusDidChange, object: nil)
                return true
            }
            return false
        } catch {
            print("Purchase Error: \(error.localizedDescription)")
            return false
        }
    }

    private func loadMockData() {
        privileges = [
            PremiumPrivilege(
                icon: "chart.bar.fill", title: "高级数据分析", description: "解锁详细健康报告和趋势分析",
                color: .tealDeep),
            PremiumPrivilege(
                icon: "brain.head.profile", title: "AI深度咨询", description: "无限次AI健康顾问对话",
                color: .purpleSoft),
            PremiumPrivilege(
                icon: "bell.badge.fill", title: "智能提醒", description: "个性化提醒和深度睡眠监测",
                color: .orangeWarm),
            PremiumPrivilege(
                icon: "crown.fill", title: "专属客服", description: "24小时VIP专属客服", color: .yellowBright),
        ]

        plans = [
            PremiumPlan(
                id: "monthly", name: "月卡", originalPrice: "¥68/月", currentPrice: "¥38/月",
                isPopular: false),
            PremiumPlan(
                id: "yearly", name: "年卡", originalPrice: "¥598/年", currentPrice: "¥298/年",
                isPopular: true),
            PremiumPlan(
                id: "lifetime", name: "永久会员", originalPrice: "¥998", currentPrice: "¥598",
                isPopular: false),
        ]

        faqs = [
            FAQItem(
                question: "Premium会员有什么特权？", answer: "Premium会员可以享受高级数据分析、AI深度咨询、智能提醒、专属客服等全部高级功能。"),
            FAQItem(question: "如何取消订阅？", answer: "您可以在设置-订阅管理中取消订阅，取消后将在当前周期结束前继续享受会员特权。"),
            FAQItem(question: "支付安全吗？", answer: "我们使用Apple官方支付系统，所有支付信息都由Apple安全处理，我们无法获取您的支付信息。"),
        ]

        selectedPlan = "yearly"
    }
}

// MARK: - 数据模型
struct PremiumPrivilege: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct PremiumPlan: Identifiable {
    let id: String
    let name: String
    let originalPrice: String
    let currentPrice: String
    let isPopular: Bool
}

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

// MARK: - 预览
#Preview("Level") {
    LevelScreen()
}

#Preview("Reward") {
    RewardScreen()
}

#Preview("Premium") {
    PremiumScreen()
}
