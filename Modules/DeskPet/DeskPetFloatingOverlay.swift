import SwiftUI

/*
 设计导出建议（接近 QQ 桌宠「只有小人」）：
 - 画布：按角色 **实际轮廓** 裁紧，四周仅留约 4～12pt 透明边（@1x 基准；@3x 可按比例放大）。
 - 格式：**PNG**，保留 **Alpha**；勿整张横屏/竖屏大片留白再叠小人。
 - 尺寸：不必正方形；最长边建议 **512～1024px** 即可（程序内会缩放到约 84pt）。
 - 替换资源：`AegisAssets.xcassets` → `DeskPetMascot`，勿改名。
 - 代码会在运行时再做一次透明边裁剪（`aegisTrimmingTransparentEdges`），但 **源文件裁紧** 观感最好。
 */

import UIKit

struct DeskPetFloatingOverlay: View {

    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject private var data = DataManager.shared

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
    @State private var showPopup = false

    private let popupSize = CGSize(width: 268, height: 356)

    private var displayPosition: CGPoint {
        CGPoint(x: center.x + dragTranslation.width, y: center.y + dragTranslation.height)
    }

    private var petCollisionRadius: CGFloat {
        baseDiameter / 2 + 16
    }

    private var popupAnchor: CGPoint {
        let screen = UIScreen.main.bounds
        let horizontalMargin: CGFloat = 12
        let verticalMargin: CGFloat = 18

        let placeRight = displayPosition.x < screen.midX
        let placeAbove = displayPosition.y > screen.midY

        let xCandidate = placeRight
            ? displayPosition.x + petCollisionRadius + popupSize.width / 2 + 6
            : displayPosition.x - petCollisionRadius - popupSize.width / 2 - 6

        let yCandidate = placeAbove
            ? displayPosition.y - petCollisionRadius - popupSize.height / 2 - 10
            : displayPosition.y + petCollisionRadius + popupSize.height / 2 + 10

        let x = min(max(xCandidate, popupSize.width / 2 + horizontalMargin), screen.width - popupSize.width / 2 - horizontalMargin)
        let y = min(max(yCandidate, popupSize.height / 2 + verticalMargin), screen.height - popupSize.height / 2 - verticalMargin)
        return CGPoint(x: x, y: y)
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
                    if showPopup {
                        PetPopupView(isPresented: $showPopup, anchor: popupAnchor)
                            .transition(.scale(scale: 0.95).combined(with: .opacity))
                            .zIndex(20)
                    }

                    if showBubble {
                        bubbleLayer
                    }

                    petOrb
                        .position(displayPosition)
                        .gesture(dragGesture)
                        .onTapGesture { showCompactPopup() }
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

    private func showCompactPopup() {
        showBubble = false
        bubbleText = ""
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            showPopup = true
        }
    }
}

struct PetPopupView: View {
    @Binding var isPresented: Bool
    let anchor: CGPoint
    @ObservedObject private var data = DataManager.shared

    @State private var currentTab = 0
    @State private var chatMessages: [PetPopupChatMessage] = [
        .init(text: "今天记得多喝水哦 💧", isUser: false),
        .init(text: "好的，我等下就去喝一杯。", isUser: true),
    ]
    @State private var chatInputText = ""
    @State private var calorieInputText = ""

    private let days = ["一", "二", "三", "四", "五", "六", "日"]

    private var currentThemeColor: Color {
        switch currentTab {
        case 0: return Color.green.opacity(0.8)
        case 1: return Color.green.opacity(0.8)
        default: return Color.green.opacity(0.8)
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack(spacing: 4) {
                        PetPopupTabButton(icon: "message.fill", isActive: currentTab == 0) { currentTab = 0 }
                        PetPopupTabButton(icon: "bag.fill", isActive: currentTab == 1) { currentTab = 1 }
                        PetPopupTabButton(icon: "waveform.path.ecg", isActive: currentTab == 2) { currentTab = 2 }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                    .padding(.top, 10)
                    .padding(.horizontal, 12)

                    Spacer(minLength: 8)

                    ZStack {
                        switch currentTab {
                        case 0:
                            CompactChatView(chatMessages: $chatMessages, inputText: $chatInputText) {
                                sendChatMessage()
                            }
                        case 1:
                            CompactFeedingView(
                                todayCalories: data.caloriesBurned,
                                targetCalories: data.caloriesGoal,
                                bodyStatus: feedingStatus,
                                inputCalorieString: $calorieInputText,
                                addCalories: addCalories,
                                resetCalories: resetCalories
                            )
                        default:
                            CompactPredictionView(
                                predictions: predictionItems
                            )
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, 4)
                }
                .frame(width: 280, height: 380)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
            }
            .position(anchor)
        }
    }

