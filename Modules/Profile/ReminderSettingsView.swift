import Combine
import SwiftUI

// MARK: - 提醒设置页面
struct ReminderSettingsView: View {
    @StateObject private var viewModel = ReminderSettingsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AegisSpacing.sectionGap) {
                        // 全局开关
                        GlobalReminderToggle(
                            isEnabled: $viewModel.remindersEnabled,
                            onToggle: viewModel.toggleAllReminders
                        )

                        // 饮水提醒
                        ReminderSection(
                            icon: "drop.fill",
                            title: "饮水提醒",
                            subtitle: "定时提醒补充水分",
                            color: .androidBlue,
                            isEnabled: $viewModel.waterReminderEnabled,
                            reminderTimes: $viewModel.waterTimes,
                            onAddTime: viewModel.addWaterTime,
                            onRemoveTime: viewModel.removeWaterTime
                        )

                        // 运动提醒
                        ReminderSection(
                            icon: "figure.walk",
                            title: "运动提醒",
                            subtitle: "提醒起身活动",
                            color: .tealDeep,
                            isEnabled: $viewModel.exerciseReminderEnabled,
                            reminderTimes: $viewModel.exerciseTimes,
                            onAddTime: viewModel.addExerciseTime,
                            onRemoveTime: viewModel.removeExerciseTime
                        )

                        // 睡眠提醒
                        ReminderSection(
                            icon: "moon.fill",
                            title: "睡眠提醒",
                            subtitle: "提醒按时休息",
                            color: .purpleSoft,
                            isEnabled: $viewModel.sleepReminderEnabled,
                            reminderTimes: $viewModel.sleepTimes,
                            onAddTime: viewModel.addSleepTime,
                            onRemoveTime: viewModel.removeSleepTime
                        )

                        // 饮食提醒
                        ReminderSection(
                            icon: "fork.knife",
                            title: "饮食提醒",
                            subtitle: "提醒按时进食",
                            color: .orangeWarm,
                            isEnabled: $viewModel.mealReminderEnabled,
                            reminderTimes: $viewModel.mealTimes,
                            onAddTime: viewModel.addMealTime,
                            onRemoveTime: viewModel.removeMealTime
                        )

                        // 智能提醒
                        SmartReminderCard(
                            isEnabled: $viewModel.smartReminderEnabled,
                            sensitivity: $viewModel.smartSensitivity
                        )

                        Spacer(minLength: AegisSpacing.bottomSafe)
                    }
                    .padding(.horizontal, AegisSpacing.pageHorizontal)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("提醒设置")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.loadSettings()
        }
    }
}

// MARK: - 全局提醒开关
struct GlobalReminderToggle: View {
    @Binding var isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.sageBright.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.sageBright)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("全部提醒")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.grayDark)

                Text(isEnabled ? "提醒已开启" : "提醒已关闭")
                    .font(.system(size: 13))
                    .foregroundColor(.grayMid)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .toggleStyle(AegisSwitchToggleStyle(tint: .aegisFreshGreen))
                .onChange(of: isEnabled) { _, _ in
                    onToggle()
                }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
    }
}

// MARK: - 提醒区块
struct ReminderSection: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Binding var isEnabled: Bool
    @Binding var reminderTimes: [Date]
    let onAddTime: () -> Void
    let onRemoveTime: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.grayDark)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.grayMid)
                }

                Spacer()

                Toggle("", isOn: $isEnabled)
                    .toggleStyle(AegisSwitchToggleStyle(tint: color))
            }

            // 提醒时间列表
            if isEnabled {
                Divider()
                    .padding(.vertical, 8)

                FlowLayout(spacing: 8) {
                    ForEach(Array(reminderTimes.enumerated()), id: \.offset) { index, time in
                        TimeChip(
                            time: time,
                            onDelete: { onRemoveTime(index) }
                        )
                    }

                    Button(action: onAddTime) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("添加时间")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(color.opacity(0.1))
                        .cornerRadius(16)
                    }
                }
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
    }
}

// MARK: - 时间标签
struct TimeChip: View {
    let time: Date
    let onDelete: () -> Void

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(timeString)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.grayDark)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.grayMid)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.grayLight.opacity(0.5))
        .cornerRadius(16)
    }
}

