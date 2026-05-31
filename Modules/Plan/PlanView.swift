import SwiftUI
import UIKit

// MARK: - Plan 子界面系统色（与组件背景协调）
private enum PlanUIKitSurface {
    static let grouped = Color(uiColor: .systemGroupedBackground)
    static let secondaryGrouped = Color(uiColor: .secondarySystemGroupedBackground)
    static let label = Color(uiColor: .label)
    static let secondaryLabel = Color(uiColor: .secondaryLabel)
    static let separator = Color(uiColor: .separator)
}

/// 计划详情内「设置」风格分组块（对齐系统次级分组背景）
private struct PlanFormSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(PlanUIKitSurface.label)
                .labelStyle(.titleAndIcon)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PlanUIKitSurface.secondaryGrouped)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Plan页面 (单页垂直滚动，匹配Android布局)
struct PlanView: View {
    @StateObject private var viewModel = PlanViewModel()
    @State private var activeFitnessPlan: ExercisePlanItem?

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    PlanPageHeader(viewModel: viewModel)
                        .aegisReveal(delay: 0.00)
                    ExercisePlanSection(viewModel: viewModel, onOpenFitnessPlan: { plan in
                        withAnimation(.snappy(duration: 0.28, extraBounce: 0)) {
                            activeFitnessPlan = plan
                        }
                    })
                        .aegisReveal(delay: 0.08)
                    MicroExerciseSection(viewModel: viewModel)
                        .aegisReveal(delay: 0.16)
                    HabitSection(viewModel: viewModel)
                        .aegisReveal(delay: 0.24)
                    AIAdjustSection(viewModel: viewModel)
                        .aegisReveal(delay: 0.32)
                    Spacer(minLength: 100)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable { await viewModel.refresh() }
            if viewModel.isAiProcessing {
                AIProcessingOverlay()
            }
            if let plan = activeFitnessPlan {
                Color.black.opacity(0.24)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.22, extraBounce: 0)) {
                            activeFitnessPlan = nil
                        }
                    }

                FitnessPopupHost(plan: plan) {
                    withAnimation(.snappy(duration: 0.22, extraBounce: 0)) {
                        activeFitnessPlan = nil
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.scale(scale: 0.92).combined(with: .opacity))
                .zIndex(2)
            }

            // Micro exercise custom overlay (moved to ZStack so it appears above content)
            if let ex = viewModel.selectedMicroExercise {
                Color.black.opacity(0.24)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.22, extraBounce: 0)) {
                            viewModel.dismissMicroExerciseGuide()
                        }
                    }

                VStack {
                    Spacer()
                    ExerciseCardViewMicro(exercise: ex) {
                        withAnimation(.snappy(duration: 0.22, extraBounce: 0)) {
                           viewModel.dismissMicroExerciseGuide()
                        }
                    }
                    .frame(maxWidth: 375)
                    Spacer()
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 12)
                .transition(.scale(scale: 0.92).combined(with: .opacity))
                .zIndex(3)
            }
        }
        .background(AegisDynamicBackground())
        .onAppear { viewModel.loadData() }
        .sheet(isPresented: $viewModel.showAddMicroExercise) {
            AddMicroExerciseSheet(
                onCancel: { viewModel.dismissAddMicroExerciseDialog() },
                onConfirm: { name, duration in
                    viewModel.addCustomMicroExercise(name: name, durationMinutes: duration)
                }
            )
            .presentationDetents([.height(380), .medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationBackground(.regularMaterial)
        }
        .sheet(item: $viewModel.adjustmentResult) { result in
            AdjustmentResultSheet(
                result: result,
                onDismiss: { viewModel.dismissAdjustmentResult() }
            )
            .presentationDetents([.medium, .height(400)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationBackground(.regularMaterial)
        }
    }
}

// MARK: - Header
private struct PlanPageHeader: View {
    @ObservedObject var viewModel: PlanViewModel
    @EnvironmentObject private var coordinator: NavigationCoordinator

    var body: some View {
        HealthCardView()
    }

    private func headerMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.72))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        return h < 12 ? "早安" : h < 18 ? "午安" : "晚安"
    }
    private var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "EEEE, M月d日"
        return f.string(from: Date())
    }
}

// MARK: - Module 1: 专业运动计划
private struct ExercisePlanSection: View {
    @ObservedObject var viewModel: PlanViewModel
    @State private var detailPlan: ExercisePlanItem?
    var onOpenFitnessPlan: ((ExercisePlanItem) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("专业运动计划")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.grayDark)
                    Text("横向滑动查看 · 共 \(viewModel.exercisePlans.count) 套")
                        .font(.system(size: 13))
                        .foregroundColor(.grayMid)
                }
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                        viewModel.toggleAIPlanProfileForm()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles").font(.system(size: 12))
                        Text(viewModel.isGeneratingPlan ? "生成中" : "AI 生成")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.purpleSoft)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.purpleSoft.opacity(0.2))
                    .cornerRadius(20)
                }
                .disabled(viewModel.isGeneratingPlan)
            }
            .padding(.horizontal, 24)

            if viewModel.showAIPlanProfileForm {
                AIPlanProfileInlineCard(viewModel: viewModel)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.exercisePlans) { plan in
                        ExerciseCard(plan: plan) {
                            if plan.sportType == "BASIC_FITNESS" || plan.sportType == "ADVANCED_FITNESS" {
                                onOpenFitnessPlan?(plan)
                            } else {
                                detailPlan = plan
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 4)
            }
        }
        .padding(.vertical, 16)
        .sheet(item: $detailPlan) { plan in
            PlanDetailSheet(planId: plan.id, viewModel: viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .presentationBackground(.regularMaterial)
        }
    }
}

