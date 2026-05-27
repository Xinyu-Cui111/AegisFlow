import SwiftUI

// MARK: - 全局高级金配色 & 极简运动金币
let textGold = Color(hex: "#D4AF37")
let gradientGold = LinearGradient(
    colors: [Color(hex: "#F9D976"), Color(hex: "#E6C27A")], startPoint: .topLeading,
    endPoint: .bottomTrailing)

struct PremiumCoinIcon: View {
    var size: CGFloat = 16
    var body: some View {
        ZStack {
            // 钱币本体 & 高光内圈
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FFDF73"), Color(hex: "#E6B94A")],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white, Color(hex: "#D4AF37").opacity(0.2)],
                        startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: max(1, size * 0.08))

            // 钱币纹理雕饰
            Circle()
                .stroke(Color(hex: "#B8860B").opacity(0.5), lineWidth: max(0.5, size * 0.03))
                .padding(size * 0.12)

            Image(systemName: "star.fill")
                .font(.system(size: size * 0.45, weight: .black))
                .foregroundColor(.white)
                .shadow(color: Color(hex: "#B8860B").opacity(0.8), radius: 1, x: 0, y: 1)

            // 金光闪闪特效
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.35))
                .foregroundColor(.white)
                .offset(x: size * 0.25, y: -size * 0.25)
                .shadow(color: .white, radius: 2, x: 0, y: 0)
        }
        .frame(width: size, height: size)
        .shadow(color: Color(hex: "#FFDF73").opacity(0.6), radius: size * 0.3, x: 0, y: size * 0.15)
    }
}

// MARK: - 2. 奖励 (AegisRewardsView)
struct ShopItem: Identifiable {
    let id = UUID()
    let icon: String
    let name: String
    let desc: String
    let price: Int
    let color: Color
    let category: String
}

// 修改了毛巾无图标问题为水滴状表示高吸水毛巾
let mockShopItems: [ShopItem] = [
    ShopItem(
        icon: "tshirt.fill", name: "定制运动T恤", desc: "限量 100 件", price: 2000, color: .androidBlue,
        category: "实物"),
    ShopItem(
        icon: "cup.and.saucer.fill", name: "品牌水杯", desc: "不锈钢高质感", price: 800, color: .androidGreen,
        category: "实物"),
    ShopItem(
        icon: "face.smiling.fill", name: "独家表情包", desc: "动态萌趣", price: 50, color: .pink,
        category: "虚拟"),
    ShopItem(
        icon: "paintbrush.fill", name: "VIP主题皮肤", desc: "极客黑夜", price: 300, color: .androidPurple,
        category: "虚拟"),
    ShopItem(
        icon: "fork.knife", name: "健康餐优惠券", desc: "满50减10", price: 150, color: .androidGreen,
        category: "优惠券"),
    ShopItem(
        icon: "figure.run", name: "健身房体验券", desc: "单次免费次卡", price: 400, color: .androidOrange,
        category: "优惠券"),
    ShopItem(
        icon: "star.fill", name: "七天尊享体验", desc: "完整功能解锁", price: 1000, color: textGold,
        category: "会员"),
    ShopItem(
        icon: "drop.fill", name: "吸水运动毛巾", desc: "吸汗速干亲肤", price: 500, color: .cyan, category: "实物"),
]

