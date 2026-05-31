import SwiftUI
import UIKit

private let dashboardTrendCardBackground = Color(red: 0.97, green: 0.98, blue: 0.94)

struct DashboardV2RecordsSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    let onPlusTap: () -> Void
    let onTypeTap: (LogType) -> Void

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
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionTitle(title: "我的记录", subtitle: sectionSubtitle)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                recordActionCard
                recordEmptyCard
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recordActionCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.96, green: 0.96, blue: 0.96))
                .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 160)

            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onPlusTap()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(viewModel.dayTheme.primary)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("添加记录")
            .accessibilityHint("打开记录类型选择")
        }
    }

    private var recordEmptyCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.96, green: 0.96, blue: 0.96))
                .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 160)

            VStack(alignment: .leading, spacing: 12) {
                Text("今天还没有记录")
                Text("点击 + 开始记录吧")
            }
            .font(.custom("STKaiti", size: 22).weight(.medium))
            .foregroundColor(Color.gray.opacity(0.8))
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct DashboardV2GoalSection: View {
    @ObservedObject var viewModel: DashboardViewModel

    private var themeColor: Color {
        viewModel.dayTheme.primary
    }

    private var trackColor: Color {
        viewModel.dayTheme.blobLight
    }

    private var weeklyThemeTitle: String {
        switch viewModel.javaDayOfWeekForSelectedDate {
        case 1: return "周期修复"
        case 2: return "关节激活"
        case 3: return "睡眠改善"
        case 4: return "训练恢复"
        case 5: return "压力疏导"
        case 6: return "心肺唤醒"
        default: return "轻松收束"
        }
    }

    private var stepTargetText: String {
        "\(viewModel.stepsGoal)步"
    }

    private var stepCurrentText: String {
        "\(viewModel.dailySteps)步"
    }

    private var distanceTargetKm: Double { 5.0 }

    private var distanceCurrentKm: Double {
        Double(viewModel.dailySteps) * 0.0008
    }

    private var distanceProgress: CGFloat {
        CGFloat(min(max(distanceCurrentKm / distanceTargetKm, 0), 1))
    }

    private var calorieTargetText: String {
        "\(viewModel.caloriesGoal)Cal"
    }

    private var calorieCurrentText: String {
        "\(viewModel.caloriesBurned)Cal"
    }

    var body: some View {
        VStack(spacing: 28) {
            HStack(alignment: .bottom) {
                HStack(spacing: 4) {
                    Text("目标")
                        .font(.system(.title2, design: .serif))
                        .bold()
                    Text("每月任务 >")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray)
                }

                Spacer()

                Text(weeklyThemeTitle)
                    .font(.system(.callout, design: .rounded))
                    .bold()
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(themeColor)
                    .cornerRadius(25)
            }
            .padding(.bottom, 10)

            DashboardV2GoalMetricRow(
                title: "步数",
                targetText: stepTargetText,
                currentText: stepCurrentText,
                iconName: "trophy.fill",
                iconColor: themeColor,
                progress: CGFloat(viewModel.stepProgress),
                trackColor: trackColor
            )

            DashboardV2GoalMetricRow(
                title: "距离",
                targetText: String(format: "%.0fkm", distanceTargetKm),
                currentText: String(format: "%.1fkm", distanceCurrentKm),
                iconName: "star.fill",
                iconColor: themeColor,
                progress: distanceProgress,
                trackColor: trackColor
            )

            DashboardV2GoalMetricRow(
                title: "卡路里",
                targetText: calorieTargetText,
                currentText: calorieCurrentText,
                iconName: "flame.fill",
                iconColor: themeColor,
                progress: CGFloat(viewModel.caloriesProgress),
                trackColor: trackColor
            )
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DashboardV2GoalMetricRow: View {
    let title: String
    let targetText: String
    let currentText: String
    let iconName: String
    let iconColor: Color
    let progress: CGFloat
    let trackColor: Color

    var body: some View {
        VStack(spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .lastTextBaseline) {
                    Text(title)
                        .font(.system(.title3, design: .serif))
                        .foregroundColor(.black.opacity(0.8))

                    Spacer(minLength: 8)

                    Text(targetText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.7))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.title3, design: .serif))
                        .foregroundColor(.black.opacity(0.8))

                    Text(targetText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.7))
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(trackColor)
                                .frame(height: 18)

                            Capsule()
                                .fill(iconColor)
                                .frame(width: geometry.size.width * min(max(progress, 0), 1), height: 18)
                        }
                    }
                    .frame(height: 18)

                    HStack(spacing: 4) {
                        Text(currentText)
                            .font(.system(.title3, design: .rounded))
                            .bold()
                            .foregroundColor(iconColor)

                        Image(systemName: iconName)
                            .foregroundColor(iconColor)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(width: 95, alignment: .trailing)
                }

                VStack(alignment: .leading, spacing: 10) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(trackColor)
                                .frame(height: 18)

                            Capsule()
                                .fill(iconColor)
                                .frame(width: geometry.size.width * min(max(progress, 0), 1), height: 18)
                        }
                    }
                    .frame(height: 18)

                    HStack(spacing: 4) {
                        Text(currentText)
                            .font(.system(.title3, design: .rounded))
                            .bold()
                            .foregroundColor(iconColor)

                        Image(systemName: iconName)
                            .foregroundColor(iconColor)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }
}

