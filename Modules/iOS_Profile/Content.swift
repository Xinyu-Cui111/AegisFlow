import SwiftUI

struct ContentView: View {
    @State private var path = NavigationPath()
    @State private var height: Float = 180
    @State private var weight: Float = 60.0

    @State private var showEditProfile = false
    @State private var showBluetoothSearch = false
    @State private var showLogoutAlert = false
    @State private var showAccountDialog = false
    @State private var showContent = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AegisDynamicBackground()  // 应用全局顶级 iOS 景深流体背景

                // 1. 底层滑动内容
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 25) {
                        headerSection
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8).delay(0.1),
                                value: showContent)

                        // 1. 个人资料卡片
                        ProfileHeaderView(
                            userName: "演示用户",
                            isPremium: true,
                            avatarInitials: "YS",
                            avatarLocalPath: nil,
                            onAction: { action in
                                switch action {
                                case .editProfile:
                                    showEditProfile = true
                                case .upgrade:
                                    path.append("Level")
                                case .rewards:
                                    path.append("Rewards")
                                case .premium:
                                    path.append("Premium")
                                }
                            }
                        )
                        .scaleEffect(showContent ? 1 : 0.95)
                        .opacity(showContent ? 1 : 0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.7).delay(0.2),
                            value: showContent)

                        // 2. 身体数据统计
                        BodyStatsView(height: $height, weight: $weight)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 25)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8).delay(0.3),
                                value: showContent)

                        // 3. 设备管理
                        BluetoothManagerView(onSearch: { showBluetoothSearch = true })
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8).delay(0.4),
                                value: showContent)

                        // 4. 设置列表
                        SettingsListView(path: $path, onLogout: { showLogoutAlert = true })
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 35)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8).delay(0.5),
                                value: showContent)

                        switchAccountButton
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 40)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8).delay(0.6),
                                value: showContent)

                        Spacer(minLength: 120)
                    }
                }  // ScrollView 结束
                .onAppear { showContent = true }

                // 2. 顶层弹窗逻辑 (放在 ZStack 里确保浮在最上面)
                if showAccountDialog {
                    AccountSwitchDialog(
                        isPresented: $showAccountDialog,
                        onSwitchToOtherAccount: {},
                        onRegisterAccount: {}
                    )
                    .zIndex(10)
                }

                if showLogoutAlert {
                    LogoutConfirmationDialog(
                        isPresented: $showLogoutAlert,
                        onConfirmLogout: {}
                    )
                    .zIndex(11)
                }
            }  // ZStack 结束
            .navigationDestination(for: String.self) { route in
                switch route {
                case "HealthGoals": HealthGoals()
                case "Notification": NotificationSettings()
                case "Privacy": PrivacySettings()
                case "HelpSupport": HelpView()
                default: EmptyView()
                }
            }
            .sheet(isPresented: $showEditProfile) { EditProfileModal() }
            .sheet(isPresented: $showBluetoothSearch) { BluetoothSearchModal() }
        }  // NavigationStack 结束
    }  // body 结束

    // MARK: - 功能组件 (保持不变)
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("个人中心")
                .font(.largeTitle)  // Dynamic Type
                .bold()
            Text("管理你的健康信息")
                .font(.subheadline)  // Dynamic Type
                .foregroundColor(.gray.opacity(0.7))
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private var switchAccountButton: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            showAccountDialog = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.rectangle.fill").font(.title3)
                Text("切换账号").font(.headline)
            }
            .foregroundColor(.androidGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.androidCardBg)
                    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.ultraThinMaterial)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(AegisBouncyCardStyle())
        .padding(.horizontal, 20)
    }
}
// MARK: - 身体数据模块 (应用新样式：配色和阴影)
struct BodyStatsView: View {
    @Binding var height: Float
    @Binding var weight: Float

