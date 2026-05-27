import SwiftUI
import UIKit

// MARK: - 1. 完整颜色系统 (AegisFlow主题色)

// MARK: 品牌色系
extension Color {
    // 品牌绿色系
    static let sageLight = Color(hex: "#A7CDB8")  // 主色浅绿
    static let aegisFreshGreen = Color(hex: "#77D6A1")  // 清新青翠（基础不透明，按需在视图层设置透明度）
    static let aegisFreshGreenDeep = Color(hex: "#4FAE83")  // 深一档的同色系强调（基础不透明）
    static let sageBright = Color.aegisFreshGreen  // 兼容旧代码：统一到新绿色
    static let tealDeep = Color.aegisFreshGreenDeep  // 保持层次但统一到新绿色系

    // 原有颜色别名（兼容现有代码）
    static let androidGreen = Color.aegisFreshGreen  // 兼容旧代码
    static let androidBlue = Color(hex: "#4FC3F7")  // 兼容旧代码
    static let androidPurple = Color(hex: "#9575CD")  // 兼容旧代码
    static let androidOrange = Color(hex: "#FF8A65")  // 兼容旧代码
    static let themeDarkGreen = Color.aegisFreshGreenDeep  // 兼容旧代码

    // 中性色系
    static let grayDark = Color(hex: "#2E2E2E")  // 深灰文字
    static let grayMid = Color(hex: "#ABABAB")  // 中灰文字
    static let grayLight = Color(hex: "#E5E7EB")  // 浅灰分隔线
    static let cream = Color(hex: "#ECECEC")  // 背景米色
    static let whitePure = Color(hex: "#FFFFFF")  // 纯白

    // 功能色系
    static let yellowBright = Color(hex: "#EBE038")  // 亮黄
    static let orangeWarm = Color(hex: "#E18B1F")  // 暖橙
    static let purpleSoft = Color(hex: "#C399FF")  // 柔和紫
    static let blueSky = Color(hex: "#6ED4DF")  // 天蓝

    // 状态色系
    static let successGreen = Color(hex: "#81C784")  // 成功绿
    static let warningOrange = Color(hex: "#FFA726")  // 警告橙
    static let errorRed = Color(hex: "#E57373")  // 错误红

    // 聊天相关色系
    static let chatBackground = Color(hex: "#FAFAF8")  // 聊天背景
    static let userBubble = Color(hex: "#4A9A8C")  // 用户消息气泡
    static let aiBubbleBorder = Color(hex: "#E8ECE9")  // AI消息边框
    static let sidebarBackground = Color(hex: "#FAFAFA")  // 侧边栏背景
    static let aiAvatarBg = Color(hex: "#F0F7F2")  // AI头像背景
    static let accentGreenLight = Color(hex: "#D4EADB")  // 浅薄荷绿

    // 全局背景
    static let androidBg = Color(hex: "#F2F5EB")  // 全局底层背景
    static let androidCardBg = Color(hex: "#FAFCF2")  // 卡片背景
    static let androidElementBg = Color(hex: "#E9EDDE")  // 元素背景（旧版；首页优先用 dashboardInsetSurface）
    static let androidNaturalShadow = Color(hex: "#4A5533").opacity(0.06)  // 自然阴影