private struct FitnessPopupHost: View {
    let plan: ExercisePlanItem
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            Spacer()
            Group {
                if plan.sportType == "ADVANCED_FITNESS" {
                    AdvancedFitnessPopupContainerView(plan: plan, onClose: onDismiss)
                } else {
                    FitnessPopupContainerView(plan: plan, onClose: onDismiss)
                }
            }
            .frame(maxWidth: 375)
            .transition(.scale(scale: 0.92).combined(with: .opacity))
            Spacer()
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 12)
        .onAppear {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

private struct ExerciseCard: View {
    let plan: ExercisePlanItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                LinearGradient(
                    colors: [Color.tealDeep.opacity(0.75), Color.grayDark.opacity(0.55)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                if showsSportArtwork {
                    Image(safeSystemName: sportIcon, fallback: "figure.run").font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.12))
                        .offset(x: 60, y: -20)
                }
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.15), Color.black.opacity(0.7)],
                    startPoint: .top, endPoint: .bottom)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        if !plan.emoji.isEmpty {
                            Text(plan.emoji)
                                .font(.system(size: 22))
                        }
                        if showsSportBadge {
                            Text(sportLabel)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.white.opacity(0.18))
                                .clipShape(Capsule())
                        }
                    }
                    Text(plan.name).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    Text(plan.duration).font(.system(size: 13)).foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(16)

                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3").font(.system(size: 12))
                            Text("定制").font(.system(size: 12, weight: .bold))
                        }.foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.sageBright.opacity(0.95)).cornerRadius(12).padding(12)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "book.fill").font(.system(size: 10))
                        Text("点击查看专业指导与定制方案").font(.system(size: 11))
                    }.foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.tealDeep.opacity(0.85)).cornerRadius(8)

                    HStack(spacing: 8) {
                        ParamTag(text: "消耗 \(plan.calories)")
                        ParamTag(text: "强度：\(plan.intensity)")
                        ParamTag(text: riskLabel, color: Color.sageLight.opacity(0.8))
                    }
                }.padding(16)
            }
            .frame(width: 280, height: 180).cornerRadius(24)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(AegisBouncyCardStyle())
    }

    private var riskLabel: String {
        switch plan.intensity {
        case "低": return "风险：低"
        case "中": return "风险：中"
        case "高": return "风险：留意"
        default: return "风险：低"
        }
    }

    private var sportLabel: String {
        switch plan.sportType {
        case "BASIC_FITNESS": return "健身"
        case "ADVANCED_FITNESS": return "健身"
        case "CYCLING": return "骑行"
        case "RUNNING": return "跑步"
        case "SWIMMING": return "游泳"
        case "YOGA": return "瑜伽"
        case "HIKING": return "登山"
        default: return "综合"
        }
    }

    private var sportIcon: String {
        switch plan.sportType {
        case "BASIC_FITNESS": return "figure.strengthtraining.traditional"
        case "ADVANCED_FITNESS": return "figure.strengthtraining.traditional"
        case "CYCLING": return "bicycle"
        case "RUNNING": return "figure.run"
        case "SWIMMING": return "figure.open.water.swim"
        case "YOGA": return "figure.yoga"
        case "HIKING": return "figure.hiking"
        default: return "figure.run"
        }
    }

    private var showsSportBadge: Bool {
        plan.sportType != "BASIC_FITNESS" && plan.sportType != "ADVANCED_FITNESS"
    }

    private var showsSportArtwork: Bool {
        plan.sportType != "BASIC_FITNESS" && plan.sportType != "ADVANCED_FITNESS"
    }
}

private struct ParamTag: View {
    let text: String
    var color: Color = Color.white.opacity(0.2)
    var body: some View {
        Text(text).font(.system(size: 11)).foregroundColor(.white)
            .padding(.horizontal, 8).padding(.vertical, 4).background(color).cornerRadius(8)
    }
}

// MARK: - Module 2: 碎片化运动计划
private struct MicroExerciseSection: View {
    @ObservedObject var viewModel: PlanViewModel
    @State private var activeIdx = 0
    private let scenes = [
        ("briefcase.fill", "工位"), ("tram.fill", "通勤"), ("house.fill", "居家"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("碎片化运动计划")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.grayDark)
                Text(sceneHint)
                    .font(.system(size: 13))
                    .foregroundColor(.grayMid)
            }
            .padding(.horizontal, 24)

            HStack(spacing: 8) {
                ForEach(Array(scenes.enumerated()), id: \.offset) { i, s in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3)) { activeIdx = i }
                        viewModel.filterMicroExercises(by: s.1)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: s.0).font(.system(size: 14, weight: .medium))
                            Text(s.1)
                                .font(.system(size: 14, weight: .medium))
                            Text("\(count(for: s.1))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(activeIdx == i ? .white.opacity(0.9) : .grayMid)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(
                                    Capsule().fill(
                                        activeIdx == i
                                            ? Color.white.opacity(0.22) : Color.grayMid.opacity(0.12))
                                )
                        }
                        .foregroundColor(activeIdx == i ? .white : .grayDark)
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(activeIdx == i ? Color.grayDark : Color.cream)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    activeIdx == i ? Color.sageBright.opacity(0.55) : Color.clear,
                                    lineWidth: 1.2)
                        )
                    }
                    .buttonStyle(AegisBouncyCardStyle())
                }
            }.padding(.horizontal, 24)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.filteredMicroExercises) { ex in
                    Button {
                        viewModel.startMicroExercise(ex)
                    } label: {
                        VStack(spacing: 8) {
                            Image(safeSystemName: ex.displaySFPlanSymbol, fallback: "figure.walk")
                                .font(.system(size: 30))
                                .foregroundStyle(Color.tealDeep)
                                .symbolRenderingMode(.hierarchical)
                            Text(ex.name).font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.grayDark)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                            Text(ex.duration).font(.system(size: 12)).foregroundColor(.grayMid)
                            Text("查看要领")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.tealDeep)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 18)
                        .aegisCardStyle(padding: 12)
                    }.buttonStyle(AegisBouncyCardStyle())
                }
            }.padding(.horizontal, 24)

            Button {
                viewModel.showAddMicroExerciseDialog()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 16))
                    Text("添加自定义动作")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.tealDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.tealDeep.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.tealDeep.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(AegisBouncyCardStyle())
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 16)
        .onAppear {
            if let i = scenes.firstIndex(where: { $0.1 == viewModel.currentScene }) {
                activeIdx = i
            }
            viewModel.filterMicroExercises(by: viewModel.currentScene)
        }
    }

    private var sceneHint: String {
        let c = viewModel.microExerciseCount
        return "按场景筛选 · 工位 \(c.工位) · 通勤 \(c.通勤) · 居家 \(c.居家)"
    }

    private func count(for scene: String) -> Int {
        switch scene {
        case "工位": return viewModel.microExerciseCount.工位
        case "通勤": return viewModel.microExerciseCount.通勤
        case "居家": return viewModel.microExerciseCount.居家
        default: return 0
        }
    }

}
// MARK: - Module 3: 1% 改造计划
private struct HabitSection: View {
    @ObservedObject var viewModel: PlanViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("1% 改造计划")
                    .font(.system(size: 20, weight: .bold)).foregroundColor(.grayDark)
                Text("今日打卡 \(viewModel.habitsCheckedInToday)/\(viewModel.habits.count) · 微习惯叠加复利")
                    .font(.system(size: 13)).foregroundColor(.grayMid)
            }

            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 44, height: 44)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.tealDeep)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("今日任务").font(.system(size: 12, weight: .medium)).foregroundColor(.grayMid)
                    Text(viewModel.todayTaskText)
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(.grayDark)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                Button(action: { viewModel.logTodayTask() }) {
                    VStack(spacing: 2) {
                        Text(viewModel.todayTaskCompleted ? "已录入" : "录入")
                            .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                        if viewModel.todayTaskCompleted {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(viewModel.todayTaskCompleted ? Color.sageLight : Color.grayDark)
                    .cornerRadius(20)
                }
                .disabled(viewModel.todayTaskCompleted)
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: viewModel.todayTaskCompleted
                        ? [Color.sageLight.opacity(0.3), Color.sageLight.opacity(0.1)]
                        : [Color(hex: "#E8DF98"), Color.yellowBright.opacity(0.3)],
                    startPoint: .leading, endPoint: .trailing)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .cornerRadius(24)

            ForEach(viewModel.habits) { habit in
                Button(action: { viewModel.toggleHabit(habit) }) {
                    HStack(spacing: 12) {
                        Text(habit.emoji).font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(habit.name)坚持 \(habit.currentDays) 天")
                                        .font(.system(size: 15, weight: .semibold)).foregroundColor(
                                            .grayDark)
                                    if habit.isCompletedToday {
                                        Text("今日已打卡")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.tealDeep)
                                    }
                                }
                                Spacer()
                                Text("\(habit.currentDays)/\(habit.targetDays)")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.grayMid)
                            }
                            GeometryReader { geo in
                                let p = min(
                                    CGFloat(habit.currentDays) / CGFloat(habit.targetDays), 1.0)
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.cream).frame(height: 6)
                                    Capsule().fill(Color.tealDeep)
                                        .frame(width: geo.size.width * p, height: 6)
                                        .animation(.spring(response: 0.6), value: p)
                                }
                            }.frame(height: 6)
                        }
                    }
                    .padding(16)
                    .aegisCardStyle(padding: 16)
                    .overlay(alignment: .topTrailing) {
                        if habit.isCompletedToday {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.sageBright)
                                .padding(10)
                        }
                    }
                }
                .buttonStyle(AegisBouncyCardStyle())
            }
        }
        .padding(.horizontal, 24).padding(.vertical, 16)
    }
}