    var bmi: Double {
        let h = Double(height) / 100
        return h > 0 ? Double(weight) / (h * h) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("身体数据")
                .font(.title3)
                .bold()
                .padding(.leading, 12)

            // --- 修正：应用新卡片样式和阴影 ---
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
                        RoundedRectangle(cornerRadius: 20, style: .continuous).fill(
                            Color.androidBg.opacity(0.6))
                        RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(
                            Color.black.opacity(0.02), lineWidth: 1)
                    }
                )

                VStack(spacing: 12) {
                    statResultCard(
                        title: "BMI 指数", value: String(format: "%.1f", bmi), status: getBMIStatus(),
                        color: .androidPurple)
                    statResultCard(
                        title: "理想体脂率 (估算)", value: "18.5%", status: "正常", color: .androidOrange)
                }
            }
            .aegisCardStyle()  // 应用卡片样式(配色+阴影+圆角)
        }
        .padding(.horizontal, 20)
    }

    // ... getBMIStatus 和 statResultCard 保持不变 ...
    private func getBMIStatus() -> String {
        if bmi < 18.5 { return "偏瘦" } else if bmi < 24 { return "正常" } else { return "偏胖" }
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

// MARK: - 设备管理
struct BluetoothManagerView: View {
    var onSearch: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("设备管理")
                .font(.title3)
                .bold()
                .padding(.leading, 12)

            VStack(spacing: 16) {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 35, weight: .light))
                    .foregroundColor(.androidBlue)
                    .shadow(color: .androidBlue.opacity(0.3), radius: 4, x: 0, y: 2)

                Text("连接你的智能设备")
                    .font(.headline)

                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onSearch()
                }) {
                    Text("+ 搜索并绑定")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                Capsule().fill(Color.androidBlue)
                                Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
                            }
                        )
                        .foregroundColor(.white)
                        .shadow(color: Color.androidBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(AegisBouncyCardStyle())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .aegisCardStyle()  // 应用卡片样式
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - 设置列表模块
struct SettingsListView: View {
    @Binding var path: NavigationPath
    var onLogout: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("设置")
                .font(.title3)
                .bold()
                .padding(.leading, 12)

            // --- 修正：应用新卡片样式 ---
            VStack(spacing: 0) {
                SettingRow(icon: "target", title: "健康目标", color: .androidGreen) {
                    path.append("HealthGoals")
                }
                Divider().padding(.horizontal, 20)
                SettingRow(icon: "bell.fill", title: "通知", color: .androidBlue) {
                    path.append("Notification")
                }
                Divider().padding(.horizontal, 20)
                SettingRow(icon: "lock.shield.fill", title: "隐私设置", color: .androidPurple) {
                    path.append("Privacy")
                }
                Divider().padding(.horizontal, 20)
                SettingRow(icon: "questionmark.circle.fill", title: "帮助与支持", color: .androidOrange)
                { path.append("HelpSupport") }
                Divider().padding(.horizontal, 20)
                SettingRow(
                    icon: "arrow.right.circle.fill", title: "退出登录", color: .red, titleColor: .red
                ) { onLogout() }
            }
            .padding(.vertical, 4)  // 增加内边距对齐图3
            .aegisCardStyle()  // 应用新卡片样式
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - 基础组件
struct SettingRow: View {
    let icon, title: String
    let color: Color
    var titleColor: Color = .black
    let action: () -> Void
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(titleColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.001))
        }
        .buttonStyle(.plain)
    }
}

struct ProfileCardView: View {
    var onEdit: () -> Void
    var body: some View {
        ProfileHeaderView(
            userName: "演示用户",
            isPremium: true,
            avatarInitials: "YS",
            avatarLocalPath: nil,
            onAction: { action in
                // 在此处处理编辑或跳转操作
                if action == .editProfile {
                    onEdit()
                }
            }
        )  // 直接使用我们刚刚重置好顶尖光影的 ProfileHeaderView 组件替换原本的硬编码
    }
}

// MARK: - 切换账号高级弹窗组件
struct AccountSwitchDialog: View {
    @Binding var isPresented: Bool
    let onSwitchToOtherAccount: () -> Void
    let onRegisterAccount: () -> Void

    var body: some View {
        ZStack {
            // 毛玻璃遮罩
            Color.black.opacity(0.2)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPresented = false
                    }
                }

            VStack(alignment: .leading, spacing: 20) {
                // 顶部 Header
                HStack {
                    ZStack {
                        Circle().fill(Color.androidGreen.opacity(0.12)).frame(width: 40, height: 40)
                        Image(systemName: "person.2.badge.gearshape.fill")
                            .foregroundColor(.androidGreen)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text("账号中心")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary.opacity(0.85))

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary.opacity(0.4))
                    }
                }

                VStack(spacing: 12) {
                    // 当前活跃账号
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.androidGreen.opacity(0.8), Color.themeDarkGreen,
                                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .frame(width: 48, height: 48)
                                .shadow(color: .themeDarkGreen.opacity(0.3), radius: 4, x: 0, y: 2)
                            Text("SA")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("当前活跃账号")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.androidGreen)
                            Text("sarah.chen@email.com")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary.opacity(0.9))
                        }
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.androidGreen)
                    }
                    .padding(16)
                    .background(Color.androidGreen.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.androidGreen.opacity(0.2), lineWidth: 1)
                    )

                    // 其他操作选项
                    rowItem(
                        icon: "arrow.left.and.right.circle.fill", title: "切换至其他账号",
                        sub: "退出当前并登录新身份", action: onSwitchToOtherAccount)
                    rowItem(
                        icon: "person.badge.plus.fill", title: "注册新设备账号", sub: "为家庭成员创建独立档案",
                        color: .blue, action: onRegisterAccount)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.thickMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 24, x: 0, y: 12)
            .overlay(  // 顶级高光描边边缘
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 24)
            .transition(.scale(scale: 0.95).combined(with: .opacity))  // 从缩放和透明度优雅进场
        }
    }

    @ViewBuilder
    func rowItem(
        icon: String, title: String, sub: String, color: Color = .primary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPresented = false
            }
            action()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.85))
                    Text(sub)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .padding(12)
            .background(Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 高级退出登录确认弹窗
struct LogoutConfirmationDialog: View {
    @Binding var isPresented: Bool
    let onConfirmLogout: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPresented = false
                    }
                }

            VStack(spacing: 24) {
                // 顶部退出图标
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 64, height: 64)
                    Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.orange)
                        .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                        .offset(x: 2)  // 箭头略微偏右的视觉中心补偿
                }
                .padding(.top, 10)

                VStack(spacing: 8) {
                    Text("退出当前账号？")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    Text("退出后，需要重新使用密码或 Face ID 验证身份才能再次访问你的专属健康资产。")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
                .padding(.horizontal, 10)

                // 操作按钮组
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isPresented = false
                        }
                    }) {
                        Text("取消")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.secondary.opacity(0.1))
                            .foregroundColor(.primary.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .rigid)
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isPresented = false
                        }
                        onConfirmLogout()
                    }) {
                        Text("确认退出")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.orange.opacity(0.9))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .orange.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.thickMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 24, x: 0, y: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 32)
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
    }
}
