import SwiftUI

enum DashboardV2Spacing {
    static let pageHorizontal: CGFloat = 24
    /// 与「个人中心」等板块间距节奏接近；略加大透气感，对齐 Apple 资讯 / 健康 Feed。
    static let sectionGap: CGFloat = 24
    /// Hero 弧底与下方卡片流之间的首段间距（避免「贴脸」；略增一档更透气）
    static let scrollContentTopInset: CGFloat = 22
    static let heroHeight: CGFloat = 360
    static let cardPadding: CGFloat = 16
    /// Hero 顶部区内：标题栏 ↔ 周历 之间的纵向节奏
    static let heroChromeGap: CGFloat = 15
    /// 周历区块与问候标题之间略拉大，形成「控件层 / 阅读层」分段（刘海区更易扫读）
    static let heroWeekToGreetingGap: CGFloat = 22
    /// 问候主标题与副标题间距（对齐大标题 + 说明的常见层级）
    static let heroGreetingTitleSubtitleGap: CGFloat = 9
    /// Hero 问候区与下方关怀主文案之间的透气间距（略大一线，避免上下两段黏在一起）
    static let heroBodyTopGap: CGFloat = 20
    /// Hero 中部问候 + 下部关怀文案的共同阅读宽度（略放宽一档，避免版面偏窄）
    static let heroReadableMaxWidth: CGFloat = 348
    /// 在系统安全区基础上的额外水平内缩（略减以换更宽正文列）
    static let heroExtraSafeHorizontal: CGFloat = 8
    /// Hero 前景统一水平边距（page + 额外安全内缩）
    static let heroContentHorizontalPadding: CGFloat = pageHorizontal + heroExtraSafeHorizontal
    /// 首页卡片流 `aegisReveal` 错开间隔（秒）
    static let sectionRevealStagger: Double = 0.048
}

enum DashboardV2Radius {
    static let large: CGFloat = 20
    static let medium: CGFloat = 14
    static let small: CGFloat = 10
}

// MARK: - 区块标题色：随日历主题（与 Hero 同色体系）

private struct DashboardSectionAccentKey: EnvironmentKey {
    static let defaultValue: Color = Color.orangeWarm
}

extension EnvironmentValues {
    /// 与当日 `DayTheme.primary` 对齐，用于小节左侧竖条等点缀。
    var dashboardSectionAccent: Color {
        get { self[DashboardSectionAccentKey.self] }
        set { self[DashboardSectionAccentKey.self] = newValue }
    }
}

struct DashboardSectionTitle: View {
    let title: String
    var subtitle: String? = nil

    @Environment(\.dashboardSectionAccent) private var accent

    var body: some View {
        VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 5) {
            HStack(alignment: .center, spacing: 11) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accent, accent.opacity(0.55)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: 17)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 14)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