// MARK: - Module 4: AI 动态调整
private struct AIAdjustSection: View {
    @ObservedObject var viewModel: PlanViewModel
    @State private var inputAccessoryHint: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("AI 动态调整")
                    .font(.system(size: 20, weight: .bold)).foregroundColor(.grayDark)
                Text("先选中一项计划，再用文字描述你的想法（语音与影像入口即将接入）")
                    .font(.system(size: 13)).foregroundColor(.grayMid)
                    .fixedSize(horizontal: false, vertical: true)
            }

            selectedPlanSummary

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.adjustablePlans) { p in
                        Button {
                            viewModel.selectAdjustPlan(
                                viewModel.selectedAdjustPlanId == p.id ? nil : p.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(p.category)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color(hex: p.textColorHex))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: p.bgColorHex))
                                    .cornerRadius(20)
                                Text(p.name).font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.grayDark).lineLimit(1)
                                Text(p.description).font(.system(size: 12)).foregroundColor(
                                    .grayMid
                                ).lineLimit(2)
                            }
                            .padding(16).frame(width: 160).aegisCardStyle(padding: 16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        viewModel.selectedAdjustPlanId == p.id
                                            ? Color.sageLight : Color.clear, lineWidth: 2)
                            )
                            .shadow(
                                color: .black.opacity(
                                    viewModel.selectedAdjustPlanId == p.id ? 0.1 : 0.04),
                                radius: viewModel.selectedAdjustPlanId == p.id ? 8 : 4,
                                y: viewModel.selectedAdjustPlanId == p.id ? 4 : 2
                            )
                        }.buttonStyle(AegisBouncyCardStyle())
                    }
                }
            }

            if let hint = inputAccessoryHint {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill").foregroundColor(.tealDeep)
                    Text(hint).font(.system(size: 12)).foregroundColor(.grayDark)
                    Spacer()
                }
                .padding(12)
                .background(Color.tealDeep.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        inputAccessoryHint = "语音输入能力可在后续版本接入系统听写或自定义识别。"
                    } label: {
                        Image(systemName: "mic.fill").font(.system(size: 18)).foregroundColor(
                            .orangeWarm)
                    }
                    .accessibilityLabel("语音输入说明")

                    TextField(
                        "描述你希望如何调整计划…",
                        text: Binding(
                            get: { viewModel.adjustmentInput },
                            set: { viewModel.updateAdjustmentInput($0) }
                        ),
                        axis: .vertical
                    )
                    .lineLimit(1...4)
                    .font(.system(size: 14)).foregroundColor(.grayDark)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Color(hex: "#E8DF98").opacity(0.5)).cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .stroke(Color.orangeWarm.opacity(0.25), lineWidth: 1)
                )

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    inputAccessoryHint = "拍照可用于记录饮食或场景备注，后续可与计划联动分析。"
                } label: {
                    Image(systemName: "camera.fill").font(.system(size: 18)).foregroundColor(
                        .grayMid
                    )
                    .frame(width: 48, height: 48).background(Color.white).clipShape(Circle())
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    .overlay(Circle().stroke(Color.grayMid.opacity(0.12), lineWidth: 1))
                }
                .accessibilityLabel("影像备注说明")
            }

            if viewModel.selectedAdjustPlanId != nil
                && !viewModel.adjustmentInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
            {
                Button {
                    viewModel.submitAdjustment()
                } label: {
                    HStack {
                        if viewModel.isAiProcessing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        }
                        Text(viewModel.isAiProcessing ? "AI 思考中..." : "提交调整")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.sageLight)
                    .cornerRadius(14)
                }
                .disabled(viewModel.isAiProcessing)
                .buttonStyle(AegisBouncyCardStyle())
            }
        }
        .padding(.horizontal, 24).padding(.vertical, 16)
    }

    @ViewBuilder
    private var selectedPlanSummary: some View {
        if let id = viewModel.selectedAdjustPlanId,
            let p = viewModel.adjustablePlans.first(where: { $0.id == id })
        {
            HStack(spacing: 10) {
                Image(systemName: "arrow.right.circle.fill").foregroundColor(.sageBright)
                VStack(alignment: .leading, spacing: 2) {
                    Text("已选择").font(.system(size: 11, weight: .medium)).foregroundColor(.grayMid)
                    Text(p.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.grayDark)
                }
                Spacer()
            }
            .padding(12)
            .background(Color.sageBright.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

// MARK: - Plan Detail Sheet
private struct PlanDetailSheet: View {
    let planId: String
    @ObservedObject var viewModel: PlanViewModel
    @State private var tab = 0
    @Environment(\.dismiss) private var dismiss
    private var plan: ExercisePlanItem? {
        viewModel.exercisePlans.first(where: { $0.id == planId })
    }

    var body: some View {
        if let plan {
            NavigationStack {
                VStack(spacing: 0) {
                    planCompactHero(plan: plan)

                    Picker("章节", selection: $tab) {
                        Text("定制").tag(0).accessibilityLabel("计划定制")
                        Text("指导").tag(1).accessibilityLabel("专业指导")
                        Text("分解").tag(2).accessibilityLabel("动作分解")
                        Text("周历").tag(3).accessibilityLabel("周计划")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .onChange(of: tab) { _, _ in
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            switch tab {
                            case 0:
                                ConfigTab(plan: plan) { update in
                                    viewModel.updateConfig(for: plan.id, transform: update)
                                }
                            case 1: GuidanceTab(plan: plan)
                            case 2: TechniqueTab(plan: plan)
                            case 3: WeeklyTab(plan: plan)
                            default: EmptyView()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .padding(.bottom, 24)
                    }
                    .scrollIndicators(.hidden)
                    .background(PlanUIKitSurface.grouped)
                }
                .background(PlanUIKitSurface.grouped)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 8) {
                            Image(safeSystemName: sportSymbol(for: plan.sportType), fallback: "figure.run")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.tealDeep)
                            VStack(spacing: 0) {
                                Text(plan.name)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(PlanUIKitSurface.label)
                                    .lineLimit(1)
                                Text(sportTitle(for: plan.sportType))
                                    .font(.caption)
                                    .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                            }
                        }
                        .frame(maxWidth: 260)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("完成") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .tint(Color.tealDeep)
                    }
                }
            }
        } else {
            EmptyView()
        }
    }

    private func planCompactHero(plan: ExercisePlanItem) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 56, height: 56)
                Image(safeSystemName: sportSymbol(for: plan.sportType), fallback: "figure.run")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    compactMetric(icon: "clock.fill", text: plan.duration)
                    compactMetric(icon: "bolt.horizontal.fill", text: plan.intensity)
                }
                compactMetric(icon: "flame.fill", text: "消耗 \(plan.calories)")
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white.opacity(0.92))
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.tealDeep, Color.grayDark.opacity(0.82)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PlanUIKitSurface.separator.opacity(0.35))
                .frame(height: 0.5)
        }
    }

    private func compactMetric(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
            Text(text)
                .lineLimit(1)
        }
    }

    private func sportSymbol(for type: String) -> String {
        switch type {
        case "CYCLING": return "bicycle"
        case "RUNNING": return "figure.run"
        case "SWIMMING": return "figure.open.water.swim"
        case "YOGA": return "figure.yoga"
        case "HIKING": return "figure.hiking"
        default: return "figure.strengthtraining.traditional"
        }
    }

    private func sportTitle(for type: String) -> String {
        switch type {
        case "CYCLING": return "骑行"
        case "RUNNING": return "跑步"
        case "SWIMMING": return "游泳"
        case "YOGA": return "瑜伽"
        case "HIKING": return "登山"
        default: return "训练"
        }
    }
}

