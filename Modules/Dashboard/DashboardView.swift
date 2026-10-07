import Combine
import SwiftUI
import UIKit
// Debug visualization toggle for dashboard sections
private let DEBUG_VISUALIZE_DASHBOARD_SECTIONS = false

extension View {
    @ViewBuilder
    func debugOutline(_ name: String) -> some View {
        if DEBUG_VISUALIZE_DASHBOARD_SECTIONS {
            self
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.6), lineWidth: 1)
                )
                .overlay(
                    Text(name)
                        .font(.caption2)
                        .padding(4)
                        .background(Color.red.opacity(0.12))
                        .cornerRadius(4)
                        .offset(x: 12, y: -12),
                    alignment: .topLeading
                )
        } else {
            self
        }
    }
}
// MARK: - Hero底部弧形裁切
struct HeroBottomArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let arcStartY = rect.height * 0.86
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: arcStartY))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: arcStartY),
            control: CGPoint(x: rect.width * 0.5, y: rect.height * 1.08)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - 卡片装饰纹样
enum CardPatternStyle: CaseIterable {
    case fluidBlobs, stripesBlocks, starFrames, radiantLines
    case ovalSpring, crossNodes, softCurves

    /// Kotlin `LocalDate.dayOfWeek.value` Mon=1 … Sun=7 ↔ `DashboardScreenV2.themeForDate`
    static func forJavaWeekday(_ j: Int) -> CardPatternStyle {
        switch j {
        case 1: return .fluidBlobs
        case 2: return .stripesBlocks
        case 3: return .starFrames
        case 4: return .radiantLines
        case 5: return .ovalSpring
        case 6: return .crossNodes
        default: return .softCurves
        }
    }
}

// MARK: - 日主题（与 Kotlin `DashboardScreenV2.themeForDate(LocalDate.dayOfWeek.value)` 一致）
struct DayTheme {
    let primary: Color
    let secondary: Color
    let blobLight: Color
    let tag: String
    let gradientStart: Color
    let gradientMid: Color
    let gradientEnd: Color
    let lineColor: Color
    let patternStyle: CardPatternStyle

    /// `javaWeekday`：周一=1 … 周日=7（同 Android `DayOfWeek.value`）
    /// 配色：清新通透基础上略提饱和度，刘海区更有活力、仍避免荧光刺眼。
    static func forJavaWeekday(_ java: Int) -> DayTheme {
        switch java {
        case 1: // Mon — 冰川薄荷（活力青碧）
            return DayTheme(
                primary: Color(hex: "#2B8F9C"), secondary: Color(hex: "#4BC0D0"), blobLight: Color(hex: "#D3F2F7"),
                tag: "周期修复",
                gradientStart: Color(hex: "#B8E8F2"), gradientMid: Color(hex: "#72D4E4"), gradientEnd: Color(hex: "#48B8CC"),
                lineColor: Color(hex: "#2A9BA8"),
                patternStyle: .fluidBlobs)
        case 2: // Tue — 玫瑰活力（雾粉偏玫）
            return DayTheme(
                primary: Color(hex: "#C4528E"), secondary: Color(hex: "#E085B5"), blobLight: Color(hex: "#FCE8F2"),
                tag: "关节激活",
                gradientStart: Color(hex: "#F8D2E6"), gradientMid: Color(hex: "#ECA8CA"), gradientEnd: Color(hex: "#E088B8"),
                lineColor: Color(hex: "#B84884"),
                patternStyle: .stripesBlocks)
        case 3: // Wed — 薰衣草活力（天光蓝紫）
            return DayTheme(
                primary: Color(hex: "#5568D4"), secondary: Color(hex: "#8899EE"), blobLight: Color(hex: "#E8ECFD"),
                tag: "睡眠改善",
                gradientStart: Color(hex: "#D4E0FA"), gradientMid: Color(hex: "#A8BCF2"), gradientEnd: Color(hex: "#8AA4EA"),
                lineColor: Color(hex: "#4E62C8"),
                patternStyle: .starFrames)
        case 4: // Thu — 森氧活力（翡翠雾）
            return DayTheme(
                primary: Color(hex: "#388F7A"), secondary: Color(hex: "#5CC4A8"), blobLight: Color(hex: "#DCF5EC"),
                tag: "训练恢复",
                gradientStart: Color(hex: "#C4EBDD"), gradientMid: Color(hex: "#8FD9BF"), gradientEnd: Color(hex: "#5CC9A0"),
                lineColor: Color(hex: "#2E8B72"),
                patternStyle: .radiantLines)
        case 5: // Fri — 芽绿活力（橄榄金带翠）
            return DayTheme(
                primary: Color(hex: "#8A9A42"), secondary: Color(hex: "#A8B85E"), blobLight: Color(hex: "#EEF3DC"),
                tag: "压力疏导",
                gradientStart: Color(hex: "#E2ECC8"), gradientMid: Color(hex: "#CED9A0"), gradientEnd: Color(hex: "#B8C878"),
                lineColor: Color(hex: "#7A8C38"),
                patternStyle: .ovalSpring)
        case 6: // Sat — 珊瑚活力（蜜桃偏橘）
            return DayTheme(
                primary: Color(hex: "#D85868"), secondary: Color(hex: "#EF8A96"), blobLight: Color(hex: "#FFECEE"),
                tag: "心肺唤醒",
                gradientStart: Color(hex: "#FCD0D6"), gradientMid: Color(hex: "#F9A0AC"), gradientEnd: Color(hex: "#F07888"),
                lineColor: Color(hex: "#C84858"),
                patternStyle: .crossNodes)
        default: // Sun 7 — 暮霭琥珀（周末暖阳；与周一冰川青碧、周六珊瑚区分）
            return DayTheme(
                primary: Color(hex: "#B56F38"), secondary: Color(hex: "#D99462"), blobLight: Color(hex: "#FFF4EA"),
                tag: "轻松收束",
                gradientStart: Color(hex: "#FFE8D4"), gradientMid: Color(hex: "#EEBC88"), gradientEnd: Color(hex: "#D49252"),
                lineColor: Color(hex: "#9A5C28"),
                patternStyle: .softCurves)
        }
    }
}

