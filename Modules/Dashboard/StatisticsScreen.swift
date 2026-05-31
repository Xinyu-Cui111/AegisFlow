import Combine
import SwiftUI

private struct StatisticsExportToolbar: ToolbarContent {
    @ObservedObject var viewModel: StatisticsViewModel

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { viewModel.exportData() }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.grayDark)
            }
        }
    }
}

// MARK: - StatisticsScreen统计页面
struct StatisticsScreen: View {
    @StateObject private var viewModel = StatisticsViewModel()
    @State private var selectedPeriod = 0
    @State private var selectedDate = Date()

    private let periods = ["本周", "本月", "本年"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AegisSpacing.sectionGap) {
                        StatisticsDateHeader(selectedDate: $selectedDate)
                        StatisticsWeekStrip(selectedDate: $selectedDate)
                        // 周期选择器
                        PeriodSelector(selectedPeriod: $selectedPeriod, periods: periods)
                        QuickMetricStrip(viewModel: viewModel)

                        // 综合评分卡片
                        OverallScoreCard(score: viewModel.overallScore, trend: viewModel.scoreTrend)

                        // 核心指标卡片
                        CoreMetricsSection(viewModel: viewModel)

                        // 趋势分析
                        TrendAnalysisSection(viewModel: viewModel, selectedPeriod: selectedPeriod)

                        // 活动分布
                        ActivityDistributionSection(viewModel: viewModel)

                        // 睡眠分析
                        SleepAnalysisSection(viewModel: viewModel)

                        // 营养分析
                        NutritionAnalysisSection(viewModel: viewModel)
                        WeeklySummarySection(viewModel: viewModel)
                        HealthTipsBanner()

                        Spacer(minLength: AegisSpacing.bottomSafe)
                    }
                    .padding(.horizontal, AegisSpacing.pageHorizontal)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("数据统计")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                StatisticsExportToolbar(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.loadData()
        }
        .onChange(of: selectedPeriod) { _, value in
            let key = value == 0 ? "week" : (value == 1 ? "month" : "year")
            viewModel.loadData(period: key)
        }
    }
}

struct StatisticsDateHeader: View {
    @Binding var selectedDate: Date
    private var title: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日"
        return f.string(from: selectedDate)
    }

    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.grayMid)
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.grayDark)
            Spacer()
        }
    }
}

struct StatisticsWeekStrip: View {
    @Binding var selectedDate: Date

    var body: some View {
        let dates = (-3...3).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: selectedDate)
        }
        return HStack(spacing: 8) {
            ForEach(dates, id: \.self) { day in
                let selected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
                Button {
                    selectedDate = day
                } label: {
                    VStack(spacing: 4) {
                        Text(weekday(day))
                            .font(.system(size: 11, weight: .medium))
                        Text("\(Calendar.current.component(.day, from: day))")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(selected ? .white : .grayMid)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selected ? Color.grayDark : Color.white)
                    .cornerRadius(10)
                }
            }
        }
    }

    private func weekday(_ date: Date) -> String {
        let arr = ["日", "一", "二", "三", "四", "五", "六"]
        return arr[max(0, Calendar.current.component(.weekday, from: date) - 1)]
    }
}

struct QuickMetricStrip: View {
    @ObservedObject var viewModel: StatisticsViewModel
    var body: some View {
        HStack(spacing: 8) {
            chip("步数", "\(viewModel.totalSteps)")
            chip("饮水", "\(viewModel.avgWater)ml")
            chip("睡眠", "\(viewModel.avgSleepHours)h")
        }
    }

    private func chip(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.system(size: 11)).foregroundColor(.grayMid)
            Text(value).font(.system(size: 13, weight: .bold)).foregroundColor(.grayDark)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(10)
    }
}

struct WeeklySummarySection: View {
    @ObservedObject var viewModel: StatisticsViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("本周总结")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.grayDark)
            HStack {
                summary("活动总数", "\(viewModel.totalActivities)")
                summary("睡眠质量", "\(viewModel.sleepQuality)%")
                summary("综合评分", "\(viewModel.overallScore)")
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
    }

    private func summary(_ t: String, _ v: String) -> some View {
        VStack(spacing: 4) {
            Text(v).font(.system(size: 18, weight: .bold)).foregroundColor(.grayDark)
            Text(t).font(.system(size: 11)).foregroundColor(.grayMid)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HealthTipsBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill").foregroundColor(.orangeWarm)
            Text("健康建议：本周建议增加 1 次有氧训练，并将入睡时间提前 30 分钟。")
                .font(.system(size: 13))
                .foregroundColor(.grayDark)
        }
        .padding(12)
        .background(Color(hex: "#FFF3E0"))
        .cornerRadius(12)
    }
}

