import Combine
import PhotosUI
import SwiftUI

// MARK: - Profile视图
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()

    @State private var navSelection: String? = nil
    @State private var showLegacyAccountSwitchDialog = false
    @State private var showLegacyLogoutDialog = false

    var body: some View {
        ZStack {
            AegisDynamicBackground()

            NavigationStack {
                ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 头部标题
                        VStack(alignment: .leading, spacing: 4) {
                            Text("个人中心")
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundColor(Color(hex: "#222B2E"))
                            Text("管理你的健康信息")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "#7A8B99"))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .aegisReveal(delay: 0.00)
                        .uiDemoTopAnchor()

                        if let error = viewModel.error {
                            ProfileErrorBanner(message: error)
                                .padding(.horizontal, 24)
                                .aegisReveal(delay: 0.06)
                        }

                        // 白金风格个人资料大框
                        ProfileHeaderView(
                            userName: viewModel.userName,
                            isPremium: viewModel.isPremium,
                            avatarInitials: viewModel.avatarInitials,
                            avatarLocalPath: viewModel.avatarLocalPath,
                            onAction: { action in
                                switch action {
                                case .editProfile:
                                    viewModel.openEditProfile()
                                case .upgrade:
                                    navSelection = "level"
                                case .rewards:
                                    navSelection = "rewards"
                                case .premium:
                                    navSelection = "premium"
                                }
                            }
                        )
                        .aegisReveal(delay: 0.12)

                        Twin3DEntryCard(onOpen: { navSelection = "twin3d" })
                            .padding(.horizontal, 24)
                            .aegisReveal(delay: 0.20)

                        if let profile = viewModel.userInsightProfile {
                            ProfileInsightCardView(
                                profileSummary: profile,
                                personalizationScore: viewModel.personalizationScore,
                                isLoading: viewModel.isLoadingUserInsight,
                                todaySteps: viewModel.realtimeSteps,
                                todayHeartRate: viewModel.realtimeHeartRate,
                                todaySleepMinutes: viewModel.todaySleepMinutes,
                                onRefresh: { viewModel.loadUserInsights() },
                                onExplore: { _ in }
                            )
                            .padding(.horizontal, 24)
                            .aegisReveal(delay: 0.28)
                        }

                        // 身体数据
                        BodyMetricsSection(
                            height: $viewModel.heightCm,
                            weight: $viewModel.weightKg,
                            bmi: viewModel.bmi,
                            bodyFat: viewModel.bodyFatPercent,
                            onHeightTap: { viewModel.showHeightEditor = true },
                            onWeightTap: { viewModel.showWeightEditor = true },
                            onValuesChanged: { viewModel.updateUserProfile() }
                        )
                        .aegisReveal(delay: 0.36)

                        // 设备管理
                        RealDevicesSection(
                            boundDevices: viewModel.boundDevices,
                            isScanning: viewModel.isScanning,
                            isSyncing: viewModel.isSyncingDevice,
                            realtimeSteps: viewModel.realtimeSteps,
                            realtimeHeartRate: viewModel.realtimeHeartRate,
                            onScanClick: { viewModel.showScanDialog = true },
                            onSyncClick: { viewModel.syncDeviceData() },
                            onUnbindClick: { device in
                                viewModel.showUnbindDialog = device.id
                            }
                        )
                        .aegisReveal(delay: 0.44)

                        // 设置 (NavigationLink-based)
                        NavigableSettingsSection(
                            items: viewModel.settingsItems,
                            onLogout: { showLegacyLogoutDialog = true }
                        )
                        .aegisReveal(delay: 0.52)

                        // 切换账号
                        SwitchAccountButton(onClick: { showLegacyAccountSwitchDialog = true })
                            .aegisReveal(delay: 0.60)
                        EmptyView().uiDemoBottomAnchor()
                    }
                    .padding(.bottom, 100)
                }
                .id("profileScrollView")  // 防止导航返回时 ScrollView 重置位置
                .background(Color.clear)
                .uiDemoPerformAutoScroll(proxy: scrollProxy)
                }
                // 隐藏 NavigationLink：允许通过设置 navSelection（String）进行编程导航
                NavigationLink(destination: AegisLevelView(), tag: "level", selection: $navSelection) { EmptyView() }
                NavigationLink(destination: AegisRewardsView(), tag: "rewards", selection: $navSelection) { EmptyView() }
                NavigationLink(destination: AegisPremiumView(), tag: "premium", selection: $navSelection) { EmptyView() }
                NavigationLink(destination: Twin3DView(), tag: "twin3d", selection: $navSelection) { EmptyView() }
            }
        }
        .navigationDestination(for: String.self) { route in
            switch route {
            case "goals":
                HealthGoals()
            case "notifications":
                NotificationSettings()
            case "privacy":
                PrivacySettings()
            case "help":
                HelpView()
            case "level":
                AegisLevelView()
            case "rewards":
                AegisRewardsView()
            case "premium":
                AegisPremiumView()
            case "twin3d":
                Twin3DView()
            default:
                Text("页面未找到")
            }
        }
        .sheet(isPresented: $viewModel.showEditProfile) {
            EditProfileModal(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showScanDialog) {
            DeviceScanSheet(viewModel: viewModel)
        }
        .overlay {
            if showLegacyAccountSwitchDialog {
                AccountSwitchDialog(
                    isPresented: $showLegacyAccountSwitchDialog,
                    onSwitchToOtherAccount: {
                        viewModel.switchAccount()
                    },
                    onRegisterAccount: {
                        viewModel.addAccount()
                    }
                )
                .zIndex(10)
            }
            if showLegacyLogoutDialog {
                LogoutConfirmationDialog(
                    isPresented: $showLegacyLogoutDialog,
                    onConfirmLogout: {
                        viewModel.logout()
                    }
                )
                .zIndex(11)
            }
        }
        .alert(
            "解绑设备",
            isPresented: Binding(
                get: { viewModel.showUnbindDialog != nil },
                set: { if !$0 { viewModel.showUnbindDialog = nil } }
            )
        ) {
            Button("取消", role: .cancel) { viewModel.showUnbindDialog = nil }
            Button("解绑", role: .destructive) {
                if let deviceId = viewModel.showUnbindDialog {
                    viewModel.unbindDevice(deviceId: deviceId)
                }
                viewModel.showUnbindDialog = nil
            }
        } message: {
            Text("确定要解绑此设备吗？")
        }
        .alert("权限被拒绝", isPresented: $viewModel.showPermissionDeniedDialog) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("请在设置中开启蓝牙权限以连接设备")
        }

        .onAppear {
            viewModel.fetchUserProfile()
            viewModel.fetchUserPreferences()
            viewModel.loadUserInsights()
        }
        .onChange(of: navSelection) { _, _ in
            // 当用户点击导航项时，取消所有待处理的异步任务，防止返回时闪移
            viewModel.cancelPendingTasks()
        }
    }
}

