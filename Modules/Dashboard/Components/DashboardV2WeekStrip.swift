import SwiftUI
import UIKit

/// 周历：单行胶囊底座 + 日内选中态，节奏略放松，避免挤成一团。
struct DashboardV2WeekStrip: View {
    let dates: [Date]
    let selectedDate: Date
    let todayDate: Date
    let onSelect: (Date) -> Void

    private let dayLabels = ["日", "一", "二", "三", "四", "五", "六"]

    private func javaDayOfWeek(for date: Date) -> Int {
        DashboardViewModel.javaDayOfWeek(for: date)
    }

    private func weekdayLabel(for date: Date) -> String {
        dayLabels[javaDayOfWeek(for: date) % 7]
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(dates, id: \.self) { day in
                let cal = Calendar.current
                let selected = cal.isDate(day, inSameDayAs: selectedDate)
                let isToday = cal.isDate(day, inSameDayAs: todayDate)
                let dayNum = cal.component(.day, from: day)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onSelect(day)
                } label: {
                    VStack(spacing: 4) {
                        Text(isToday ? "今天" : weekdayLabel(for: day))
                            .font(.system(size: 11, weight: isToday || selected ? .semibold : .medium))
                            .foregroundStyle(labelColor(isSelected: selected, isToday: isToday))
                        Text("\(dayNum)")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(numberColor(isSelected: selected))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 2)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(selected ? Color.white.opacity(0.82) : Color.clear)
                            .shadow(color: selected ? Color.black.opacity(0.06) : .clear, radius: 4, x: 0, y: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.42), lineWidth: 0.75)
                }
        }
    }

    private func labelColor(isSelected: Bool, isToday: Bool) -> Color {
        if isSelected { return Color.primary.opacity(0.92) }
        if isToday { return Color.primary.opacity(0.82) }
        return Color.primary.opacity(0.52)
    }

    private func numberColor(isSelected: Bool) -> Color {
        isSelected ? Color.primary.opacity(0.92) : Color.primary.opacity(0.72)
    }
}
