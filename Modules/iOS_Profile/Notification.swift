import SwiftUI
import UIKit
import UniformTypeIdentifiers
import UserNotifications

struct FixedSlotReminderItem: Identifiable, Equatable {
    let id: UUID
    var time: Date
    var note: String

    init(id: UUID = UUID(), time: Date, note: String = "") {
        self.id = id
        self.time = time
        self.note = note
    }
}

struct NotificationSettings: View {
    @Environment(\.dismiss) var dismiss

    // MARK: - 系统通知状态
    @State private var receiveNotifications = true
    @State private var notificationSound = true
    @State private var vibrationAlert = true
    @State private var popupReminder = true

    // MARK: - 健康提醒状态
    @State private var dailyReminders = true
    @State private var waterReminder = true
    @State private var sportReminder = true
    @State private var sleepReminder = true
    @State private var fixedSlotReminder = false
    @State private var fixedSlotWorkdaysOnly = true
    @State private var fixedSlotItems: [FixedSlotReminderItem] = [
        FixedSlotReminderItem(
            time: Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
            note: "早餐后"
        ),
        FixedSlotReminderItem(
            time: Calendar.current.date(from: DateComponents(hour: 14, minute: 30)) ?? Date(),
            note: "午休后"
        ),
        FixedSlotReminderItem(
            time: Calendar.current.date(from: DateComponents(hour: 21, minute: 30)) ?? Date(),
            note: "睡前"
        ),
    ]
    @State private var editingTimeItemID: UUID? = nil
    @State private var tempEditingTime = Date()
    @State private var editingNoteItemID: UUID? = nil
    @State private var tempEditingNote = ""
    @State private var showTimePicker = false
    @State private var showNoteEditor = false
    @State private var draggedFixedSlotID: UUID? = nil

    // MARK: - 数据报告状态
    @State private var weeklyReport = true
    @State private var testStatusText = "用于验证手机通知链路是否正常。"