    /// 首页分组卡片 **内嵌区域**：对齐 `secondarySystemGroupedBackground`，干净清冷、深浅色自适应（氧气感）
    static var dashboardInsetSurface: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }

    /// 内嵌区域再抬一层（小块、行背景）：`tertiarySystemGroupedBackground`
    static var dashboardInsetElevated: Color {
        Color(uiColor: .tertiarySystemGroupedBackground)
    }

    // MARK: 周主题色系（7种日间主题）
    static func weekThemeColor(for dayOfWeek: Int) -> (
        primary: Color, secondary: Color, blobLight: Color, gradientEnd: Color
    ) {
        switch dayOfWeek {
        case 1:  // 周日 - 周期修复
            return (
                Color(hex: "#2F97A3"),
                Color(hex: "#5BC2D2"),
                Color(hex: "#D6F2F6"),
                Color(hex: "#8DE2EC")
            )
        case 2:  // 周一 - 关节激活
            return (
                Color(hex: "#B85E8E"),
                Color(hex: "#DB87B3"),
                Color(hex: "#F8D6E8"),
                Color(hex: "#F8B7D3")
            )
        case 3:  // 周二 - 睡眠改善
            return (
                Color(hex: "#5B73C8"),
                Color(hex: "#8FA3E8"),
                Color(hex: "#E3E9FF"),
                Color(hex: "#B8C5FA")
            )
        case 4:  // 周三 - 训练恢复
            return (
                Color(hex: "#3C8E79"),
                Color(hex: "#69B9A4"),
                Color(hex: "#D8F2EA"),
                Color(hex: "#ADE6D7")
            )
        case 5:  // 周四 - 压力疏导
            return (
                Color(hex: "#A6A01B"),
                Color(hex: "#CCC82A"),
                Color(hex: "#F6F6BE"),
                Color(hex: "#F2F56B")
            )
        case 6:  // 周五 - 心肺唤醒
            return (
                Color(hex: "#C8676E"),
                Color(hex: "#E3878D"),
                Color(hex: "#FAD0D3"),
                Color(hex: "#F5B0B8")
            )
        case 7:  // 周六 - 轻松收束
            return (
                Color(hex: "#2B97A5"),
                Color(hex: "#56C0CC"),
                Color(hex: "#CFF2F4"),
                Color(hex: "#92DEE5")
            )
        default:
            return (
                Color(hex: "#2F97A3"),
                Color(hex: "#5BC2D2"),
                Color(hex: "#D6F2F6"),
                Color(hex: "#8DE2EC")
            )
        }
    }
}

// MARK: - 2. 字体扩展
extension Font {
    // 标题字体
    static let aegisLargeTitle = Font.system(size: 28, weight: .bold)
    static let aegisTitle = Font.system(size: 22, weight: .bold)
    static let aegisHeadline = Font.system(size: 18, weight: .semibold)
    static let aegisSubheadline = Font.system(size: 16, weight: .medium)

    // 正文字体
    static let aegisBody = Font.system(size: 15, weight: .regular)
    static let aegisCallout = Font.system(size: 14, weight: .regular)
    static let aegisFootnote = Font.system(size: 13, weight: .regular)

    // 标签字体
    static let aegisCaption = Font.system(size: 12, weight: .regular)
    static let aegisCaptionBold = Font.system(size: 12, weight: .semibold)

    // 数字字体（等宽）
    static let aegisMono = Font.system(size: 16, weight: .medium, design: .monospaced)
    static let aegisMonoLarge = Font.system(size: 24, weight: .bold, design: .monospaced)

    // Emoji标题
    static let aegisEmoji = Font.system(size: 32)
}

// MARK: - 3. 圆角规范
struct AegisCornerRadius {
    static let extraLarge: CGFloat = 28  // 大卡片/弹窗
    static let large: CGFloat = 24  // 主卡片
    static let medium: CGFloat = 20  // 中等卡片
    static let small: CGFloat = 16  // 小卡片/按钮
    static let tag: CGFloat = 12  // 标签/Chip
    static let input: CGFloat = 14  // 输入框
    static let avatar: CGFloat = 50  // 头像
}

// MARK: - 4. 间距规范
struct AegisSpacing {
    static let pageHorizontal: CGFloat = 24  // 页面水平内边距
    static let cardPadding: CGFloat = 20  // 卡片内边距
    static let sectionGap: CGFloat = 16  // 模块间距
    static let itemGap: CGFloat = 12  // 元素间距
    static let tight: CGFloat = 8  // 紧凑间距
    static let heroHeight: CGFloat = 380  // Hero区域高度
    static let bottomSafe: CGFloat = 100  // 底部安全区
}