// MARK: - 智能提醒卡片
struct SmartReminderCard: View {
    @Binding var isEnabled: Bool
    @Binding var sensitivity: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.purpleSoft.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20))
                        .foregroundColor(.purpleSoft)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("智能提醒")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.grayDark)

                    Text("根据你的习惯自动调整提醒时间")
                        .font(.system(size: 12))
                        .foregroundColor(.grayMid)
                }

                Spacer()

                Toggle("", isOn: $isEnabled)
                    .toggleStyle(AegisSwitchToggleStyle(tint: .purpleSoft))
            }

            if isEnabled {
                Divider()
                    .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("灵敏度")
                            .font(.system(size: 13))
                            .foregroundColor(.grayMid)

                        Spacer()

                        Text(sensitivityLabel)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.purpleSoft)
                    }

                    Slider(value: $sensitivity, in: 0...2, step: 1)
                        .tint(.purpleSoft)

                    HStack {
                        Text("低")
                            .font(.system(size: 11))
                            .foregroundColor(.grayMid)

                        Spacer()

                        Text("高")
                            .font(.system(size: 11))
                            .foregroundColor(.grayMid)
                    }
                }
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
    }

    var sensitivityLabel: String {
        switch Int(sensitivity) {
        case 0: return "低"
        case 1: return "中"
        case 2: return "高"
        default: return "中"
        }
    }
}

// MARK: - ViewModel
class ReminderSettingsViewModel: ObservableObject {
    @Published var remindersEnabled: Bool = true
    @Published var waterReminderEnabled: Bool = true
    @Published var exerciseReminderEnabled: Bool = true
    @Published var sleepReminderEnabled: Bool = true
    @Published var mealReminderEnabled: Bool = false
    @Published var smartReminderEnabled: Bool = true
    @Published var smartSensitivity: Double = 1

    @Published var waterTimes: [Date] = []
    @Published var exerciseTimes: [Date] = []
    @Published var sleepTimes: [Date] = []
    @Published var mealTimes: [Date] = []

    func loadSettings() {
        // 饮水时间
        waterTimes = [
            createTime(hour: 9, minute: 0),
            createTime(hour: 11, minute: 0),
            createTime(hour: 14, minute: 0),
            createTime(hour: 16, minute: 0),
            createTime(hour: 19, minute: 0),
        ]

        // 运动时间
        exerciseTimes = [
            createTime(hour: 8, minute: 0),
            createTime(hour: 18, minute: 0),
        ]

        // 睡眠时间
        sleepTimes = [
            createTime(hour: 22, minute: 0)
        ]
    }

    func toggleAllReminders() {
        // 将全局开关同步到各子开关与本地通知设置
        NotificationSettingsManager.shared.isNotificationEnabled = remindersEnabled
        NotificationSettingsManager.shared.isWaterReminderEnabled = waterReminderEnabled && remindersEnabled
        NotificationSettingsManager.shared.isExerciseReminderEnabled = exerciseReminderEnabled && remindersEnabled
        NotificationSettingsManager.shared.isSleepReminderEnabled = sleepReminderEnabled && remindersEnabled
        NotificationSettingsManager.shared.isWeeklyReportEnabled = remindersEnabled

        // 同步提醒时间（取第一个示例时间）
        if let first = waterTimes.first {
            NotificationSettingsManager.shared.waterReminderTime = Calendar.current.dateComponents([.hour, .minute], from: first)
        }
        if let first = exerciseTimes.first {
            NotificationSettingsManager.shared.exerciseReminderTime = Calendar.current.dateComponents([.hour, .minute], from: first)
        }
        if let first = sleepTimes.first {
            NotificationSettingsManager.shared.sleepReminderTime = Calendar.current.dateComponents([.hour, .minute], from: first)
        }

        Task {
            if !remindersEnabled {
                // 关闭则取消所有计划提醒
                NotificationService.shared.cancelAllNotifications()
            }
            await NotificationSettingsManager.shared.applySettings()
        }
    }

    func addWaterTime() {
        waterTimes.append(createTime(hour: 12, minute: 0))
    }

    func addExerciseTime() {
        exerciseTimes.append(createTime(hour: 12, minute: 0))
    }

    func addSleepTime() {
        sleepTimes.append(createTime(hour: 22, minute: 30))
    }

    func addMealTime() {
        mealTimes.append(createTime(hour: 12, minute: 0))
    }

    func removeWaterTime(_ index: Int) {
        guard waterTimes.indices.contains(index) else { return }
        waterTimes.remove(at: index)
    }

    func removeExerciseTime(_ index: Int) {
        guard exerciseTimes.indices.contains(index) else { return }
        exerciseTimes.remove(at: index)
    }

    func removeSleepTime(_ index: Int) {
        guard sleepTimes.indices.contains(index) else { return }
        sleepTimes.remove(at: index)
    }

    func removeMealTime(_ index: Int) {
        guard mealTimes.indices.contains(index) else { return }
        mealTimes.remove(at: index)
    }

    private func createTime(hour: Int, minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }
}

// MARK: - 预览
#Preview {
    ReminderSettingsView()
}