struct ProfileErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundColor(.orangeWarm)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#222B2E"))

            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
    }
}

// MARK: - 用户资料卡片
struct UserProfileCard: View {
    let userName: String
    let email: String
    let isPremium: Bool
    let avatarLocalPath: String?
    let avatarInitials: String
    let onEditClick: () -> Void
    let onHeroAction: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center, spacing: 14) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let path = avatarLocalPath, let uiImage = UIImage(contentsOfFile: path) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .overlay(
                                    Text(avatarInitials)
                                        .font(.system(size: 26, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .frame(width: 82, height: 82)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 3))

                    Button(action: onEditClick) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "pencil")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.sageBright)
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(userName)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                    Text(email)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                    if isPremium {
                        Text("尊享会员")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.grayDark)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.yellowBright)
                            .cornerRadius(8)
                    }
                }
                Spacer()
            }

            HStack(spacing: 12) {
                heroAction(icon: "medal.fill", title: "升级", route: "level")
                heroAction(icon: "star.fill", title: "奖励", route: "rewards")
                heroAction(icon: "diamond.fill", title: "Premium", route: "premium")
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [.sageBright, .tealDeep.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(24)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func heroAction(icon: String, title: String, route: String) -> some View {
        Button(action: { onHeroAction(route) }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.2))
            .cornerRadius(14)
        }
    }
}