// MARK: - Detail Tabs

private struct ConfigTab: View {
    let plan: ExercisePlanItem
    let onConfigChange: ((inout ExerciseConfig) -> Void) -> Void
    private let cyclingTerrains = [("🛣️", "公路骑行"), ("⛰️", "山地越野"), ("🏠", "室内骑行台")]
    private let runningTerrains = [("🛣️", "公路"), ("🏟️", "跑道"), ("⛰️", "越野"), ("🏃", "跑步机")]
    private let yogaStyles = ["哈他瑜伽", "流瑜伽", "阴瑜伽"]
    private let yogaLevels = ["入门", "进阶", "高级"]
    private let swimStrokes = ["自由泳", "蛙泳", "仰泳", "蝶泳"]
    private let hikeLevels = ["轻松", "中等", "强度", "极限"]

    var body: some View {
        let cfg = plan.config
        VStack(alignment: .leading, spacing: 16) {
            if plan.sportType == "RUNNING" {
                PlanFormSection(title: "跑步目标", systemImage: "figure.run") {
                    ConfigSlider(
                        label: "目标距离",
                        value: cfg.targetDistance,
                        range: 1...42,
                        unit: "公里"
                    ) { val in onConfigChange { $0.targetDistance = val } }
                    ConfigSlider(
                        label: "目标配速",
                        value: cfg.targetPace,
                        range: 3...10,
                        unit: "分/公里"
                    ) { val in onConfigChange { $0.targetPace = val } }
                }
                PlanFormSection(title: "地形选择", systemImage: "map") {
                    ChipSelectRow(
                        items: runningTerrains.map(\.1),
                        selected: cfg.runningTerrain
                    ) { idx in onConfigChange { $0.runningTerrain = idx } }
                }
            } else if plan.sportType == "CYCLING" {
                PlanFormSection(title: "骑行目标", systemImage: "figure.outdoor.cycle") {
                    ConfigSlider(
                        label: "目标骑行距离", value: cfg.cyclingDistance, range: 5...200, unit: "公里"
                    ) { val in
                        onConfigChange { $0.cyclingDistance = val }
                    }
                    ConfigSlider(
                        label: "目标消耗", value: cfg.targetCalories, range: 100...1500, unit: "kcal"
                    ) { val in
                        onConfigChange { $0.targetCalories = val }
                    }
                }
                PlanFormSection(title: "路面与踏频", systemImage: "mountain.2") {
                    ChipSelectRow(items: cyclingTerrains.map(\.1), selected: cfg.cyclingTerrain) {
                        idx in
                        onConfigChange { $0.cyclingTerrain = idx }
                    }
                    ConfigSlider(label: "踏频", value: cfg.cyclingCadence, range: 50...120, unit: "rpm") {
                        val in
                        onConfigChange { $0.cyclingCadence = val }
                    }
                }
            } else if plan.sportType == "YOGA" {
                PlanFormSection(title: "瑜伽配置", systemImage: "figure.yoga") {
                    ChipSelectRow(items: yogaStyles, selected: cfg.yogaStyle) { idx in
                        onConfigChange { $0.yogaStyle = idx }
                    }
                    ChipSelectRow(items: yogaLevels, selected: cfg.yogaDifficulty) { idx in
                        onConfigChange { $0.yogaDifficulty = idx }
                    }
                    ConfigSlider(label: "冥想时长", value: cfg.meditationMinutes, range: 0...20, unit: "分钟")
                    { val in
                        onConfigChange { $0.meditationMinutes = val }
                    }
                }
            } else if plan.sportType == "SWIMMING" {
                PlanFormSection(title: "游泳配置", systemImage: "figure.open.water.swim") {
                    ChipSelectRow(items: swimStrokes, selected: cfg.swimmingStroke) { idx in
                        onConfigChange { $0.swimmingStroke = idx }
                    }
                    ConfigSlider(label: "目标距离", value: cfg.swimDistance, range: 100...3000, unit: "米") {
                        val in
                        onConfigChange { $0.swimDistance = val }
                    }
                    ConfigSlider(label: "每圈休息", value: cfg.restPerLap, range: 0...60, unit: "秒") {
                        val in
                        onConfigChange { $0.restPerLap = val }
                    }
                }
            } else if plan.sportType == "HIKING" {
                PlanFormSection(title: "登山配置", systemImage: "figure.hiking") {
                    ChipSelectRow(items: hikeLevels, selected: cfg.hikingDifficulty) { idx in
                        onConfigChange { $0.hikingDifficulty = idx }
                    }
                    ConfigSlider(
                        label: "累计爬升", value: cfg.hikingElevationGain, range: 50...2000, unit: "米"
                    ) { val in
                        onConfigChange { $0.hikingElevationGain = val }
                    }
                    ConfigSlider(label: "背包重量", value: cfg.hikingPackWeight, range: 0...20, unit: "公斤")
                    { val in
                        onConfigChange { $0.hikingPackWeight = val }
                    }
                }
            } else {
                PlanFormSection(title: "通用配置", systemImage: "target") {
                    ConfigSlider(
                        label: "目标消耗", value: cfg.targetCalories, range: 100...1000, unit: "kcal"
                    ) { val in
                        onConfigChange { $0.targetCalories = val }
                    }
                    ConfigSlider(label: "训练时长", value: cfg.targetTime, range: 10...120, unit: "分钟") {
                        val in
                        onConfigChange { $0.targetTime = val }
                    }
                }
            }

            PlanFormSection(title: "每周频次", systemImage: "calendar") {
                ConfigSlider(label: "每周训练", value: cfg.weeklyFrequency, range: 1...7, unit: "次/周") {
                    val in
                    onConfigChange { $0.weeklyFrequency = val }
                }
                Text("会与「周历」页的训练负荷展示联动参考。")
                    .font(.system(size: 12))
                    .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
    }
}

private struct GuidanceTab: View {
    let plan: ExercisePlanItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SecHead(icon: "lightbulb", title: "训练建议")
            if plan.guidanceTips.isEmpty {
                Text("AI 生成方案将在此补充个性化提示；你可先在「计划定制」中设定目标。")
                    .font(.system(size: 14))
                    .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PlanUIKitSurface.secondaryGrouped)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                ForEach(Array(plan.guidanceTips.enumerated()), id: \.offset) { i, tip in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.sageBright).frame(width: 28, height: 28)
                            Text("\(i + 1)").font(.system(size: 13, weight: .bold)).foregroundColor(
                                .white)
                        }
                        Text(tip).font(.system(size: 15)).foregroundStyle(PlanUIKitSurface.label)
                        Spacer()
                    }
                    .padding(14)
                    .background(PlanUIKitSurface.secondaryGrouped)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

