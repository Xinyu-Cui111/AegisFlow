import SwiftUI

struct AnalysisView: View {
    @State private var selectedTab = "步数"
    let tabs = ["步数", "饮水", "热量"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题行
            HStack {
                Text("趋势分析")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
                Spacer()
                Text("近7日")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            // 切换开关 (层级优化：使用 androidElementBg 作为底座)
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
            .background(Color.androidElementBg)  // 重点：改为装饰底色
            .cornerRadius(14)

            // 模拟图表
            chartContent
        }
        // 应用统一的精美卡片样式
        .aegisCardStyle()
        .padding(.horizontal, 24)
    }

    private var chartContent: some View {
        VStack(spacing: 15) {
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(0..<7) { i in
                    VStack(spacing: 12) {
                        // 柱状图：优化圆角和透明度
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        chartColor.opacity(i == 4 ? 1 : 0.3),
                                        chartColor.opacity(i == 4 ? 0.7 : 0.1),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 22, height: CGFloat.random(in: 40...100))

                        Text(["一", "二", "三", "四", "五", "六", "日"][i])
                            .font(.system(size: 11))
                            .foregroundColor(i == 4 ? .black : .gray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 130)
            .padding(.top, 10)
        }
    }

    // 根据选择返回颜色
    private var chartColor: Color {
        switch selectedTab {
        case "步数": return .androidGreen
        case "饮水": return .androidBlue
        default: return .androidOrange
        }
    }
}
