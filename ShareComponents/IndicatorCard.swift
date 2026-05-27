import SwiftUI

struct IndicatorCard: View {
    // 保持原有属性不变
    let icon: String
    let title: String
    let value: String
    let unit: String
    let target: Double
    let current: Double
    let color: Color
    
    // 进度计算逻辑保持不变
    private var progress: CGFloat {
        let ratio = current / (target > 0 ? target : 1.0)
        return CGFloat(min(max(ratio, 0), 1.0))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // --- 第一行：图标 + 百分比 ---
            HStack {
                // 圆形背景图标：底色改用装饰色
                ZStack {
                    Circle()
                        .fill(Color.androidElementBg) // 使用统一的装饰底色
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                // 右上角百分比：胶囊样式微调
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.08)) // 稍微减淡一点，更具呼吸感
                    .cornerRadius(6)
            }
            
            // --- 第二行：数值 + 单位 ---
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                    Text(unit)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            // --- 第三行：底部进度条 ---
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // 背景轨道：改用装饰底色
                    Capsule()
                        .fill(Color.androidElementBg)
                        .frame(height: 5)
                    
                    // 实际进度
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 5)
                        .shadow(color: color.opacity(0.2), radius: 2, x: 0, y: 1)
                }
            }
            .frame(height: 5)
        }
        .frame(width: 115) // 保持固定宽度
        // --- 核心改动：统一应用淡青柠卡片样式 ---
        .aegisCardStyle()
    }
}

// MARK: - 预览
struct IndicatorCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // 模拟真实背景色
            Color.androidBg.ignoresSafeArea()
            
            HStack(spacing: 15) {
                IndicatorCard(icon: "figure.walk", title: "步数", value: "8540", unit: "步", target: 10000, current: 8540, color: .androidGreen)
                IndicatorCard(icon: "drop.fill", title: "饮水", value: "1.2", unit: "L", target: 2.0, current: 1.2, color: .androidBlue)
            }
            .padding()
        }
    }
}