// MARK: - 场景标签压缩
func adviceEmojiForHero(_ text: String) -> String {
    if text.range(of: "睡眠|早睡|休息|入睡", options: .regularExpression) != nil { return "😴" }
    if text.range(of: "焦虑|压力|放松|冥想|呼吸", options: .regularExpression) != nil { return "🧘" }
    if text.range(of: "步行|快走|有氧|训练|运动", options: .regularExpression) != nil { return "🏃" }
    if text.range(of: "饮食|蔬菜|蛋白|水果|早餐|晚餐|热量|盐|糖", options: .regularExpression) != nil { return "🥗" }
    return "✨"
}

func compactSceneTag(_ rawTag: String) -> String {
    if rawTag.contains("睡眠") { return "睡眠节律" }
    if rawTag.contains("压力") { return "情绪调节" }
    if rawTag.contains("周期") { return "周期修复" }
    if rawTag.contains("恢复") { return "训练恢复" }
    if rawTag.contains("关节") { return "关节激活" }
    if rawTag.contains("心肺") { return "心肺唤醒" }
    if rawTag.contains("收束") { return "轻松收束" }
    let prefix = rawTag.prefix(6)
    return String(prefix)
}

/// Hero 刘海区底纹：升弧 + 通幅柔曲 + 微粒；叠层侧由 `multiply` 与高光强度协同以保证可见。
struct HeroPatternOverlay: View {
    let theme: DayTheme

    private var patternPhase: CGFloat {
        CGFloat(CardPatternStyle.allCases.firstIndex(of: theme.patternStyle) ?? 0)
    }

