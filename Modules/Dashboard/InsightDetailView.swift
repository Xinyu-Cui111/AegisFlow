import SwiftUI

struct InsightDetailView: View {
    let category: String
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var showStatistics = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header with gradient
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [colorForCategory(category), colorForCategory(category).opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 220)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(emojiForCategory(category))
                            .font(.system(size: 40))

                        Text(title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text(category)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                    }
                    .padding(24)
                }

                VStack(alignment: .leading, spacing: 24) {
                    // Summary
                    VStack(alignment: .leading, spacing: 8) {
                        Text("概述")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.grayDark)

                        Text(summaryForCategory(category))
                            .font(.system(size: 15))
                            .foregroundColor(.grayMid)
                            .lineSpacing(6)
                    }

                    Divider()

                    // Recommendations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("建议")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.grayDark)

                        ForEach(recommendationsForCategory(category), id: \.self) { rec in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.sageBright)
                                    .font(.system(size: 16))

                                Text(rec)
                                    .font(.system(size: 14))
                                    .foregroundColor(.grayDark)
                                    .lineSpacing(4)
                            }
                        }
                    }

                    Divider()

                    Button(action: { showStatistics = true }) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("查看详细数据")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.sageBright)
                        .cornerRadius(16)
                    }
                }
                .padding(24)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $showStatistics) {
            StatisticsScreen()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
    }

    private func colorForCategory(_ cat: String) -> Color {
        switch cat {
        case "运动": return .sageBright
        case "饮食", "营养": return .orangeWarm
        case "睡眠": return .purpleSoft
        case "心理", "压力": return .androidBlue
        default: return .tealDeep
        }
    }

    private func emojiForCategory(_ cat: String) -> String {
        switch cat {
        case "运动": return "🏃"
        case "饮食", "营养": return "🥗"
        case "睡眠": return "😴"
        case "心理", "压力": return "🧘"
        default: return "✨"
        }
    }

    private func summaryForCategory(_ cat: String) -> String {
        switch cat {
        case "运动":
            return "根据您近期的运动数据分析，您的运动频率和强度整体良好。建议适当增加有氧运动比例，以更好地促进心肺功能。"
        case "饮食", "营养":
            return "您的饮食结构基本合理，但蛋白质摄入略有不足。建议适当增加优质蛋白的摄入量，如鸡胸肉、鱼类和豆制品。"
        case "睡眠":
            return "您近一周的平均睡眠时长为7.2小时，睡眠质量评分中等。入睡时间波动较大，建议建立规律的作息时间。"
        default:
            return "基于您的健康数据综合分析，当前整体状况良好。持续保持健康的生活习惯，关注各项指标的变化趋势。"
        }
    }

    private func recommendationsForCategory(_ cat: String) -> [String] {
        switch cat {
        case "运动":
            return ["每周保持3-5次中等强度运动", "交替进行有氧和力量训练", "运动前后注意充分热身和拉伸"]
        case "饮食", "营养":
            return ["增加优质蛋白摄入", "每日蔬果不少于5份", "控制精制糖和加工食品"]
        case "睡眠":
            return ["固定就寝和起床时间", "睡前1小时减少屏幕使用", "保持卧室温度在18-22度"]
        default:
            return ["保持规律作息", "均衡饮食营养", "适度运动锻炼", "定期检查身体指标"]
        }
    }
}
