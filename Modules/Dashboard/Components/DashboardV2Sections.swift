import SwiftUI
import UIKit

struct DashboardV2RecordsSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    let onPlusTap: () -> Void
    let onTypeTap: (LogType) -> Void

    private let logTypes: [LogType] = [.meal, .water, .mood, .exercise, .sleep, .headache, .bloodPressure, .bloodSugar, .meditation, .menstrual]

    @Environment(\.dashboardSectionAccent) private var sectionAccent

    /// 与周历、Hero 日期上下文对齐：今日 / 历史 / 未来三种说明（对标「情境化文案」）
    private var sectionSubtitle: String {
        if viewModel.isFutureDate {
            return "所选为未来日期；可先填写，闭环与统计将在当日更新后纳入。"
        }
        if !viewModel.isSelectedDateToday {
            return "正在为 \(viewModel.formattedDateTitle) 补记，与当前周历所选日期一致。"
        }
        return "饮食、饮水、心情、运动与睡眠；轻点卡片快速写入，与下方今日概览联动。"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                DashboardSectionTitle(title: "我的记录", subtitle: sectionSubtitle)
                Spacer(minLength: 8)
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onPlusTap()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26, weight: .regular))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(sectionAccent, sectionAccent.opacity(0.38))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("更多记录类型")
                .accessibilityHint("打开列表，选择要补记的类型")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(logTypes) { type in
                        RecordQuickEntryTile(type: type, sectionAccent: sectionAccent) {
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            onTypeTap(type)
                        }
                    }
                }
                .padding(.vertical, 2)
                .padding(.trailing, 6)
            }
        }
        .aegisCardStyle(padding: 16)
    }
}

// MARK: - 快速补记入口（对齐 Health / 钱包类「模块化胶囊」密度）