            SportIntensityReferenceBlock(sportType: plan.sportType)

            SecHead(icon: "heart", title: "心率区间")
            let zones = [
                ("热身区", "50-60% HRmax", Color.sageBright, 0.5),
                ("燃脂区", "60-70% HRmax", Color.androidBlue, 0.6),
                ("有氧区", "70-80% HRmax", Color.orangeWarm, 0.7),
                ("无氧区", "80-90% HRmax", Color.purpleSoft, 0.8),
                ("极限区", "90-100% HRmax", Color.errorRed, 0.95),
            ]
            VStack(spacing: 8) {
                ForEach(Array(zones.enumerated()), id: \.offset) { _, z in
                    VStack(spacing: 4) {
                        HStack {
                            Text(z.0).font(.system(size: 11, weight: .medium)).foregroundColor(
                                .grayDark)
                            Spacer()
                            Text(z.1).font(.system(size: 11, design: .monospaced)).foregroundColor(
                                .grayMid)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(z.2.opacity(0.15)).frame(height: 10)
                                Capsule().fill(z.2).frame(width: geo.size.width * z.3, height: 10)
                            }
                        }.frame(height: 10)
                    }
                }
                Text("HRmax 估算 = 220 - 年龄")
                    .font(.system(size: 11))
                    .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                    .padding(.top, 4)
            }
            .padding(14)
            .background(PlanUIKitSurface.secondaryGrouped)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

/// 按运动类型展示强度 / 配速参考（骑行保留原有表格，其余运动单独适配）
private struct SportIntensityReferenceBlock: View {
    let sportType: String

    private let cyclingRows = [
        ("休闲骑行", "15 - 20 km/h", "轻松交谈"),
        ("健身骑行", "20 - 28 km/h", "略有喘息"),
        ("训练骑行", "28 - 35 km/h", "呼吸较快"),
        ("竞速骑行", "35 - 45 km/h", "难以说话"),
        ("极限冲刺", "> 45 km/h", "全力输出"),
    ]
    private let runningRows = [
        ("轻松跑", "7:30 - 8:30", "完整对话"),
        ("有氧跑", "6:00 - 7:30", "短句交流"),
        ("节奏跑", "5:00 - 6:00", "单字回答"),
        ("间歇跑", "4:00 - 5:00", "难以说话"),
        ("冲刺", "< 4:00", "全力"),
    ]
    private let swimRows = [
        ("恢复游", "慢于轻松配速", "技术修正为主"),
        ("有氧游", "可持续连续游", "鼻吸口呼稳定"),
        ("节奏游", "略快于舒适区", "转身保留体力"),
        ("间歇包干", "快游 + 充分休息", "监控肩部疲劳"),
    ]
    private let colors: [Color] = [.sageBright, .androidBlue, .orangeWarm, .purpleSoft, .errorRed]

    var body: some View {
        Group {
            switch sportType {
            case "CYCLING":
                paceTable(
                    title: "骑行配速参考",
                    icon: "gauge.with.dots.needle.bottom.50percent",
                    col2: "车速(km/h)",
                    rows: cyclingRows.map { ($0.0, $0.1, $0.2) },
                    footnote: "踏频建议保持在 80 - 100 rpm，低踏频高阻力易伤膝盖。"
                )
            case "RUNNING":
                paceTable(
                    title: "跑步配速参考",
                    icon: "figure.run",
                    col2: "配速(分/公里)",
                    rows: runningRows.map { ($0.0, $0.1, $0.2) },
                    footnote: "路面与气温会影响体感；上坡可按心率而非配速为主。"
                )
            case "SWIMMING":
                paceTable(
                    title: "游泳强度分层",
                    icon: "drop.fill",
                    col2: "说明",
                    rows: swimRows.map { ($0.0, $0.1, $0.2) },
                    footnote: "划水效率优先于绝对速度；休息时段关注肩部与颈部放松。"
                )
            case "YOGA":
                referenceCard(
                    title: "瑜伽练习要点",
                    icon: "figure.yoga",
                    lines: [
                        "鼻吸鼻呼为主，拉伸阶段呼气加深。",
                        "关节对齐优先于幅度：膝踝髋一线，避免憋气。",
                        "站立体式从足弓激活开始，坐姿从坐骨扎根开始。",
                    ]
                )
            case "HIKING":
                referenceCard(
                    title: "登山节奏建议",
                    icon: "mountain.2.fill",
                    lines: [
                        "上坡小步高频，重心略前倾；下坡屈膝缓冲保护膝盖。",
                        "背包重心贴近背部，肩带与髋带分担重量。",
                        "海拔与气温升高时主动降速，以呼吸可交谈为度。",
                    ]
                )
            default:
                referenceCard(
                    title: "强度参考",
                    icon: "chart.line.uptrend.xyaxis",
                    lines: [
                        "以「训练时可简短对话」为有氧上限粗略参考。",
                        "连续两天高强度后安排轻松日或主动恢复。",
                        "睡眠与营养不足时自动下调一成计划量更安全。",
                    ]
                )
            }
        }
    }