struct DashboardV2BiometricTodaySection: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            DashboardSectionTitle(title: "生理指标")

            HStack(spacing: 16) {
                DashboardV2PhysiologyMetricCard(
                    backgroundColor: Color(hex: "FCD5DF"),
                    iconName: "suit.heart.fill",
                    isStressIcon: false,
                    iconColor: Color(hex: "E05C67"),
                    iconBgColor: Color(hex: "FABECB"),
                    valueText: "- -",
                    valueUnit: "bpm",
                    title: "心率",
                    hasRing: false
                )

                DashboardV2PhysiologyMetricCard(
                    backgroundColor: Color(hex: "D1EFEA"),
                    iconName: "person.cog",
                    isStressIcon: true,
                    iconColor: Color(hex: "3F7670"),
                    iconBgColor: Color(hex: "B7E3DC"),
                    valueText: "- -",
                    valueUnit: "分",
                    title: "压力水平",
                    hasRing: true
                )
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct DashboardV2TodayDataSection: View {
    @ObservedObject var viewModel: DashboardViewModel

    private var stepText: String { "\(viewModel.dailySteps)" }

    private var waterText: String {
        String(format: "%.1fL", Double(viewModel.waterIntake) / 1000.0)
    }

    private var calorieText: String { "\(viewModel.caloriesBurned)" }

    private var sleepText: String {
        String(format: "%.1fh", viewModel.sleepHours)
    }

    private var rowLayout: some View {
        HStack(spacing: 0) {
            DashboardV2TodayDataItemView(
                value: stepText,
                unit: "步数",
                circleColor: Color(hex: "E2F0E7")
            )

            DashboardV2TodayDataDivider()

            DashboardV2TodayDataItemView(
                value: waterText,
                unit: "饮水",
                circleColor: Color(hex: "E3F4F4")
            )

            DashboardV2TodayDataDivider()

            DashboardV2TodayDataItemView(
                value: calorieText,
                unit: "卡路里",
                circleColor: Color(hex: "FBF0D9")
            )

            DashboardV2TodayDataDivider()

            DashboardV2TodayDataItemView(
                value: sleepText.replacingOccurrences(of: "h", with: "\nh"),
                unit: "睡眠",
                circleColor: Color(hex: "EDE7F6"),
                isSleep: true
            )
        }
    }

    private var compactGridLayout: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            DashboardV2TodayDataItemView(
                value: stepText,
                unit: "步数",
                circleColor: Color(hex: "E2F0E7")
            )

            DashboardV2TodayDataItemView(
                value: waterText,
                unit: "饮水",
                circleColor: Color(hex: "E3F4F4")
            )

            DashboardV2TodayDataItemView(
                value: calorieText,
                unit: "卡路里",
                circleColor: Color(hex: "FBF0D9")
            )

            DashboardV2TodayDataItemView(
                value: sleepText,
                unit: "睡眠",
                circleColor: Color(hex: "EDE7F6")
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            DashboardSectionTitle(title: "今日数据")

            ViewThatFits(in: .horizontal) {
                rowLayout
                compactGridLayout
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 0)
            .background(Color(hex: "F8F9F3"))
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .clipped()
    }
}

private struct DashboardV2PhysiologyMetricCard: View {
    let backgroundColor: Color
    let iconName: String
    var isStressIcon: Bool = false
    let iconColor: Color
    let iconBgColor: Color
    let valueText: String
    let valueUnit: String
    let title: String
    var hasRing: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(iconBgColor)
                        .frame(width: 48, height: 48)

                    Image(systemName: isStressIcon ? "waveform.path.ecg" : iconName)
                        .font(.system(size: 20, weight: .bold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(iconColor)
                }

                Spacer()

                Text("暂无数据")
                    .font(.custom("STKaiti", size: 14))
                    .foregroundColor(.black.opacity(0.25))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .padding(.trailing, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .layoutPriority(1)
            }

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(valueText)
                    .font(.system(size: 38, weight: .black))
                    .foregroundColor(Color(hex: "222222"))

                Text(valueUnit)
                    .font(.custom("STKaiti", size: 18).italic())
                    .foregroundColor(.black.opacity(0.3))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                Group {
                    if hasRing {
                        Circle()
                            .trim(from: 0.1, to: 0.9)
                            .stroke(
                                iconColor.opacity(0.12),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 80, height: 80)
                            .offset(x: -22, y: -10)
                    }
                },
                alignment: .trailing
            )

            Spacer()

            Text(title)
                .font(.custom("STKaiti", size: 18))
                .foregroundColor(.black.opacity(0.35))
        }
        .padding(16)
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        
    }
}

private struct DashboardV2TodayDataItemView: View {
    let value: String
    let unit: String
    let circleColor: Color
    var isSleep: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(circleColor, lineWidth: 4)
                    .frame(width: 44, height: 44)

                Text("0")
                    .font(.system(size: 14, design: .serif))
                    .italic()
                    .foregroundColor(Color(hex: "333333"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: isSleep ? 20 : 22, weight: .medium, design: .default))
                    .lineLimit(2)
                    .foregroundColor(Color(hex: "1A1A1A"))

                Text(unit)
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(Color.gray.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct DashboardV2TodayDataDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 1, height: 40)
    }
}

struct DashboardV2NotificationSection: View {
    let items: [NotificationPreviewItem]
    let onMore: () -> Void

    private var visibleItems: [NotificationPreviewItem] {
        let normalized = items.compactMap { item -> NotificationPreviewItem? in
            let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let body = item.body.trimmingCharacters(in: .whitespacesAndNewlines)
            let time = item.timeText.trimmingCharacters(in: .whitespacesAndNewlines)
            if title.isEmpty && body.isEmpty { return nil }
            return NotificationPreviewItem(
                title: title.isEmpty ? "消息提醒" : title,
                body: body.isEmpty ? "你有一条新的通知，请点击查看详情。" : body,
                timeText: time.isEmpty ? "刚刚" : time
            )
        }

        var result = Array(normalized.prefix(3))
        if result.count < 3 {
            result.append(contentsOf: DashboardV2NotificationSection.fallbackItems.prefix(3 - result.count))
        }
        return result
    }

