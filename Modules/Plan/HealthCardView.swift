import SwiftUI

struct HealthCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 主标题
            Text("个性化健康计划")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // 副标题 / 描述文本
            Text("由 AI 为你量身定制，涵盖运动、习惯与微锻炼")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                // 调整行间距以匹配原本的宽松感
                .lineSpacing(6) 
        }
        // 保持左对齐，并让内容撑开宽度
        .frame(maxWidth: .infinity, alignment: .leading)
        // 内边距
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
        // 核心：设置渐变背景与圆角
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.62, green: 0.88, blue: 0.00), // 左侧鲜艳黄绿
                    Color(red: 0.24, green: 0.64, blue: 0.46), // 中间过渡绿
                    Color(red: 0.00, green: 0.38, blue: 0.39)  // 右侧深青色
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        // 圆角效果
        .cornerRadius(36)
        // 稍微在外层加一点边距，避免贴实屏幕边缘（非白色外圈）
        .padding(.horizontal, 16)
    }
}

struct HealthCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            HealthCardView()
        }
    }
}