private struct RecordQuickEntryTile: View {
    let type: LogType
    let sectionAccent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    type.color.opacity(0.38),
                                    type.color.opacity(0.12),
                                ],
                                center: .topLeading,
                                startRadius: 2,
                                endRadius: 28
                            )
                        )
                        .frame(width: 46, height: 46)
                        .overlay {
                            Circle()
                                .strokeBorder(type.color.opacity(0.22), lineWidth: 1)
                        }

                    Image(safeSystemName: type.icon, fallback: "square.grid.2x2")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(type.color)
                        .symbolRenderingMode(.hierarchical)
                }

                Text(type.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(width: 92, height: 112)
            .background {
                RoundedRectangle(cornerRadius: DashboardV2Radius.large, style: .continuous)
                    .fill(Color.dashboardInsetSurface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: DashboardV2Radius.large, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                type.color.opacity(0.42),
                                sectionAccent.opacity(0.12),
                                Color.primary.opacity(0.06),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: type.color.opacity(0.08), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(RecordQuickEntryPressStyle())
        .accessibilityLabel("\(type.title)记录")
        .accessibilityHint("打开补记表单")
    }
}

private struct RecordQuickEntryPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct DashboardV2GoalSection: View {
    @ObservedObject var viewModel: DashboardViewModel

    /// 与 Hero「关怀文案」分工：此处仅为所选日的 **量化闭环**（步数 / 饮水 / 消耗），合并为一张分组卡片，减少三块独立模块的视觉噪音。
    private var overviewSubtitle: String {
        viewModel.isSelectedDateToday ? "活动与摄入闭环" : "所选日期的当日汇总"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                DashboardSectionTitle(title: "今日概览", subtitle: overviewSubtitle)
                if !viewModel.isSelectedDateToday {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .font(.system(size: 12, weight: .semibold))
                        Text("正在查看 \(viewModel.formattedDateTitle) 的进度")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 0) {
                goalMetricRow(
                    icon: "shoeprints.fill",
                    title: "步数",
                    value: viewModel.dailySteps,
                    goal: viewModel.stepsGoal,
                    progress: viewModel.stepProgress,
                    color: .tealDeep,
                    valueFontSize: 26
                )
                .padding(DashboardV2Spacing.cardPadding)

                Divider()
                    .opacity(0.35)

                HStack(spacing: 0) {
                    goalMetricColumn(
                        icon: "drop.fill",
                        title: "饮水",
                        value: viewModel.waterIntake,
                        goal: viewModel.waterGoal,
                        progress: viewModel.waterProgress,
                        color: .androidBlue
                    )
                    Rectangle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 1)
                        .padding(.vertical, 10)
                    goalMetricColumn(
                        icon: "flame.fill",
                        title: "消耗",
                        value: viewModel.caloriesBurned,
                        goal: viewModel.caloriesGoal,
                        progress: viewModel.caloriesProgress,
                        color: .orangeWarm
                    )
                }
                .frame(minHeight: 112)
            }
            .background(Color.dashboardInsetSurface)
            .clipShape(RoundedRectangle(cornerRadius: DashboardV2Radius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DashboardV2Radius.large, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
        }
        .aegisCardStyle(padding: 16)
    }

    private func goalMetricRow(
        icon: String,
        title: String,
        value: Int,
        goal: Int,
        progress: Double,
        color: Color,
        valueFontSize: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label(title, systemImage: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text("\(value)")
                    .font(.system(size: valueFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.15))
                    Capsule().fill(color).frame(width: max(0, geo.size.width * progress))
                }
            }
            .frame(height: 7)
            Text("目标 \(goal)")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private func goalMetricColumn(
        icon: String,
        title: String,
        value: Int,
        goal: Int,
        progress: Double,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.88)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.15))
                    Capsule().fill(color).frame(width: max(0, geo.size.width * progress))
                }
            }
            .frame(height: 6)
            Text("目标 \(goal)")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(DashboardV2Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DashboardV2BiometricTodaySection: View {
    @ObservedObject var viewModel: DashboardViewModel

    /// 与「今日概览」分工：步数 / 饮水 / 消耗仅在一处展示；此处只保留 **体征类**（心率、压力）与 **睡眠摘要**（概览未覆盖的维度）。
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionTitle(
                title: "生理指标",
                subtitle: "心率与压力；睡眠时长（活动与饮水见「今日概览」）"
            )
            HStack(spacing: 12) {
                statCard(
                    title: "心率", value: "\(viewModel.heartRate)", unit: "bpm", color: .errorRed,
                    icon: "heart.fill")
                statCard(
                    title: "压力", value: "\(viewModel.stressLevel)", unit: "指数", color: .purpleSoft,
                    icon: "brain")
            }
            sleepSummaryCard
        }
        .aegisCardStyle(padding: 16)
    }

    private var sleepSummaryCard: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.purpleSoft.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(safeSystemName: "bed.double.fill", fallback: "moon.zzz.fill")
                        .foregroundColor(.purpleSoft)
                        .font(.system(size: 16, weight: .semibold))
                )
            VStack(alignment: .leading, spacing: 4) {
                Text("睡眠")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    Text(sleepDisplayValue)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("小时")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(DashboardV2Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dashboardInsetSurface)
        .clipShape(RoundedRectangle(cornerRadius: DashboardV2Radius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DashboardV2Radius.medium, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var sleepDisplayValue: String {
        let h = viewModel.sleepHours
        guard h > 0.05 else { return "—" }
        return String(format: "%.1f", h)
    }

    private func statCard(title: String, value: String, unit: String, color: Color, icon: String) -> some View {
        HStack(spacing: 10) {
            Circle().fill(color.opacity(0.2)).frame(width: 36, height: 36)
                .overlay(
                    Image(safeSystemName: icon, fallback: "circle.fill")
                        .foregroundColor(color)
                        .font(.system(size: 14)))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 12)).foregroundStyle(.secondary)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value).font(.system(size: 19, weight: .bold, design: .rounded))
                    Text(unit).font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(DashboardV2Spacing.cardPadding)
        .background(Color.dashboardInsetSurface)
        .clipShape(RoundedRectangle(cornerRadius: DashboardV2Radius.medium, style: .continuous))
    }
}

struct DashboardV2NotificationSection: View {
    let items: [NotificationPreviewItem]
    let onMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                DashboardSectionTitle(title: "通知")
                Spacer()
                Button(action: onMore) {
                    Text("查看全部")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.androidBlue)
                }
            }
            if items.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("暂无最近通知")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("开启提醒后，饮水与运动提示会出现在这里。")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.dashboardInsetSurface)
                .clipShape(RoundedRectangle(cornerRadius: DashboardV2Radius.medium, style: .continuous))
            } else {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.title).font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Text(item.timeText).font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Text(item.body).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(2)
                    }
                    .padding(12)
                    .background(Color.dashboardInsetSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .aegisCardStyle(padding: 16)
    }
}

struct DashboardV2ReminderSection: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DashboardSectionTitle(title: "今日提醒")
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orangeWarm)
                    .frame(width: 36, height: 36)
                    .background(Color.orangeWarm.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(Color.dashboardInsetSurface)
            .clipShape(RoundedRectangle(cornerRadius: DashboardV2Radius.medium, style: .continuous))
        }
        .aegisCardStyle(padding: 16)
    }
}