    var body: some View {
        ZStack {
            // 全局灵动光影背景
            AegisDynamicBackground()

            VStack(spacing: 0) {
                // 顶部导航 (自带超强毛玻璃与阴影)
                SubPageHeader(title: "通知设置") { dismiss() }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // 1. 顶部引导卡片
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.androidBlue.opacity(0.12))
                                    .frame(width: 48, height: 48)
                                    .shadow(
                                        color: Color.androidBlue.opacity(0.2), radius: 6, x: 0, y: 3
                                    )

                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.androidBlue)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("管理提醒")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary.opacity(0.85))
                                Text("控制应用通知与健康行为干预")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .aegisCardStyle(padding: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.androidBlue.opacity(0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.androidBlue.opacity(0.20), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        // 1.1 顶部功能入口：立即测试提醒
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.aegisFreshGreen.opacity(0.16))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.aegisFreshGreen)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text("立即测试提醒")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary.opacity(0.86))
                                Text(testStatusText)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Button(action: {
                                Task { await triggerTestNotification() }
                            }) {
                                Text("发送")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.aegisFreshGreen)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .aegisCardStyle(padding: 16)
                        .padding(.horizontal, 16)

                        // 2. 系统通知组
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "系统通知", icon: "iphone")

                            VStack(spacing: 0) {
                                // 总开关：接收通知
                                ToggleRow(
                                    icon: "bell.fill", title: "接收通知", subtitle: "开启后可收到应用消息推送",
                                    color: .androidBlue, isOn: $receiveNotifications)

                                Divider().background(Color.black.opacity(0.04)).padding(
                                    .leading, 64)

                                // 子开关：声音与振动
                                Group {
                                    ToggleRow(
                                        icon: "speaker.wave.2.fill", title: "通知声音",
                                        subtitle: "收到通知时播放提示音", color: .androidGreen,
                                        isOn: $notificationSound)
                                    Divider().background(Color.black.opacity(0.04)).padding(
                                        .leading, 64)
                                    ToggleRow(
                                        icon: "water.waves", title: "触感反馈", subtitle: "收到通知时提供随动震感",
                                        color: .androidPurple, isOn: $vibrationAlert)
                                    Divider().background(Color.black.opacity(0.04)).padding(
                                        .leading, 64)
                                    ToggleRow(
                                        icon: "rectangle.portrait.tophalf.filled", title: "弹出提醒",
                                        subtitle: "横幅与锁屏提醒由 iOS 通知系统控制", color: .androidOrange,
                                        isOn: $popupReminder)
                                    Divider().background(Color.black.opacity(0.04)).padding(
                                        .leading, 64)
                                    SettingsActionRow(
                                        icon: "gearshape.fill", title: "系统通知与弹窗位置",
                                        subtitle: nil,
                                        color: .aegisFreshGreen,
                                        actionTitle: "去设置"
                                    ) {
                                        openSystemNotificationSettings()
                                    }
                                }
                                .disabled(!receiveNotifications)  // 核心逻辑：总关则子禁
                                .opacity(receiveNotifications ? 1 : 0.4)
                                .animation(.easeInOut(duration: 0.2), value: receiveNotifications)
                            }
                            .aegisCardStyle(padding: 8)
                        }
                        .padding(.horizontal, 16)

                        // 3. 健康提醒组
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "健康提醒", icon: "heart.fill")

                            VStack(spacing: 0) {
                                // 总开关：每日提醒
                                ToggleRow(
                                    icon: "clock.fill", title: "每日互动", subtitle: "智能提醒您记录健康生理数据",
                                    color: .androidOrange, isOn: $dailyReminders)

                                Divider().background(Color.black.opacity(0.04)).padding(
                                    .leading, 64)

                                // 子开关
                                Group {
                                    ToggleRow(
                                        icon: "drop.fill", title: "饮水充能", subtitle: "每隔 2 小时提醒补充水份",
                                        color: .androidBlue, isOn: $waterReminder)
                                    Divider().background(Color.black.opacity(0.04)).padding(
                                        .leading, 64)
                                    ToggleRow(
                                        icon: "figure.walk", title: "久坐起立",
                                        subtitle: "久坐超 1 小时提醒起身活动", color: .androidGreen,
                                        isOn: $sportReminder)
                                    Divider().background(Color.black.opacity(0.04)).padding(
                                        .leading, 64)
                                    ToggleRow(
                                        icon: "moon.stars.fill", title: "就寝节律",
                                        subtitle: "入睡前 30 分钟环境准备", color: .androidPurple,
                                        isOn: $sleepReminder)
                                    Divider().background(Color.black.opacity(0.04)).padding(
                                        .leading, 64)
                                    ToggleRow(
                                        icon: "timer", title: "固定时段提醒",
                                        subtitle: "可自定义增删时段，按你的节奏定时提醒",
                                        color: .themeDarkGreen,
                                        isOn: $fixedSlotReminder)
                                    if fixedSlotReminder {
                                        VStack(alignment: .leading, spacing: 10) {
                                            HStack(spacing: 8) {
                                                PresetTimeButton(title: "轻提醒") {
                                                    fixedSlotItems = makePresetItems([
                                                        (9, 0, "早餐后"),
                                                        (21, 0, "睡前"),
                                                    ])
                                                }
                                                PresetTimeButton(title: "均衡") {
                                                    fixedSlotItems = makePresetItems([
                                                        (9, 0, "早餐后"),
                                                        (14, 30, "午休后"),
                                                        (21, 30, "睡前"),
                                                    ])
                                                }
                                                PresetTimeButton(title: "高频") {
                                                    fixedSlotItems = makePresetItems([
                                                        (8, 30, "早晨激活"),
                                                        (12, 30, "午间补给"),
                                                        (16, 30, "下午复盘"),
                                                        (21, 0, "睡前收尾"),
                                                    ])
                                                }
                                            }

                                            HStack(spacing: 8) {
                                                Button {
                                                    addFixedSlotTime()
                                                } label: {
                                                    Label("添加时段", systemImage: "plus")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 7)
                                                        .background(Color.aegisFreshGreen)
                                                        .clipShape(Capsule())
                                                }
                                                .buttonStyle(.plain)

                                                Button {
                                                    removeFixedSlotTime()
                                                } label: {
                                                    Label("删除时段", systemImage: "minus")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundColor(.aegisFreshGreen)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 7)
                                                        .background(
                                                            Color.aegisFreshGreen.opacity(0.12)
                                                        )
                                                        .clipShape(Capsule())
                                                }
                                                .buttonStyle(.plain)
                                                .disabled(fixedSlotItems.count <= 1)
                                                .opacity(fixedSlotItems.count <= 1 ? 0.45 : 1)
                                            }

                                            Text("拖动右侧把手可调整顺序，点时段或备注可编辑")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(.secondary)

                                            VStack(spacing: 8) {
                                                ForEach(fixedSlotItems) { item in
                                                    FixedSlotReminderRow(
                                                        item: item,
                                                        onEditTime: {
                                                            editingTimeItemID = item.id
                                                            tempEditingTime = item.time
                                                            showTimePicker = true
                                                        },
                                                        onEditNote: {
                                                            editingNoteItemID = item.id
                                                            tempEditingNote = item.note
                                                            showNoteEditor = true
                                                        },
                                                        onDelete: {
                                                            deleteFixedSlotItem(item.id)
                                                        }
                                                    )
                                                    .onDrag {
                                                        draggedFixedSlotID = item.id
                                                        return NSItemProvider(
                                                            object: item.id.uuidString as NSString)
                                                    }
                                                    .onDrop(
                                                        of: [UTType.text],
                                                        delegate: FixedSlotDropDelegate(
                                                            item: item,
                                                            items: $fixedSlotItems,
                                                            draggedItemID: $draggedFixedSlotID
                                                        )
                                                    )
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                    }
                                    Divider().background(Color.black.opacity(0.04)).padding(
                                        .leading, 64)
                                    ToggleRow(
                                        icon: "calendar", title: "提醒频率：工作日模式",
                                        subtitle: "仅周一至周五推送，减少周末打扰", color: .androidBlue,
                                        isOn: $fixedSlotWorkdaysOnly
                                    )
                                    .disabled(!fixedSlotReminder)
                                }
                                .disabled(!dailyReminders)
                                .opacity(dailyReminders ? 1 : 0.4)
                                .animation(.easeInOut(duration: 0.2), value: dailyReminders)
                            }
                            .aegisCardStyle(padding: 8)
                        }
                        .padding(.horizontal, 16)

                        // 4. 数据报告
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "数据洞察", icon: "chart.pie.fill")

                            ToggleRow(
                                icon: "calendar.badge.clock", title: "每周健康简报",
                                subtitle: "每周日智能推送上周健康数据总结", color: .themeDarkGreen,
                                isOn: $weeklyReport
                            )
                            .aegisCardStyle(padding: 8)
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)  // 隐藏系统原生的多余空白导航栏和多余返回键
        .ignoresSafeArea(.all, edges: .top)  // 让背景顶到状态栏
        // MARK: - 联动控制逻辑
        .onChange(of: receiveNotifications) { _, newValue in
            if !newValue {  // 如果总开关关闭
                notificationSound = false
                vibrationAlert = false
                popupReminder = false
                fixedSlotReminder = false
                Task {
                    await NotificationService.shared.cancelNotifications(
                        matchingPrefix: "fixed_slot")
                }
            } else {
                Task {
                    _ = await ensureNotificationAuthorizationIfNeeded()
                }
            }
        }
        .onChange(of: dailyReminders) { _, newValue in
            if !newValue {  // 如果总开关关闭
                waterReminder = false
                sportReminder = false
                sleepReminder = false
                fixedSlotReminder = false
                Task {
                    await NotificationService.shared.cancelNotifications(
                        matchingPrefix: "fixed_slot")
                }
            }
        }
        .onChange(of: fixedSlotReminder) { _, _ in
            Task { await applyFixedSlotReminders() }
        }
        .onChange(of: fixedSlotWorkdaysOnly) { _, _ in
            Task { await applyFixedSlotReminders() }
        }
        .onChange(of: fixedSlotItems) { _, _ in
            Task { await applyFixedSlotReminders() }
        }
        .sheet(isPresented: $showTimePicker) {
            NavigationStack {
                VStack(spacing: 18) {
                    DatePicker(
                        "选择提醒时间",
                        selection: $tempEditingTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()

                    Button("保存此时段") {
                        guard let id = editingTimeItemID else {
                            showTimePicker = false
                            return
                        }
                        updateFixedSlotTime(id: id, time: tempEditingTime)
                        showTimePicker = false
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.aegisFreshGreen)
                    .cornerRadius(23)
                }
                .padding(20)
                .navigationTitle("编辑固定时段")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.height(320)])
        }
        .sheet(isPresented: $showNoteEditor) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("例如：早餐后 / 午休 / 睡前", text: $tempEditingNote, axis: .vertical)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: 8) {
                        QuickNoteButton(title: "早餐后") {
                            tempEditingNote = "早餐后"
                        }
                        QuickNoteButton(title: "午休") {
                            tempEditingNote = "午休"
                        }
                        QuickNoteButton(title: "睡前") {
                            tempEditingNote = "睡前"
                        }
                    }

                    Button("保存备注") {
                        guard let id = editingNoteItemID else {
                            showNoteEditor = false
                            return
                        }
                        updateFixedSlotNote(id: id, note: tempEditingNote)
                        showNoteEditor = false
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.aegisFreshGreen)
                    .cornerRadius(23)

                    Spacer()
                }
                .padding(20)
                .navigationTitle("编辑备注")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.height(260)])
        }
    }

    private func ensureNotificationAuthorizationIfNeeded() async -> Bool {
        let status = await NotificationService.shared.getAuthorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return await NotificationService.shared.requestAuthorization()
        default:
            return false
        }
    }

    private func triggerTestNotification() async {
        guard receiveNotifications else {
            testStatusText = "请先开启“接收通知”后再测试。"
            return
        }

        let granted = await ensureNotificationAuthorizationIfNeeded()
        guard granted else {
            testStatusText = "通知权限未开启，请前往系统设置授权。"
            openSystemNotificationSettings()
            return
        }

        await NotificationService.shared.scheduleInstantTestNotification(after: 3)
        testStatusText = "测试提醒已发送，约 3 秒后会在手机上弹出。"
    }

    private func applyFixedSlotReminders() async {
        await NotificationService.shared.cancelNotifications(matchingPrefix: "fixed_slot")

        guard receiveNotifications, dailyReminders, fixedSlotReminder else { return }
        let granted = await ensureNotificationAuthorizationIfNeeded()
        guard granted else { return }

        await NotificationService.shared.scheduleFixedSlotReminders(
            items: fixedSlotItems,
            weekdaysOnly: fixedSlotWorkdaysOnly,
            identifierPrefix: "fixed_slot"
        )
    }

    private func openSystemNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func makePresetTimes(_ hours: [Int], minute: Int) -> [Date] {
        let calendar = Calendar.current
        return hours.compactMap { hour in
            calendar.date(from: DateComponents(hour: hour, minute: minute))
        }
    }

    private func makePresetItems(_ specs: [(Int, Int, String)]) -> [FixedSlotReminderItem] {
        let calendar = Calendar.current
        return specs.compactMap { hour, minute, note in
            guard let date = calendar.date(from: DateComponents(hour: hour, minute: minute)) else {
                return nil
            }
            return FixedSlotReminderItem(time: date, note: note)
        }
    }

    private func addFixedSlotTime() {
        let newTime = nextSuggestedFixedSlotTime()
        let newItem = FixedSlotReminderItem(time: newTime, note: "")
        fixedSlotItems.append(newItem)
        fixedSlotItems.sort { $0.time < $1.time }
        editingTimeItemID = newItem.id
        tempEditingTime = newTime
        showTimePicker = true
    }

    private func removeFixedSlotTime() {
        guard fixedSlotItems.count > 1 else { return }
        if let id = editingTimeItemID, fixedSlotItems.contains(where: { $0.id == id }) {
            deleteFixedSlotItem(id)
        } else {
            if let lastID = fixedSlotItems.last?.id {
                deleteFixedSlotItem(lastID)
            }
        }
    }

    private func nextSuggestedFixedSlotTime() -> Date {
        let calendar = Calendar.current
        let base = fixedSlotItems.map(\.time).sorted().last ?? Date()
        return calendar.date(byAdding: .hour, value: 1, to: base) ?? base
    }

    private func updateFixedSlotTime(id: UUID, time: Date) {
        guard let index = fixedSlotItems.firstIndex(where: { $0.id == id }) else { return }
        fixedSlotItems[index].time = time
        fixedSlotItems.sort { $0.time < $1.time }
    }

    private func updateFixedSlotNote(id: UUID, note: String) {
        guard let index = fixedSlotItems.firstIndex(where: { $0.id == id }) else { return }
        fixedSlotItems[index].note = note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func deleteFixedSlotItem(_ id: UUID) {
        guard fixedSlotItems.count > 1 else { return }
        fixedSlotItems.removeAll { $0.id == id }
        if editingTimeItemID == id { editingTimeItemID = nil }
        if editingNoteItemID == id { editingNoteItemID = nil }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 分组标题组件 (细致的小型标题)
struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text(title)
                .font(.system(size: 14, weight: .bold))
        }
        .foregroundColor(.secondary)
        .padding(.leading, 12)
        .padding(.top, 4)
    }
}