    private static let fallbackItems: [NotificationPreviewItem] = [
        NotificationPreviewItem(title: "久坐提醒", body: "已经坐了很久，起来活动 2 分钟，放松一下肩颈。", timeText: "17小时前"),
        NotificationPreviewItem(title: "睡眠提醒", body: "建议提前放下手机，给自己留出放松时间。", timeText: "18小时前"),
        NotificationPreviewItem(title: "睡眠提醒", body: "建议提前放下手机，给自己一段平稳入睡节奏。", timeText: "22小时前"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            DashboardSectionTitle(title: "通知列表")

            VStack(spacing: 0) {
                VStack(spacing: 24) {
                    ForEach(visibleItems) { item in
                        DashboardV2NotificationRow(item: item)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)

                HStack {
                    Spacer()
                    Button(action: onMore) {
                        Text("查看全部通知")
                            .font(.custom("HanziPenSC-Regular", size: 18))
                            .foregroundColor(Color(red: 139 / 255, green: 195 / 255, blue: 74 / 255))
                            .padding(.trailing, 24)
                            .padding(.bottom, 24)
                    }
                }
            }
            .background(Color(red: 247 / 255, green: 251 / 255, blue: 242 / 255))
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
        .padding(.top, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
    }
}

private struct DashboardV2NotificationRow: View {
    let item: NotificationPreviewItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(red: 255 / 255, green: 121 / 255, blue: 89 / 255))
                .frame(width: 10, height: 10)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(item.title)
                        .font(.custom("HanziPenSC-Bold", size: 22))
                        .foregroundColor(Color.black.opacity(0.8))
                    Spacer()
                    Text(item.timeText)
                        .font(.custom("HanziPenSC-Regular", size: 16))
                        .foregroundColor(.gray)
                }

                Text(item.body)
                    .font(.custom("HanziPenSC-Regular", size: 18))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
    }
}

struct DashboardV2ReminderSection: View {
    let text: String
    let onTap: () -> Void

    private var reminderTimeText: String {
        let reminderComponents = NotificationSettingsManager.shared.exerciseReminderTime
        let now = Date()
        let calendar = Calendar.current

        guard let reminderDateToday = calendar.date(from: DateComponents(
            year: calendar.component(.year, from: now),
            month: calendar.component(.month, from: now),
            day: calendar.component(.day, from: now),
            hour: reminderComponents.hour,
            minute: reminderComponents.minute
        )) else {
            return "3小时后"
        }

        let targetDate = reminderDateToday >= now ? reminderDateToday : calendar.date(byAdding: .day, value: 1, to: reminderDateToday) ?? reminderDateToday
        let deltaMinutes = max(Int(targetDate.timeIntervalSince(now) / 60), 0)

        if deltaMinutes < 60 {
            return "\(max(deltaMinutes, 1))分钟后"
        }

        let hours = max((deltaMinutes + 59) / 60, 1)
        return "\(hours)小时后"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionTitle(title: "今日提醒")

            Button(action: onTap) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 254 / 255, green: 226 / 255, blue: 236 / 255))
                            .frame(width: 65, height: 65)

                        Image(systemName: "figure.run")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.orange)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("下次提醒")
                            .font(.system(size: 14, weight: .regular, design: .serif))
                            .foregroundColor(.gray)

                        Text(text)
                            .font(.system(size: 16, weight: .medium, design: .serif))
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .allowsTightening(true)
                    }

                    Spacer(minLength: 0)

                    Text(reminderTimeText)
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color(red: 227 / 255, green: 23 / 255, blue: 120 / 255),
                                    Color(red: 247 / 255, green: 71 / 255, blue: 139 / 255),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .mask(
                            Text(reminderTimeText)
                                .font(.system(size: 18, weight: .semibold, design: .serif))
                        )
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: 95, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 253 / 255, green: 239 / 255, blue: 244 / 255))
                )
            }
            .buttonStyle(.plain)
        }
        .clipped()
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
        .frame(maxWidth: .infinity, alignment: .leading)
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

struct DashboardV2NutritionOverviewSection: View {
    private let totalCalories: CGFloat = 2000
    private let consumedCalories: CGFloat = 0

    private let proteinTarget: CGFloat = 120
    private let proteinConsumed: CGFloat = 0

    private let carbsTarget: CGFloat = 250
    private let carbsConsumed: CGFloat = 0

    private let fatTarget: CGFloat = 65
    private let fatConsumed: CGFloat = 0

    private let fiberTarget: CGFloat = 30
    private let fiberConsumed: CGFloat = 0

