import SwiftUI

struct FitnessPopupContainerView: View {
    let plan: ExercisePlanItem
    let onClose: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var isPresented = false
    @Namespace private var tabIndicatorNamespace

    private let tabs = ["计划定制", "专业指导", "动作分解", "周计划"]

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: [Color(hex: "2C4E3D"), Color(hex: "5A8B2A")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 160)
                .overlay(Color.black.opacity(0.15))

                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.name)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    Text("\(plan.duration) · \(plan.intensity)强度 · 预计消耗 \(plan.calories)")
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 24)
                .padding(.top, 48)

                Button(action: closePopup) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .padding(.trailing, 16)
                .padding(.top, 16)
            }
            .frame(height: 160)

            HStack(alignment: .top, spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(action: { selectedTab = index }) {
                        VStack(spacing: 6) {
                            let splitText = splitTabTitle(tabs[index])
                            VStack(spacing: 2) {
                                Text(splitText.0)
                                Text(splitText.1)
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(selectedTab == index ? Color(hex: "87B836") : Color.gray.opacity(0.8))

                            ZStack {
                                if selectedTab == index {
                                    Capsule()
                                        .fill(Color(hex: "87B836"))
                                        .matchedGeometryEffect(id: "fitnessTabIndicator", in: tabIndicatorNamespace)
                                }
                            }
                            .frame(height: 3)
                            .padding(.horizontal, 8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 14)
            .background(Color(hex: "F4F9E4"))

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    switch selectedTab {
                    case 0: PlanCustomView()
                    case 1: ProfessionalGuideView()
                    case 2: ActionBreakdownView()
                    case 3: WeeklyPlanView()
                    default: EmptyView()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
                .id(selectedTab)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            .background(Color(hex: "F4F9E4"))
        }
        .frame(maxWidth: 375)
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 8)
        .padding(.horizontal, 16)
        .opacity(isPresented ? 1 : 0)
        .scaleEffect(isPresented ? 1 : 0.985)
        .offset(y: isPresented ? 0 : 10)
        .animation(.snappy(duration: 0.25, extraBounce: 0), value: isPresented)
        .animation(.snappy(duration: 0.28, extraBounce: 0), value: selectedTab)
        .onAppear {
            guard !isPresented else { return }
            isPresented = true
        }
    }

    private func splitTabTitle(_ title: String) -> (String, String) {
        if title.count == 4 {
            let index = title.index(title.startIndex, offsetBy: 2)
            return (String(title[..<index]), String(title[index...]))
        }
        return (title, "")
    }

    private func closePopup() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}

private struct PlanCustomView: View {
    @State private var targetCalories: Double = 250
    @State private var duration: Double = 45
    @State private var frequency: Double = 1
    @State private var warmUp: Double = 5
    @State private var stretch: Double = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            FitnessSectionHeader(icon: "flame.fill", title: "训练目标")
            FitnessSliderRow(title: "目标消耗", value: $targetCalories, range: 100...500, unit: "kcal", step: 10)
            FitnessSliderRow(title: "训练时长", value: $duration, range: 10...120, unit: "分钟", step: 1)

            FitnessSectionHeader(icon: "calendar", title: "每周频次")
            FitnessSliderRow(title: "每周训练", value: $frequency, range: 1...7, unit: "次/周", step: 1)

            FitnessSectionHeader(icon: "figure.cooldown", title: "热身与放松")
            FitnessSliderRow(title: "热身时长", value: $warmUp, range: 0...20, unit: "分钟", step: 1)
            FitnessSliderRow(title: "放松拉伸", value: $stretch, range: 0...20, unit: "分钟", step: 1)

            VStack(alignment: .leading, spacing: 10) {
                Text("方案预览")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "2C4E3D"))
                FitnessPreviewRow(label: "目标消耗", value: "\(Int(targetCalories)) kcal")
                FitnessPreviewRow(label: "总时长", value: "\(Int(duration + warmUp + stretch)) 分钟 (热身\(Int(warmUp))+训练\(Int(duration))+放松\(Int(stretch)))")
                FitnessPreviewRow(label: "每周频次", value: "\(Int(frequency)) 次/周")
                Divider()
                    .background(Color(hex: "87B836").opacity(0.2))
                    .padding(.vertical, 4)
                Text("运动前充分热身，运动后注意拉伸和补水")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "5A8B2A"))
            }
            .padding(16)
            .background(Color(hex: "EBF4D7"))
            .cornerRadius(16)
            .animation(.easeOut(duration: 0.18), value: targetCalories)
            .animation(.easeOut(duration: 0.18), value: duration)
            .animation(.easeOut(duration: 0.18), value: frequency)
            .animation(.easeOut(duration: 0.18), value: warmUp)
            .animation(.easeOut(duration: 0.18), value: stretch)
        }
    }
}