struct AegisRewardsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var coinBounce = false
    @State private var checkedInDateKeys: Set<String> = CheckInDateKey.seededAroundToday()
    @State private var displayedMonth = Date()
    @State private var showCheckInCelebrate = false
    @State private var selectedCategory = "全部"
    let categories = ["全部", "虚拟", "实物", "优惠券", "会员"]

    var filteredItems: [ShopItem] {
        if selectedCategory == "全部" { return mockShopItems }
        return mockShopItems.filter { $0.category == selectedCategory }
    }

    private var hasCheckedInToday: Bool {
        checkedInDateKeys.contains(CheckInDateKey.make(from: Date()))
    }

    private var currentStreak: Int {
        CheckInDateKey.streakEnding(at: Date(), using: checkedInDateKeys)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 1. 顶端贵气金颜色大功能框
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        PremiumCoinIcon(size: 72)
                            .offset(y: coinBounce ? -8 : 8)
                            .animation(
                                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                value: coinBounce
                            )
                            .onAppear { coinBounce = true }

                        Text("3,240")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                        Text("运动币")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    HStack {
                        VStack(spacing: 4) {
                            Text("累计获得").font(.system(size: 12)).foregroundColor(
                                .white.opacity(0.8))
                            Text("12,450").font(.system(size: 18, weight: .bold)).foregroundColor(
                                .white)
                        }
                        .frame(maxWidth: .infinity)

                        Rectangle().fill(Color.white.opacity(0.3)).frame(width: 1, height: 30)

                        VStack(spacing: 4) {
                            Text("累计花费").font(.system(size: 12)).foregroundColor(
                                .white.opacity(0.8))
                            Text("9,210").font(.system(size: 18, weight: .bold)).foregroundColor(
                                .white)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 30)
                .background(
                    ZStack {
                        gradientGold
                        RadialGradient(
                            gradient: Gradient(colors: [.white.opacity(0.2), .clear]), center: .top,
                            startRadius: 10, endRadius: 250)
                    }
                )
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24).stroke(
                        Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: textGold.opacity(0.3), radius: 12, x: 0, y: 6)
                .padding(.horizontal, 20)

                // 2. 每日打卡 (月历样式)
                VStack(alignment: .leading, spacing: 16) {
                    VStack(spacing: 20) {
                        HStack {
                            Text("每日打卡")
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill").foregroundColor(textGold).font(
                                    .system(size: 10))
                                Text("连续\(currentStreak)天").font(.system(size: 12, weight: .bold))
                                    .foregroundColor(textGold)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(textGold.opacity(0.15).cornerRadius(12))
                        }

                        MonthHeatmapCheckInView(
                            monthDate: $displayedMonth,
                            checkedInDateKeys: checkedInDateKeys,
                            accent: textGold
                        )

                        Button {
                        } label: {
                            HStack(spacing: 6) {
                                Text(hasCheckedInToday ? "今日已打卡" : "长按立即打卡")
                                Text("+10").foregroundColor(textGold)
                                PremiumCoinIcon(size: 14)
                            }
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(hasCheckedInToday ? Color.gray.opacity(0.1) : Color.primary)
                            .foregroundColor(hasCheckedInToday ? .gray : .white)
                            .cornerRadius(26)
                            .overlay(
                                RoundedRectangle(cornerRadius: 26).stroke(
                                    Color.white.opacity(0.1), lineWidth: 1))
                        }
                        .onLongPressGesture(minimumDuration: 0.5) {
                            guard !hasCheckedInToday else { return }
                            let impact = UINotificationFeedbackGenerator()
                            impact.notificationOccurred(.success)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                checkedInDateKeys.insert(CheckInDateKey.make(from: Date()))
                                displayedMonth = Date()
                                showCheckInCelebrate = true
                            }
                        }

                        Text(hasCheckedInToday ? "已完成今日打卡，继续保持节奏！" : "距离 14天 里程碑还有 2 天，继续加油！")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                    .background(Color.androidCardBg.cornerRadius(24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24).stroke(
                            Color.white.opacity(0.1), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)
                }

                // 3. 阶梯奖励
                VStack(alignment: .leading, spacing: 16) {
                    Text("阶梯奖励")
                        .font(.system(size: 16, weight: .bold))
                        .padding(.horizontal, 24)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            let steps = [(7, 50), (14, 100), (30, 200), (60, 500), (90, 1000)]
                            ForEach(0..<steps.count, id: \.self) { index in
                                let step = steps[index]
                                HStack(spacing: 0) {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle().fill(textGold.opacity(0.1)).frame(
                                                width: 44, height: 44)
                                            Image(systemName: "gift.fill").foregroundColor(textGold)
                                        }
                                        Text("\(step.0)天").font(.system(size: 12, weight: .bold))
                                        HStack(spacing: 2) {
                                            Text("+\(step.1)").font(.system(size: 10))
                                                .foregroundColor(textGold)
                                            PremiumCoinIcon(size: 10)
                                        }
                                    }
                                    .frame(width: 70)

                                    if index < steps.count - 1 {
                                        Rectangle().fill(Color.gray.opacity(0.2)).frame(
                                            width: 30, height: 1
                                        )
                                        .offset(y: -15)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // 4. 积分商城 (两列展现)
                VStack(alignment: .leading, spacing: 16) {
                    Text("积分商城")
                        .font(.system(size: 16, weight: .bold))
                        .padding(.horizontal, 24)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.self) { cat in
                                Text(cat)
                                    .font(
                                        .system(
                                            size: 14,
                                            weight: selectedCategory == cat ? .bold : .medium)
                                    )
                                    .padding(.horizontal, 16).padding(.vertical, 8)
                                    .background(
                                        selectedCategory == cat
                                            ? AnyShapeStyle(gradientGold)
                                            : AnyShapeStyle(Color.gray.opacity(0.08))
                                    )
                                    .foregroundColor(selectedCategory == cat ? .black : .primary)
                                    .cornerRadius(20)
                                    .shadow(
                                        color: selectedCategory == cat
                                            ? textGold.opacity(0.3) : .clear, radius: 4, x: 0, y: 2
                                    )
                                    .onTapGesture { withAnimation { selectedCategory = cat } }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // 动态网格商品列表
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16)
                    {
                        ForEach(filteredItems) { item in
                            MallItemBox(item: item)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // 5. 交易记录
                VStack(alignment: .leading, spacing: 16) {
                    Text("交易记录")
                        .font(.system(size: 16, weight: .bold))
                        .padding(.horizontal, 24)

                    VStack(spacing: 0) {
                        TransactionRow(
                            title: "每日打卡奖励 (第12天)", date: "04-11 08:30", amount: "+10",
                            color: textGold)
                        Divider().padding(.leading, 64)
                        TransactionRow(
                            title: "每日打卡奖励 (第11天)", date: "04-10 09:15", amount: "+10",
                            color: textGold)
                        Divider().padding(.leading, 64)
                        TransactionRow(
                            title: "兑换 品牌水杯", date: "04-09 14:20", amount: "-800", color: .primary)
                    }
                    .background(Color.androidCardBg.cornerRadius(24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24).stroke(
                            Color.white.opacity(0.1), lineWidth: 0.5)
                    )
                    .padding(.horizontal, 20)
                }

                Spacer().frame(height: 40)
            }
        }
        .background(Color.androidBg.ignoresSafeArea())
        .overlay {
            if showCheckInCelebrate {
                CheckInCelebrationPopup(isPresented: $showCheckInCelebrate, rewardCoins: 10)
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    .zIndex(10)
            }
        }
        .navigationTitle("奖励")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left").foregroundColor(.primary)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct MonthHeatmapCheckInView: View {
    @Binding var monthDate: Date
    let checkedInDateKeys: Set<String>
    let accent: Color

    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal
    }()

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: monthDate)
    }

    private var daysGrid: [Date?] {
        let comps = calendar.dateComponents([.year, .month], from: monthDate)
        guard
            let firstDay = calendar.date(
                from: DateComponents(year: comps.year, month: comps.month, day: 1)),
            let range = calendar.range(of: .day, in: .month, for: monthDate)
        else {
            return []
        }

        let weekday = calendar.component(.weekday, from: firstDay)
        let leading = (weekday + 5) % 7
        var grid: [Date?] = Array(repeating: nil, count: leading)
        grid.append(
            contentsOf: range.compactMap { day in
                calendar.date(from: DateComponents(year: comps.year, month: comps.month, day: day))
            }
        )

        let trailing = (7 - (grid.count % 7)) % 7
        grid.append(contentsOf: Array(repeating: nil, count: trailing))
        return grid
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    shiftMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color.gray.opacity(0.10))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Text("\(monthTitle) 打卡热力")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)

                Button {
                    shiftMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color.gray.opacity(0.10))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                Button("本月") {
                    monthDate = Date()
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(accent)
            }

            HStack(spacing: 6) {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { week in
                    Text(week)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6
            ) {
                ForEach(Array(daysGrid.enumerated()), id: \.offset) { _, date in
                    if let date {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(heatColor(for: date))
                                .frame(height: 26)

                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(isCheckedIn(date) ? .white : .secondary)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(
                                    calendar.isDateInToday(date) ? accent.opacity(0.7) : .clear,
                                    lineWidth: 1.4)
                        )
                    } else {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.clear)
                            .frame(height: 26)
                    }
                }
            }
        }
    }

    private func shiftMonth(by value: Int) {
        guard let changed = calendar.date(byAdding: .month, value: value, to: monthDate) else {
            return
        }
        monthDate = changed
    }

    private func isCheckedIn(_ date: Date) -> Bool {
        checkedInDateKeys.contains(CheckInDateKey.make(from: date))
    }

    private func heatColor(for date: Date) -> Color {
        guard isCheckedIn(date) else { return Color.gray.opacity(0.10) }
        let streak = CheckInDateKey.streakEnding(at: date, using: checkedInDateKeys)
        let opacity = min(0.92, 0.24 + Double(max(streak - 1, 0)) * 0.08)
        return accent.opacity(opacity)
    }
}

