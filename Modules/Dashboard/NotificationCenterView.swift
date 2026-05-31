import SwiftUI

// MARK: - 1. 数据模型
enum CenterNotificationType: String, CaseIterable {
    case all = "全部"
    case health = "健康提醒"
    case system = "系统通知"
}

struct CenterNotificationItem: Identifiable {
    let id = UUID()
    let type: CenterNotificationType
    let iconName: String
    let iconColor: Color
    let title: String
    let content: String
    let timeString: String
    var isUnread: Bool = true
}

// MARK: - 2. 主视图
struct NotificationCenterView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var notifications: [CenterNotificationItem] = [
        CenterNotificationItem(type: .health, iconName: "heart.fill", iconColor: .red, title: "步数小目标", content: "再活动几分钟，离今天的步数目标更近一步。", timeString: "刚刚"),
        CenterNotificationItem(type: .health, iconName: "heart.fill", iconColor: .red, title: "轻运动提醒", content: "试试一组 3 分钟拉伸，让身体状态更轻盈。", timeString: "1 小时前"),
        CenterNotificationItem(type: .health, iconName: "heart.fill", iconColor: .red, title: "轻运动提醒", content: "试试一组 3 分钟拉伸，让身体状态更轻盈。", timeString: "3 小时前"),
        CenterNotificationItem(type: .health, iconName: "heart.fill", iconColor: .red, title: "步数小目标", content: "再活动几分钟，离今天的步数目标更近一步。", timeString: "3 小时前"),
        CenterNotificationItem(type: .health, iconName: "heart.fill", iconColor: .red, title: "久坐提醒", content: "已经坐了很久，起来活动 2 分钟，放...", timeString: "4 小时前"),
        CenterNotificationItem(type: .system, iconName: "info.circle.fill", iconColor: Color(red: 0.2, green: 0.4, blue: 0.4), title: "测试提醒已触发", content: "你刚刚点击了立即测试提醒，如果系统通知权限开启，将在通知栏看到...", timeString: "5月2日"),
        CenterNotificationItem(type: .system, iconName: "info.circle.fill", iconColor: Color(red: 0.2, green: 0.4, blue: 0.4), title: "测试提醒已触发", content: "你刚刚点击了立即测试提醒，如果系统通知权限开启，将在通知栏看到...", timeString: "5月2日"),
        CenterNotificationItem(type: .system, iconName: "info.circle.fill", iconColor: Color(red: 0.2, green: 0.4, blue: 0.4), title: "通知权限提示", content: "为了及时收到系统通知，建议开启通知权限并允许横幅显示。", timeString: "5月1日")
    ]

    @State private var selectedTab: CenterNotificationType = .all

    var filteredNotifications: [CenterNotificationItem] {
        switch selectedTab {
        case .all:
            return notifications
        case .health:
            return notifications.filter { $0.type == .health }
        case .system:
            return notifications.filter { $0.type == .system }
        }
    }

    func unreadCount(for type: CenterNotificationType) -> Int {
        switch type {
        case .all:
            return notifications.filter { $0.isUnread }.count
        default:
            return notifications.filter { $0.type == type && $0.isUnread }.count
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(.black)
                }

                HStack(spacing: 4) {
                    Text("通知中心")
                        .font(.custom("STKaiti", size: 24))
                        .bold()

                    if unreadCount(for: .all) > 0 {
                        Text("\(unreadCount(for: .all))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                Button(action: {
                    for index in notifications.indices {
                        notifications[index].isUnread = false
                    }
                }) {
                    Text("全部已读")
                        .font(.custom("STKaiti", size: 16))
                        .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.4))
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CenterNotificationType.allCases, id: \.self) { tab in
                        NotificationTabButton(
                            title: tab.rawValue,
                            count: unreadCount(for: tab),
                            isSelected: selectedTab == tab
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 16)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredNotifications) { item in
                        NotificationCard(item: item)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.95).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - 3. 子组件：分类标签按钮
struct NotificationTabButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isSelected ? Color(red: 0.2, green: 0.4, blue: 0.4) : .white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(isSelected ? Color.white : Color.orange)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color(red: 0.2, green: 0.4, blue: 0.4) : Color.white)
            .foregroundColor(isSelected ? .white : .black)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 4. 子组件：通知卡片
struct NotificationCard: View {
    let item: CenterNotificationItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(item.iconColor.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: item.iconName)
                    .font(.title3)
                    .foregroundColor(item.iconColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.custom("STKaiti", size: 18))
                    .bold()
                    .foregroundColor(.black)

                Text(item.content)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .lineSpacing(3)

                Text(item.timeString)
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.7))
                    .padding(.top, 2)
            }

            Spacer()

            if item.isUnread {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(.all, 16)
        .background(Color(red: 0.98, green: 0.99, blue: 0.96))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 5. 预览
struct NotificationCenterView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationCenterView()
    }
}
