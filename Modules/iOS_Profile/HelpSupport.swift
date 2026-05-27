import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss

    // 用来记录当前哪个问题被展开了，nil 表示全部收起
    @State private var expandedQuestionId: Int? = nil

    var body: some View {
        ZStack {
            // 全局灵动光影背景
            AegisDynamicBackground()

            VStack(spacing: 0) {
                // 顶部导航 (自带超强毛玻璃与阴影)
                SubPageHeader(title: "帮助与支持") { dismiss() }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // 1. 顶部引导卡片 (橙色风格)
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.12))
                                    .frame(width: 48, height: 48)
                                    .shadow(color: Color.orange.opacity(0.2), radius: 6, x: 0, y: 3)

                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.orange)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("常见问题与联系")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary.opacity(0.85))
                                Text("快速获取解答与官方服务指引")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .aegisCardStyle(padding: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.orange.opacity(0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.orange.opacity(0.20), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        // 2. 常见问题列表 (折叠面板)
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(
                                title: "常见内容检索", icon: "bubble.left.and.text.bubble.right.fill")

                            VStack(spacing: 0) {
                                FAQRow(
                                    id: 1, icon: "flag.fill", color: .androidGreen,
                                    question: "如何设置基本健康目标？",
                                    answer:
                                        "进入「我的」→「健康目标」，你可以自定义每日步数、饮水量、睡眠时长等核心指标。系统会根据你的选择自动下发追踪与反馈行为。",
                                    expandedId: $expandedQuestionId)

                                Divider().background(Color.black.opacity(0.04)).padding(
                                    .leading, 64)

                                FAQRow(
                                    id: 2, icon: "icloud.fill", color: .cyan,
                                    question: "记录数据如何跨端同步？",
                                    answer:
                                        "首先确保在「隐私设置」中开启了「iCloud 备份」。在稳定的 Wi-Fi 网络下，所有体征记录和运动轨迹都将被端到端加密后自动发送至云端服务器。",
                                    expandedId: $expandedQuestionId)

                                Divider().background(Color.black.opacity(0.04)).padding(
                                    .leading, 64)

                                FAQRow(
                                    id: 3, icon: "applewatch", color: .teal,
                                    question: "如何绑定 Apple Watch？",
                                    answer:
                                        "打开「设备」标签页，轻触右上角的「+添加设备」，确保手机蓝牙处于开启状态。应用将自动探测附近的智能穿戴设备，按照提示进行授权匹配即可。",
                                    expandedId: $expandedQuestionId)

                                Divider().background(Color.black.opacity(0.04)).padding(
                                    .leading, 64)

                                FAQRow(
                                    id: 4, icon: "brain.head.profile", color: .purple,
                                    question: "AI 健康引擎如何工作？",
                                    answer:
                                        "我们的 AI 健康分析引擎可以深度读取你的长期数据趋势，提供早诊预测、交叉报告解读及饮食干预计划。数据在计算完成后即刻清除，不作留存。",
                                    expandedId: $expandedQuestionId)

                                Divider().background(Color.black.opacity(0.04)).padding(
                                    .leading, 64)

                                FAQRow(
                                    id: 5, icon: "arrow.down.doc.fill", color: .androidOrange,
                                    question: "我能下载历史的数据吗？",
                                    answer:
                                        "可以。前往「隐私设置」-「数据与资产」，轻点「导出我的数据」。为了您的隐私安全，导出的数据档案将会加密并发送到您账号绑定的注册邮箱中。",
                                    expandedId: $expandedQuestionId)
                            }
                            .aegisCardStyle(padding: 8)
                        }
                        .padding(.horizontal, 16)

                        // 3. 联系我们
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "专属支持", icon: "person.2.fill")

                            VStack(spacing: 0) {
                                HelpNavigationRow(
                                    icon: "envelope.fill", title: "邮件反馈工单",
                                    subtitle: "support@aegisflow.com", color: .cyan)
                                Divider().background(Color.black.opacity(0.04)).padding(
                                    .leading, 64)
                                HelpNavigationRow(
                                    icon: "ellipsis.message.fill", title: "实时在线解答",
                                    subtitle: "工作时间 9:00 - 18:00", color: .androidGreen)
                                Divider().background(Color.black.opacity(0.04)).padding(
                                    .leading, 64)
                                HelpNavigationRow(
                                    icon: "headphones", title: "尊享语音专线", subtitle: "仅限 Premium 会员",
                                    color: .teal)
                                Divider().background(Color.black.opacity(0.04)).padding(
                                    .leading, 64)
                                HelpNavigationRow(
                                    icon: "safari.fill", title: "官方支持门户",
                                    subtitle: "www.aegisflow.com", color: .purple)
                            }
                            .aegisCardStyle(padding: 8)
                        }
                        .padding(.horizontal, 16)

                        // 4. 底部品牌与版权信息
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.androidGreen.opacity(0.8),
                                                Color.themeDarkGreen,
                                            ], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 52, height: 52)
                                    .shadow(
                                        color: Color.themeDarkGreen.opacity(0.3), radius: 8, x: 0,
                                        y: 4)

                                Image(systemName: "heart.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                            .padding(.bottom, 6)

                            Text("Aegis Flow")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.primary.opacity(0.85))

                            Text("版本 1.1.4 (构建号 8492)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                Text("服务条款")
                                    .foregroundColor(.blue)
                                Text("·")
                                    .foregroundColor(.secondary.opacity(0.3))
                                Text("隐私政策")
                                    .foregroundColor(.blue)
                            }
                            .font(.system(size: 12, weight: .medium))
                            .padding(.top, 10)
                        }
                        .padding(.vertical, 40)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)  // 彻底隐藏系统多余返回键
        .ignoresSafeArea(.all, edges: .top)  // 让流体背景完全释放
    }
}

// MARK: - 专属支持行组件 (解决命名冲突)
struct HelpNavigationRow: View {
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
                .foregroundColor(isDestructive ? .red.opacity(0.3) : .secondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())  // 确保整行可点击
    }
}

// MARK: - 精致 FAQ 折叠行组件
struct FAQRow: View {
    let id: Int
    let icon: String
    let color: Color
    let question: String
    let answer: String
    @Binding var expandedId: Int?

    var isExpanded: Bool { expandedId == id }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                let medImpact = UIImpactFeedbackGenerator(style: .medium)
                medImpact.impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    expandedId = isExpanded ? nil : id
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(color.opacity(0.15))
                            .frame(width: 38, height: 38)
                        Image(systemName: icon)
                            .foregroundColor(color)
                            .font(.system(size: 16, weight: .semibold))
                    }

                    Text(question)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary.opacity(0.85))
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.5))  // 修正展开箭头次级弱化
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))  // 丝滑顺畅翻转
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            // 展开后的精致文字内容
            if isExpanded {
                Text(answer)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineSpacing(5)  // Apple 标准纵向舒适阅读距
                    .padding(.leading, 70)  // 对齐图标的右侧边缘
                    .padding(.trailing, 24)
                    .padding(.bottom, 20)
                    .padding(.top, -4)
                    // 弹簧高度延伸动画与深呼吸淡出
                    .transition(
                        .opacity.combined(with: .move(edge: .top)).combined(
                            with: .scale(scale: 0.98)))
            }
        }
    }
}