// MARK: - 周期选择器
struct PeriodSelector: View {
    @Binding var selectedPeriod: Int
    let periods: [String]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(periods.enumerated()), id: \.offset) { index, period in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPeriod = index
                    }
                }) {
                    Text(period)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedPeriod == index ? .white : .grayDark)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            selectedPeriod == index
                                ? Color.sageBright : Color.grayLight.opacity(0.5)
                        )
                        .cornerRadius(AegisCornerRadius.tag)
                }
            }
        }
    }
}

// MARK: - 综合评分卡片
struct OverallScoreCard: View {
    let score: Int
    let trend: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("健康综合评分")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.8))

                    HStack(alignment: .bottom, spacing: 8) {
                        Text("\(score)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("分")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.bottom, 8)
                    }
                }

                Spacer()

                // 趋势指示
                VStack(spacing: 4) {
                    Image(
                        systemName: trend >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
                    )
                    .font(.system(size: 24))
                    .foregroundColor(trend >= 0 ? .white : .errorRed)

                    Text("\(trend >= 0 ? "+" : "")\(trend)%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
            }

            // 评分等级
            HStack(spacing: 16) {
                ScoreLevelItem(label: "运动", value: 85, maxValue: 100, color: .white)
                ScoreLevelItem(label: "睡眠", value: 72, maxValue: 100, color: .white)
                ScoreLevelItem(label: "营养", value: 68, maxValue: 100, color: .white)
                ScoreLevelItem(label: "压力", value: 45, maxValue: 100, color: .white)
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(
            LinearGradient(
                colors: [.tealDeep, Color(hex: "#4A9999")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AegisCornerRadius.large)
    }
}

// MARK: - 评分等级项
struct ScoreLevelItem: View {
    let label: String
    let value: Int
    let maxValue: Int
    let color: Color

    var progress: Double {
        Double(value) / Double(maxValue)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Text("\(value)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(color.opacity(0.8))
        }
    }
}

// MARK: - 核心指标区
struct CoreMetricsSection: View {
    @ObservedObject var viewModel: StatisticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("核心指标")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.grayDark)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(
                    icon: "figure.walk",
                    title: "总步数",
                    value: "\(viewModel.totalSteps)",
                    unit: "步",
                    trend: viewModel.stepsTrend,
                    color: .tealDeep
                )

                MetricCard(
                    icon: "drop.fill",
                    title: "平均饮水",
                    value: "\(viewModel.avgWater)",
                    unit: "ml",
                    trend: viewModel.waterTrend,
                    color: .androidBlue
                )

                MetricCard(
                    icon: "flame.fill",
                    title: "消耗卡路里",
                    value: "\(viewModel.totalCalories)",
                    unit: "kcal",
                    trend: viewModel.caloriesTrend,
                    color: .orangeWarm
                )

                MetricCard(
                    icon: "moon.fill",
                    title: "平均睡眠",
                    value: "\(viewModel.avgSleepHours)",
                    unit: "小时",
                    trend: viewModel.sleepTrend,
                    color: .purpleSoft
                )
            }
        }
    }
}

// MARK: - 指标卡片
struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let trend: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(abs(trend))%")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(trend >= 0 ? .successGreen : .errorRed)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.grayDark)

                    Text(unit)
                        .font(.system(size: 12))
                        .foregroundColor(.grayMid)
                        .padding(.bottom, 4)
                }

                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.grayMid)
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 趋势分析区
struct TrendAnalysisSection: View {
    @ObservedObject var viewModel: StatisticsViewModel
    let selectedPeriod: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("趋势分析")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.grayDark)

            VStack(spacing: 16) {
                // 步数趋势
                TrendChart(
                    title: "步数趋势",
                    icon: "figure.walk",
                    data: viewModel.stepsTrendData,
                    color: .tealDeep,
                    unit: "步"
                )

                // 睡眠趋势
                TrendChart(
                    title: "睡眠趋势",
                    icon: "moon.fill",
                    data: viewModel.sleepTrendData,
                    color: .purpleSoft,
                    unit: "小时"
                )

                // 压力趋势
                TrendChart(
                    title: "压力趋势",
                    icon: "brain.head.profile",
                    data: viewModel.stressTrendData,
                    color: .orangeWarm,
                    unit: ""
                )
            }
        }
    }
}