    var body: some View {
        GeometryReader { geo in
            let w = max(geo.size.width, 1)
            let h = max(geo.size.height, 1)
            Canvas { context, _ in
                HeroPatternDrawing.atmosphericMinimal(
                    context: &context,
                    theme: theme,
                    w: w,
                    h: h,
                    phase: patternPhase
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
}

private enum HeroPatternDrawing {
    /// 参考系统级大色块 Hero：锚点在屏幕下方外的「升弧」保证可见；辅以通幅柔曲与微粒，对比度足够但仍克制。
    static func atmosphericMinimal(
        context: inout GraphicsContext,
        theme: DayTheme,
        w: CGFloat,
        h: CGFloat,
        phase: CGFloat
    ) {
        let mn = min(w, h)
        let ink = theme.lineColor
        let mist = theme.secondary
        let air = theme.blobLight

        risingArcs(context: &context, w: w, h: h, mn: mn, ink: ink, phase: phase)
        flowContours(context: &context, w: w, h: h, ink: ink, phase: phase)
        softBlooms(context: &context, w: w, h: h, mn: mn, mist: mist, air: air, phase: phase)
        filmGrain(context: &context, w: w, h: h, ink: ink, phase: phase)
    }

    /// 圆心在底部边线之下，只画上沿弧带 — 类似 Apple 天气 / Fitness 大卡片底缘的气层曲线。
    static func risingArcs(
        context: inout GraphicsContext,
        w: CGFloat,
        h: CGFloat,
        mn: CGFloat,
        ink: Color,
        phase: CGFloat
    ) {
        let cx = w * (0.48 + sin(phase * 0.45) * 0.06)
        let cy = h * 1.22 + cos(phase * 0.4) * mn * 0.04
        let strokeLo = StrokeStyle(lineWidth: 0.9, lineCap: .round)

        for i in 0 ..< 6 {
            let r = mn * (0.34 + CGFloat(i) * 0.088)
            let alpha = 0.26 - CGFloat(i) * 0.03
            var arc = Path()
            arc.addArc(
                center: CGPoint(x: cx, y: cy),
                radius: r,
                startAngle: .degrees(195 + Double(phase) * 2.5 + Double(i) * 1.2),
                endAngle: .degrees(345 + Double(i) * 0.5),
                clockwise: false
            )
            context.stroke(arc, with: .color(ink.opacity(max(0.08, alpha))), style: strokeLo)
        }
    }

    /// 通幅轻盈等高线，确保一定落在可视区内。
    static func flowContours(
        context: inout GraphicsContext,
        w: CGFloat,
        h: CGFloat,
        ink: Color,
        phase: CGFloat
    ) {
        let strokeStyle = StrokeStyle(lineWidth: 0.85, lineCap: .round, lineJoin: .round)
        for i in 0 ..< 4 {
            var path = Path()
            let baseY = h * (0.38 + CGFloat(i) * 0.11)
            path.move(to: CGPoint(x: 0, y: baseY))
            let segments = 12
            for s in 0 ..< segments {
                let t0 = CGFloat(s) / CGFloat(segments)
                let t1 = CGFloat(s + 1) / CGFloat(segments)
                let x1 = w * t1
                let mid = w * (t0 + t1) / 2
                let amp = h * 0.014 * (1 + 0.1 * sin(phase + CGFloat(i)))
                let sway = sin(phase * 0.85 + CGFloat(i) * 0.5 + t0 * 2 * CGFloat.pi) * amp
                path.addQuadCurve(
                    to: CGPoint(x: x1, y: baseY + sway * 0.32),
                    control: CGPoint(x: mid, y: baseY + sway))
            }
            context.stroke(path, with: .color(ink.opacity(0.17)), style: strokeStyle)
        }

        let tilt = CGFloat(Double(phase) * 0.012)
        var horizon = Path()
        let y0 = h * 0.62
        horizon.move(to: CGPoint(x: w * 0.05, y: y0 + w * 0.05 * tilt))
        horizon.addLine(to: CGPoint(x: w * 0.97, y: y0 - w * 0.045 * tilt))
        context.stroke(
            horizon,
            with: .color(ink.opacity(0.12)),
            style: StrokeStyle(lineWidth: 0.55, lineCap: .round))
    }

    static func softBlooms(
        context: inout GraphicsContext,
        w: CGFloat,
        h: CGFloat,
        mn: CGFloat,
        mist: Color,
        air: Color,
        phase: CGFloat
    ) {
        let rMist = mn * 0.44
        let ox = sin(phase * 0.5) * mn * 0.03
        context.fill(
            Ellipse().path(in: CGRect(
                x: w * 0.58 - rMist * 0.45 + ox,
                y: h * 0.48 - rMist * 0.32,
                width: rMist * 1.05,
                height: rMist * 0.72
            )),
            with: .color(mist.opacity(0.14))
        )
        let rAir = mn * 0.3
        context.fill(
            Circle().path(in: CGRect(x: -rAir * 0.4, y: h * 0.55 - rAir, width: rAir * 2, height: rAir * 2)),
            with: .color(air.opacity(0.13))
        )
    }

    static func filmGrain(context: inout GraphicsContext, w: CGFloat, h: CGFloat, ink: Color, phase: CGFloat) {
        let cols = 12
        let rows = 8
        for row in 0 ..< rows {
            for col in 0 ..< cols {
                let u = CGFloat(col) / CGFloat(max(cols - 1, 1))
                let v = CGFloat(row) / CGFloat(max(rows - 1, 1))
                if v < 0.28 { continue }

                let jx = sin(phase * 1.15 + u * 17.3 + v * 11.1) * 3.2
                let jy = cos(phase * 0.85 + u * 13.7 + v * 19.2) * 3.2
                let x = w * (0.1 + u * 0.86) + jx
                let y = h * (0.34 + v * 0.64) + jy

                let g = 0.055 + 0.035 * sin(phase + u * 22 + v * 15)
                let d = CGFloat(0.65 + 0.45 * sin(phase * 2 + CGFloat(col + row)))

                context.fill(
                    Circle().path(in: CGRect(x: x - d * 0.5, y: y - d * 0.5, width: d, height: d)),
                    with: .color(ink.opacity(g))
                )
            }
        }
    }
}

// MARK: - 首页滚动区背景（对齐系统「分组」美学 + 每日 Hero 主题色晕染）

/// 中性底为 `systemGroupedBackground`；其上用当日 `DayTheme` 做多层渐变叠色（色相清晰可辨、不靠黑色压暗），与 Hero 一致。
struct DashboardAdaptiveBackground: View {
    let theme: DayTheme

    @Environment(\.colorScheme) private var colorScheme

    /// 深色模式下略收敛饱和度，仍保证当日色相一眼可辨。
    private var themeStrength: Double {
        colorScheme == .dark ? 0.70 : 1.0
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = max(geo.size.height, 1)
            let k = themeStrength
            ZStack {
                Color(.systemGroupedBackground)

                // 主铺色：gradientStart → Mid → blobLight，自上而下渐变铺开，底部溶入透明
                LinearGradient(
                    stops: [
                        .init(color: theme.gradientStart.opacity(0.30 * k), location: 0),
                        .init(color: theme.gradientMid.opacity(0.165 * k), location: min(0.38, 420 / h)),
                        .init(color: theme.blobLight.opacity(0.218 * k), location: min(0.58, 560 / h)),
                        .init(color: Color.clear, location: 1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottom
                )

                // primary 极薄罩层：强化「当日主题」色相（透明度低，不糊屏）
                LinearGradient(
                    stops: [
                        .init(color: theme.primary.opacity(0.055 * k), location: 0),
                        .init(color: Color.clear, location: min(0.52, 520 / h)),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // 辅向渐变：secondary 扫过，与其他层合成完整渐变
                LinearGradient(
                    stops: [
                        .init(color: theme.secondary.opacity(0.118 * k), location: 0),
                        .init(color: Color.clear, location: 0.58),
                    ],
                    startPoint: .bottomTrailing,
                    endPoint: UnitPoint(x: 0.2, y: 0.15)
                )

                RadialGradient(
                    colors: [
                        theme.secondary.opacity(0.21 * k),
                        Color.clear,
                    ],
                    center: UnitPoint(x: 0.14, y: 0.07),
                    startRadius: 16,
                    endRadius: w * 0.92
                )

                // 顶区透气高光：blobLight，与主题同属一个色系
                RadialGradient(
                    colors: [
                        theme.blobLight.opacity(0.54 * k),
                        Color.clear,
                    ],
                    center: .top,
                    startRadius: 28,
                    endRadius: w * 0.82
                )
                .opacity(0.78)

                // 底部收束：gradientEnd 加深当日色尾韵
                LinearGradient(
                    colors: [
                        Color.clear,
                        theme.gradientEnd.opacity(0.095 * k),
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
    }
}

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showHeroCalendarSheet = false
    @State private var heroCalendarDraft = Date()
    @State private var showBreathingPopup = false

    private var sectionRevealStep: Double { DashboardV2Spacing.sectionRevealStagger }

    var body: some View {
        ZStack {
            DashboardAdaptiveBackground(theme: viewModel.dayTheme)

            // Debug helper: temporarily visualize section bounds to find overflow sources
            // Toggle with `DEBUG_VISUALIZE_DASHBOARD_SECTIONS` below
            

            GeometryReader { proxy in
                ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Group {
                            DashboardV2HeroSection(viewModel: viewModel) {
                                heroCalendarDraft = viewModel.selectedDate
                                showHeroCalendarSheet = true
                            }
                        }
                        .debugOutline("Hero")
                        .uiDemoTopAnchor()

                        VStack(spacing: DashboardV2Spacing.sectionGap) {
                            if let error = viewModel.error {
                                DashboardErrorBanner(message: error)
                                    .aegisReveal(delay: 0)
                            }

                            Group {
                                DashboardV2RecordsSection(
                                    viewModel: viewModel,
                                    onPlusTap: { viewModel.toggleTypePicker() },
                                    onTypeTap: { type in
                                        viewModel.openLogSheet(type: type)
                                    })
                            }
                            .debugOutline("Records")
                            .aegisReveal(delay: sectionRevealStep * 1)

                            Group {
                                DashboardV2GoalSection(viewModel: viewModel)
                            }
                            .debugOutline("Goal")
                            .aegisReveal(delay: sectionRevealStep * 2)

                            Group {
                                DashboardV2BiometricTodaySection(viewModel: viewModel)
                            }
                            .debugOutline("Biometric")
                            .aegisReveal(delay: sectionRevealStep * 3)

                            Group {
                                DashboardV2TodayDataSection(viewModel: viewModel)
                            }
                            .debugOutline("TodayData")
                            .aegisReveal(delay: sectionRevealStep * 4)

                            Group {
                                DashboardV2ReminderSection(text: viewModel.exerciseReminderCardText) {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showBreathingPopup = true
                                    }
                                }
                            }
                            .debugOutline("Reminder")
                            .aegisReveal(delay: sectionRevealStep * 5)

                            Group {
                                DashboardV2NotificationSection(items: viewModel.notificationPreview) {
                                    NavigationCoordinator.shared.navigate(to: .notificationCenter)
                                }
                            }
                            .debugOutline("Notifications")
                            .aegisReveal(delay: sectionRevealStep * 6)

                            Group {
                                DashboardV2NutritionOverviewSection()
                            }
                            .debugOutline("Nutrition")
                            .aegisReveal(delay: sectionRevealStep * 7)

                            Group {
                                DashboardV2DataAnalysisSection()
                            }
                            .debugOutline("DataAnalysis")
                            .aegisReveal(delay: sectionRevealStep * 8)

                            Group {
                                DashboardV2TrendSection(viewModel: viewModel)
                            }
                            .debugOutline("Trend")
                            .aegisReveal(delay: sectionRevealStep * 9)

                            Group {
                                DashboardV2TodayGoalsSection(viewModel: viewModel)
                            }
                            .debugOutline("TodayGoals")
                            .aegisReveal(delay: sectionRevealStep * 10)

                            Group {
                                DashboardV2InsightsSection(viewModel: viewModel) {
                                    NavigationCoordinator.shared.navigate(to: .knowledgeGraph)
                                }
                            }
                            .debugOutline("Insights")
                            .aegisReveal(delay: sectionRevealStep * 11)
                        }
                        .padding(.horizontal, DashboardV2Spacing.pageHorizontal)
                        .padding(.top, DashboardV2Spacing.scrollContentTopInset)
                        .padding(.bottom, AegisSpacing.bottomSafe)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .uiDemoBottomAnchor()
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .refreshable {
                    await viewModel.refreshDashboard()
                }
                .uiDemoPerformAutoScroll(proxy: scrollProxy)
                }
            }
        }
        .overlay {
            if showBreathingPopup {
                BreathingPopupView(isPresented: $showBreathingPopup)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .environment(\.dashboardSectionAccent, viewModel.dayTheme.primary)
        // 路由由 MainTabView 的 NavigationStack + navigationDestination 统一承载，
        // 此处再挂一份会导致 statistics/knowledge/food 等 push 失败、截图仍停在首页。
        .onAppear {
            viewModel.loadData()
            #if DEBUG
            if NavigationCoordinator.shared.uiDemoPresentLogPicker {
                NavigationCoordinator.shared.uiDemoPresentLogPicker = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    viewModel.showTypePicker = true
                }
            }
            #endif
        }
        .sheet(isPresented: $showHeroCalendarSheet) {
            NavigationStack {
                Form {
                    Section {
                        DatePicker(
                            "日期",
                            selection: $heroCalendarDraft,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .accessibilityLabel("选择日期")
                    } header: {
                        Text("日历")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    } footer: {
                        Text("首页统计与关怀内容将随所选日期刷新。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
                .navigationTitle("选择日期")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消", role: .cancel) {
                            showHeroCalendarSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") {
                            viewModel.selectDate(heroCalendarDraft)
                            showHeroCalendarSheet = false
                        }
                        .fontWeight(.semibold)
                    }
                }
                .toolbarBackground(.automatic, for: .navigationBar)
            }
            .tint(viewModel.dayTheme.primary)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationBackground(.regularMaterial)
            .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $viewModel.showLogSheet) {
            if let logType = viewModel.currentLogType {
                LogBottomSheet(
                    logType: logType,
                    isPresented: $viewModel.showLogSheet,
                    dateContextLine: viewModel.logSheetDateContextLine
                )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.regularMaterial)
                    .presentationContentInteraction(.scrolls)
            }
        }
        .sheet(isPresented: $viewModel.showTypePicker) {
                RecordTypePickerSheet(
                accent: viewModel.dayTheme.primary,
                onSelect: { type in
                    viewModel.showTypePicker = false
                    DispatchQueue.main.async {
                        viewModel.openLogSheet(type: type)
                    }
                },
                onCancel: {
                    viewModel.showTypePicker = false
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationBackground(.regularMaterial)
            .presentationContentInteraction(.scrolls)
        }
    }
}

struct DashboardErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.orange.opacity(0.22), lineWidth: 1)
                }
        }
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

struct DashboardV2Greeting: View {
    let greeting: String
    let userName: String
    let subtitle: String

    private var displayName: String { userName.isEmpty ? "用户" : userName }

    private var readableMaxWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let safeWidth = screenWidth - (DashboardV2Spacing.heroContentHorizontalPadding * 2) - 12
        return min(DashboardV2Spacing.heroReadableMaxWidth, max(240, safeWidth))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DashboardV2Spacing.heroGreetingTitleSubtitleGap) {
            // 分段字重：问候语略轻、姓名略重，扫读时层次更清晰（对齐系统「标题 + 强调」习惯）
            (Text("\(greeting)，").fontWeight(.semibold) + Text(displayName).fontWeight(.bold))
                .font(.title3)
                .foregroundStyle(.primary)
                .kerning(-0.15)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .accessibilityAddTraits(.isHeader)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .lineLimit(3)
                    .minimumScaleFactor(0.88)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: readableMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DashboardV2HeroCareColumn: View {
    @ObservedObject var viewModel: DashboardViewModel
    let theme: DayTheme
    /// 非空时在弧底区域内限制高度并启用内部纵向滚动，防止大字块溢出裁切
    var contentMaxHeight: CGFloat? = nil

    /// 中间主文案：整体较前一档略小一号，减轻弧形容器内溢出与压迫感
    private var mainFontSize: CGFloat {
        let hasSubtitle = viewModel.heroSubtitleText != nil
        if hasSubtitle && viewModel.heroIsLongBody { return 20 }
        if hasSubtitle { return 22 }
        if viewModel.heroIsLongBody { return 24 }
        return 26
    }

    /// 中文长正文：略收紧行距，避免「行间空洞」或挤压感不一
    private var bodyLineSpacing: CGFloat {
        max(4, min(8, mainFontSize * 0.22))
    }

    private var readableMaxWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let safeWidth = screenWidth - (DashboardV2Spacing.heroContentHorizontalPadding * 2) - 12
        return min(DashboardV2Spacing.heroReadableMaxWidth, max(240, safeWidth))
    }

    @ViewBuilder
    private var primaryBodyText: some View {
        if contentMaxHeight == nil {
            Text(viewModel.heroPrimaryBodyText)
                .font(.system(size: mainFontSize, weight: .semibold, design: .default))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineSpacing(bodyLineSpacing)
                .minimumScaleFactor(0.88)
                .lineLimit(viewModel.heroSubtitleText != nil ? 4 : 4)
        } else {
            Text(viewModel.heroPrimaryBodyText)
                .font(.system(size: mainFontSize, weight: .semibold, design: .default))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineSpacing(bodyLineSpacing)
                .minimumScaleFactor(0.88)
        }
    }

    var body: some View {
        let scene = compactSceneTag(theme.tag)
        let stack = VStack(alignment: .leading, spacing: 0) {
            // 元信息胶囊：左对齐、统一高度，避免与正文「左右打架」
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 8) {
                    chip(scene, style: .glass)
                    if let nutrient = viewModel.heroFocusNutrientTrimmed {
                        chip("💡 \(nutrient)", style: .accent)
                    }
                    chip(viewModel.heroCareBadgeText, style: .muted)
                }
                .padding(.vertical, 2)
            }
            .padding(.bottom, 8)

            if let subtitle = viewModel.heroSubtitleText {
                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .lineLimit(2)
                    .minimumScaleFactor(0.88)
                    .padding(.bottom, 8)
            }

            primaryBodyText
                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)

            if let advice = viewModel.heroMealAdviceTrimmed {
                let emoji = adviceEmojiForHero(advice)
                VStack(alignment: .leading, spacing: 6) {
                    Divider()
                        .opacity(0.35)
                        .padding(.top, 10)
                    Text("今日建议 \(emoji)  \(advice)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(3)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
            }
        }
        .frame(maxWidth: readableMaxWidth, alignment: .leading)

        Group {
            if let cap = contentMaxHeight {
                ScrollView(.vertical, showsIndicators: false) {
                    stack
                        .padding(.bottom, 18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: cap)
                .clipped()
            } else {
                stack
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private enum ChipStyle {
        case glass, accent, muted
    }

    private func chip(_ text: String, style: ChipStyle) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(
                style == .accent ? Color(hex: "#166534") : .primary.opacity(style == .muted ? 0.82 : 0.9)
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(chipFill(style))
            }
    }

    private func chipFill(_ style: ChipStyle) -> Color {
        switch style {
        case .glass: return Color.white.opacity(0.34)
        case .accent: return Color(hex: "#DCFCE7").opacity(0.95)
        case .muted: return Color.white.opacity(0.42)
        }
    }
}

struct DashboardV2HeroSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    let onCalendarTap: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

    private var theme: DayTheme { viewModel.dayTheme }

    private var heroHeight: CGFloat {
        let h = UIScreen.main.bounds.height
        return min(max(h * 0.52, 360), 520)
    }

    /// 与 `HeroBottomArcShape`（弧底约 0.86h）对齐：略加大留白，避免最后一行贴弧底被裁切
    private var heroArcInteriorBottomInset: CGFloat {
        max(58, heroHeight * 0.108)
    }

    /// 下半区关怀文案最大高度：略抬高上限，弧内少挤最后一行
    private var heroCareColumnMaxHeight: CGFloat {
        max(126, heroHeight * 0.345)
    }

    /// 降低透明度 / 低电量：略减饱和与高光，减轻「壁纸 + 装饰层」对视觉与 GPU 的压力
    private var softenHeroWallpaper: Bool {
        reduceTransparency || isLowPowerMode
    }

    /// 弧形内缘高光（仅白/透明，不替换 DayTheme 色值）
    private var edgeHighlightColors: [Color] {
        let a = softenHeroWallpaper ? 0.4 : 0.62
        return [
            Color.white.opacity(a),
            Color.white.opacity(0.16),
            Color.white.opacity(0.05),
        ]
    }

    @ViewBuilder
    private func heroGradientStack(heroHeight: CGFloat) -> some View {
        GeometryReader { innerGeo in
            let w = innerGeo.size.width
            let g = min(w, heroHeight) * 1.08
            let s = softenHeroWallpaper
        // 顶、斜向「空气感」高光与底部轻压影：中性色叠层，通透立体
        let topA: CGFloat = s ? 0.18 : 0.32
        let diagA: CGFloat = s ? 0.07 : 0.13
        let botA: CGFloat = s ? 0.04 : 0.09
        let specA: CGFloat = s ? 0.09 : 0.18

        ZStack {
            LinearGradient(
                colors: [theme.gradientStart, theme.gradientMid, theme.gradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .saturation(s ? 0.74 : 1)
            .opacity(s ? 0.94 : 1)

            // 中心强光略收一档，避免把顶层 Canvas 底纹「漂没」
            RadialGradient(
                colors: s
                    ? [Color.white.opacity(0.11), Color.white.opacity(0.035), Color.clear]
                    : [Color.white.opacity(0.22), Color.white.opacity(0.075), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: g
            )

            LinearGradient(
                colors: [Color.white.opacity(topA), Color.white.opacity(0.05), Color.clear],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.62)
            )
            .blendMode(.screen)

            LinearGradient(
                colors: [Color.white.opacity(diagA), Color.clear],
                startPoint: .topLeading,
                endPoint: UnitPoint(x: 0.72, y: 0.58)
            )
            .blendMode(.screen)

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(botA)],
                startPoint: UnitPoint(x: 0.5, y: 0.42),
                endPoint: .bottom
            )
            .blendMode(.multiply)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(specA), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: w * 0.42
                    )
                )
                .frame(width: w * 0.92, height: heroHeight * 0.42)
                .offset(y: -heroHeight * 0.34)
                .blendMode(.screen)
                .allowsHitTesting(false)

            // 刘海 / 灵动岛下缘：极淡压影，增强层次但不抢内容（对齐大厂卡片顶缘处理）
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        Color.black.opacity(s ? 0.03 : 0.052),
                        Color.clear,
                    ],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.32)
                )
                .frame(height: min(heroHeight * 0.36, 132))
                Spacer(minLength: 0)
            }
            .blendMode(.multiply)
            .allowsHitTesting(false)

            // 底纹叠在高光之上；multiply 在浅色渐变上压暗一线，比 overlay/softLight 更易读出纹样
            HeroPatternOverlay(theme: theme)
                .compositingGroup()
                .blendMode(.multiply)
                .opacity(s ? 0.85 : 0.94)
                .allowsHitTesting(false)
        }
        .frame(height: heroHeight)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            heroGradientStack(heroHeight: heroHeight)
                .frame(maxWidth: .infinity)
                .frame(height: heroHeight)
                .clipShape(HeroBottomArcShape())
                .overlay {
                    HeroBottomArcShape()
                        .stroke(
                            LinearGradient(
                                colors: edgeHighlightColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color.black.opacity(softenHeroWallpaper ? 0.05 : 0.09), radius: 22, x: 0, y: 14)
                .shadow(color: Color.white.opacity(softenHeroWallpaper ? 0.12 : 0.22), radius: 0, x: 0, y: -1)

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: DashboardV2Spacing.heroChromeGap) {
                    DashboardV2TopBar(
                        dateTitle: viewModel.formattedDateTitle,
                        unreadCount: viewModel.unreadNotificationCount,
                        onNotificationTap: { NavigationCoordinator.shared.navigate(to: .notificationCenter) },
                        onCalendarTap: onCalendarTap
                    )
                    DashboardV2WeekStrip(
                        dates: viewModel.weekDates,
                        selectedDate: viewModel.selectedDate,
                        todayDate: Calendar.current.startOfDay(for: Date())
                    ) { date in
                        viewModel.selectDate(date)
                    }
                }
                .padding(.horizontal, DashboardV2Spacing.heroContentHorizontalPadding)

                DashboardV2Greeting(
                    greeting: viewModel.greeting,
                    userName: viewModel.displayNameForGreeting(),
                    subtitle: viewModel.greetingSubtitle
                )
                .padding(.horizontal, DashboardV2Spacing.heroContentHorizontalPadding)
                .padding(.top, DashboardV2Spacing.heroWeekToGreetingGap)

                Spacer(minLength: DashboardV2Spacing.heroBodyTopGap)

                DashboardV2HeroCareColumn(
                    viewModel: viewModel,
                    theme: theme,
                    contentMaxHeight: heroCareColumnMaxHeight
                )
                    .padding(.horizontal, DashboardV2Spacing.heroContentHorizontalPadding)
                    .padding(.bottom, heroArcInteriorBottomInset)
            }
            .frame(height: heroHeight, alignment: .top)
            .frame(maxWidth: .infinity)
            // 略加大顶部安全区内边距，避免问候/日期视觉上切入刘海与灵动岛区域
            .safeAreaPadding(.top, 14)
            // 与背景同一弧底裁切：文字绝不画出圆弧边界（对标卡片内容的「形随轮廓」）
            .clipShape(HeroBottomArcShape())
        }
        .frame(height: heroHeight)
        .onAppear {
            isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NSProcessInfoPowerStateDidChange"))) { _ in
            isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }
}

// legacy sections removed after V2 split

// MARK: - 记录卡片
struct RecordCard: View {
    let type: LogType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(type.emoji)
                    .font(.system(size: 28))
                
                Text(type.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.grayDark)
            }
            .frame(width: 75, height: 90)
            .background(Color.white)
            .cornerRadius(AegisCornerRadius.medium)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(AegisBouncyCardStyle())
    }
}

// MARK: - 目标进度区域
struct GoalSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // 步数
            GoalProgressCard(
                icon: "figure.walk",
                title: "步数",
                value: viewModel.dailySteps,
                goal: viewModel.stepsGoal,
                progress: viewModel.stepProgress,
                unit: "步",
                color: .tealDeep
            )
            
            HStack(spacing: 12) {
                // 饮水
                GoalProgressCard(
                    icon: "drop.fill",
                    title: "饮水量",
                    value: viewModel.waterIntake,
                    goal: viewModel.waterGoal,
                    progress: viewModel.waterProgress,
                    unit: "ml",
                    color: .androidBlue,
                    isCompact: true
                )
                
                // 卡路里
                GoalProgressCard(
                    icon: "flame.fill",
                    title: "消耗",
                    value: viewModel.caloriesBurned,
                    goal: viewModel.caloriesGoal,
                    progress: viewModel.caloriesProgress,
                    unit: "kcal",
                    color: .orangeWarm,
                    isCompact: true
                )
            }
        }
    }
}