    private func paceTable(
        title: String,
        icon: String,
        col2: String,
        rows: [(String, String, String)],
        footnote: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SecHead(icon: icon, title: title)
            VStack(spacing: 0) {
                HStack {
                    Text("级别").font(.system(size: 11, weight: .bold)).foregroundColor(.grayMid)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(col2).font(.system(size: 11, weight: .bold)).foregroundColor(.grayMid)
                        .frame(maxWidth: .infinity)
                    Text("体感").font(.system(size: 11, weight: .bold)).foregroundColor(.grayMid)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }.padding(.bottom, 8)
                ForEach(Array(rows.enumerated()), id: \.offset) { i, r in
                    HStack {
                        HStack(spacing: 6) {
                            Circle().fill(colors[min(i, colors.count - 1)]).frame(width: 8, height: 8)
                            Text(r.0).font(.system(size: 12)).foregroundColor(.grayDark)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        Text(r.1).font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.grayDark).frame(maxWidth: .infinity)
                        Text(r.2).font(.system(size: 12)).foregroundColor(.grayMid).frame(
                            maxWidth: .infinity, alignment: .trailing)
                    }.padding(.vertical, 6)
                }
                Text(footnote)
                    .font(.system(size: 11))
                    .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                    .padding(.top, 4)
            }
            .padding(14)
            .background(PlanUIKitSurface.secondaryGrouped)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func referenceCard(title: String, icon: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SecHead(icon: icon, title: title)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(i + 1)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Color.tealDeep)
                            .clipShape(Circle())
                        Text(line)
                            .font(.system(size: 14))
                            .foregroundStyle(PlanUIKitSurface.label)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PlanUIKitSurface.secondaryGrouped)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

private struct TechniqueTab: View {
    let plan: ExercisePlanItem

    private var mistakeRows: [(String, String)] {
        switch plan.sportType {
        case "RUNNING":
            return [
                ("步幅过大", "小步快频更易减脂且降低膝冲击"),
                ("直立后仰跑", "身体微前倾利用重力前移"),
            ]
        case "CYCLING":
            return [
                ("踏频过低硬踩", "优先保持 80 rpm 左右再加大阻力"),
                ("上肢紧绷耸肩", "屈肘放松，重量在手肘而非手腕"),
            ]
        case "SWIMMING":
            return [
                ("颈部过度抬起", "视线略向下，髋腿抬高贴近水面"),
                ("憋气过久", "韵律呼吸：划水呼气转头吸气"),
            ]
        case "YOGA":
            return [
                ("强求幅度", "关节顺位优于触碰脚尖的深度"),
                ("屏息憋气", "伸展呼气帮助深层释放"),
            ]
        default:
            return [
                ("热身不足", "任何运动前都应进行 5–10 分钟动态热身"),
                ("忽视拉伸", "运动后的静态拉伸有助于肌肉恢复"),
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SecHead(icon: "figure.strengthtraining.traditional", title: "核心动作要领")
            let total = plan.techniqueSteps.count
            ForEach(Array(plan.techniqueSteps.enumerated()), id: \.offset) { i, step in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(
                                LinearGradient(
                                    colors: [.sageBright, .tealDeep], startPoint: .topLeading,
                                    endPoint: .bottomTrailing)
                            ).frame(width: 32, height: 32)
                            Text("\(i+1)").font(.system(size: 14, weight: .bold)).foregroundColor(
                                .white)
                        }
                        Text("步骤 \(i+1) / \(total)").font(.system(size: 12)).foregroundColor(
                            .grayMid)
                    }
                    Text(step).font(.system(size: 14)).foregroundColor(.grayDark)
                    GeometryReader { geo in
                        let p = CGFloat(i + 1) / CGFloat(total)
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.sageBright.opacity(0.15)).frame(height: 4)
                            Capsule().fill(Color.sageBright).frame(
                                width: geo.size.width * p, height: 4)
                        }
                    }.frame(height: 4)
                }
                .padding(16)
                .background(PlanUIKitSurface.secondaryGrouped)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            SecHead(icon: "exclamationmark.triangle", title: "常见错误")
            ForEach(Array(mistakeRows.enumerated()), id: \.offset) { _, m in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.circle.fill").font(.system(size: 18))
                        .foregroundStyle(Color.orangeWarm)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(m.0).font(.system(size: 14, weight: .bold)).foregroundStyle(PlanUIKitSurface.label)
                        Text(m.1).font(.system(size: 13)).foregroundStyle(PlanUIKitSurface.secondaryLabel)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orangeWarm.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
}

private struct WeeklyTab: View {
    let plan: ExercisePlanItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SecHead(icon: "calendar", title: "本周训练安排")
            if plan.weeklySchedule.isEmpty {
                Text("尚未生成周视图：可在「计划定制」中设定每周频次，或通过 AI 生成完整方案。")
                    .font(.system(size: 14))
                    .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PlanUIKitSurface.secondaryGrouped)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            ForEach(plan.weeklySchedule) { s in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                s.isActive
                                    ? LinearGradient(
                                        colors: [.sageBright, .tealDeep], startPoint: .topLeading,
                                        endPoint: .bottomTrailing)
                                    : LinearGradient(
                                        colors: [
                                            Color.grayMid.opacity(0.15),
                                            Color.grayMid.opacity(0.15),
                                        ], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(width: 40, height: 40)
                        Text(s.weekdayGlyph)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(s.isActive ? .white : .grayMid)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(s.day).font(.system(size: 13, weight: .bold)).foregroundColor(
                                s.isActive ? .grayDark : .grayMid)
                            Spacer()
                            if !s.duration.isEmpty {
                                Text(s.duration).font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.tealDeep)
                                    .padding(.horizontal, 8).padding(.vertical, 3).background(
                                        Color.tealDeep.opacity(0.1)
                                    ).cornerRadius(6)
                            }
                        }
                        Text(s.focus).font(.system(size: 13, weight: .medium)).foregroundColor(
                            s.isActive ? .tealDeep : .grayMid)
                        Text(s.details).font(.system(size: 12)).foregroundColor(.grayMid)
                    }
                }
                .padding(14)
                .background(s.isActive ? PlanUIKitSurface.secondaryGrouped : PlanUIKitSurface.grouped)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(s.isActive ? Color.tealDeep.opacity(0.22) : Color.clear, lineWidth: 1)
                )
                .shadow(color: s.isActive ? .black.opacity(0.06) : .clear, radius: 8, y: 4)
            }
        }
    }
}

