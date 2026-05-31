import SwiftUI

/// 首页 Hero 顶栏：对称玻璃圆形按钮 + 居中日期（对齐系统导航标题层级）。
struct DashboardV2TopBar: View {
    let dateTitle: String
    var unreadCount: Int = 0
    let onNotificationTap: () -> Void
    let onCalendarTap: () -> Void

    /// 限制日期标题最大宽度，避免与灵动岛/刘海左右抢空间导致裁切或溢出感
    private var dateTitleMaxWidth: CGFloat {
        min(148, UIScreen.main.bounds.width * 0.30)
    }

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onNotificationTap) {
                ZStack(alignment: .topTrailing) {
                    chromeCircle {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    if unreadCount > 0 {
                        Text("\(min(unreadCount, 99))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, unreadCount > 9 ? 4 : 5)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.92))
                            .clipShape(Capsule())
                            .offset(x: 9, y: -5)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(unreadCount > 0 ? "通知，\(unreadCount) 条未读" : "通知")

            Spacer(minLength: 12)

            Text(dateTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .tracking(-0.25)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .multilineTextAlignment(.center)
                .frame(maxWidth: dateTitleMaxWidth)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 12)

            Button(action: onCalendarTap) {
                chromeCircle {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("选择日期")
        }
        .padding(.vertical, 6)
    }

    private func chromeCircle<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .foregroundStyle(.primary)
            .frame(width: 40, height: 40)
            .background {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                    Circle()
                        .strokeBorder(Color.white.opacity(0.38), lineWidth: 0.75)
                }
            }
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}