// MARK: - 目标进度卡片
struct GoalProgressCard: View {
    let icon: String
    let title: String
    let value: Int
    let goal: Int
    let progress: Double
    let unit: String
    let color: Color
    var isCompact: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.grayMid)
                
                Spacer()
                
                Text("\(value)")
                    .font(.system(size: isCompact ? 18 : 24, weight: .bold, design: .rounded))
                    .foregroundColor(.grayDark)
                
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundColor(.grayMid)
            }
            
            // 进度条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.15))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
            
            if !isCompact {
                Text("目标: \(goal)\(unit)")
                    .font(.system(size: 12))
                    .foregroundColor(.grayMid)
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 生理指标区域
struct BiometricSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionTitle(title: "生理指标")
            
            HStack(spacing: 12) {
                // 心率
                BiometricCard(
                    icon: "heart.fill",
                    title: "心率",
                    value: "\(viewModel.heartRate)",
                    unit: "bpm",
                    color: .errorRed
                )
                
                // 压力
                BiometricCard(
                    icon: "brain.head.profile",
                    title: "压力",
                    value: "\(viewModel.stressLevel)",
                    unit: "指数",
                    color: .purpleSoft
                )
            }
        }
    }
}

// MARK: - 生理指标卡片
struct BiometricCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.grayMid)
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.grayDark)
                    
                    Text(unit)
                        .font(.system(size: 11))
                        .foregroundColor(.grayMid)
                        .padding(.bottom, 2)
                }
            }
            
            Spacer()
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 营养概览
struct NutritionOverviewSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("营养摄入")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.grayDark)
            
            HStack(spacing: 16) {
                // 环形图
                DonutChartView(progress: 0.65, color: .successGreen)
                    .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 8) {
                    NutrientRow(label: "蛋白质", value: "45g", color: .androidBlue)
                    NutrientRow(label: "碳水", value: "120g", color: .orangeWarm)
                    NutrientRow(label: "脂肪", value: "30g", color: .purpleSoft)
                }
                
                Spacer()
            }
            .padding(AegisSpacing.cardPadding)
            .background(Color.white)
            .cornerRadius(AegisCornerRadius.large)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - 营养行