private extension WeeklyScheduleItem {
    /// 「周一」→「一」，便于在圆标内展示
    var weekdayGlyph: String {
        if day.hasPrefix("周"), day.count >= 2 {
            return String(day.dropFirst())
        }
        return String(day.prefix(1))
    }
}

// MARK: - Shared helpers
private struct SecHead: View {
    let icon: String
    let title: String
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color.sageBright.opacity(0.12)).frame(
                    width: 28, height: 28)
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(.tealDeep)
            }
            Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(.grayDark)
        }
    }
}

private struct SRow: View {
    let label: String
    @Binding var val: Double
    let range: ClosedRange<Double>
    let unit: String
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label).font(.system(size: 14)).foregroundColor(.grayMid)
                Spacer()
                Text("\(Int(val))  \(unit)").font(
                    .system(size: 14, weight: .bold, design: .monospaced)
                ).foregroundColor(.tealDeep)
            }
            Slider(value: $val, in: range).tint(.sageBright)
        }
    }
}

private struct ConfigSlider: View {
    let label: String
    let value: Double
    let range: ClosedRange<Double>
    let unit: String
    let onChanged: (Double) -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(PlanUIKitSurface.label)
                Spacer()
                Text("\(Int(value)) \(unit)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.tealDeep)
                    .monospacedDigit()
            }
            Slider(
                value: Binding(
                    get: { value },
                    set: { onChanged($0) }
                ),
                in: range
            )
            .tint(Color.sageBright)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label)，当前 \(Int(value)) \(unit)")
    }
}

private struct ChipSelectRow: View {
    let items: [String]
    let selected: Int
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onSelect(i)
                    } label: {
                        Text(item)
                            .font(.system(size: 13, weight: selected == i ? .semibold : .regular))
                            .foregroundStyle(selected == i ? Color.tealDeep : PlanUIKitSurface.secondaryLabel)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                selected == i ? Color.sageBright.opacity(0.18) : Color.primary.opacity(0.04)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        selected == i ? Color.sageBright.opacity(0.9) : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct AIPlanProfileInlineCard: View {
    @ObservedObject var viewModel: PlanViewModel
    private let levels: [(String, String)] = [
        ("BEGINNER", "新手入门"), ("INTERMEDIATE", "中级进阶"), ("ADVANCED", "高阶专业"),
    ]
    private let goals: [(String, String)] = [
        ("WEIGHT_LOSS", "减脂塑形"), ("MUSCLE", "增肌力量"), ("ENDURANCE", "耐力心肺"), ("FLEXIBILITY", "柔韧恢复"),
        ("GENERAL", "综合健康"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI 个性化方案")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(PlanUIKitSurface.label)
                    Text("用于生成本页「专业运动计划」卡片；不会在后台持久存储敏感原文。")
                        .font(.system(size: 12))
                        .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        viewModel.showAIPlanProfileForm = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                        .padding(8)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("训练诉求")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PlanUIKitSurface.label)
                    TextField("描述偏好、场地或禁忌（可选）", text: $viewModel.aiPlanPrompt, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(12)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("健身水平")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PlanUIKitSurface.label)
                    HStack(spacing: 8) {
                        ForEach(levels, id: \.0) { level in
                            AIPlanPill(title: level.1, selected: viewModel.fitnessLevel == level.0)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                                        viewModel.fitnessLevel = level.0
                                    }
                                }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("训练目标")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PlanUIKitSurface.label)
                    FlowLayout(spacing: 8) {
                        ForEach(goals, id: \.0) { goal in
                            AIPlanPill(title: goal.1, selected: viewModel.healthGoal == goal.0)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                                        viewModel.healthGoal = goal.0
                                    }
                                }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("训练节奏")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PlanUIKitSurface.label)

                    Stepper(value: $viewModel.planWeeklyFrequency, in: 1...7) {
                        HStack {
                            Text("每周次数")
                            Spacer()
                            Text("\(viewModel.planWeeklyFrequency) 次")
                                .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                                .monospacedDigit()
                        }
                    }

                    Stepper(value: $viewModel.planSessionDuration, in: 20...120, step: 5) {
                        HStack {
                            Text("单次时长")
                            Spacer()
                            Text("\(viewModel.planSessionDuration) 分钟")
                                .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                                .monospacedDigit()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("身体限制")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PlanUIKitSurface.label)
                    TextField("如医嘱、旧伤部位（可选）", text: $viewModel.healthLimitations, axis: .vertical)
                        .lineLimit(2...5)
                        .padding(12)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

            Button {
                viewModel.generateAIPlan()
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isGeneratingPlan {
                        ProgressView().padding(.trailing, 4)
                    }
                    Text(viewModel.isGeneratingPlan ? "生成中…" : "生成个性化方案")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                }
                .foregroundStyle(.white)
                .frame(height: 48)
                .background(Color.purpleSoft)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(viewModel.isGeneratingPlan)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
    }
}

private struct AIPlanPill: View {
    let title: String
    let selected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(selected ? Color.white : PlanUIKitSurface.label)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? Color.purpleSoft : Color.primary.opacity(0.05))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(selected ? Color.clear : Color.primary.opacity(0.05), lineWidth: 1)
            )
    }
}

private struct AIPlanProfileForm: View {
    @ObservedObject var viewModel: PlanViewModel
    @Environment(\.dismiss) private var dismiss
    private let levels: [(String, String)] = [
        ("BEGINNER", "新手入门"), ("INTERMEDIATE", "中级进阶"), ("ADVANCED", "高阶专业"),
    ]
    private let goals: [(String, String)] = [
        ("WEIGHT_LOSS", "减脂塑形"), ("MUSCLE", "增肌力量"), ("ENDURANCE", "耐力心肺"), ("FLEXIBILITY", "柔韧恢复"),
        ("GENERAL", "综合健康"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("用于生成本页「专业运动计划」卡片；不会在后台持久存储敏感原文。")
                        .font(.footnote)
                        .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                }
                Section("训练诉求") {
                    TextField("描述偏好、场地或禁忌（可选）", text: $viewModel.aiPlanPrompt, axis: .vertical)
                        .lineLimit(4...10)
                }
                Section("健身水平") {
                    Picker("水平", selection: $viewModel.fitnessLevel) {
                        ForEach(levels, id: \.0) { l in
                            Text(l.1).tag(l.0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("训练目标") {
                    Picker("主目标", selection: $viewModel.healthGoal) {
                        ForEach(goals, id: \.0) { g in
                            Text(g.1).tag(g.0)
                        }
                    }
                }
                Section("训练节奏") {
                    Stepper(value: $viewModel.planWeeklyFrequency, in: 1...7) {
                        HStack {
                            Text("每周次数")
                            Spacer()
                            Text("\(viewModel.planWeeklyFrequency) 次")
                                .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                                .monospacedDigit()
                        }
                    }
                    Stepper(value: $viewModel.planSessionDuration, in: 20...120, step: 5) {
                        HStack {
                            Text("单次时长")
                            Spacer()
                            Text("\(viewModel.planSessionDuration) 分钟")
                                .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                                .monospacedDigit()
                        }
                    }
                }
                Section("身体限制") {
                    TextField("如医嘱、旧伤部位（可选）", text: $viewModel.healthLimitations, axis: .vertical)
                        .lineLimit(2...6)
                }
                Section {
                    Button {
                        viewModel.generateAIPlan()
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isGeneratingPlan {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(viewModel.isGeneratingPlan ? "生成中…" : "生成个性化方案")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isGeneratingPlan)
                }
            }
            .navigationTitle("AI 个性化方案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                        viewModel.showAIPlanProfileForm = false
                    }
                }
            }
            .tint(Color.purpleSoft)
        }
    }
}

private struct AIProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.42).ignoresSafeArea()
            VStack(spacing: 18) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.35)
                    .tint(Color.tealDeep)
                VStack(spacing: 6) {
                    Text("正在处理")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(PlanUIKitSurface.label)
                    Text("AI 正在结合你的描述微调计划")
                        .font(.system(size: 14))
                        .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(28)
            .frame(minWidth: 260)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
        }
    }
}