// MARK: - 趋势图表
struct TrendChart: View {
    let title: String
    let icon: String
    let data: [Int]
    let color: Color
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.grayDark)
            }

            // 迷你折线图
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    let maxValue = CGFloat(data.max() ?? 1)
                    let height = maxValue > 0 ? CGFloat(value) / maxValue * 60 : 0

                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(index == data.count - 1 ? 1 : 0.5))
                            .frame(width: 24, height: height)

                        if index == data.count - 1 {
                            Text("\(value)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(color)
                        }
                    }
                }
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 活动分布区
struct ActivityDistributionSection: View {
    @ObservedObject var viewModel: StatisticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("活动分布")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.grayDark)

            VStack(spacing: 16) {
                // 饼图
                HStack {
                    // 简化饼图
                    ZStack {
                        ForEach(Array(viewModel.activityDistribution.enumerated()), id: \.offset) {
                            index, item in
                            Circle()
                                .trim(
                                    from: calculateStart(from: index),
                                    to: calculateEnd(item.percentage)
                                )
                                .stroke(item.color, lineWidth: 20)
                                .rotationEffect(.degrees(-90))
                        }

                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)

                        VStack(spacing: 0) {
                            Text("总活动")
                                .font(.system(size: 10))
                                .foregroundColor(.grayMid)
                            Text("\(viewModel.totalActivities)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.grayDark)
                        }
                    }
                    .frame(width: 150, height: 150)

                    // 图例
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.activityDistribution, id: \.name) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 10, height: 10)

                                Text(item.name)
                                    .font(.system(size: 12))
                                    .foregroundColor(.grayDark)

                                Spacer()

                                Text("\(item.percentage)%")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.grayMid)
                            }
                        }
                    }
                    .padding(.leading, 16)
                }
            }
            .padding(AegisSpacing.cardPadding)
            .background(Color.white)
            .cornerRadius(AegisCornerRadius.large)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }

    private func calculateStart(from index: Int) -> CGFloat {
        var start: CGFloat = 0
        for i in 0..<index {
            start += CGFloat(viewModel.activityDistribution[i].percentage) / 100
        }
        return start
    }

    private func calculateEnd(_ percentage: Int) -> CGFloat {
        return CGFloat(percentage) / 100
    }
}

// MARK: - 睡眠分析区
struct SleepAnalysisSection: View {
    @ObservedObject var viewModel: StatisticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("睡眠分析")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.grayDark)

            HStack(spacing: 16) {
                SleepMetricItem(
                    icon: "bed.double.fill",
                    title: "平均时长",
                    value: "\(viewModel.avgSleepHours)h",
                    color: .purpleSoft
                )

                SleepMetricItem(
                    icon: "moon.stars.fill",
                    title: "睡眠质量",
                    value: "\(viewModel.sleepQuality)%",
                    color: .androidBlue
                )

                SleepMetricItem(
                    icon: "clock.fill",
                    title: "平均入睡",
                    value: "\(viewModel.avgSleepTime)",
                    color: .tealDeep
                )
            }

            // 睡眠时段分布
            SleepTimeDistribution(data: viewModel.sleepDistribution)
        }
    }
}

// MARK: - 睡眠指标项
struct SleepMetricItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.grayDark)

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.grayMid)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.medium)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 睡眠时段分布
struct SleepTimeDistribution: View {
    let data: [SleepTimeSlot]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("睡眠时段分布")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.grayDark)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data) { slot in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(slot.color)
                            .frame(width: 30, height: slot.height)

                        Text(slot.time)
                            .font(.system(size: 10))
                            .foregroundColor(.grayMid)
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.medium)
    }
}

