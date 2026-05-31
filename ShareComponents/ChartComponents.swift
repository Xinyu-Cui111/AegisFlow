import SwiftUI
import Charts

// MARK: - 周趋势折线图 (matches Android's weekly trend line chart)
struct WeeklyTrendLineChart: View {
    let data: [(day: String, value: Double)]
    let color: Color
    let unit: String
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.grayDark)
                Spacer()
                if let last = data.last {
                    Text("\(Int(last.value)) \(unit)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(color)
                }
            }
            
            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    LineMark(
                        x: .value("Day", item.day),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(color.gradient)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    
                    AreaMark(
                        x: .value("Day", item.day),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Day", item.day),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(color)
                    .symbolSize(index == data.count - 1 ? 60 : 30)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.grayLight)
                    AxisValueLabel()
                        .foregroundStyle(Color.grayMid)
                        .font(.system(size: 10))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(Color.grayMid)
                        .font(.system(size: 10))
                }
            }
            .frame(height: 180)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 首页「健康趋势」折线图（配置与 `WeeklyTrendLineChart` 一致；外层由 `aegisCardStyle` 包裹）

/// 使用与健康数据页相同的 `LineMark` + `AreaMark` + `PointMark`、Catmull-Rom 插值与坐标轴样式。
struct DashboardTrendLineChart: View {
    let data: [StepDataPoint]
    let color: Color
    let unit: String

    private var series: [(day: String, value: Double)] {
        if data.isEmpty {
            return [
                ("一", 0), ("二", 0), ("三", 0), ("四", 0), ("五", 0), ("六", 0), ("日", 0),
            ]
        }
        return data.map { ($0.day, Double($0.value)) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Spacer(minLength: 0)
                if let last = data.last {
                    Text("\(last.value) \(unit)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(color)
                } else if let last = series.last {
                    Text("\(Int(last.value)) \(unit)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(color)
                }
            }

            Chart {
                ForEach(Array(series.enumerated()), id: \.offset) { index, item in
                    LineMark(
                        x: .value("Day", item.day),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(color.gradient)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    AreaMark(
                        x: .value("Day", item.day),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Day", item.day),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(color)
                    .symbolSize(index == series.count - 1 ? 60 : 30)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.grayLight)
                    AxisValueLabel()
                        .foregroundStyle(Color.grayMid)
                        .font(.system(size: 10))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.grayMid)
                        .font(.system(size: 10))
                }
            }
            .frame(height: 176)
        }
    }
}

// MARK: - 环形进度指示器 (matches Android's circular progress)
struct RingProgressView: View {
    let progress: Double
    let color: Color
    let icon: String
    let title: String
    let currentValue: String
    let goalValue: String
    var lineWidth: CGFloat = 10
    var size: CGFloat = 100
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: lineWidth)
                    .frame(width: size, height: size)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.7)]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)
                
                // Center content
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: size * 0.2))
                        .foregroundColor(color)
                    
                    Text(currentValue)
                        .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                        .foregroundColor(.grayDark)
                }
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.grayDark)
                
                Text(goalValue)
                    .font(.system(size: 10))
                    .foregroundColor(.grayMid)
            }
        }
    }
}

// MARK: - 多环进度组合 (matches Android's goal rings row)
struct GoalRingsRow: View {
    let steps: Double
    let stepsGoal: Double
    let water: Double
    let waterGoal: Double
    let calories: Double
    let caloriesGoal: Double
    let sleep: Double
    let sleepGoal: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日目标")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.grayDark)
            
            HStack(spacing: 0) {
                RingProgressView(
                    progress: stepsGoal > 0 ? steps / stepsGoal : 0,
                    color: .sageBright,
                    icon: "figure.walk",
                    title: "步数",
                    currentValue: "\(Int(steps))",
                    goalValue: "/ \(Int(stepsGoal))",
                    lineWidth: 8,
                    size: 72
                )
                .frame(maxWidth: .infinity)
                
                RingProgressView(
                    progress: waterGoal > 0 ? water / waterGoal : 0,
                    color: .androidBlue,
                    icon: "drop.fill",
                    title: "饮水",
                    currentValue: "\(Int(water))",
                    goalValue: "/ \(Int(waterGoal))ml",
                    lineWidth: 8,
                    size: 72
                )
                .frame(maxWidth: .infinity)
                
                RingProgressView(
                    progress: caloriesGoal > 0 ? calories / caloriesGoal : 0,
                    color: .orangeWarm,
                    icon: "flame.fill",
                    title: "卡路里",
                    currentValue: "\(Int(calories))",
                    goalValue: "/ \(Int(caloriesGoal))",
                    lineWidth: 8,
                    size: 72
                )
                .frame(maxWidth: .infinity)
                
                RingProgressView(
                    progress: sleepGoal > 0 ? sleep / sleepGoal : 0,
                    color: .purpleSoft,
                    icon: "moon.fill",
                    title: "睡眠",
                    currentValue: String(format: "%.1fh", sleep / 60),
                    goalValue: "/ \(Int(sleepGoal / 60))h",
                    lineWidth: 8,
                    size: 72
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 柱状图 (matches Android's bar chart for nutrition)
struct NutritionBarChart: View {
    let data: [(label: String, value: Double, goal: Double, color: Color)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("营养摄入")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.grayDark)
            
            VStack(spacing: 14) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                    NutritionBarRow(
                        label: item.label,
                        value: item.value,
                        goal: item.goal,
                        color: item.color
                    )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct NutritionBarRow: View {
    let label: String
    let value: Double
    let goal: Double
    let color: Color
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.grayDark)
                Spacer()
                Text("\(Int(value)) / \(Int(goal))")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.grayMid)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.15))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * progress), height: 8)
                        .animation(.spring(response: 0.6), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - 迷你周柱状图 (for dashboard inline use)
struct MiniWeekBarChart: View {
    let data: [(day: String, value: Double)]
    let color: Color
    let maxValue: Double?
    
    private var effectiveMax: Double {
        maxValue ?? (data.map(\.value).max() ?? 1)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(index == data.count - 1 ? color : color.opacity(0.4))
                        .frame(width: 20, height: max(4, CGFloat(item.value / effectiveMax) * 60))
                        .animation(.spring(response: 0.5).delay(Double(index) * 0.05), value: item.value)
                    
                    Text(item.day)
                        .font(.system(size: 9))
                        .foregroundColor(.grayMid)
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Line Chart") {
    WeeklyTrendLineChart(
        data: [("Mon", 8500), ("Tue", 12000), ("Wed", 6800), ("Thu", 9200), ("Fri", 10500), ("Sat", 7800), ("Sun", 6789)],
        color: .sageBright,
        unit: "步",
        title: "本周步数"
    )
    .padding()
}

#Preview("Ring Progress") {
    GoalRingsRow(
        steps: 6789, stepsGoal: 10000,
        water: 1200, waterGoal: 3000,
        calories: 450, caloriesGoal: 2000,
        sleep: 420, sleepGoal: 480
    )
    .padding()
}
