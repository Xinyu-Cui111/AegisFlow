import SwiftUI

/*
 设计导出建议（接近 QQ 桌宠「只有小人」）：
 - 画布：按角色 **实际轮廓** 裁紧，四周仅留约 4～12pt 透明边（@1x 基准；@3x 可按比例放大）。
 - 格式：**PNG**，保留 **Alpha**；勿整张横屏/竖屏大片留白再叠小人。
 - 尺寸：不必正方形；最长边建议 **512～1024px** 即可（程序内会缩放到约 84pt）。
 - 替换资源：`AegisAssets.xcassets` → `DeskPetMascot`，勿改名。
 - 代码会在运行时再做一次透明边裁剪（`aegisTrimmingTransparentEdges`），但 **源文件裁紧** 观感最好。
 - 批量抠底/裁边（仅 Mac 终端）：仓库根目录 `Scripts/trim_png_alpha.swift`，勿放进 `Modules/`（会被 Xcode 当作 App 源码编译）。
 */

/// 全局桌宠：IP **本体轮廓**悬浮（透明底），不做圆球外壳；阴影只做脚下接触影，避免「一整块矩形浮层」观感。
import UIKit

// MARK: - HoverDetector
// 将 UIHoverGestureRecognizer 封装为 UIViewRepresentable，用于捕获指针在指定视图内的位置（iPadOS pointer / Catalyst）

// 简单眼睛覆盖层（用于位图覆盖）
struct DeskPetFloatingOverlay: View {
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject private var data = DataManager.shared

    /// 原始桌宠素材（运行时裁掉透明边），基于 `DataManager` 的选中名称动态加载
    // 用统一预览组件 DeskPetOrbPreview

    /// 圆形底座直径（微调为更紧凑尺寸）
    private let baseDiameter: CGFloat = 104

    @State private var center: CGPoint = CGPoint(
        x: UIScreen.main.bounds.width - 52,
        y: UIScreen.main.bounds.height * 0.58
    )
    @State private var dragTranslation: CGSize = .zero
    @State private var isDragging = false
    @State private var showBubble = false
    @State private var bubbleText = ""
    @State private var bubbleOffset: CGSize = .zero
    @State private var animateIdle = false

    private var displayPosition: CGPoint {
        CGPoint(x: center.x + dragTranslation.width, y: center.y + dragTranslation.height)
    }

    private var petCollisionRadius: CGFloat {
        baseDiameter / 2 + 16
    }

    private let greetings = [
        "今天记得多喝水哦 💧",
        "该起来活动一下了 🏃",
        "保持好心情 😊",
        "注意休息眼睛 👀",
        "今天运动了吗？💪",
        "深呼吸放松一下 🧘",
        "别忘了吃早餐 🍳",
    ]

    var body: some View {
        Group {
            if data.deskPetEnabled {
                ZStack {
                    if showBubble {
                        bubbleLayer
                    }

                    petOrb
                        .position(displayPosition)
                        .gesture(dragGesture)
                        .onTapGesture { showRandomBubble() }
                }
            }
        }
        .allowsHitTesting(true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("桌宠助手")
        .accessibilityHint("拖移可调整位置，轻点查看提示")
        .onAppear {
            // 初始化位置来自全局状态
            center = CGPoint(x: data.deskPetPositionX, y: data.deskPetPositionY)

            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                animateIdle = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { showRandomBubble() }
        }
        .onChange(of: data.deskPetPositionX) { newX in
            center.x = newX
        }
        .onChange(of: data.deskPetPositionY) { newY in
            center.y = newY
        }
        .onChange(of: data.deskPetEnabled) { _ in
            // no-op: view body will update based on `data.deskPetEnabled`
        }
    }

    private var bubbleLayer: some View {
        VStack(spacing: 0) {
            Text(bubbleText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    Color.white.opacity(colorScheme == .dark ? 0.12 : 0.55),
                                    lineWidth: 1)
                        )
                }
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)