// MARK: - 5. 阴影规范
struct AegisShadow {
    static let card = Shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    static let cardElevated = Shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
    static let dialog = Shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - 5.1 统一开关样式
struct AegisSwitchToggleStyle: ToggleStyle {
    var tint: Color = .aegisFreshGreen
    var width: CGFloat = 54
    var height: CGFloat = 34

    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.72)) {
                configuration.isOn.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                configuration.label

                Spacer(minLength: 0)

                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule(style: .continuous)
                        .fill(configuration.isOn ? tint.opacity(0.44) : Color.white.opacity(0.84))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(
                                    configuration.isOn
                                        ? tint.opacity(0.62) : Color.black.opacity(0.08),
                                    lineWidth: 1)
                        )

                    Circle()
                        .fill(Color.white)
                        .frame(width: height - 6, height: height - 6)
                        .shadow(
                            color: .black.opacity(configuration.isOn ? 0.14 : 0.10), radius: 2,
                            x: 0, y: 1
                        )
                        .padding(3)
                }
                .frame(width: width, height: height)
                .shadow(
                    color: tint.opacity(configuration.isOn ? 0.26 : 0.05), radius: 5, x: 0, y: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 6. 十六进制颜色初始化（支持 3 / 6 / 8 位，含可选 Alpha）
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 2. 统一卡片样式（对齐系统分组 / Summary：材质 + 极淡叠色 + 发丝描边 + 克制阴影）
struct AegisCardModifier: ViewModifier {
    /// Apple Health / 设置类分区常用 16~20
    var padding: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    private let cornerRadius: CGFloat = 22

    /// 浅色：极淡 **冷白** 叠在材质上，偏氧气通透；深色：极低提亮
    private var materialCoolOverlay: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.08)
        }
        return Color(red: 0.96, green: 0.98, blue: 0.99).opacity(0.44)
    }

    private var edgeStroke: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color.white.opacity(0.14), Color.white.opacity(0.04), Color.black.opacity(0.35)]
                : [Color.white.opacity(0.65), Color.white.opacity(0.12), Color.primary.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.regularMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(materialCoolOverlay)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(edgeStroke, lineWidth: colorScheme == .dark ? 0.65 : 0.75)
                }
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.42 : 0.06),
                radius: colorScheme == .dark ? 20 : 14,
                x: 0,
                y: colorScheme == .dark ? 10 : 6
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.035),
                radius: 2,
                x: 0,
                y: 1
            )
    }
}

extension View {
    /// 应用通透毛玻璃、带多层软阴影的精美卡片样式
    /// - Parameter padding: 内部留白，默认采用 Apple Health 比例 16pt
    func aegisCardStyle(padding: CGFloat = 16) -> some View {
        self.modifier(AegisCardModifier(padding: padding))
    }

    /// 卡片入场动效：轻微下移、渐显并以 spring 延迟依次出现
    func aegisReveal(delay: Double = 0) -> some View {
        self.modifier(AegisRevealModifier(delay: delay))
    }

    /// 微动效交互卡片：添加点击缩放至 0.98 倍，并附带系统级触感反馈
    func aegisPressableCard(action: @escaping () -> Void = {}) -> some View {
        Button(action: {
            // 触发 UIImpactFeedbackGenerator 轻量震动反馈
            let impactMed = UIImpactFeedbackGenerator(style: .light)
            impactMed.impactOccurred()
            action()
        }) {
            self
        }
        .buttonStyle(AegisBouncyCardStyle())
    }
}

struct AegisRevealModifier: ViewModifier {
    let delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 18)
            .scaleEffect(isVisible ? 1 : 0.985)
            .onAppear {
                if reduceMotion {
                    isVisible = true
                } else {
                    withAnimation(
                        .spring(response: 0.6, dampingFraction: 0.82, blendDuration: 0)
                            .delay(delay)
                    ) {
                        isVisible = true
                    }
                }
            }
    }
}

// 供 aegisPressableCard 使用的弹性按钮交互样式
struct AegisBouncyCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.95 : 1.0)  // 极其细微的点击变暗
            .animation(
                .spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0),
                value: configuration.isPressed)
    }
}