    private var completionPercentage: Int {
        totalCalories > 0 ? Int((consumedCalories / totalCalories) * 100) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        LinearGradient(
                            colors: [Color(hex: "7FC15A"), Color(hex: "498451")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: 40, height: 40)
                        .cornerRadius(12)

                        Image(systemName: "fork.knife")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text("营养摄入概览")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "2C3E2B"))
                }

                Spacer()

                Text("当日")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "498451"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Color(hex: "EBF5E6"))
                    .cornerRadius(14)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 20) {
                    nutritionRing
                    VStack(spacing: 12) {
                        DashboardV2NutritionNutrientRow(title: "蛋白质", consumed: proteinConsumed, target: proteinTarget, color: Color(hex: "FFA845"))
                        DashboardV2NutritionNutrientRow(title: "碳水", consumed: carbsConsumed, target: carbsTarget, color: Color(hex: "9BD843"))
                        DashboardV2NutritionNutrientRow(title: "脂肪", consumed: fatConsumed, target: fatTarget, color: Color(hex: "B78CFF"))
                        DashboardV2NutritionNutrientRow(title: "膳食纤维", consumed: fiberConsumed, target: fiberTarget, color: Color(hex: "276A62"))
                    }
                }

                VStack(spacing: 16) {
                    nutritionRing
                    VStack(spacing: 12) {
                        DashboardV2NutritionNutrientRow(title: "蛋白质", consumed: proteinConsumed, target: proteinTarget, color: Color(hex: "FFA845"))
                        DashboardV2NutritionNutrientRow(title: "碳水", consumed: carbsConsumed, target: carbsTarget, color: Color(hex: "9BD843"))
                        DashboardV2NutritionNutrientRow(title: "脂肪", consumed: fatConsumed, target: fatTarget, color: Color(hex: "B78CFF"))
                        DashboardV2NutritionNutrientRow(title: "膳食纤维", consumed: fiberConsumed, target: fiberTarget, color: Color(hex: "276A62"))
                    }
                }
            }

            HStack(alignment: .center) {
                VStack(spacing: 4) {
                    Text("\(Int(consumedCalories)) kcal")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "81C443"))
                    Text("已摄入")
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 35)
                    .background(Color(hex: "D0E6CD"))

                VStack(spacing: 4) {
                    Text("\(Int(max(0, totalCalories - consumedCalories))) kcal")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "276A62"))
                    Text("剩余")
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 35)
                    .background(Color(hex: "D0E6CD"))

                VStack(spacing: 4) {
                    Text("\(completionPercentage)%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "FFA845"))
                    Text("完成度")
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 15)
            .background(Color(hex: "F2FAF0"))
            .cornerRadius(16)
        }
        .padding(20)
        .background(dashboardTrendCardBackground)
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color(hex: "E2F3DD"), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private var nutritionRing: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "EDEDED"), lineWidth: 24)
                .frame(width: 128, height: 128)

            Circle()
                .trim(from: 0, to: totalCalories > 0 ? (consumedCalories / totalCalories) : 0)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "7FC15A"), Color(hex: "498451")],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 24, lineCap: .round)
                )
                .frame(width: 128, height: 128)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(Int(consumedCalories))")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "232323"))
                Text("/ \(Int(totalCalories)) kcal")
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 140)
    }
}

private struct DashboardV2NutritionNutrientRow: View {
    let title: String
    let consumed: CGFloat
    let target: CGFloat
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                    Text(title)
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(.gray)
                }
                Spacer()
                Text("\(Int(consumed))/\(Int(target))g")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "232323"))
            }

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(color.opacity(0.12))
                    .frame(height: 5)
                Capsule()
                    .fill(color)
                    .frame(width: target > 0 ? max(0, min(120, 120 * (consumed / target))) : 0, height: 5)
            }
        }
    }
}

