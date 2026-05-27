import SwiftUI

/// **Aegis 小盾灵（Flow Spirit）** — 程序化矢量吉祥物：胶囊躯体 + 圆形头部叠放，几何清晰、任意缩放锐利；配色沿用 `tealDeep` / `sageBright`，与 App 主品牌一致。
struct AegisFlowMascotGlyph: View {
    /// 与桌宠 idle 呼吸联动（轻微垂直位移）
    var breatheOffset: CGFloat = 0
    /// 眼睛相对于默认位置的偏移（用于跟随指针）
    var eyeOffset: CGSize = .zero

    private let teal = Color.tealDeep
    private let sage = Color.sageBright

    var body: some View {
        ZStack(alignment: .top) {
            // 环境柔光
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [sage.opacity(0.4), teal.opacity(0.12), Color.clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: 26
                    )
                )
                .frame(width: 40, height: 36)
                .offset(y: 6)
                .blur(radius: 2)

            // 躯体：纵向胶囊 — 暗示「流动的水滴 / 体态」
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [teal.opacity(0.95), sage],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 22, height: 26)
                .overlay {
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.12),
                                    Color.black.opacity(0.05),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.9
                        )
                }
                .offset(y: 8)

            // 头部：正圆 — Memoji 式简洁亲和
            Circle()
                .fill(
                    LinearGradient(
                        colors: [teal, sage.opacity(0.88)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 24, height: 24)
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.55), Color.white.opacity(0.15)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.85
                        )
                }
                .overlay {
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.38), Color.white.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 14, height: 8)
                        .offset(x: -3, y: -5)
                        .blur(radius: 0.4)
                }
                .offset(y: -2 + breatheOffset * 0.2)

            // 五官（眼睛可动）
            EyesView(breatheOffset: breatheOffset, eyeOffset: eyeOffset)

            // 小叶角标 — Wellness 隐喻，不抢主体
            Image(systemName: "leaf.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [sage, teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(-18))
                .offset(x: 15, y: 18)
                .shadow(color: teal.opacity(0.35), radius: 1, x: 0, y: 1)
        }
        .frame(width: 36, height: 40)
        .accessibilityHidden(true)
    }
}

private struct SmileArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY + 1)
        )
        return p
    }
}

private struct EyesView: View {
    var breatheOffset: CGFloat = 0
    var eyeOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 6) {
                eyeMark
                eyeMark
            }

            SmileArc()
                .stroke(Color.white.opacity(0.82), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                .frame(width: 12, height: 6)
        }
        .offset(y: 2 + breatheOffset * 0.2)
    }

    private var eyeMark: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.96),
                        Color.tealDeep.opacity(0.18),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 4.8, height: 7.2)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.4)
            )
            .offset(
                x: min(max(eyeOffset.width, -1.2), 1.2),
                y: min(max(eyeOffset.height, -1.2), 1.2)
            )
    }
}