struct DashboardV2NutritionSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionTitle(title: "营养概览")
            HStack(spacing: 14) {
                DonutChartView(progress: 0.67, color: .successGreen)
                    .frame(width: 72, height: 72)
                VStack(alignment: .leading, spacing: 7) {
                    row("蛋白质", "45g", .androidBlue)
                    row("碳水", "120g", .orangeWarm)
                    row("脂肪", "30g", .purpleSoft)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.dashboardInsetSurface)
            .clipShape(RoundedRectangle(cornerRadius: DashboardV2Radius.medium, style: .continuous))
        }
        .aegisCardStyle(padding: 16)
    }

    private func row(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 12)).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundStyle(.primary)
        }
    }
}

struct DashboardV2DataAnalysisSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                DashboardSectionTitle(title: "数据分析")
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    NavigationCoordinator.shared.navigate(to: .statistics)
                } label: {
                    HStack(spacing: 4) {
                        Text("统计详情")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.androidBlue)
                }
            }
            HStack(spacing: 12) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    NavigationCoordinator.shared.navigate(to: .statistics)
                } label: {
                    analysisCard(
                        title: "营养达成分析", value: "67%", symbol: "chart.pie.fill", accent: .tealDeep)
                }
                .buttonStyle(.plain)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    NavigationCoordinator.shared.navigate(to: .statistics)
                } label: {
                    analysisCard(
                        title: "活动分布", value: "轻度 45%", symbol: "figure.walk", accent: .sageBright)
                }
                .buttonStyle(.plain)
            }
        }
        .aegisCardStyle(padding: 16)
    }

    private func analysisCard(title: String, value: String, symbol: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.2), accent.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(safeSystemName: symbol, fallback: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundStyle(accent.opacity(0.55), accent.opacity(0.2))
                    .symbolRenderingMode(.hierarchical)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
            Text(value).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dashboardInsetSurface)
        .clipShape(RoundedRectangle(cornerRadius: DashboardV2Radius.medium, style: .continuous))
    }
}

struct DashboardV2TrendSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var selectedTab = "步数"

    private let tabs = ["步数", "饮水", "睡眠"]

    private var trendPoints: [StepDataPoint] {
        switch selectedTab {
        case "步数": return viewModel.weeklyStepsData
        case "饮水": return viewModel.weeklyWaterData.map { StepDataPoint(day: $0.day, value: $0.value) }
        default: return viewModel.weeklySleepData.map { StepDataPoint(day: $0.day, value: $0.value) }
        }
    }

    private var trendColor: Color {
        switch selectedTab {
        case "步数": return .androidGreen
        case "饮水": return .androidBlue
        default: return .purple
        }
    }

    private var trendUnit: String {
        switch selectedTab {
        case "步数": return "步"
        case "饮水": return "ml"
        default: return "分钟"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                DashboardSectionTitle(title: "健康趋势")
                Spacer()
                Text("近7日")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                ForEach(tabs, id: \.self) { tab in
                    Text(tab)
                        .font(.system(size: 13, weight: selectedTab == tab ? .bold : .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(selectedTab == tab ? Color.white : Color.clear)
                        .foregroundColor(selectedTab == tab ? .androidGreen : .gray)
                        .cornerRadius(10)
                        .shadow(
                            color: selectedTab == tab ? Color.black.opacity(0.05) : .clear,
                            radius: 4, x: 0, y: 2
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                        }
                }
            }
            .padding(4)
            .background(Color.dashboardInsetSurface)
            .cornerRadius(14)

            DashboardTrendLineChart(data: trendPoints, color: trendColor, unit: trendUnit)
                .padding(12)
                .background(Color.dashboardInsetSurface)
                .clipShape(RoundedRectangle(cornerRadius: DashboardV2Radius.medium, style: .continuous))
                .id(selectedTab)
        }
        .aegisCardStyle(padding: 16)
    }
}

struct DashboardV2InsightsSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    let onTapInsight: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                DashboardSectionTitle(title: "健康见解")
                Spacer()
                Button("查看详情", action: onTapInsight)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.androidBlue)
            }
            if viewModel.todayInsights.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("暂无今日见解")
                            .font(.system(size: 14, weight: .semibold))
                        Text("同步健康数据或连续记录几天后，会生成个性化提示。")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.dashboardInsetSurface)
                .clipShape(RoundedRectangle(cornerRadius: DashboardV2Radius.medium, style: .continuous))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.todayInsights) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                Image(safeSystemName: item.icon, fallback: "lightbulb.fill")
                                    .foregroundColor(item.color)
                                Text(item.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.primary)
                                Text(item.description).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(3)
                            }
                            .padding(12)
                            .frame(width: 188, alignment: .leading)
                            .background(Color.dashboardInsetSurface)
                            .clipShape(RoundedRectangle(cornerRadius: DashboardV2Radius.medium, style: .continuous))
                        }
                    }
                }
            }
        }
        .aegisCardStyle(padding: 16)
    }
}