struct Twin3DEntryCard: View {
    @ObservedObject private var data = DataManager.shared
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onOpen) {
                HStack(spacing: 16) {
                    DeskPetOrbPreview(mascotName: data.deskPetMascotName, diameter: 44)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("桌宠")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("配置外观与风格，生成你的专属桌宠头像")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(spacing: 8) {
                Toggle("", isOn: $data.deskPetEnabled)
                    .labelsHidden()
                    .toggleStyle(AegisSwitchToggleStyle(tint: .aegisFreshGreen))
                    .frame(width: 54, height: 34)
                    .onChange(of: data.deskPetEnabled) { _, _ in
                        data.saveSettings()
                    }

                Button(action: {
                    data.deskPetPositionX = Double(UIScreen.main.bounds.width - 52)
                    data.deskPetPositionY = Double(UIScreen.main.bounds.height * 0.58)
                    data.saveSettings()
                }) {
                    Text("重置")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.04)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

// MARK: - 身体数据区域
struct BodyMetricsSection: View {
    @Binding var height: Float
    @Binding var weight: Float
    let bmi: Float
    let bodyFat: Float
    let onHeightTap: () -> Void
    let onWeightTap: () -> Void
    var onValuesChanged: (() -> Void)? = nil

    private func getBMIStatus() -> String {
        if bmi < 18.5 { return "偏瘦" } else if bmi < 24 { return "正常" } else { return "偏胖" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("身体数据")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#222B2E"))
                .padding(.horizontal, 24)

            // --- 修正：应用跟 Content.swift 一致的卡片与滑块交互样式 ---
            VStack(spacing: 20) {
                VStack(spacing: 0) {
                    GoalAdjustableRow(
                        icon: "arrow.up.and.down", title: "我的身高", value: "\(Int(height)) cm",
                        color: .androidBlue, val: $height, range: 100...220
                    )
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)

                    Divider().padding(.horizontal, 20)

                    GoalAdjustableRow(
                        icon: "scalemass.fill", title: "我的体重",
                        value: String(format: "%.1f kg", weight), color: .androidGreen,
                        val: $weight, range: 30...150
                    )
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous).fill(
                            Color.black.opacity(0.01))
                        RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(
                            Color.black.opacity(0.02), lineWidth: 1)
                    }
                )
                // 拖拽改变数值时通知外层保存
                .onChange(of: height) { _, _ in onValuesChanged?() }
                .onChange(of: weight) { _, _ in onValuesChanged?() }

                // BMI & BodyFat 展示卡片
                VStack(spacing: 12) {
                    statResultCard(
                        title: "BMI 指数", value: String(format: "%.1f", bmi), status: getBMIStatus(),
                        color: .purpleSoft)
                    statResultCard(
                        title: "体脂率 (估算)", value: String(format: "%.1f%%", bodyFat), status: "正常",
                        color: .orangeWarm)
                }
            }
            .background(Color.white)
            .cornerRadius(18)
            .padding(.horizontal, 24).padding(.vertical, 8)
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
    }

    @ViewBuilder
    private func statResultCard(title: String, value: String, status: String, color: Color)
        -> some View
    {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.caption).foregroundColor(.gray)
                Text(value).font(.title2).bold().foregroundColor(color)
            }
            Spacer()
            Text(status)
                .font(.caption)
                .bold()
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    ZStack {
                        Capsule().fill(color.opacity(0.12))
                        Capsule().stroke(color.opacity(0.2), lineWidth: 0.5)
                    }
                )
                .foregroundColor(color)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.1), lineWidth: 0.5)
        )
    }
}