struct DashboardV2TrendSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var selectedTab = 0

    private let days = ["一", "二", "三", "四", "五", "六", "日"]

    private var trendColor: Color {
        switch selectedTab {
        case 0: return Color(red: 0.52, green: 0.73, blue: 0.25)
        case 1: return Color(red: 0.25, green: 0.81, blue: 0.88)
        default: return Color(red: 0.73, green: 0.53, blue: 0.88)
        }
    }

    private var currentThemeColor: Color { trendColor }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DashboardSectionTitle(title: "健康趋势")
                .padding(.top, 20)

            VStack(spacing: 0) {
                HStack {
                    Text("健康趋势")
                        .font(.system(size: 20, weight: .medium, design: .serif))
                        .foregroundColor(Color(white: 0.15))
                    Spacer()
                    Text("近7日")
                        .font(.system(size: 14, weight: .light, design: .serif))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                CustomSegmentedControl(selectedTab: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
                        Spacer()
                        Divider().background(Color(white: 0.9))
                        Spacer()
                        Divider().background(Color(white: 0.9))
                        Spacer()
                    }
                    .frame(height: 160)
                    .padding(.horizontal, 24)

                    VStack(spacing: 12) {
                        ZStack {
                            VStack(spacing: 2) {
                                currentThemeColor
                                    .frame(height: 2)
                                currentThemeColor
                                    .frame(height: 2)
                            }
                            .padding(.horizontal, 24)

                            HStack {
                                ForEach(0..<days.count, id: \.self) { index in
                                    Circle()
                                        .fill(currentThemeColor)
                                        .frame(width: 10, height: 10)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                    if index != days.count - 1 { Spacer() }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        HStack {
                            ForEach(days, id: \.self) { day in
                                Text(day)
                                    .font(.system(size: 15, weight: .light, design: .serif))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .padding(.bottom, 20)
                }
                .frame(height: 220)
                .padding(.top, 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(red: 0.97, green: 0.98, blue: 0.94))
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
            )
            .padding(.horizontal, 0)
            .padding(.top, 20)
        }
        .padding(.bottom, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BreathingPopupView: View {
    @Binding var isPresented: Bool
    var onDeepBreathTap: () -> Void = {}
    var onBoxBreathingTap: () -> Void = {}
    var onMeditationTap: () -> Void = {}

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Button(action: {
                                isPresented = false
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.system(size: 20, weight: .medium))
                                    .padding([.top, .trailing], 20)
                            }
                        }

                        Text("🌬️")
                            .font(.system(size: 70))
                            .padding(.top, -10)

                        Text("深呼吸，放松一下")
                            .font(.custom("PingFangSC-Medium", size: 24))
                            .foregroundColor(.white)
                            .padding(.top, 25)
                            .padding(.bottom, 30)

                        VStack(spacing: 16) {
                            BreathingPopupMenuButton(icon: "🌬️", title: "深呼吸 3次") {
                                onDeepBreathTap()
                                isPresented = false
                            }

                            BreathingPopupMenuButton(icon: "📦", title: "盒式呼吸 1分钟") {
                                onBoxBreathingTap()
                                isPresented = false
                            }

                            BreathingPopupMenuButton(icon: "🧘", title: "冥想放松 3分钟") {
                                onMeditationTap()
                                isPresented = false
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 35)
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "FF94B7"), Color(hex: "E51C77")]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(32)
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                    .frame(maxWidth: 420)
                    .padding(.horizontal, 28)
                    .padding(.vertical, max(proxy.safeAreaInsets.top, 16))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

private struct BreathingPopupMenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Spacer()

                Text(icon)
                    .font(.system(size: 26))

                Text(title)
                    .font(.custom("PingFangSC-Regular", size: 20))
                    .foregroundColor(Color(hex: "D13070"))

                Spacer()
            }
            .frame(height: 64)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// Replaced the compact analysis cards with a richer nutrition & activity view supplied by designer
struct DashboardV2DataAnalysisSection: View {
    struct NutritionItem: Identifiable {
        let id = UUID()
        let name: String
        let current: Double
        let target: Double
        let color: Color

        var percentage: Int { target > 0 ? Int((current / target) * 100) : 0 }
    }

    private let nutritionData: [NutritionItem] = [
        NutritionItem(name: "蛋白质", current: 0, target: 120, color: Color(red: 0.22, green: 0.54, blue: 0.44)),
        NutritionItem(name: "碳水", current: 0, target: 250, color: Color(red: 0.44, green: 0.73, blue: 0.65)),
        NutritionItem(name: "脂肪", current: 0, target: 65, color: Color(red: 0.95, green: 0.65, blue: 0.26)),
        NutritionItem(name: "膳食纤维", current: 0, target: 30, color: Color(red: 0.44, green: 0.81, blue: 0.88))
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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

            VStack(spacing: 12) {
                nutritionCard
                activityCard
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
    }

    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("营养达成分析")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(Color(white: 0.12))
                Spacer()
                Text("目标达成率")
                    .font(.system(size: 12))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.88, green: 0.92, blue: 0.89))
                    .foregroundColor(Color(red: 0.3, green: 0.45, blue: 0.38))
                    .cornerRadius(12)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    RadarChartBackground()
                        .frame(width: 120, height: 120)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(nutritionData) { item in
                            HStack(alignment: .center, spacing: 10) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 12, height: 12)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(white: 0.15))
                                    Text("\(Int(item.current))/\(Int(item.target))g")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text("\(item.percentage)%")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(red: 0.95, green: 0.65, blue: 0.26))
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    RadarChartBackground()
                        .frame(width: 120, height: 120)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(nutritionData) { item in
                            HStack(alignment: .center, spacing: 10) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 12, height: 12)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(white: 0.15))
                                    Text("\(Int(item.current))/\(Int(item.target))g")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text("\(item.percentage)%")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(red: 0.95, green: 0.65, blue: 0.26))
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(dashboardTrendCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("活动分布")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(Color(white: 0.12))

            HStack(spacing: 24) {
                Circle()
                    .stroke(Color(red: 0.88, green: 0.88, blue: 0.86), lineWidth: 28)
                    .frame(width: 96, height: 96)

                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                        .frame(width: 12, height: 12)

                    Text("暂无数据")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.35))

                    Spacer()

                    Text("100%")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(dashboardTrendCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func RadarChartBackground() -> some View {
        ZStack {
            ForEach(1...4, id: \.self) { index in
                Rectangle()
                    .stroke(Color(red: 0.88, green: 0.89, blue: 0.87), lineWidth: 1)
                    .rotationEffect(.degrees(45))
                    .scaleEffect(Double(index) * 0.22)
            }
            GeometryReader { geo in
                Path { path in
                    path.move(to: CGPoint(x: geo.size.width / 2, y: 0))
                    path.addLine(to: CGPoint(x: geo.size.width / 2, y: geo.size.height))
                    path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                }
                .stroke(Color(red: 0.88, green: 0.89, blue: 0.87), lineWidth: 1)
            }
            Circle()
                .fill(Color(red: 0.44, green: 0.81, blue: 0.88))
                .frame(width: 8, height: 8)
        }
    }
}

struct DashboardV2TodayGoalsSection: View {
    @ObservedObject var viewModel: DashboardViewModel

