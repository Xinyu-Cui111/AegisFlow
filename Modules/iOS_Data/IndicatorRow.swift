import SwiftUI

struct IndicatorRow: View {
    // 注入全局环境对象，获取实时健康数据
    @EnvironmentObject var manager: DataManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 模块标题：今日详情
            Text("今日详情")
                .font(.system(size: 18, weight: .bold))
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // 1. 步数卡片
                    IndicatorCard(
                        icon: "figure.walk",
                        title: "步数",
                        value: "\(manager.dailySteps)",
                        unit: "步",
                        target: Double(manager.dailyStepsGoal),
                        current: Double(manager.dailySteps),
                        color: .androidGreen
                    )

                    // 2. 消耗热量卡片
                    IndicatorCard(
                        icon: "flame.fill",
                        title: "消耗热量",
                        value: "\(manager.caloriesBurned)",
                        unit: "千卡",
                        target: Double(max(manager.caloriesGoal, 1)),
                        current: Double(manager.caloriesBurned),
                        color: .androidOrange
                    )

                    // 3. 饮水量卡片
                    IndicatorCard(
                        icon: "drop.fill",
                        title: "饮水",
                        value: String(format: "%.1f", Double(manager.waterIntakeMl) / 1000.0),
                        unit: "升",
                        target: Double(manager.waterGoalMl) / 1000.0,
                        current: Double(manager.waterIntakeMl) / 1000.0,
                        color: .androidBlue
                    )

                    // 4. 睡眠卡片
                    IndicatorCard(
                        icon: "moon.stars.fill",
                        title: "睡眠",
                        value: String(format: "%.1f", Double(manager.sleepMinutes) / 60.0),
                        unit: "小时",
                        target: Double(manager.sleepGoalMinutes) / 60.0,
                        current: Double(manager.sleepMinutes) / 60.0,
                        color: .purple
                    )
                }
                // 这里的 Padding 确保首尾卡片不会紧贴屏幕边缘，且保留阴影空间
                .padding(.horizontal, 24)
                .padding(.bottom, 10)
            }
        }
    }
}

// MARK: - 预览
struct IndicatorRow_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(hex: "#F7F9F2").ignoresSafeArea()
            IndicatorRow()
                .environmentObject(DataManager())
        }
    }
}