            PetBubbleTriangle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.18) : Color.white.opacity(0.92))
                .frame(width: 14, height: 9)
                .overlay {
                    PetBubbleTriangle()
                        .stroke(
                            Color.white.opacity(colorScheme == .dark ? 0.12 : 0.5), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .position(
            x: displayPosition.x + bubbleOffset.width,
            y: displayPosition.y + bubbleOffset.height
        )
        .allowsHitTesting(false)
        .transition(.scale(scale: 0.92).combined(with: .opacity))
    }

    private var petOrb: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.16 : 0.82),
                            Color.white.opacity(colorScheme == .dark ? 0.09 : 0.58),
                            Color.tealDeep.opacity(colorScheme == .dark ? 0.24 : 0.12),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.56), lineWidth: 1)
                )
                .shadow(color: .black.opacity(isDragging ? 0.20 : 0.14), radius: 18, x: 0, y: 10)

            Ellipse()
                .fill(Color.black.opacity(isDragging ? 0.16 : 0.11))
                .frame(width: baseDiameter * 0.52, height: baseDiameter * 0.10)
                .blur(radius: isDragging ? 7 : 5)
                .offset(y: baseDiameter * 0.33)
                .allowsHitTesting(false)

            petMascotCore

            hoverDetectorView(baseDiameter)
                .frame(width: baseDiameter, height: baseDiameter)
                .allowsHitTesting(true)
        }
        .frame(width: baseDiameter, height: baseDiameter)
        .fixedSize()
        .contentShape(Circle())
        .scaleEffect(isDragging ? 1.04 : (animateIdle ? 1.02 : 1.0))
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: isDragging)
        .animation(.easeInOut(duration: 2.6), value: animateIdle)
    }

    @ViewBuilder
    private var petMascotCore: some View {
        let bob = animateIdle ? CGFloat(-2.5) : CGFloat(2.5)
        DeskPetOrbPreview(mascotName: data.deskPetMascotName, diameter: baseDiameter * 0.78)
            .offset(y: bob * 0.16)
            .accessibilityHidden(true)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                isDragging = true
                dragTranslation = value.translation
            }
            .onEnded { value in
                var next = CGPoint(
                    x: center.x + value.translation.width,
                    y: center.y + value.translation.height
                )
                let w = UIScreen.main.bounds.width
                let h = UIScreen.main.bounds.height
                let half = petCollisionRadius
                next.x = min(max(next.x, half), w - half)
                next.y = min(max(next.y, 120), h - 160)

                withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                    if next.x < w / 2 {
                        next.x = half
                    } else {
                        next.x = w - half
                    }
                    center = next
                    dragTranslation = .zero
                    isDragging = false
                }
                // 持久化位置到全局状态
                data.deskPetPositionX = center.x
                data.deskPetPositionY = center.y
                data.saveSettings()
            }
    }

    // 把 Hover 探测器限定在宠物周围的圆域内，使用 UIHoverGestureRecognizer 捕获鼠标/指针位置
    private func hoverDetectorView(_ radius: CGFloat) -> some View {
        HoverDetector { pointInView, hovering in
            guard hovering, let p = pointInView else {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    showBubble = false
                }
                return
            }

            // 自动判断靠近屏幕边缘时气泡翻转
            let screenW = UIScreen.main.bounds.width
            let center = CGPoint(x: radius, y: radius)
            let globalX = displayPosition.x
            let horizontalSide: CGFloat = (globalX < screenW * 0.33) ? 1 : (globalX > screenW * 0.67) ? -1 : (p.x < center.x ? 1 : -1)
            let bubbleHorizontal = horizontalSide * (baseDiameter * 0.72)
            let bubbleVertical = -baseDiameter * 0.88
            if !showBubble {
                bubbleText = greetings.randomElement() ?? ""
            }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                showBubble = true
            }
            bubbleOffset = CGSize(width: bubbleHorizontal, height: bubbleVertical)
        }
    }

    private func showRandomBubble() {
        bubbleText = greetings.randomElement() ?? ""
        let screenW = UIScreen.main.bounds.width
        let side: CGFloat = (center.x < screenW * 0.33) ? 1 : (center.x > screenW * 0.67) ? -1 : (center.x < screenW / 2 ? 1 : -1)
        bubbleOffset = CGSize(width: side * (baseDiameter * 0.72), height: -baseDiameter * 0.88)
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) { showBubble = true }
        data.deskPetShowBubble = true
        data.saveSettings()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                showBubble = false
                data.deskPetShowBubble = false
                data.saveSettings()
            }
        }
    }
}
private struct PetBubbleTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
private struct HoverDetector: UIViewRepresentable {
    var onHover: (CGPoint?, Bool) -> Void

    func makeUIView(context: Context) -> UIView {
        let v = UIView(frame: .zero)
        v.backgroundColor = .clear
        let hover = UIHoverGestureRecognizer(
            target: context.coordinator, action: #selector(Coordinator.handle(_:)))
        v.addGestureRecognizer(hover)
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onHover: onHover) }

    class Coordinator: NSObject {
        var onHover: (CGPoint?, Bool) -> Void
        init(onHover: @escaping (CGPoint?, Bool) -> Void) { self.onHover = onHover }

        @objc func handle(_ g: UIHoverGestureRecognizer) {
            guard let view = g.view else { return }
            switch g.state {
            case .ended, .cancelled:
                onHover(nil, false)
            default:
                let loc = g.location(in: view)
                onHover(loc, true)
            }
        }
    }
}