    private var cards: [DashboardV2TodayGoalCardModel] {
        [
            DashboardV2TodayGoalCardModel(
                iconName: "figure.walk",
                iconColor: Color(red: 140 / 255, green: 195 / 255, blue: 65 / 255),
                currentAmount: "\(viewModel.dailySteps)",
                unit: "",
                targetAmount: "\(viewModel.stepsGoal.formatted())",
                progress: viewModel.stepProgress
            ),
            DashboardV2TodayGoalCardModel(
                iconName: "drop.fill",
                iconColor: Color(red: 90 / 255, green: 195 / 255, blue: 210 / 255),
                currentAmount: String(format: "%.0f", Double(viewModel.waterIntake)),
                unit: "ml",
                targetAmount: "\(viewModel.waterGoal / 1000)L",
                progress: viewModel.waterProgress
            ),
            DashboardV2TodayGoalCardModel(
                iconName: "flame.fill",
                iconColor: Color(red: 245 / 255, green: 150 / 255, blue: 50 / 255),
                currentAmount: "\(viewModel.caloriesBurned)",
                unit: "",
                targetAmount: "\(viewModel.caloriesGoal.formatted())",
                progress: viewModel.caloriesProgress
            ),
            DashboardV2TodayGoalCardModel(
                iconName: "moon.fill",
                iconColor: Color(red: 185 / 255, green: 140 / 255, blue: 240 / 255),
                currentAmount: String(format: "%.1f", viewModel.sleepHours),
                unit: "h",
                targetAmount: "8.0h",
                progress: min(viewModel.sleepHours / 8.0, 1)
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DashboardSectionTitle(title: "今日目标")
                .padding(.top, 20)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                ForEach(cards) { card in
                    DashboardV2TodayGoalCardView(card: card)
                }
            }
            .padding(.bottom, 2)
        }
        .padding(.top, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DashboardV2TodayGoalCardModel: Identifiable {
    let id = UUID()
    let iconName: String
    let iconColor: Color
    let currentAmount: String
    let unit: String
    let targetAmount: String
    let progress: Double
}

private struct DashboardV2TodayGoalCardView: View {
    let card: DashboardV2TodayGoalCardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: card.iconName)
                    .font(.title2)
                    .foregroundColor(card.iconColor)
                Spacer()
                Text("\(Int(card.progress * 100))%")
                    .font(.system(.subheadline, design: .rounded))
                    .bold()
                    .foregroundColor(card.iconColor)
            }

            Spacer(minLength: 0)

            HStack(alignment: .bottom, spacing: 2) {
                Text(card.currentAmount)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                if !card.unit.isEmpty {
                    Text(card.unit)
                        .font(.system(.body, design: .rounded))
                        .bold()
                        .padding(.bottom, 6)
                }
            }
            .foregroundColor(.black.opacity(0.85))

            Text("目标 \(card.targetAmount)")
                .font(.system(.subheadline, design: .serif))
                .foregroundColor(.gray.opacity(0.6))

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(card.iconColor.opacity(0.15))
                        .frame(height: 4)

                    Capsule()
                        .fill(card.iconColor)
                        .frame(width: geometry.size.width * CGFloat(min(max(card.progress, 0), 1)), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(10)
        .frame(minHeight: 128, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 247 / 255, green: 251 / 255, blue: 245 / 255))
        )
    }
}

private struct CustomSegmentedControl: View {
    @Binding var selectedTab: Int
    private let options = ["步数", "饮水", "睡眠"]

    private func getSelectedColor(for index: Int) -> Color {
        switch index {
        case 0: return Color(red: 0.52, green: 0.73, blue: 0.25)
        case 1: return Color(red: 0.25, green: 0.81, blue: 0.88)
        case 2: return Color(red: 0.73, green: 0.53, blue: 0.88)
        default: return .gray
        }
    }

    private func getSelectedWeight(for index: Int) -> Font.Weight {
        index == selectedTab ? .medium : .light
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<options.count, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = index
                    }
                } label: {
                    ZStack {
                        if index == selectedTab {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .padding(4)
                                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                        }

                        Text(options[index])
                            .font(.system(size: 18, weight: getSelectedWeight(for: index), design: .serif))
                            .foregroundColor(index == selectedTab ? getSelectedColor(for: index) : Color(white: 0.5))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 54)
        .background(Color(red: 0.91, green: 0.91, blue: 0.91))
        .cornerRadius(20)
    }
}

struct DashboardV2InsightsSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    let onTapInsight: () -> Void

    private let insights: [DashboardV2HealthInsightCardModel] = [
        DashboardV2HealthInsightCardModel(
            iconName: "figure.walk",
            iconColor: Color(red: 0.45, green: 0.75, blue: 0.15),
            iconBgColor: Color(red: 0.93, green: 0.96, blue: 0.85),
            title: "步行不足",
            description: "建议每天走够5000步，有助于提高新陈代谢。",
            destination: AnyView(HealthInsightLibrary.activityInsight)
        ),
        DashboardV2HealthInsightCardModel(
            iconName: "drop.fill",
            iconColor: Color(red: 0.35, green: 0.78, blue: 0.88),
            iconBgColor: Color(red: 0.88, green: 0.96, blue: 0.95),
            title: "缺水",
            description: "每天应摄入约1500毫升的水，保持身体水分平衡。",
            destination: AnyView(HealthInsightLibrary.waterInsight)
        ),
        DashboardV2HealthInsightCardModel(
            iconName: "moon.fill",
            iconColor: Color(red: 0.65, green: 0.45, blue: 0.95),
            iconBgColor: Color(red: 0.94, green: 0.91, blue: 0.97),
            title: "缺乏睡眠",
            description: "每晚应保证7-9小时的睡眠，有助于身体恢复。",
            destination: AnyView(HealthInsightLibrary.sleepInsight)
        ),
        DashboardV2HealthInsightCardModel(
            iconName: "brain.head.profile",
            iconColor: Color(red: 0.20, green: 0.45, blue: 0.40),
            iconBgColor: Color(red: 0.88, green: 0.92, blue: 0.90),
            title: "压力管理",
            description: "尝试深呼吸练习或冥想以减轻日常压力。",
            destination: AnyView(HealthInsightLibrary.stressInsight)
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                DashboardSectionTitle(title: "健康见解")
                Spacer()
                Button(action: onTapInsight) {
                    HStack(spacing: 2) {
                        Text("点击查看详情")
                        Image(systemName: "arrow.right")
                    }
                    .font(.footnote)
                    .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.5))
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(insights) { insight in
                        NavigationLink(destination: insight.destination) {
                            DashboardV2HealthInsightCardView(item: insight)
                        }
                    }
                }
            }
        }
    }
}

private struct DashboardV2HealthInsightCardModel: Identifiable {
    let id = UUID()
    let iconName: String
    let iconColor: Color
    let iconBgColor: Color
    let title: String
    let description: String
    let destination: AnyView
}

