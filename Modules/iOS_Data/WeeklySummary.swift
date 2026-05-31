import SwiftUI

struct WeeklySummaryView: View {
    // 1. 保留原有数据注入逻辑，不动功能
    @EnvironmentObject var manager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // 标题行
            HStack {
                Text("周总结")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
                Spacer()
                // 增加一个小装饰图标，增加精致感
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.4))
            }
            
            // 数据行：使用 0 spacing 配合 maxWidth: .infinity 实现完美等分
            HStack(alignment: .top, spacing: 0) {
                SummaryCircleItem(
                    value: "\(manager.dailySteps * 7)",
                    label: "总步数",
                    color: .androidGreen
                )
                
                SummaryCircleItem(
                    value: "\(manager.dailySteps)",
                    label: "日均步数",
                    color: .androidBlue
                )
                
                SummaryCircleItem(
                    value: String(format: "%.1fL", Double(manager.waterIntakeMl) / 1000.0 * 7.0),
                    label: "总饮水",
                    color: .androidBlue // 建议统一使用定义的 androidBlue
                )
                
                SummaryCircleItem(
                    value: "0/7",
                    label: "达标天数",
                    color: .androidOrange
                )
            }
        }
        // 2. 统一应用精美淡青柠卡片样式
        .aegisCardStyle()
        .padding(.horizontal, 24)
    }
}

// MARK: - 子组件：单个统计圆圈
struct SummaryCircleItem: View {
    let value: String
    let label: String
    let color: Color // 传入主色调
    
    var body: some View {
        VStack(spacing: 12) {
            // 顶部圆圈：使用统一的 androidElementBg 营造“微陷”质感
            ZStack {
                Circle()
                    .fill(Color.androidElementBg)
                    .frame(width: 52, height: 52)
                
                // 简略值 (如 50k, 1.2L)
                Text(value.prefix(4))
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(color)
            }
            
            // 下方详细文字
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 预览
struct WeeklySummaryView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.androidBg.ignoresSafeArea()
            WeeklySummaryView()
                .environmentObject(DataManager())
        }
    }
}
