import Combine
import SwiftUI

// MARK: - 通知中心
struct NotificationCenterView: View {
    @StateObject private var viewModel = NotificationCenterViewModel()
    @State private var selectedFilter = 0
    @State private var selectedNotification: AppNotification?

    private let filters = ["全部", "提醒", "活动", "系统"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Text("未读 \(viewModel.unreadCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.errorRed)
                            .cornerRadius(20)
                        Spacer()
                    }
                    .padding(.horizontal, AegisSpacing.pageHorizontal)
                    .padding(.top, 8)

                    // 过滤器
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(filters.enumerated()), id: \.offset) { index, filter in
                                FilterChip(
                                    title: filter,
                                    isSelected: selectedFilter == index
                                ) {
                                    withAnimation {
                                        selectedFilter = index
                                        viewModel.filterNotifications(by: index)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AegisSpacing.pageHorizontal)
                        .padding(.vertical, 12)
                    }

                    // 通知列表
                    if viewModel.filteredNotifications.isEmpty {
                        EmptyNotificationView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredNotifications) { notification in
                                    NotificationCard(notification: notification) {
                                        viewModel.handleNotificationTap(notification)
                                        selectedNotification = notification
                                    }
                                }
                            }
                            .padding(.horizontal, AegisSpacing.pageHorizontal)
                            .padding(.bottom, AegisSpacing.bottomSafe)
                        }
                    }
                }
            }
            .navigationTitle("通知中心")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewModel.markAllAsRead() }) {
                            Label("全部已读", systemImage: "checkmark.circle")
                        }
                        Button(role: .destructive, action: { viewModel.clearAll() }) {
                            Label("清空通知", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.grayDark)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadNotifications()
        }
        .sheet(item: $selectedNotification) { notification in
            NotificationDetailSheet(notification: notification)
        }
    }
}

// MARK: - 过滤标签
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .grayDark)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.sageBright : Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - 通知卡片
struct NotificationCard: View {
    let notification: AppNotification
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // 图标
                ZStack {
                    Circle()
                        .fill(notification.color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: notification.icon)
                        .font(.system(size: 20))
                        .foregroundColor(notification.color)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(notification.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.grayDark)

                        Spacer()

                        if !notification.isRead {
                            Circle()
                                .fill(Color.errorRed)
                                .frame(width: 8, height: 8)
                        }
                    }

                    Text(notification.message)
                        .font(.system(size: 14))
                        .foregroundColor(.grayMid)
                        .lineLimit(2)

                    Text(notification.time)
                        .font(.system(size: 12))
                        .foregroundColor(.grayLight)
                }
            }
            .padding(AegisSpacing.cardPadding)
            .background(Color.white)
            .cornerRadius(AegisCornerRadius.large)
            .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 空状态视图
struct EmptyNotificationView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bell.slash")
                .font(.system(size: 64))
                .foregroundColor(.grayLight)

            Text("暂无通知")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.grayMid)

            Text("新的通知会在这里显示")
                .font(.system(size: 14))
                .foregroundColor(.grayLight)

            Spacer()
        }
    }
}