private struct DashboardV2HealthInsightCardView: View {
    let item: DashboardV2HealthInsightCardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: item.iconName)
                    .font(.title2)
                    .foregroundColor(item.iconColor)
                    .frame(width: 44, height: 44)
                    .background(item.iconBgColor)
                    .cornerRadius(14)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(.systemGray4))
                    .padding(.top, 4)
            }

            Text(item.title)
                .font(.title3)
                .bold()
                .foregroundColor(Color(.darkGray))

            Text(item.description)
                .font(.body)
                .foregroundColor(.gray)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(width: 260, height: 180)
        .background(dashboardTrendCardBackground)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

struct HealthArticleView: View {
    let themeColor: Color
    let title: String
    let subtitle: String
    let iconName: String
    let sections: [ArticleSection]

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    themeColor.frame(height: 180)

                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(10)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }

                        Image(systemName: iconName)
                            .font(.title)
                            .padding(12)
                            .background(Color.white.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(15)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(title).font(.system(size: 24, weight: .bold))
                            Text(subtitle).font(.system(size: 14))
                        }.foregroundColor(.white)
                    }
                    .padding(.top, 50)
                    .padding(.horizontal, 25)
                }

                VStack(spacing: 20) {
                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 15) {
                            HStack(spacing: 12) {
                                Text("\(section.index)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(themeColor)
                                    .frame(width: 24, height: 24)
                                    .background(themeColor.opacity(0.1))
                                    .clipShape(Circle())

                                Text(section.header).font(.system(size: 18, weight: .bold))
                            }

                            Text(section.content)
                                .font(.system(size: 15))
                                .foregroundColor(.primary.opacity(0.8))
                                .lineSpacing(6)

                            if !section.bullets.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(section.bullets, id: \.self) { bullet in
                                        HStack(alignment: .top, spacing: 8) {
                                            Circle().fill(themeColor.opacity(0.5)).frame(width: 6, height: 6).padding(.top, 6)
                                            Text(bullet).font(.system(size: 14)).foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(15)
                                .background(Color(white: 0.97))
                                .cornerRadius(15)
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(25)
                        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                    }

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill").foregroundColor(themeColor.opacity(0.6))
                        Text("健康知识仅供参考，如有疑问请咨询专业医师。")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                }
                .padding(20)
                .background(Color(white: 0.96))
                .cornerRadius(40, corners: [.topLeft, .topRight])
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}

struct ArticleSection: Identifiable {
    let id = UUID()
    let index: Int
    let header: String
    let content: String
    var bullets: [String] = []
}

private enum HealthInsightLibrary {
    static var waterInsight: some View {
        HealthGuideView(selectedTab: 0)
    }

    static var activityInsight: some View {
        HealthGuideView(selectedTab: 1)
    }

    static var sleepInsight: some View {
        HealthGuideView(selectedTab: 2)
    }

    static var stressInsight: some View {
        HealthGuideView(selectedTab: 3)
    }
}

// MARK: - HealthGuideView (designer-supplied)
// Inserted here so the four insight destinations can reuse the same multi-page guide.
struct HealthGuideSection: Identifiable {
    let id = UUID()
    let number: String
    let title: String
    let content: String
    let bulletPoints: [String]
}

private let waterSections = [
    HealthGuideSection(
        number: "1",
        title: "为什么水分如此重要？",
        content: "人体约60%由水分组成，水参与了几乎所有的生理过程，包括营养输送、体温调节、关节润滑和废物排泄。即使轻度脱水（体重减少1-2%）也会影响认知功能、情绪和体力表现。",
        bulletPoints: [
            "起床后先喝一杯温水，唤醒身体代谢",
            "运动前30分钟预先补充200-300ml水",
            "不要等口渴才喝水，建立定时饮水习惯",
            "注意观察尿液颜色，浅黄色表明水分充足"
        ]
    ),
    HealthGuideSection(
        number: "2",
        title: "每日饮水量建议",
        content: "成年人每日建议饮水量为1500-2500ml，具体取决于体重、活动量和环境温度。一个简单的计算公式：体重(kg) × 30ml。例如体重70kg的人，每日约需2100ml水。剧烈运动或高温环境下需额外补充。",
        bulletPoints: []
    ),
    HealthGuideSection(
        number: "3",
        title: "饮水的最佳时机",
        content: "合理安排饮水时间能最大化水分吸收效率。避免一次性大量饮水，建议少量多次。",
        bulletPoints: [
            "晨起空腹：促进肠道蠕动",
            "餐前30分钟：有助于控制食量",
            "运动中：每15-20分钟补充150-200ml",
            "睡前1小时：避免夜间频繁起夜"
        ]
    )
]

private let activitySections = [
    HealthGuideSection(
        number: "1",
        title: "久坐的健康风险",
        content: "研究表明，每天久坐超过8小时且缺乏运动的人，其健康风险与吸烟、肥胖相当。久坐会导致代谢率降低、血液循环减缓、肌肉萎缩，并增加心血管疾病、糖尿病和某些癌症的发生风险。",
        bulletPoints: [
            "每坐45-60分钟，站起来活动5分钟",
            "尝试站立办公或使用升降桌",
            "利用午休时间进行短距离步行",
            "用走楼梯替代乘坐电梯"
        ]
    ),
    HealthGuideSection(
        number: "2",
        title: "步行的益处",
        content: "每天步行7000-10000步可显著降低全因死亡率。快步走（速度≥5.5km/h）是一种高效的有氧运动，能改善心肺功能、增强骨骼密度、促进精神健康。即使每天只增加2000步，也能带来可测量的健康收益。",
        bulletPoints: []
    ),
    HealthGuideSection(
        number: "3",
        title: "如何增加日常活动量",
        content: "不需要专门安排运动时间，将活动融入日常生活同样有效。",
        bulletPoints: [
            "通勤时提前一站下车步行",
            "与同事进行「步行会议」",
            "做家务也是很好的身体活动",
            "饭后散步15分钟辅助消化"
        ]
    )
]

private let sleepSections = [
    HealthGuideSection(
        number: "1",
        title: "睡眠的重要性",
        content: "睡眠期间，身体进行组织修复、肌肉生长、激素调节和记忆巩固。长期睡眠不足（每晚少于7小时）会增加肥胖、心血管疾病、抑郁和免疫力下降的风险。成年人建议每晚睡眠7-9小时。",
        bulletPoints: [
            "保持固定的睡觉和起床时间",
            "创造黑暗、安静、凉爽的睡眠环境",
            "睡前1小时避免使用电子设备",
            "午后限制咖啡因摄入"
        ]
    ),
    HealthGuideSection(
        number: "3",
        title: "改善睡眠质量的方法",
        content: "建立良好的睡前习惯能显著提升睡眠质量。",
        bulletPoints: [
            "睡前进行放松活动（阅读、冥想）",
            "白天保证充足的自然光照射",
            "规律运动但避免睡前2小时剧烈运动",
            "如20分钟无法入睡，起床做较轻松活动后再试"
        ]
    )
]

private let stressSections = [
    HealthGuideSection(
        number: "1",
        title: "认识压力反应",
        content: "适度压力能提升表现，但慢性压力会导致皮质醇持续升高，引发免疫抑制、消化问题、失眠、焦虑等问题。识别压力信号（肌肉紧张、头痛、易怒）是管理压力的第一步。",
        bulletPoints: [
            "识别自己的压力触发因素",
            "建立日常放松仪式",
            "学会对不必要的任务说「不」",
            "保持社交连接和情感支持"
        ]
    ),
    HealthGuideSection(
        number: "2",
        title: "有效的减压方法",
        content: "科学研究证实的减压方法包括：正念冥想（可降低皮质醇14%）、深呼吸练习（激活副交感神经系统）、渐进性肌肉放松和有氧运动。每天仅需5-10分钟的正念练习就能产生显著效果。",
        bulletPoints: []
    ),
    HealthGuideSection(
        number: "3",
        title: "4-7-8 呼吸法",
        content: "这是一种简单有效的即时放松技巧，可随时随地练习。",
        bulletPoints: [
            "吸气4秒：通过鼻子缓慢吸气",
            "屏息7秒：轻柔地屏住呼吸",
            "呼气8秒：通过嘴巴缓慢呼出",
            "重复3-4个循环即可感受到放松"
        ]
    )
]

// HealthGuideView components
struct HealthGuideView: View {
    @State private var selectedTab = 0

    init(selectedTab: Int = 0) {
        _selectedTab = State(initialValue: selectedTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            GuidePageContainer(themeColor: Color(red: 0.33, green: 0.84, blue: 0.88), iconName: "drop.fill", title: "科学饮水指南", subtitle: "了解水分对人体的重要意义", sections: waterSections).tag(0)
            GuidePageContainer(themeColor: Color(red: 0.64, green: 0.84, blue: 0.19), iconName: "figure.walk", title: "日常活动与健康", subtitle: "让运动融入每一天", sections: activitySections).tag(1)
            GuidePageContainer(themeColor: Color(red: 0.74, green: 0.61, blue: 0.98), iconName: "moon.fill", title: "优质睡眠科学", subtitle: "睡眠是最好的恢复", sections: sleepSections).tag(2)
            GuidePageContainer(themeColor: Color(red: 0.27, green: 0.52, blue: 0.52), iconName: "gearshape.fill", title: "压力管理策略", subtitle: "掌控压力，守护身心", sections: stressSections).tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(Color(red: 0.93, green: 0.93, blue: 0.93).ignoresSafeArea())
    }
}

struct GuidePageContainer: View {
    let themeColor: Color
    let iconName: String
    let title: String
    let subtitle: String
    let sections: [HealthGuideSection]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 18) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(title)
                                .font(.custom("STKaiti", size: 30))
                                .bold()
                                .foregroundColor(.white)

                            Text(subtitle)
                                .font(.custom("STKaiti", size: 16))
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(2)
                        }

                        Spacer(minLength: 12)

                        Image(systemName: iconName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(themeColor)
                            .frame(width: 52, height: 52)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    }

                    Rectangle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 42, height: 4)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 170, alignment: .bottomLeading)
                .background(themeColor)

                VStack(spacing: 20) {
                    ForEach(sections) { section in
                        HealthGuideCardView(section: section, themeColor: themeColor)
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill").foregroundColor(themeColor).font(.system(size: 16))

                        Text("健康知识仅供参考，如遇疑问请咨询专业医师。")
                            .font(.custom("STKaiti", size: 13))
                            .foregroundColor(.gray.opacity(0.8))
                            .lineSpacing(4)
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 50)
            }
        }
        .edgesIgnoringSafeArea(.top)
    }
}

struct HealthGuideCardView: View {
    let section: HealthGuideSection
    let themeColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Text(section.number).font(.system(size: 12, weight: .bold)).foregroundColor(themeColor).frame(width: 22, height: 22).background(themeColor.opacity(0.15)).clipShape(Circle())

                Text(section.title).font(.custom("STKaiti", size: 20)).bold().foregroundColor(Color(.darkGray))
            }

            Text(section.content).font(.custom("STKaiti", size: 15)).foregroundColor(Color.black.opacity(0.7)).lineSpacing(7)

            if !section.bulletPoints.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(section.bulletPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•").foregroundColor(themeColor).font(.system(size: 18, weight: .bold))
                            Text(point).font(.custom("STKaiti", size: 14)).foregroundColor(Color.black.opacity(0.7)).lineSpacing(4)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(themeColor.opacity(0.06))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct HealthGuideView_Previews: PreviewProvider {
    static var previews: some View { HealthGuideView() }
}