private struct AdjustmentResultSheet: View {
    let result: AdjustmentResultItem
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.sageBright, .tealDeep], startPoint: .topLeading,
                                endPoint: .bottomTrailing)
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: Color.tealDeep.opacity(0.35), radius: 12, y: 6)
                    Image(systemName: "checkmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .white.opacity(0.35))
                        .font(.system(size: 36))
                }
                .padding(.top, 8)

                VStack(spacing: 8) {
                    Text("计划已更新")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(PlanUIKitSurface.label)
                    Text("新的执行要点已写入下方卡片")
                        .font(.subheadline)
                        .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.tealDeep)
                        Text(result.adjustedName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(PlanUIKitSurface.label)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(result.adjustedDescription)
                        .font(.system(size: 15))
                        .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                    if !result.reason.isEmpty {
                        Divider()
                        Text(result.reason)
                            .font(.system(size: 14))
                            .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PlanUIKitSurface.secondaryGrouped)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onDismiss()
                } label: {
                    Text("知道了")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.sageLight)
                .controlSize(.large)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .navigationTitle("调整结果")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct AddMicroExerciseSheet: View {
    let onCancel: () -> Void
    let onConfirm: (String, Int) -> Void

    @State private var name: String = ""
    @State private var duration: Double = 3
    @FocusState private var nameFieldFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("添加后将出现在当前场景（工位 / 通勤 / 居家）下，并带有默认要领模板。")
                        .font(.footnote)
                        .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                }
                Section("名称") {
                    TextField("例如：办公室肩颈绕环", text: $name)
                        .focused($nameFieldFocused)
                        .textInputAutocapitalization(.never)
                }
                Section("单次时长") {
                    Stepper(value: Binding(
                        get: { Int(duration) },
                        set: { duration = Double($0) }
                    ), in: 1...10) {
                        HStack {
                            Text("时长")
                            Spacer()
                            Text("\(Int(duration)) 分钟")
                                .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                                .monospacedDigit()
                        }
                    }
                }
            }
            .navigationTitle("自定义动作")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onConfirm(trimmedName, Int(duration))
                    }
                    .disabled(trimmedName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .tint(Color.tealDeep)
            .onAppear {
                nameFieldFocused = true
            }
        }
    }
}

private struct MicroExerciseGuideSheet: View {
    let exercise: MicroExerciseItem
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(safeSystemName: exercise.displaySFPlanSymbol, fallback: "figure.walk")
                            .font(.system(size: 38))
                            .foregroundStyle(Color.tealDeep)
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 48, height: 48)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(exercise.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(PlanUIKitSurface.label)
                            HStack(spacing: 8) {
                                Label(exercise.duration, systemImage: "clock.fill")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.tealDeep)
                                Text(exercise.scene)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(PlanUIKitSurface.secondaryLabel)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(PlanUIKitSurface.secondaryGrouped)
                                    .clipShape(Capsule())
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Color.tealDeep.opacity(0.14), Color.sageBright.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    if !exercise.scenarioTips.isEmpty {
                        infoBlock(
                            title: "场景提示",
                            content: exercise.scenarioTips,
                            icon: "mappin.and.ellipse",
                            color: .orangeWarm
                        )
                    }

                    if !exercise.steps.isEmpty {
                        Text("动作步骤")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(PlanUIKitSurface.label)
                        ForEach(Array(exercise.steps.enumerated()), id: \.offset) { i, s in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(i + 1)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.tealDeep)
                                    .clipShape(Circle())
                                Text(s)
                                    .font(.system(size: 15))
                                    .foregroundStyle(PlanUIKitSurface.label)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(PlanUIKitSurface.secondaryGrouped)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }

                    if !exercise.breathingTips.isEmpty {
                        infoBlock(
                            title: "呼吸配合",
                            content: exercise.breathingTips,
                            icon: "wind",
                            color: .sageBright
                        )
                    }
                    if !exercise.benefits.isEmpty {
                        infoBlock(
                            title: "训练收益",
                            content: exercise.benefits,
                            icon: "heart.fill",
                            color: .tealDeep
                        )
                    }

                    if !exercise.commonMistakes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("常见误区", systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.orangeWarm)
                            ForEach(exercise.commonMistakes, id: \.self) { m in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(Color.orangeWarm.opacity(0.85))
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 6)
                                    Text(m)
                                        .font(.system(size: 14))
                                        .foregroundStyle(PlanUIKitSurface.label)
                                }
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orangeWarm.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    if !exercise.progression.isEmpty || !exercise.regression.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("进阶 / 退阶")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(PlanUIKitSurface.label)
                            if !exercise.progression.isEmpty {
                                tagLine(
                                    icon: "arrow.up.circle.fill",
                                    title: "进阶",
                                    text: exercise.progression,
                                    color: .tealDeep
                                )
                            }
                            if !exercise.regression.isEmpty {
                                tagLine(
                                    icon: "arrow.down.circle.fill",
                                    title: "退阶",
                                    text: exercise.regression,
                                    color: .grayMid
                                )
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PlanUIKitSurface.secondaryGrouped)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(20)
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
            .background(PlanUIKitSurface.grouped)
            .navigationTitle("动作指南")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Divider()
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onDismiss()
                    } label: {
                        Label("开始跟练", systemImage: "play.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.tealDeep)
                    .controlSize(.large)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                }
            }
            .tint(Color.tealDeep)
        }
    }

    private func infoBlock(title: String, content: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
            Text(content)
                .font(.system(size: 14))
                .foregroundStyle(PlanUIKitSurface.label)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func tagLine(icon: String, title: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(color)
                Text(text).font(.system(size: 14)).foregroundStyle(PlanUIKitSurface.label)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PlanView()
        .environmentObject(DataManager.shared)
        .environmentObject(NavigationCoordinator.shared)
}