// MARK: - ViewModel
class NotificationCenterViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var filteredNotifications: [AppNotification] = []
    @Published var isLoading: Bool = false
    @Published var unreadCount: Int = 0

    private let apiClient = APIClient.shared

    @MainActor
    func loadNotifications() {
        isLoading = true
        Task {
            do {
                let response = try await apiClient.request(
                    endpoint: "/api/v1/notifications",
                    method: "GET"
                )

                if let data = response["data"] as? [[String: Any]] {
                    notifications = data.compactMap { item in
                        guard let id = item["id"] as? String,
                            let icon = item["icon"] as? String,
                            let title = item["title"] as? String,
                            let message = item["message"] as? String,
                            let time = item["time"] as? String,
                            let typeStr = item["type"] as? String
                        else { return nil }

                        let type: AppNotification.NotificationType
                        switch typeStr {
                        case "reminder": type = .reminder
                        case "activity": type = .activity
                        case "alert": type = .alert
                        default: type = .system
                        }

                        let colorHex = item["color"] as? String ?? "#8FB89A"
                        return AppNotification(
                            id: id,
                            icon: icon,
                            title: title,
                            message: message,
                            time: time,
                            type: type,
                            color: Color(hex: colorHex),
                            isRead: item["is_read"] as? Bool ?? false
                        )
                    }
                    filteredNotifications = notifications
                    unreadCount = notifications.filter { !$0.isRead }.count
                }
            } catch {
                print("Notifications API Error: \(error.localizedDescription)")
                // 使用本地缓存或mock数据作为fallback
                loadMockNotifications()
            }
            isLoading = false
        }
    }

    private func loadMockNotifications() {
        notifications = [
            AppNotification(
                id: "1",
                icon: "drop.fill",
                title: "饮水提醒",
                message: "已经2小时没喝水了，记得补充水分哦！",
                time: "10分钟前",
                type: .reminder,
                color: .androidBlue,
                isRead: false
            ),
            AppNotification(
                id: "2",
                icon: "figure.walk",
                title: "运动提醒",
                message: "今天步数目标已完成，继续保持！",
                time: "30分钟前",
                type: .activity,
                color: .tealDeep,
                isRead: false
            ),
            AppNotification(
                id: "3",
                icon: "moon.fill",
                title: "睡眠提醒",
                message: "早点休息对健康很重要，今晚的目标是睡够7小时。",
                time: "1小时前",
                type: .reminder,
                color: .purpleSoft,
                isRead: true
            ),
            AppNotification(
                id: "4",
                icon: "chart.bar.fill",
                title: "周报告已生成",
                message: "您的第15周健康报告已生成，点击查看详情。",
                time: "昨天",
                type: .system,
                color: .orangeWarm,
                isRead: true
            ),
            AppNotification(
                id: "5",
                icon: "star.fill",
                title: "获得新成就",
                message: "恭喜您解锁「连续打卡7天」成就！",
                time: "2天前",
                type: .system,
                color: .yellowBright,
                isRead: true
            ),
            AppNotification(
                id: "6",
                icon: "heart.fill",
                title: "心率异常提醒",
                message: "检测到您刚才心率偏高，建议休息片刻。",
                time: "3天前",
                type: .alert,
                color: .errorRed,
                isRead: true
            ),
        ]
        filteredNotifications = notifications
        unreadCount = notifications.filter { !$0.isRead }.count
    }

    func filterNotifications(by index: Int) {
        switch index {
        case 0: filteredNotifications = notifications
        case 1: filteredNotifications = notifications.filter { $0.type == .reminder }
        case 2: filteredNotifications = notifications.filter { $0.type == .activity }
        case 3: filteredNotifications = notifications.filter { $0.type == .system }
        default: filteredNotifications = notifications
        }
    }

    @MainActor
    func handleNotificationTap(_ notification: AppNotification) {
        Task {
            do {
                // 调用标记已读API
                let _ = try await apiClient.request(
                    endpoint: "/api/v1/notifications/\(notification.id)/read",
                    method: "POST"
                )
            } catch {
                print("Mark read error: \(error.localizedDescription)")
            }
        }

        // 更新本地状态
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
        unreadCount = notifications.filter { !$0.isRead }.count
        filterNotifications(by: 0)

        // 根据通知类型导航
        navigateToNotificationDetail(notification)
    }

    @MainActor
    func markAllAsRead() {
        Task {
            do {
                let _ = try await apiClient.request(
                    endpoint: "/api/v1/notifications/read-all",
                    method: "POST"
                )
                for index in notifications.indices {
                    notifications[index].isRead = true
                }
                unreadCount = 0
            } catch {
                print("Mark all read error: \(error.localizedDescription)")
                // 即使API失败也更新本地
                for index in notifications.indices {
                    notifications[index].isRead = true
                }
                unreadCount = 0
            }
        }
    }

    @MainActor
    func clearAll() {
        Task {
            do {
                let _ = try await apiClient.request(
                    endpoint: "/api/v1/notifications/clear",
                    method: "DELETE"
                )
            } catch {
                print("Clear notifications error: \(error.localizedDescription)")
            }
            notifications.removeAll()
            filteredNotifications.removeAll()
            unreadCount = 0
        }
    }

    private func navigateToNotificationDetail(_ notification: AppNotification) {
        switch notification.type {
        case .activity:
            // 导航到活动详情或统计页面
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToStatistics"),
                object: nil
            )
        case .system:
            if notification.title.contains("成就") {
                // 导航到成就页面
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToAchievements"),
                    object: nil
                )
            }
        case .alert:
            // 导航到健康详情
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToHealthDetail"),
                object: notification.id
            )
        default:
            break
        }
    }
}

struct NotificationDetailSheet: View {
    let notification: AppNotification
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Circle()
                    .fill(notification.color.opacity(0.2))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: notification.icon).foregroundColor(notification.color))
                Spacer()
                Text(notification.time).font(.system(size: 12)).foregroundColor(.grayMid)
            }
            Text(notification.title).font(.system(size: 18, weight: .bold)).foregroundColor(
                .grayDark)
            Text(notification.message).font(.system(size: 14)).foregroundColor(.grayDark)
            Button("关闭") { dismiss() }
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.sageBright)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(20)
        .presentationDetents([.height(300)])
    }
}

// MARK: - 数据模型
struct AppNotification: Identifiable {
    let id: String
    let icon: String
    let title: String
    let message: String
    let time: String
    let type: NotificationType
    let color: Color
    var isRead: Bool

    enum NotificationType {
        case reminder
        case activity
        case system
        case alert
    }
}

// MARK: - 预览
#Preview {
    NotificationCenterView()
}
