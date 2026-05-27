import SwiftUI

struct HealthGoals: View {
    @Environment(\.dismiss) var dismiss
    
    // MARK: - 状态数据 (保留原始逻辑)
    @State private var steps: Float = 11678
    @State private var water: Float = 2000
    @State private var sleep: Float = 8.0
    @State private var calories: Float = 2000
    @State private var sportTime: Float = 24
    
    var body: some View {
        ZStack {
            // 全局灵动光影背景
            AegisDynamicBackground()
            
            VStack(spacing: 0) {
                // 顶部毛玻璃导航栏，具有更好的悬浮感
                SubPageHeader(title: "健康目标") { dismiss() }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // 2. 引导提示卡片 (更精妙的渐变与图层)
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.androidGreen.opacity(0.12))
                                    .frame(width: 48, height: 48)
                                    .shadow(color: Color.androidGreen.opacity(0.2), radius: 6, x: 0, y: 3)
                                
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.androidGreen)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("健康目标")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary.opacity(0.85))
                                Text("滑动设定您的每日专属运动与健康指标")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .aegisCardStyle(padding: 20)
                        .padding(.horizontal, 16)
                        .padding(.top, 16) // 为上端增加透气感
                        
                        // 3. 核心目标列表 (无缝光影卡片承载各项调节进度)
                        VStack(spacing: 6) {
                            GoalAdjustableRow(icon: "figure.walk", title: "每日步数", value: "\(Int(steps)) 步", color: .androidGreen, val: $steps, range: 2000...20000)
                            Divider().background(Color.black.opacity(0.04)).padding(.vertical, 6)
                            
                            GoalAdjustableRow(icon: "drop.fill", title: "每日饮水", value: "\(Int(water)) ml", color: .androidBlue, val: $water, range: 500...4000)
                            Divider().background(Color.black.opacity(0.04)).padding(.vertical, 6)
                            
                            GoalAdjustableRow(icon: "moon.stars.fill", title: "每日睡眠", value: String(format: "%.1f 小时", sleep), color: .androidPurple, val: $sleep, range: 4...12)
                            Divider().background(Color.black.opacity(0.04)).padding(.vertical, 6)
                            
                            GoalAdjustableRow(icon: "flame.fill", title: "每日消耗卡路里", value: "\(Int(calories)) kcal", color: .androidOrange, val: $calories, range: 1000...5000)
                            Divider().background(Color.black.opacity(0.04)).padding(.vertical, 6)
                            
                            GoalAdjustableRow(icon: "dumbbell.fill", title: "每日运动时间", value: "\(Int(sportTime)) 分钟", color: .androidGreen, val: $sportTime, range: 10...180)
                        }
                        .aegisCardStyle(padding: 24) // 更宽广的包覆留白
                        .padding(.horizontal, 16)
                        
                        // 4. 底部权威建议卡片
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: "lightbulb.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange.opacity(0.85))
                                .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                                
                            Text("建议：成年人每日建议保证 7-9 小时睡眠，并维持规律的运动。循序渐进的调整更利于您的身体适应。")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                                .lineSpacing(5) // Apple 标准阅读舒适行距
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(.regularMaterial) // 高级毛玻璃材质
                        )
                        .overlay( // 轻微发光描边切割
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.all, edges: .top) // 渗透至刘海区，让动态背景延伸，毛玻璃导航栏截断
    }
}