// MARK: - 指标行
struct MetricRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String
    let showChevron: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "#222B2E"))

                Spacer()

                Text(value)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#222B2E"))

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#7A8B99"))
                }

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#7A8B99"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - 真实设备管理区域
struct RealDevicesSection: View {
    let boundDevices: [BoundDevice]
    let isScanning: Bool
    let isSyncing: Bool
    let realtimeSteps: Int
    let realtimeHeartRate: Int
    let onScanClick: () -> Void
    let onSyncClick: () -> Void
    let onUnbindClick: (BoundDevice) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("设备管理")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(hex: "#222B2E"))

                Spacer()

                if !boundDevices.isEmpty {
                    Button(action: onSyncClick) {
                        HStack(spacing: 4) {
                            if isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 12))
                            }
                            Text("同步")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.sageBright)
                    }
                    .disabled(isSyncing)
                }
            }
            .padding(.horizontal, 24)

            if boundDevices.isEmpty {
                // 空状态
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.sageBright.opacity(0.1))
                            .frame(width: 64, height: 64)

                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 28))
                            .foregroundColor(.sageBright)
                    }

                    Text("连接你的智能设备")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#222B2E"))

                    Text("支持智能手表、手环、心率带等BLE设备\n实时同步步数、心率等健康数据")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#7A8B99"))
                        .multilineTextAlignment(.center)

                    Button(action: onScanClick) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                            Text("搜索并绑定")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.sageBright)
                        .cornerRadius(20)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
            } else {
                VStack(spacing: 0) {
                    ForEach(boundDevices) { device in
                        BoundDeviceRow(
                            device: device,
                            onUnbindClick: { onUnbindClick(device) }
                        )

                        if device.id != boundDevices.last?.id {
                            Divider()
                                .padding(.leading, 68)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
            }

            if !boundDevices.isEmpty {
                HStack(spacing: 16) {
                    RealtimeDataCard(
                        icon: "figure.walk", title: "实时步数", value: "\(realtimeSteps)", unit: "步")
                    RealtimeDataCard(
                        icon: "heart.fill", title: "实时心率", value: "\(realtimeHeartRate)",
                        unit: "bpm")
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - 已绑定设备行
struct BoundDeviceRow: View {
    let device: BoundDevice
    let onUnbindClick: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(deviceConnectionColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: deviceIcon)
                    .font(.system(size: 22))
                    .foregroundColor(deviceConnectionColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(device.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#222B2E"))

                HStack(spacing: 8) {
                    // 连接状态
                    HStack(spacing: 4) {
                        Circle()
                            .fill(deviceConnectionColor)
                            .frame(width: 8, height: 8)
                        Text(device.connectionState)
                            .font(.system(size: 12))
                            .foregroundColor(deviceConnectionColor)
                    }

                    // 电池
                    if device.batteryLevel >= 0 {
                        HStack(spacing: 2) {
                            Image(systemName: batteryIcon(device.batteryLevel))
                                .font(.system(size: 12))
                            Text("\(device.batteryLevel)%")
                                .font(.system(size: 12, design: .rounded))
                        }
                        .foregroundColor(Color(hex: "#7A8B99"))
                    }

                    // 最后同步
                    Text("同步于 \(formatLastSync(device.lastSyncTime))")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#7A8B99"))
                }
            }

            Spacer()

            Button(action: onUnbindClick) {
                Image(systemName: "link.badge.plus")
                    .font(.system(size: 18))
                    .foregroundColor(.errorRed)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var deviceIcon: String {
        switch device.type.lowercased() {
        case "watch": return "applewatch"
        case "band": return "figure.wristband"
        case "scale": return "scalemass"
        default: return "antenna.radiowaves.left.and.right"
        }
    }

    private var deviceConnectionColor: Color {
        switch device.connectionState.lowercased() {
        case "connected": return .successGreen
        case "disconnected": return .errorRed
        case "syncing": return .orangeWarm
        default: return .grayMid
        }
    }

    private func batteryIcon(_ level: Int) -> String {
        switch level {
        case 0..<25: return "battery.25"
        case 25..<50: return "battery.50"
        case 50..<75: return "battery.75"
        default: return "battery.100"
        }
    }

    private func formatLastSync(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 实时数据卡片
struct RealtimeDataCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.sageBright)

                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#7A8B99"))
            }

            HStack(alignment: .bottom, spacing: 3) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#222B2E"))

                Text(unit)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#7A8B99"))
                    .padding(.bottom, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 游戏化入口区域
struct GamificationSection: View {
    private let entries: [(id: String, title: String, icon: String, iconColor: Color)] = [
        ("level", "等级与荣誉", "crown.fill", .orangeWarm),
        ("rewards", "积分商城", "gift.fill", .sageBright),
        ("premium", "尊享会员", "star.fill", Color(hex: "#FFB800")),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("会员与权益")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#222B2E"))
                .padding(.horizontal, 24)

            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    NavigationLink(value: entry.id) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(entry.iconColor.opacity(0.15))
                                    .frame(width: 40, height: 40)

                                Image(systemName: entry.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(entry.iconColor)
                            }

                            Text(entry.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(hex: "#222B2E"))

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "#7A8B99"))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(AegisBouncyCardStyle())

                    if index < entries.count - 1 {
                        Divider()
                            .padding(.leading, 68)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 24)
            .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        }
    }
}

// MARK: - 设置区域 (NavigationLink-based)
struct NavigableSettingsSection: View {
    let items: [SettingsItem]
    let onLogout: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("设置")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#222B2E"))
                .padding(.horizontal, 24)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if item.id == "logout" {
                        SettingsButtonRow(item: item, onTap: onLogout)
                    } else {
                        NavigationLink(value: item.id) {
                            SettingsRowContent(item: item)
                        }
                        .buttonStyle(AegisBouncyCardStyle())
                    }

                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, 68)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 24)
            .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        }
    }
}

// MARK: - 设置行内容 (共享布局)
struct SettingsRowContent: View {
    let item: SettingsItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: item.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(item.iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "#222B2E"))
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.grayMid)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#7A8B99"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// MARK: - 退出登录按钮行
struct SettingsButtonRow: View {
    let item: SettingsItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(item.iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: item.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(item.iconColor)
                }