    private var feedingStatus: String {
        let ratio = data.caloriesGoal > 0 ? Double(data.caloriesBurned) / Double(data.caloriesGoal) : 0
        if ratio < 0.4 { return "偏轻" }
        if ratio < 0.8 { return "正常" }
        return "偏高"
    }

    private var predictionItems: [PetPopupPredictionItem] {
        [
            PetPopupPredictionItem(title: "步数趋势", level: data.stepProgress < 0.4 ? "偏低" : "正常", color: .green),
            PetPopupPredictionItem(title: "饮水趋势", level: data.waterProgress < 0.5 ? "需补充" : "正常", color: .cyan),
            PetPopupPredictionItem(title: "睡眠趋势", level: data.sleepProgress < 0.75 ? "建议加长" : "正常", color: .purple),
            PetPopupPredictionItem(title: "压力水平", level: data.stressLevel > 60 ? "偏高" : "平稳", color: .teal)
        ]
    }

    private func sendChatMessage() {
        let trimmed = chatInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        chatMessages.append(.init(text: trimmed, isUser: true))
        chatInputText = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            chatMessages.append(.init(text: "收到，我会记住这个提醒。", isUser: false))
        }
    }

    private func addCalories() {
        guard let value = Int(calorieInputText.trimmingCharacters(in: .whitespacesAndNewlines)), value > 0 else { return }
        data.caloriesBurned += value
        calorieInputText = ""
    }

    private func resetCalories() {
        data.caloriesBurned = 0
        calorieInputText = ""
    }
}

private struct PetPopupChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

private struct PetPopupPredictionItem: Identifiable {
    let id = UUID()
    let title: String
    let level: String
    let color: Color
}

private struct PetPopupTabButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isActive ? .white : .primary.opacity(0.6))
                .frame(width: 42, height: 26)
                .background(isActive ? Color.green.opacity(0.8) : Color.clear)
                .clipShape(Capsule())
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isActive)
    }
}

private struct CompactChatView: View {
    @Binding var chatMessages: [PetPopupChatMessage]
    @Binding var inputText: String
    let sendAction: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(chatMessages) { message in
                            HStack {
                                if message.isUser { Spacer() }

                                Text(message.text)
                                    .font(.system(size: 12.5, design: .rounded))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(message.isUser ? Color.green.opacity(0.8) : Color.black.opacity(0.05))
                                    .foregroundColor(message.isUser ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                                if !message.isUser { Spacer() }
                            }
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 2)
                }
                .onChange(of: chatMessages.count) { _ in
                    if let lastId = chatMessages.last?.id {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }

            HStack(spacing: 6) {
                TextField("跟桌宠聊聊...", text: $inputText)
                    .font(.system(size: 12.5))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.black.opacity(0.04))
                    .clipShape(Capsule())

                Button(action: sendAction) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(inputText.isEmpty ? Color.gray.opacity(0.4) : Color.green.opacity(0.8))
                        .clipShape(Circle())
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding([.horizontal, .bottom], 12)
        }
    }
}

private struct CompactFeedingView: View {
    let todayCalories: Int
    let targetCalories: Int
    let bodyStatus: String
    @Binding var inputCalorieString: String
    let addCalories: () -> Void
    let resetCalories: () -> Void

    private var progress: CGFloat {
        guard targetCalories > 0 else { return 0 }
        return min(CGFloat(todayCalories) / CGFloat(targetCalories), 1)
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.05), lineWidth: 10)
                    .frame(width: 102, height: 102)

                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(Color.green.opacity(0.8), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 102, height: 102)
                    .rotationEffect(Angle(degrees: -90))

                VStack(spacing: 2) {
                    Text("\(todayCalories)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("kcal")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)

            HStack(spacing: 4) {
                Text("体型状态:")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(bodyStatus)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)
            }

            VStack(spacing: 8) {
                TextField("输入热量", text: $inputCalorieString)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 13.5, design: .rounded))
                    .padding(.vertical, 7)
                    .background(Color.black.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 28)

                HStack(spacing: 12) {
                    Button(action: addCalories) {
                        Text("喂食")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 76, height: 30)
                            .background(Color.green.opacity(0.8))
                            .clipShape(Capsule())
                    }

                    Button(action: resetCalories) {
                        Text("清零")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(.red)
                            .frame(width: 76, height: 30)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer()
        }
    }
}

private struct CompactPredictionView: View {
    let predictions: [PetPopupPredictionItem]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 7) {
                Text("未来 7 天健康预测")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 2)

                ForEach(predictions) { item in
                    HStack {
                        Text(item.title)
                            .font(.system(size: 12.5))
                        Spacer()
                        Text(item.level)
                            .font(.system(size: 10.5, weight: .medium))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(item.color.opacity(0.15))
                            .foregroundColor(item.color)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
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
