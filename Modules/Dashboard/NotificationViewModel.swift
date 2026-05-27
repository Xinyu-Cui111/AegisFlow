import SwiftUI
import Combine
import Combine

class NotificationViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    
    func loadNotifications() {
        notifications = [
            NotificationItem(id: "1", title: "饮水提醒", body: "距离上次饮水已过1小时，记得补充水分", type: .reminder, isRead: false, timestamp: Date().addingTimeInterval(-1800)),
            NotificationItem(id: "2", title: "运动建议", body: "今天还没有运动记录，建议进行30分钟快走", type: .suggestion, isRead: false, timestamp: Date().addingTimeInterval(-3600)),
            NotificationItem(id: "3", title: "目标达成", body: "恭喜！今日步数已达成目标", type: .achievement, isRead: true, timestamp: Date().addingTimeInterval(-7200)),
            NotificationItem(id: "4", title: "健康周报", body: "本周健康数据汇总已生成", type: .report, isRead: true, timestamp: Date().addingTimeInterval(-86400))
        ]
        unreadCount = notifications.filter { !$0.isRead }.count
    }
    
    func markAsRead(_ id: String) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isRead = true
            unreadCount = notifications.filter { !$0.isRead }.count
        }
    }
    
    func markAllAsRead() {
        for i in notifications.indices {
            notifications[i].isRead = true
        }
        unreadCount = 0
    }
}

struct NotificationItem: Identifiable {
    let id: String
    var title: String
    var body: String
    var type: NotificationType
    var isRead: Bool
    var timestamp: Date
}

enum NotificationType {
    case reminder, suggestion, achievement, report, system
    
    var icon: String {
        switch self {
        case .reminder: return "bell.fill"
        case .suggestion: return "lightbulb.fill"
        case .achievement: return "trophy.fill"
        case .report: return "doc.text.fill"
        case .system: return "gear"
        }
    }
    
    var color: Color {
        switch self {
        case .reminder: return .orangeWarm
        case .suggestion: return .sageBright
        case .achievement: return .yellowBright
        case .report: return .androidBlue
        case .system: return .grayMid
        }
    }
}