                Text(item.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.errorRed)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#7A8B99"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(AegisBouncyCardStyle())
    }
}

// MARK: - 切换账号按钮
struct SwitchAccountButton: View {
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 18))
                Text("切换账号")
                    .font(.system(size: 17, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.sageBright)
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 24)
            .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(AegisBouncyCardStyle())
    }
}

// MARK: - 编辑资料弹窗
struct ProfileEditDialog: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var avatarItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 头像
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.sageBright, .tealDeep],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Text(viewModel.avatarInitials)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)

                        PhotosPicker(selection: $avatarItem, matching: .images, photoLibrary: .shared()) {
                            ZStack {
                                Circle()
                                    .fill(Color.sageBright)
                                    .frame(width: 32, height: 32)

                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(AegisBouncyCardStyle())
                        .offset(x: 36, y: 36)
                    }

                    .onChange(of: avatarItem) { _, newItem in
                        Task {
                            guard let data = try? await newItem?.loadTransferable(type: Data.self) else {
                                return
                            }
                            viewModel.persistAvatarData(data)
                        }
                    }

                    Text("点击更换头像")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#7A8B99"))

                    // 输入框
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("昵称")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "#7A8B99"))

                            TextField("请输入昵称", text: $viewModel.editName)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(hex: "#F7F8F9"))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            viewModel.nameError != nil
                                                ? Color.errorRed : Color.clear, lineWidth: 1)
                                )

                            if let error = viewModel.nameError {
                                Text(error)
                                    .font(.system(size: 12))
                                    .foregroundColor(.errorRed)
                            }
                        }

                        // 性别选择
                        VStack(alignment: .leading, spacing: 8) {
                            Text("性别")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "#7A8B99"))

                            HStack(spacing: 12) {
                                GenderOptionButton(
                                    title: "男", isSelected: viewModel.editGender == "male"
                                ) {
                                    viewModel.updateEditGender("male")
                                }

                                GenderOptionButton(
                                    title: "女", isSelected: viewModel.editGender == "female"
                                ) {
                                    viewModel.updateEditGender("female")
                                }

                                GenderOptionButton(
                                    title: "保密", isSelected: viewModel.editGender == "other"
                                ) {
                                    viewModel.updateEditGender("other")
                                }
                            }
                        }

                        // 生日
                        VStack(alignment: .leading, spacing: 8) {
                            Text("生日")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "#7A8B99"))

                            TextField(
                                "请选择生日",
                                text: Binding(
                                    get: { viewModel.editBirthDate ?? "" },
                                    set: { viewModel.updateEditBirthDate($0) }
                                )
                            )
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(hex: "#F7F8F9"))
                            .cornerRadius(12)
                        }

                        // 简介
                        VStack(alignment: .leading, spacing: 8) {
                            Text("简介")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "#7A8B99"))

                            TextField("请输入简介（选填）", text: $viewModel.editBio, axis: .vertical)
                                .textFieldStyle(.plain)
                                .padding()
                                .frame(minHeight: 80, alignment: .topLeading)
                                .background(Color(hex: "#F7F8F9"))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 24)
            }
            .background(Color.white)
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.closeEditProfile()
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#7A8B99"))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.saveEditProfile()
                        dismiss()
                    }) {
                        if viewModel.isSavingProfile {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("保存")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(viewModel.isSavingProfile)
                }
            }
        }
    }
}