struct NutrientRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.grayMid)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.grayDark)
        }
    }
}

// MARK: - 环形图
struct DonutChartView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 10)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.grayDark)
        }
    }
}

// MARK: - 今日目标网格
struct TodayGoalGrid: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    private let goals: [(icon: String, title: String, progress: Double, color: Color)] = [
        ("figure.walk", "步行", 0.68, .tealDeep),
        ("drop.fill", "饮水", 0.4, .androidBlue),
        ("flame.fill", "消耗", 0.22, .orangeWarm),
        ("moon.fill", "睡眠", 0.88, .purpleSoft)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日目标")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.grayDark)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(goals, id: \.title) { goal in
                    GoalMiniCard(
                        icon: goal.icon,
                        title: goal.title,
                        progress: goal.progress,
                        color: goal.color
                    )
                }
            }
        }
    }
}

// MARK: - 目标迷你卡片
struct GoalMiniCard: View {
    let icon: String
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.grayDark)
            }
            
            // 进度条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.15))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.easeInOut(duration: 0.8), value: progress)
                }
            }
            .frame(height: 6)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.grayMid)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.medium)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 健康见解区域
struct InsightsSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionTitle(title: "健康见解")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.todayInsights) { insight in
                        InsightCard(item: insight)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
    }
}

// MARK: - 见解卡片
struct InsightCard: View {
    let item: InsightItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 24))
                .foregroundColor(item.color)
            
            Text(item.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.grayDark)
            
            Text(item.description)
                .font(.system(size: 13))
                .foregroundColor(.grayMid)
                .lineLimit(2)
        }
        .frame(width: 160, alignment: .leading)
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    DashboardView()
        .environmentObject(DataManager.shared)
}
