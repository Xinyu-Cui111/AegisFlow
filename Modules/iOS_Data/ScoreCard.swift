import SwiftUI

struct ScoreCard: View {
    let score: Int
    @State private var animatedScore: Int = 0 // 用于数字和环形增长动效
    
    var body: some View {
        HStack {
            // 优化间距：Apple Health 常用紧凑但清晰的间距结构 (8pt 行距)
            VStack(alignment: .leading, spacing: 8) {
                Text("今日健康评分")
                    // 活用 Dynamic Type 建立层级：使用 headline 替代固定字号
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                    // Subtle text shadow for depth
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) { // 对齐 Baseline, 缩小间距提升聚合感
                    Text("\(animatedScore)") // 动效驱动的分数
                        // 活用系统级大标题：保留圆体增加亲和力
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .modifier(ScoreNumericTransition())
                    Text("/ 100")
                        // 活用 Dynamic Type 作为次级信息
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                }
                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)
                
                Spacer().frame(height: 4) // 给状态标签增加呼吸感
                
                // 状态标签优化材质，App Store 级毛玻璃嵌套
                Text(score < 60 ? "今天需要多关注健康" : "状态非常棒，继续保持")
                    // 活用 footnote 脚注字号
                    .font(.footnote)
                    .fontWeight(.medium)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            Rectangle().fill(.ultraThinMaterial)
                            Color.white.opacity(0.15) // 反射光效果
                        }
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule() // 边缘高光层
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    )
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            Spacer()
            
            // 右侧环形进度 (动态渲染，高级阴影质感)
            ZStack {
                // 背景环：增加内阴影拟物感
                Circle()
                    .stroke(Color.black.opacity(0.15), lineWidth: 12) // 槽底阴影
                
                // 外层环境光环绕 (Glow effect)
                Circle()
                    .trim(from: 0, to: CGFloat(animatedScore) / 100.0)
                    .stroke(
                        Color.white.opacity(0.4),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 8) // 荧光散射效果
                
                // 核心进度环 (加粗和分层阴影)
                Circle()
                    .trim(from: 0, to: CGFloat(animatedScore) / 100.0)
                    .stroke(
                        Color.white,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    // .shadow 在路径边缘制造3D隆起感
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 2, y: 2)
                
                // 中心文字区
                VStack(spacing: -3) {
                    Text("\(animatedScore)")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .modifier(ScoreNumericTransition())
                    Text("分")
                        .font(.system(size: 11, weight: .medium))
                        .opacity(0.85)
                }
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .frame(width: 96, height: 96)
        }
        .padding(20) // 对标 Apple Health 的标准卡片 20pt 内推属性
        .background(
            // 高端渐变，用 AngularGradient 结合 LinearGradient 增加光斑效果
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#8FD52A"), Color(hex: "#228570")], // 提亮颜色
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                // 顶部聚光灯光斑
                RadialGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.25), Color.clear]),
                    center: .topLeading,
                    startRadius: 10,
                    endRadius: 150
                )
            }
        )
        // 关键改动：形状与苹果级复合阴影系统 (更新为更精致的 24 大圆角)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .white.opacity(0.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        // 自然色相阴影叠层
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .shadow(color: Color(hex: "#228570").opacity(0.25), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 20) // 两侧统一为原生的 20pt 留白
        .aegisPressableCard() // 极微触发：点按回馈至 0.98，并附带震感
        .onAppear {
            // 触发高级物理弹簧动效增加进度
            withAnimation(.spring(response: 1.5, dampingFraction: 0.75, blendDuration: 0)) {
                animatedScore = score
            }
        }
    }
}

/// 数字变化时使用不透明度过渡（兼容 iOS 16+，不依赖 numericText）。
private struct ScoreNumericTransition: ViewModifier {
    func body(content: Content) -> some View {
        content.contentTransition(.opacity)
    }
}

// MARK: - 预览
struct ScoreCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.androidBg.ignoresSafeArea()
            ScoreCard(score: 85)
        }
    }
}
