import Combine
import SceneKit
import SwiftUI
import UIKit

// MARK: - 桌宠管理页
struct Twin3DView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var data = DataManager.shared
    @StateObject private var viewModel = Twin3DViewModel()
    @State private var selectedStyle = "治愈"
    @State private var selectedMode = "灵动"
    @State private var customPrompt = "更圆润、透明感更强，适合健康与桌面陪伴"
    @State private var statusMessage: String? = nil

    private let styles = ["健康", "活力", "治愈", "智感"]
    private let modes = ["灵动", "跟随", "专注", "省电"]

    var body: some View {
        ZStack {
            AegisDynamicBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                SubPageHeader(title: "桌宠管理") {
                    dismiss()
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        heroSection
                        statusSection
                        appearanceSection
                        actionSection
                        featureSection

                        Spacer(minLength: 96)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
            }

            if viewModel.isGenerating {
                Twin3DGeneratingOverlay(progress: viewModel.generationProgress)
            }

            if let statusMessage {
                VStack {
                    Spacer()
                    Text(statusMessage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.78))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
                        .padding(.bottom, 24)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea(.all, edges: .top)
        .onAppear {
            selectedStyle = currentStyleSeed
        }
    }

    private var currentStyleSeed: String {
        switch data.deskPetMascotName.lowercased() {
        case let value where value.contains("desk"):
            return "治愈"
        case let value where value.contains("pet"):
            return "健康"
        default:
            return styles[abs(data.deskPetMascotName.hashValue) % styles.count]
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                DeskPetOrbPreview(mascotName: data.deskPetMascotName, diameter: 76, showShadow: true, showBorder: true)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text("桌宠控制台")
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundColor(.primary.opacity(0.9))

                    Text("统一管理你的桌宠外观、悬浮状态与桌面行为。")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        statusChip(title: data.deskPetEnabled ? "已启用" : "已关闭", icon: data.deskPetEnabled ? "checkmark.circle.fill" : "pause.circle.fill", color: data.deskPetEnabled ? .aegisFreshGreen : .grayMid)
                        statusChip(title: data.deskPetShowBubble ? "气泡开启" : "气泡关闭", icon: "bubble.left.fill", color: .androidBlue)
                    }
                }

                Spacer()
            }

            HStack(spacing: 10) {
                quickMetric(title: "位置", value: positionSummary, icon: "location.fill")
                quickMetric(title: "风格", value: selectedStyle, icon: "sparkles")
                quickMetric(title: "模式", value: selectedMode, icon: "wand.and.stars")
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.98), Color.aegisFreshGreen.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 6)
    }

    private var positionSummary: String {
        let x = Int(data.deskPetPositionX)
        let y = Int(data.deskPetPositionY)
        return "\(x), \(y)"
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "桌宠状态", icon: "switch.2")

            VStack(spacing: 0) {
                ToggleRow(
                    icon: "power",
                    title: "启用桌宠",
                    subtitle: "关闭后桌面悬浮助手将隐藏",
                    color: .aegisFreshGreen,
                    isOn: $data.deskPetEnabled
                )

                Divider().background(Color.black.opacity(0.04)).padding(.leading, 64)

                ToggleRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "桌宠提示气泡",
                    subtitle: "在触发时显示引导气泡",
                    color: .androidBlue,
                    isOn: $data.deskPetShowBubble
                )

                Divider().background(Color.black.opacity(0.04)).padding(.leading, 64)

                NavigationRow(
                    icon: "location.north.line.fill",
                    title: "重置悬浮位置",
                    subtitle: "恢复到默认的右侧中部位置",
                    color: .androidOrange
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    data.deskPetPositionX = Double(UIScreen.main.bounds.width - 52)
                    data.deskPetPositionY = Double(UIScreen.main.bounds.height * 0.58)
                    saveSettings(with: "已重置悬浮位置")
                }
            }
            .aegisCardStyle(padding: 8)
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "外观与风格", icon: "paintpalette.fill")

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("选择风格")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.grayDark)

                    chipWrap(items: styles, selected: selectedStyle) { newStyle in
                        selectedStyle = newStyle
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("生成模式")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.grayDark)

                    chipWrap(items: modes, selected: selectedMode) { newMode in
                        selectedMode = newMode
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("补充描述")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.grayDark)

                    TextField("例如：更圆润、亲和、偏轻拟物", text: $customPrompt)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.black.opacity(0.05), lineWidth: 1)
                        )
                        .cornerRadius(14)
                }
            }
            .aegisCardStyle(padding: 12)
        }
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "生成与保存", icon: "sparkles.rectangle.stack")

            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    actionTile(title: "预览生成", subtitle: "模拟当前风格效果", icon: "wand.and.stars") {
                        viewModel.generateAvatar(style: selectedStyle)
                    }

                    actionTile(title: "立即保存", subtitle: "写入桌宠配置", icon: "square.and.arrow.down.fill") {
                        saveSettings(with: "桌宠设置已保存")
                    }
                }

                Button {
                    viewModel.generateAvatar(style: selectedStyle)
                    saveSettings(with: "正在生成并保存桌宠设置")
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isGenerating {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(viewModel.isGenerating ? "生成中..." : "生成并应用")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            colors: [.aegisFreshGreen, .aegisFreshGreenDeep],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .aegisFreshGreen.opacity(0.25), radius: 12, x: 0, y: 6)
                }
                .disabled(viewModel.isGenerating)
            }
            .aegisCardStyle(padding: 12)
        }
    }

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "桌宠亮点", icon: "star.bubble.fill")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                featureCard(icon: "person.crop.circle.badge.checkmark", title: "统一入口", subtitle: "和个人中心状态联动")
                featureCard(icon: "location.fill", title: "吸边记忆", subtitle: "拖动后保留最后位置")
                featureCard(icon: "bubble.left.fill", title: "悬浮提示", subtitle: "支持气泡提示显示")
                featureCard(icon: "square.and.arrow.down.on.square", title: "持久保存", subtitle: "桌宠配置自动保存")
            }
        }
    }

    @ViewBuilder
    private func chipWrap(items: [String], selected: String, action: @escaping (String) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Button {
                        action(item)
                    } label: {
                        Text(item)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(selected == item ? Color.aegisFreshGreen : Color.white)
                            .foregroundColor(selected == item ? .white : .grayDark)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(selected == item ? Color.clear : Color.black.opacity(0.06), lineWidth: 1)
                            )
                            .cornerRadius(12)
                    }
                    .buttonStyle(AegisBouncyCardStyle())
                }
            }
        }
    }

    private func statusChip(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(title)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    private func quickMetric(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.sageBright)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.grayMid)
            }
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.grayDark)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.78))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .cornerRadius(14)
    }

    private func actionTile(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.aegisFreshGreen.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.aegisFreshGreen)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.grayDark)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.grayMid)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .padding(14)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .cornerRadius(18)
        }
        .buttonStyle(AegisBouncyCardStyle())
    }

    private func featureCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.aegisFreshGreen)
                .frame(width: 34, height: 34)
                .background(Color.aegisFreshGreen.opacity(0.12))
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.grayDark)

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.grayMid)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 98, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .cornerRadius(18)
    }

    private func saveSettings(with message: String) {
        data.saveSettings()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            statusMessage = message
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.2)) {
                statusMessage = nil
            }
        }
    }

    // MARK: - 生成中覆盖层
    struct Twin3DGeneratingOverlay: View {
        let progress: Double

        var body: some View {
            ZStack {
                Color.black.opacity(0.56).ignoresSafeArea()

                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 128, height: 128)
                            .blur(radius: 1)

                        Circle()
                            .stroke(Color.white.opacity(0.18), lineWidth: 6)
                            .frame(width: 104, height: 104)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                LinearGradient(
                                    colors: [.aegisFreshGreen, .white],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 104, height: 104)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            Text("生成中")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    VStack(spacing: 6) {
                        Text("正在生成你的桌宠配置")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("请稍候，系统正在组合风格与行为参数")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.72))
                    }

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                }
                .padding(24)
                .background(.ultraThinMaterial.opacity(0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
                .cornerRadius(28)
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - 简化版 ViewModel（保留公用接口，便于后续恢复）
class Twin3DViewModel: ObservableObject {
    @Published var scene: SCNScene? = nil
    @Published var avatarName: String = "我的数字孪生"
    @Published var currentExpression: String = "normal"
    @Published var healthScore: Int = 85
    @Published var isGenerating: Bool = false
    @Published var generationProgress: Double = 0

    static var lastSnapshot: UIImage? = nil

    @Published var todaySteps: Int = 8500
    @Published var todayWater: Int = 1800
    @Published var todaySleep: Int = 7
    @Published var todayCalories: Int = 320

    var userHeight: Int = 175
    var userWeight: Double = 68.5

    @Published var highQuality: Bool = true

    var effectiveHighQuality: Bool { highQuality }

    func loadAvatar() {}

    func generateAvatar(style: String) {
        isGenerating = true
        generationProgress = 0.0

        Task {
            for index in 1...10 {
                try? await Task.sleep(nanoseconds: 180_000_000)
                await MainActor.run {
                    generationProgress = Double(index) / 10.0
                }
            }
            await MainActor.run {
                isGenerating = false
            }
        }
    }

    func cancelGeneration() {
        isGenerating = false
    }

    func takeSnapshot() {
        NotificationCenter.default.post(
            name: NSNotification.Name("Twin3DRequestSnapshot"), object: nil)
    }

    func shareAvatar() {}
}

// MARK: - Preview
#Preview {
    Twin3DView()
}