// MARK: - 营养分析区
struct NutritionAnalysisSection: View {
    @ObservedObject var viewModel: StatisticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("营养摄入")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.grayDark)

            VStack(spacing: 16) {
                // 营养素摄入
                HStack(spacing: 16) {
                    NutrientRing(
                        percentage: viewModel.proteinPercent, label: "蛋白质", color: .androidBlue)
                    NutrientRing(
                        percentage: viewModel.carbsPercent, label: "碳水", color: .orangeWarm)
                    NutrientRing(percentage: viewModel.fatPercent, label: "脂肪", color: .purpleSoft)
                }

                Divider()

                // 热量来源
                VStack(alignment: .leading, spacing: 8) {
                    Text("热量来源分析")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.grayDark)

                    ForEach(viewModel.calorieSources, id: \.name) { source in
                        HStack {
                            Text(source.name)
                                .font(.system(size: 13))
                                .foregroundColor(.grayDark)

                            Spacer()

                            Text("\(source.calories) kcal")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.grayMid)

                            Text("\(source.percentage)%")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(source.color)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
            .padding(AegisSpacing.cardPadding)
            .background(Color.white)
            .cornerRadius(AegisCornerRadius.large)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - 营养素环形图
struct NutrientRing: View {
    let percentage: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 8)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: CGFloat(percentage) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))

                Text("\(percentage)%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.grayDark)
            }

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.grayMid)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - StatisticsViewModel
class StatisticsViewModel: ObservableObject {
    // 综合评分
    @Published var overallScore: Int = 78
    @Published var scoreTrend: Int = 5

    // 核心指标
    @Published var totalSteps: Int = 45600
    @Published var avgWater: Int = 2100
    @Published var totalCalories: Int = 12450
    @Published var avgSleepHours: Int = 7

    // 趋势
    @Published var stepsTrend: Int = 12
    @Published var waterTrend: Int = 8
    @Published var caloriesTrend: Int = -3
    @Published var sleepTrend: Int = 5

    // 趋势数据
    @Published var stepsTrendData: [Int] = [6500, 8200, 7100, 9000, 7800, 8500, 9200]
    @Published var sleepTrendData: [Int] = [7, 6, 8, 7, 7, 8, 7]
    @Published var stressTrendData: [Int] = [45, 52, 38, 42, 48, 35, 40]

    // 活动分布
    @Published var activityDistribution: [ActivityItem] = [
        ActivityItem(name: "步行", percentage: 45, color: .tealDeep),
        ActivityItem(name: "跑步", percentage: 20, color: .orangeWarm),
        ActivityItem(name: "骑行", percentage: 15, color: .androidBlue),
        ActivityItem(name: "游泳", percentage: 10, color: .purpleSoft),
        ActivityItem(name: "其他", percentage: 10, color: .grayMid),
    ]
    @Published var totalActivities: Int = 128

    // 睡眠
    @Published var sleepQuality: Int = 82
    @Published var avgSleepTime: String = "23:30"
    @Published var sleepDistribution: [SleepTimeSlot] = [
        SleepTimeSlot(time: "22:00", height: 20, color: .purpleSoft.opacity(0.5)),
        SleepTimeSlot(time: "23:00", height: 60, color: .purpleSoft),
        SleepTimeSlot(time: "00:00", height: 90, color: .purpleSoft),
        SleepTimeSlot(time: "01:00", height: 70, color: .purpleSoft),
        SleepTimeSlot(time: "02:00", height: 50, color: .purpleSoft.opacity(0.7)),
        SleepTimeSlot(time: "06:00", height: 30, color: .purpleSoft.opacity(0.5)),
        SleepTimeSlot(time: "07:00", height: 15, color: .androidBlue.opacity(0.5)),
    ]

    // 营养
    @Published var proteinPercent: Int = 65
    @Published var carbsPercent: Int = 72
    @Published var fatPercent: Int = 58
    @Published var calorieSources: [CalorieSource] = [
        CalorieSource(name: "早餐", calories: 450, percentage: 18, color: .orangeWarm),
        CalorieSource(name: "午餐", calories: 680, percentage: 27, color: .tealDeep),
        CalorieSource(name: "晚餐", calories: 720, percentage: 29, color: .purpleSoft),
        CalorieSource(name: "加餐", calories: 350, percentage: 14, color: .androidBlue),
        CalorieSource(name: "饮品", calories: 250, percentage: 10, color: .successGreen),
    ]

    @MainActor
    func loadData(period: String = "week") {
        // 当前使用属性默认值作为展示数据。统计接口接入后，在此调用 APIClient.request(_:responseType:)。
        _ = period
    }

    @MainActor
    func exportData() {
        // 预留：对接导出接口并唤起系统分享
    }
}

// MARK: - 数据模型
struct ActivityItem: Identifiable {
    let id = UUID()
    let name: String
    let percentage: Int
    let color: Color
}

struct SleepTimeSlot: Identifiable {
    let id = UUID()
    let time: String
    let height: CGFloat
    let color: Color
}

struct CalorieSource: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    let percentage: Int
    let color: Color
}

// MARK: - 预览
#Preview {
    StatisticsScreen()
}