private enum CheckInDateKey {
    static func make(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func seededAroundToday() -> Set<String> {
        let calendar = Calendar.current
        let offsets = [-14, -13, -12, -10, -8, -7, -6, -4, -3, -2, -1]
        return Set(
            offsets.compactMap { offset in
                guard let day = calendar.date(byAdding: .day, value: offset, to: Date()) else {
                    return nil
                }
                return make(from: day)
            }
        )
    }

    static func streakEnding(at date: Date, using keys: Set<String>) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var cursor = date

        while keys.contains(make(from: cursor)) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }

        return max(streak, 0)
    }
}

struct CheckInCelebrationPopup: View {
    @Binding var isPresented: Bool
    let rewardCoins: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(textGold.opacity(0.18))
                        .frame(width: 82, height: 82)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 42))
                        .foregroundColor(textGold)
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: 30, y: -24)
                }

                Text("打卡成功")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text("奖励")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("+\(rewardCoins)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(textGold)
                    PremiumCoinIcon(size: 18)
                }

                Text("坚持是你最强的超能力，明天继续来！")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Button("太棒了") {
                    dismiss()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.primary)
                .cornerRadius(22)
            }
            .padding(22)
            .frame(maxWidth: 310)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(textGold.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            isPresented = false
        }
    }
}

struct MallItemBox: View {
    let item: ShopItem
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [item.color.opacity(0.15), item.color.opacity(0.05)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(height: 120)
                Image(systemName: item.icon)
                    .font(.system(size: 40))
                    .foregroundColor(item.color)
                    .shadow(color: item.color.opacity(0.4), radius: 6, x: 0, y: 3)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(item.color.opacity(0.2), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.system(size: 14, weight: .bold))
                Text(item.desc).font(.system(size: 11)).foregroundColor(.gray)
                HStack(spacing: 4) {
                    PremiumCoinIcon(size: 14)
                    Text("\(item.price)").font(.system(size: 14, weight: .bold, design: .rounded))
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.bottom, 8)
        .background(
            Color.androidCardBg.cornerRadius(20)
                .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
        )
    }
}

struct TransactionRow: View {
    let title, date, amount: String
    let color: Color
    var body: some View {
        HStack(spacing: 16) {
            Circle().fill(Color.gray.opacity(0.05)).frame(width: 40, height: 40)
                .overlay(Image(systemName: "doc.text.fill").foregroundColor(.gray.opacity(0.8)))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .bold))
                Text(date).font(.system(size: 12)).foregroundColor(.gray)
            }
            Spacer()
            Text(amount).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(
                color)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
}