// MARK: - 性别选项按钮
struct GenderOptionButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Color(hex: "#222B2E"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.sageBright : Color(hex: "#F7F8F9"))
                .cornerRadius(10)
        }
    }
}

// MARK: - 设备扫描弹窗
struct DeviceScanSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Text(viewModel.isScanning ? "正在搜索设备..." : "准备就绪")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#222B2E"))

                    Text("请确保设备已开启蓝牙")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#7A8B99"))
                }
                .padding(.top, 20)

                // 扫描到的设备列表
                if !viewModel.scannedDevices.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("发现设备")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "#222B2E"))

                        ForEach(viewModel.scannedDevices) { device in
                            ScannedDeviceRow(device: device) {
                                viewModel.bindDevice(device)
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                Button(action: {
                    if viewModel.isScanning {
                        viewModel.stopScanning()
                    } else {
                        viewModel.startScanning()
                    }
                }) {
                    Text(viewModel.isScanning ? "停止扫描" : "开始扫描")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.isScanning ? Color.grayMid : Color.sageBright)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)

                Button(action: { dismiss() }) {
                    Text("取消")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#7A8B99"))
                }
                .padding(.bottom, 24)
            }
            .background(Color.white)
            .navigationTitle("搜索设备")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 扫描到的设备行
struct ScannedDeviceRow: View {
    let device: ScannedDevice
    let onBind: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.androidBlue.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "applewatch")
                    .font(.system(size: 22))
                    .foregroundColor(.androidBlue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#222B2E"))

                HStack(spacing: 4) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 11))
                    Text("\(device.type) · RSSI \(device.rssi)")
                        .font(.system(size: 12))
                }
                .foregroundColor(Color(hex: "#7A8B99"))
            }

            Spacer()

            // 信号强度
            SignalStrengthIndicator(rssi: device.rssi)

            Button(action: onBind) {
                Text("绑定")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.sageBright)
                    .cornerRadius(16)
            }
        }
        .padding(14)
        .background(Color(hex: "#F7F8F9"))
        .cornerRadius(12)
    }
}

// MARK: - 信号强度指示器
struct SignalStrengthIndicator: View {
    let rssi: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < signalBars ? Color.sageBright : Color(hex: "#E0E0E0"))
                    .frame(width: 4, height: CGFloat(6 + index * 3))
            }
        }
    }

    private var signalBars: Int {
        switch rssi {
        case -50...0: return 4
        case -60..<(-50): return 3
        case -70..<(-60): return 2
        default: return 1
        }
    }
}

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - 预览
#Preview {
    ProfileView()
}
