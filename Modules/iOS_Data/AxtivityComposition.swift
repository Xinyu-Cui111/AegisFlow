import SwiftUI

struct ActivityComposition: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("活动构成")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black.opacity(0.8))
            
            HStack(spacing: 30) {
                // --- 左侧彩色圆环 (仅增加段数，逻辑保持 trim 比例) ---
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 14)
                    
                    // 1. 步行 (40%) - 显式调用 Color 解决报错
                    Circle()
                        .trim(from: 0, to: 0.4)
                        .stroke(Color.androidGreen, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    
                    // 2. 跑步 (20%)
                    Circle()
                        .trim(from: 0.4, to: 0.6)
                        .stroke(Color.androidOrange, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    
                    // 3. 骑行 (15%)
                    Circle()
                        .trim(from: 0.6, to: 0.75)
                        .stroke(Color.androidBlue, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    
                    // 4. 力量 (15%)
                    Circle()
                        .trim(from: 0.75, to: 0.9)
                        .stroke(Color.androidPurple, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    
                    // 5. 瑜伽 (10%)
                    Circle()
                        .trim(from: 0.9, to: 1.0)
                        .stroke(Color.cyan, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                }
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 3)
                
                
                VStack(alignment: .leading, spacing: 10) {
                    CompositionRow(color: Color.androidGreen, name: "步行", percent: "40%")
                    CompositionRow(color: Color.androidOrange, name: "跑步", percent: "20%")
                    CompositionRow(color: Color.androidBlue, name: "骑行", percent: "15%")
                    CompositionRow(color: Color.androidPurple, name: "力量", percent: "15%")
                    CompositionRow(color: Color.cyan, name: "瑜伽", percent: "10%")
                }
            }
            .padding(.vertical, 5)
        }
       
        .aegisCardStyle()
        .padding(.horizontal, 24)
    }
}

// MARK: - 子组件 (保持原样)
struct CompositionRow: View {
    let color: Color
    let name: String
    let percent: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(name)
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.8))
            
            Spacer()
            
            Text(percent)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black.opacity(0.7))
        }
    }
}