private struct ProfessionalGuideView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            FitnessSectionHeader(icon: "lightbulb.fill", title: "训练建议")
            VStack(spacing: 12) {
                FitnessGuideCard(number: "1", text: "循序渐进")
                FitnessGuideCard(number: "2", text: "保持专注")
                FitnessGuideCard(number: "3", text: "感受变化")
            }

            FitnessSectionHeader(icon: "heart.fill", title: "心率区间")
            VStack(spacing: 14) {
                FitnessHeartRateBar(zoneName: "热身区", rangeText: "50-60% HRmax", progress: 0.55, color: Color(hex: "87B836"))
                FitnessHeartRateBar(zoneName: "燃脂区", rangeText: "60-70% HRmax", progress: 0.68, color: Color(hex: "4FC3F7"))
                FitnessHeartRateBar(zoneName: "有氧区", rangeText: "70-80% HRmax", progress: 0.75, color: Color(hex: "FFB300"))
                FitnessHeartRateBar(zoneName: "无氧区", rangeText: "80-90% HRmax", progress: 0.82, color: Color(hex: "B388FF"))
                FitnessHeartRateBar(zoneName: "极限区", rangeText: "90-100% HRmax", progress: 0.94, color: Color(hex: "FF5252"))
            }
            .padding(16)
            .background(Color.white.opacity(0.6))
            .cornerRadius(16)

            Text("HRmax 计算 = 220 - 年龄")
                .font(.system(size: 12))
                .italic()
                .foregroundColor(.gray.opacity(0.8))
                .padding(.leading, 4)
        }
    }
}

private struct ActionBreakdownView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            FitnessSectionHeader(icon: "figure.crossmatrix", title: "核心动作要领")
            VStack(spacing: 12) {
                FitnessStepCard(step: "1", sub: "步骤 1 / 3", title: "热身 10 分钟", progress: 0.35)
                FitnessStepCard(step: "2", sub: "步骤 2 / 3", title: "力量练习 20 分钟", progress: 0.65)
                FitnessStepCard(step: "3", sub: "步骤 3 / 3", title: "拉伸 10 分钟", progress: 1.0)
            }

            FitnessSectionHeader(icon: "exclamationmark.triangle.fill", title: "常见错误")
            VStack(spacing: 12) {
                FitnessErrorTipCard(title: "热身不足", desc: "任何运动前都应进行5-10分钟动态热身")
                FitnessErrorTipCard(title: "忽视拉伸", desc: "运动后的静态拉伸有助于肌肉恢复")
            }
        }
    }
}

private struct WeeklyPlanView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            FitnessSectionHeader(icon: "calendar.badge.clock", title: "本周训练安排")
            VStack(spacing: 12) {
                FitnessScheduleRow(day: "周一", type: "力量", detail: "上半身力量", duration: "45min", isActive: true)
                FitnessScheduleRow(day: "周三", type: "有氧", detail: "核心燃脂", duration: "45min", isActive: true)
                FitnessScheduleRow(day: "周五", type: "恢复", detail: "拉伸 + 灵活性", duration: "", isActive: false)
                FitnessScheduleRow(day: "周日", type: "综合", detail: "全身循环训练", duration: "45min", isActive: true)
            }

            FitnessSectionHeader(icon: "chart.line.uptrend.xyaxis", title: "4周进阶计划")
            HStack(spacing: 14) {
                Image(systemName: "arrow.up.forward.curve")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "5A8B2A"))
                    .padding(10)
                    .background(Color(hex: "EBF4D7"))
                    .clipShape(Circle())

                Text("增加重量和强度，逐步提高耐力")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "2C4E3D"))
                Spacer()
            }
            .padding(16)
            .background(Color(hex: "EBF4D7").opacity(0.6))
            .cornerRadius(16)
        }
    }
}

private struct FitnessSectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "5A8B2A"))
                .font(.system(size: 16, weight: .semibold))
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "2C4E3D"))
            Spacer()
        }
    }
}

private struct FitnessSliderRow: View {
    var title: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var unit: String
    var step: Double

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                Spacer()
                Text("\(Int(value)) \(unit)")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "2C4E3D"))
            }
            Slider(value: $value, in: range, step: step)
                .accentColor(Color(hex: "87B836"))
        }
    }
}

private struct FitnessPreviewRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(Color(hex: "2C4E3D"))
                .multilineTextAlignment(.trailing)
        }
        .font(.system(size: 13))
    }
}

private struct FitnessGuideCard: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 26, height: 26)
                .background(Color(hex: "87B836"))
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "2C4E3D"))
            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.7))
        .cornerRadius(14)
    }
}

private struct FitnessHeartRateBar: View {
    let zoneName: String
    let rangeText: String
    let progress: CGFloat
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(zoneName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                Spacer()
                Text(rangeText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.8))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.1))
                    Capsule().fill(color).frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)
        }
    }
}

private struct FitnessStepCard: View {
    let step: String
    let sub: String
    let title: String
    let progress: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(step)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "5A8B2A"), Color(hex: "87B836")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                Text(sub)
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.8))
            }
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "2C4E3D"))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.1))
                    Capsule().fill(Color(hex: "87B836")).frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 5)
        }
        .padding(16)
        .background(Color.white.opacity(0.7))
        .cornerRadius(16)
    }
}

private struct FitnessErrorTipCard: View {
    let title: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.orange.opacity(0.8))
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "2C4E3D"))
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(hex: "FFF8F0"))
        .cornerRadius(14)
    }
}

private struct FitnessScheduleRow: View {
    let day: String
    let type: String
    let detail: String
    let duration: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text(day)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 34, height: 34)
                .background(isActive ? AnyShapeStyle(Color(hex: "87B836")) : AnyShapeStyle(Color.gray.opacity(0.4)))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(day)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(isActive ? Color(hex: "2C4E3D") : .gray)
                    Text(type)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isActive ? Color(hex: "5A8B2A") : .gray)
                }
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            Spacer()
            if !duration.isEmpty {
                Text(duration)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "5A8B2A"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "EBF4D7"))
                    .cornerRadius(6)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.7))
        .cornerRadius(16)
    }
}