// MARK: - 抽离的开关行组件 (重构高质感细节)
struct ToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.92)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .layoutPriority(1)

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(AegisSwitchToggleStyle(tint: .aegisFreshGreen))  // 统一为新的清新青翠半透绿
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsActionRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let color: Color
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.92)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .layoutPriority(1)

            Spacer()

            Button(actionTitle, action: action)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(minWidth: 76)
                .background(color)
                .clipShape(Capsule())
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct FixedSlotReminderRow: View {
    let item: FixedSlotReminderItem
    let onEditTime: () -> Void
    let onEditNote: () -> Void
    let onDelete: () -> Void

    private var noteText: String {
        item.note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 18)

            Button(action: onEditTime) {
                Text(formatTime(item.time))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.aegisFreshGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.aegisFreshGreen.opacity(0.14))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button(action: onEditNote) {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.system(size: 11, weight: .semibold))
                    Text(noteText.isEmpty ? "添加备注" : noteText)
                        .lineLimit(1)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(noteText.isEmpty ? .secondary : .primary.opacity(0.82))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.9))
                .overlay(
                    Capsule().stroke(Color.aegisFreshGreen.opacity(0.18), lineWidth: 1)
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.red.opacity(0.75))
                    .frame(width: 28, height: 28)
                    .background(Color.red.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.85))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .cornerRadius(16)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct FixedSlotDropDelegate: DropDelegate {
    let item: FixedSlotReminderItem
    @Binding var items: [FixedSlotReminderItem]
    @Binding var draggedItemID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggedItemID, draggedItemID != item.id else { return }
        guard
            let fromIndex = items.firstIndex(where: { $0.id == draggedItemID }),
            let toIndex = items.firstIndex(where: { $0.id == item.id })
        else { return }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            items.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedItemID = nil
        return true
    }
}

struct QuickNoteButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.aegisFreshGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.aegisFreshGreen.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct PresetTimeButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.aegisFreshGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.aegisFreshGreen.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