// MARK: - 3. 目标调节滑块 (配合新样式优化)
struct GoalAdjustableRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @Binding var val: Float
    let range: ClosedRange<Float>

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 16, weight: .bold))
                }

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary.opacity(0.85))

                Spacer()

                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary.opacity(0.9))
            }

            GeometryReader { geo in
                // 确保进度百分比永远在 0~1 之间，防止数值为 0 时滑块飞出屏幕不见
                let rawPercentage = CGFloat(
                    (val - range.lowerBound) / (range.upperBound - range.lowerBound))
                let percentage = max(0.0, min(1.0, rawPercentage))

                let trackHeight: CGFloat = 8
                let handleSize: CGFloat = 24

                ZStack(alignment: .leading) {
                    // 轨道底色 (高质感凹陷感)
                    Capsule()
                        .fill(Color.black.opacity(0.06))
                        .overlay(Capsule().stroke(Color.black.opacity(0.04), lineWidth: 1))
                        .frame(height: trackHeight)

                    // 已达进度 (渐变发亮质感)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.6), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(trackHeight, geo.size.width * percentage),
                            height: trackHeight
                        )
                        .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 1)

                    // 手柄：苹果原生级别阴影环
                    Circle()
                        .fill(Color.white)
                        .frame(width: handleSize, height: handleSize)
                        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)
                        .shadow(color: Color.black.opacity(0.08), radius: 1, x: 0, y: 1)
                        .offset(x: percentage * (geo.size.width - handleSize))
                        .gesture(
                            DragGesture(minimumDistance: 0).onChanged { v in
                                // 减去半个手柄的宽度让拖拽中心位于手柄中心
                                let percent = min(max(0, v.location.x / geo.size.width), 1)
                                self.val =
                                    range.lowerBound + Float(percent)
                                    * (range.upperBound - range.lowerBound)
                            })
                }
                .frame(height: handleSize)  // 确保触控区域足够大
            }
            .frame(height: 24)  // 留出手柄和滑轨的空间
        }
        .padding(.vertical, 4)  // 增加上下呼吸感
    }
}

// MARK: - 4. 统一子页面头部
struct SubPageHeader: View {
    let title: String
    var onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")  // 换成更细致的箭头
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.aegisFreshGreen)
                    .frame(width: 36, height: 36)
                    .background(Color.aegisFreshGreen.opacity(0.22))
                    .clipShape(Circle())
            }
            Spacer()
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            Spacer()
            // 占位确保标题居中
            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 15 + safeAreaTop())  // 适配刘海屏
        .padding(.bottom, 15)
        .background {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                LinearGradient(
                    colors: [
                        Color.aegisFreshGreen.opacity(0.24),
                        Color.white.opacity(0.06),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }  // 使用高级毛玻璃，让背景透出
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.aegisFreshGreen.opacity(0.22))
                .frame(height: 1)
        }
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    private func safeAreaTop() -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first
        else { return 0 }
        return window.safeAreaInsets.top
    }
}

// MARK: - 5. 顶级 iOS 流体背景 (Mesh Gradient + Material)
struct AegisDynamicBackground: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // 1. 基础优雅灰绿白底色：略微加深底色（偏铂金色度），让亮亮剔透的卡片能大幅脱颖而出
            Color(hex: "#EEF1E6").ignoresSafeArea()

            // 2. 动态网格渐变流动光斑 (提升色彩饱和度，使背景不再泛白贫血)
            GeometryReader { geo in
                ZStack {
                    // 左上角：活力青柠绿
                    Circle()
                        .fill(Color.androidGreen.opacity(0.25))
                        .frame(width: geo.size.width * 1.2)
                        .blur(radius: 90)
                        .offset(
                            x: isAnimating ? -geo.size.width * 0.2 : geo.size.width * 0.1,
                            y: isAnimating ? -geo.size.height * 0.1 : -geo.size.height * 0.2)

                    // 右下角：安静深邃翠绿
                    Circle()
                        .fill(Color.themeDarkGreen.opacity(0.25))
                        .frame(width: geo.size.width * 1.5)
                        .blur(radius: 120)
                        .offset(
                            x: isAnimating ? geo.size.width * 0.3 : geo.size.width * 0.5,
                            y: isAnimating ? geo.size.height * 0.6 : geo.size.height * 0.4)

                    // 中间偏左：清透氧气蓝，提供高级的冷暖色调碰撞
                    Circle()
                        .fill(Color.androidBlue.opacity(0.25))
                        .frame(width: geo.size.width * 0.8)
                        .blur(radius: 90)
                        .offset(
                            x: isAnimating ? geo.size.width * 0.6 : geo.size.width * 0.1,
                            y: isAnimating ? geo.size.height * 0.3 : geo.size.height * 0.6)
                }
            }
            .ignoresSafeArea()

            // 3. 材质融合层：去掉会过度削弱对比度的全局厚重磨砂，仅挂载微弱的自发光噪波反射涂层
            Color.white.opacity(0.15)  // 洗净视野，同时增加白平衡
                .ignoresSafeArea()
        }
        .onAppear {
            // 极其缓慢的呼吸流动，产生“灵动且具有深度”的错觉
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
