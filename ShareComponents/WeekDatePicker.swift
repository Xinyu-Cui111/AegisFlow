import SwiftUI

struct WeekDatePicker: View {
    @Binding var selectedDate: Date
    
    // 自动计算当前周的日期
    private var daysInWeek: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfWeek = calendar.component(.weekday, from: today)
        let weekdays = calendar.range(of: .weekday, in: .weekOfYear, for: today)!
        return weekdays.compactMap { day in
            calendar.date(byAdding: .day, value: day - dayOfWeek, to: today)
        }
    }
    
    var body: some View {
        // 去掉了原有的 VStack 和 HStack 标题栏，只保留日期滑动部分
        HStack(spacing: 0) {
            ForEach(daysInWeek, id: \.self) { date in
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                let isToday = Calendar.current.isDateInToday(date)
                
                VStack(spacing: 8) {
                    // 星期缩写 (周一...)
                    Text(getDayName(date))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isSelected ? Color.androidGreen : Color.black.opacity(0.3))
                    
                    // 日期数字
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(isSelected ? Color.white : Color.black.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .background(
                            ZStack {
                                if isSelected {
                                    Circle()
                                        .fill(Color.androidGreen)
                                        .shadow(color: Color.androidGreen.opacity(0.3), radius: 4, x: 0, y: 2)
                                } else if isToday {
                                    Circle()
                                        .stroke(Color.androidGreen.opacity(0.5), lineWidth: 1)
                                }
                            }
                        )
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle()) // 保证整个区域可点击
                .onTapGesture {
                    withAnimation(.spring()) {
                        selectedDate = date
                    }
                }
            }
        }
        .aegisCardStyle(padding: 12) // 维持你统一的卡片样式
        .padding(.horizontal, 24)
        .background(Color.androidBg) // 维持吸顶背景色
    }
    
    private func getDayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}
