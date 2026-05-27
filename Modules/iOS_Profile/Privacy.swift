import SwiftUI

struct PrivacySettings: View {
    @Environment(\.dismiss) var dismiss

    // MARK: - 开关状态
    @State private var profilePublic = true
    @State private var healthDataPublic = false
    @State private var activityPublic = false
    @State private var locationEnabled = true
    @State private var cloudSync = false
    @State private var dataAnalysis = false

    // MARK: - 弹窗控制
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            // 全局灵动光影背景
            AegisDynamicBackground()

            VStack(spacing: 0) {
                SubPageHeader(title: "隐私设置") { dismiss() }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // 1. 顶部引导卡片 (紫色风格)
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.androidPurple.opacity(0.12))
                                    .frame(width: 48, height: 48)
                                    .shadow(
                                        color: Color.androidPurple.opacity(0.2), radius: 6, x: 0,
                                        y: 3)

                                Image(systemName: "shield.lefthalf.filled")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.androidPurple)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("数据与安全")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary.opacity(0.85))
                                Text("管理你的隐私权限与资产安全")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .aegisCardStyle(padding: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.androidPurple.opacity(0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.androidPurple.opacity(0.20), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        // 2. 资料可见性
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "资料可见性", icon: "eye.fill")

                            VStack(spacing: 0) {
                                ToggleRow(
                                    icon: "person.fill", title: "个人资料公开",
                                    subtitle: "其他用户可以查看你的基本资料", color: .aegisFreshGreen,
                                    isOn: $profilePublic)
                                Divider().background(Color.black.opacity(0.04)).padding(
                                    .leading, 64)
                                ToggleRow(
                                    icon: "heart.fill", title: "健康数据公开", subtitle: "其他用户可以查看你的健康数据",
                                    color: .red.opacity(0.7), isOn: $healthDataPublic)
                                Divider().background(Color.black.opacity(0.04)).padding(
                                    .leading, 64)
                                ToggleRow(
                                    icon: "figure.run", title: "活动动态公开", subtitle: "其他用户可以查阅你的运动轨迹",
                                    color: .orange, isOn: $activityPublic)
                            }
                            .aegisCardStyle(padding: 8)
                        }
                        .padding(.horizontal, 16)

                        // 3. 权限管理
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "系统权限", icon: "key.fill")

                            VStack(spacing: 0) {
                                ToggleRow(
                                    icon: "location.fill", title: "位置权限",
                                    subtitle: "允许获取位置以记录户外运动轨迹", color: .cyan,
                                    isOn: $locationEnabled)
                                Divider().background(Color.black.opacity(0.04)).padding(
                                    .leading, 64)
                                ToggleRow(
                                    icon: "icloud.fill", title: "iCloud 备份",
                                    subtitle: "端到端加密自动备份健康数据", color: .blue, isOn: $cloudSync)
                                Divider().background(Color.black.opacity(0.04)).padding(
                                    .leading, 64)
                                ToggleRow(
                                    icon: "chart.bar.doc.horizontal", title: "应用分析",
                                    subtitle: "允许收集匿名数据以协助产品改进", color: .aegisFreshGreen,
                                    isOn: $dataAnalysis)
                            }
                            .aegisCardStyle(padding: 8)
                        }
                        .padding(.horizontal, 16)

                        // 4. 数据管理 (跳转行)
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "资产与协议", icon: "doc.text.fill")

                            VStack(spacing: 0) {
                                Button(action: { /* 导出资产 */  }) {
                                    NavigationRow(
                                        icon: "tray.and.arrow.down.fill", title: "导出我的数据",
                                        subtitle: "打包下载历史全部体征与报告数据", color: .aegisFreshGreen)
                                }
                                .buttonStyle(.plain)

                                Divider().background(Color.black.opacity(0.04)).padding(
                                    .leading, 64)

                                Button(action: { /* 打开隐私政策 */  }) {
                                    NavigationRow(
                                        icon: "shield.righthalf.filled", title: "隐私政策",
                                        subtitle: "了解我们如何严格捍卫你的数字主权", color: .blue)
                                }
                                .buttonStyle(.plain)

                                Divider().background(Color.black.opacity(0.04)).padding(
                                    .leading, 64)

                                // 点击触发清除数据危险弹窗
                                Button(action: {
                                    let impactHeavy = UIImpactFeedbackGenerator(style: .rigid)
                                    impactHeavy.impactOccurred()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showDeleteAlert = true
                                    }
                                }) {
                                    NavigationRow(
                                        icon: "trash.fill", title: "注销与抹除",
                                        subtitle: "永久删除云端及本地保存的所有资产", color: .red,
                                        isDestructive: true)
                                }
                                .buttonStyle(.plain)
                            }
                            .aegisCardStyle(padding: 8)
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)  // 彻底抹除系统自带顶部导航壳
        .ignoresSafeArea(.all, edges: .top)  // 背景深入刘海/灵动岛
        // MARK: - 二次确认高级柔弱弹窗
        .overlay {
            if showDeleteAlert {
                DeleteConfirmationDialog(isPresented: $showDeleteAlert)
                    .zIndex(1)  // 保证处于最顶层
            }
        }
    }
}

// MARK: - 辅助组件：精美跳转行
struct NavigationRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isDestructive: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isDestructive ? color.opacity(0.12) : color.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDestructive ? .red.opacity(0.9) : .primary.opacity(0.85))
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(isDestructive ? .red.opacity(0.6) : .secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isDestructive ? .red.opacity(0.3) : .secondary.opacity(0.5))  // 这里已修正编译错误
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())  // 确保整行可点击
    }
}

// MARK: - 辅助组件：清除数据原生级毛玻璃确认弹窗
struct DeleteConfirmationDialog: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // 背景毛玻璃遮罩层
            Color.black.opacity(0.2)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPresented = false
                    }
                }

            // 弹窗本体
            VStack(spacing: 24) {
                // 警示图标
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 64, height: 64)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.red.opacity(0.85))
                        .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 10)

                VStack(spacing: 8) {
                    Text("永久抹除所有资产？")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    Text("此操作将完全销毁应用内保存的体征记录、运动轨迹及目标偏好设置。该操作不可撤销，确定要这么做吗？")
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
                        // 执行删除逻辑
                        let impact = UINotificationFeedbackGenerator()
                        impact.notificationOccurred(.warning)

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isPresented = false
                        }
                    }) {
                        Text("确认注销")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red.opacity(0.85))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .red.opacity(0.3), radius: 5, x: 0, y: 3)
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
            .overlay(  // 高端内部反光切边
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 32)
            // 进入动画放大弹入
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
    }
}
