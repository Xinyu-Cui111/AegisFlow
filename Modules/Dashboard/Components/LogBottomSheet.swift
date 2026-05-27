import SwiftUI

// MARK: - 记录底部弹窗
struct LogBottomSheet: View {
    let logType: LogType
    @Binding var isPresented: Bool
    /// 非今日打开表单时，展示与首页周历一致的日期说明（今日为 nil）
    var dateContextLine: String? = nil

    @State private var selectedTags: Set<String> = []
    @State private var value: String = ""
    @State private var note: String = ""
    @State private var mealName: String = ""
    @State private var mealCalories: String = ""
    /// 与健康目标页 `GoalAdjustableRow` 一致：毫升 / 分钟 / 小时（Float）
    @State private var waterMl: Float = 500
    @State private var exerciseMinutes: Float = 30
    @State private var sleepHoursTotal: Float = 7
    @State private var showFoodAnalysis = false
    
    // 新增类型的状态变量
    @State private var headacheIntensity: Float = 5
    @State private var systolic: String = "120"
    @State private var diastolic: String = "80"
    @State private var bloodSugarValue: String = "100"
    @State private var meditationMinutes: Float = 10
    @State private var menstrualDay: Int = 1

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        if let ctx = dateContextLine {
                            Label {
                                Text(ctx)
                                    .fixedSize(horizontal: false, vertical: true)
                            } icon: {
                                Image(systemName: "calendar.circle.fill")
                                    .foregroundStyle(logType.color)
                                    .symbolRenderingMode(.hierarchical)
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }

                        HStack(alignment: .center, spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(logType.color.opacity(0.16))
                                    .frame(width: 48, height: 48)
                                Image(safeSystemName: logType.icon, fallback: "square.grid.2x2")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(logType.color)
                                    .symbolRenderingMode(.hierarchical)
                            }
                            Text(dateContextLine == nil
                                ? "填写下列字段后保存；可与首页当日摘要联动。"
                                : "填写下列字段后保存。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowSeparator(.hidden)
                }

                if !tagsForType.isEmpty {
                    Section {
                        FlowLayout(spacing: 8) {
                            ForEach(tagsForType, id: \.self) { tag in
                                TagChip(
                                    label: tag,
                                    accent: logType.color,
                                    isSelected: selectedTags.contains(tag)
                                ) {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    } header: {
                        Text("标签")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                }

                Section("内容") {
                    switch logType {
                    case .meal:
                        MealInputSection(
                            foodName: $mealName,
                            calories: $mealCalories,
                            onScanPhoto: { showFoodAnalysis = true }
                        )
                    case .water:
                        WaterInputSection(milliliters: $waterMl)
                    case .mood:
                        MoodInputSection()
                    case .exercise:
                        ExerciseInputSection(minutes: $exerciseMinutes)
                    case .sleep:
                        SleepInputSection(totalHours: $sleepHoursTotal)
                    case .headache:
                        HeadacheInputSection(intensity: $headacheIntensity)
                    case .bloodPressure:
                        BloodPressureInputSection(systolic: $systolic, diastolic: $diastolic)
                    case .bloodSugar:
                        BloodSugarInputSection(value: $bloodSugarValue)
                    case .meditation:
                        MeditationInputSection(minutes: $meditationMinutes)
                    case .menstrual:
                        MenstrualInputSection(day: $menstrualDay)
                    }
                }

                Section("备注") {
                    TextField("备注（可选）", text: $note, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section {
                    Button(action: submitLog) {
                        HStack(spacing: 8) {
                            Spacer(minLength: 0)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.body.weight(.semibold))
                            Text("保存记录")
                                .font(.body.weight(.semibold))
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(logType.color)
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("新建\(logType.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭", role: .cancel) {
                        isPresented = false
                    }
                }
            }
            .toolbarBackground(.automatic, for: .navigationBar)
        }
        .tint(logType.color)
        .sheet(isPresented: $showFoodAnalysis) {
            FoodAnalysisView()
        }
    }
    
    // MARK: - 根据类型返回标签
    private var tagsForType: [String] {
        switch logType {
        case .meal:
            return ["早餐", "午餐", "晚餐", "加餐", "零食", "水果", "蔬菜", "主食", "肉类", "饮品"]
        case .water:
            return ["早起", "运动后", "餐前", "餐后", "睡前"]
        case .mood:
            return ["开心", "平静", "焦虑", "疲惫", "兴奋", "难过", "压力大"]
        case .exercise:
            return ["跑步", "瑜伽", "游泳", "健身", "骑行", "散步", "跳舞", "冥想"]
        case .sleep:
            return ["深睡眠", "浅睡眠", "做梦", "醒来", "翻身多"]
        case .headache:
            return ["轻微", "中等", "剧烈", "持续", "阵发", "偏头痛", "颈部紧张"]
        case .bloodPressure:
            return ["早起", "运动前", "运动后", "用餐后", "睡前", "平时"]
        case .bloodSugar:
            return ["空腹", "餐前", "餐后2小时", "餐后1小时", "睡前"]
        case .meditation:
            return ["呼吸练习", "身体扫描", "正念冥想", "放松冥想", "瑜伽冥想", "晨间冥想", "晚间冥想"]
        case .menstrual:
            return ["月经来潮", "月经中期", "排卵期", "月经结束", "健康状态"]
        default:
            return []
        }
    }
    
    // MARK: - 提交记录
    private func submitLog() {
        var numericValue: Int? = nil

        switch logType {
        case .water:
            numericValue = Int(waterMl)
        case .meal:
            numericValue = Int(mealCalories)
        case .exercise:
            numericValue = Int(exerciseMinutes)
        case .sleep:
            // 以小时为单位上传（后端可按需转换）
            numericValue = Int(sleepHoursTotal)
        case .headache:
            numericValue = Int(headacheIntensity)
        case .meditation:
            numericValue = Int(meditationMinutes)
        case .menstrual:
            numericValue = menstrualDay
        default:
            if let v = Int(value) { numericValue = v }
        }

        let tags = selectedTags.isEmpty ? nil : Array(selectedTags)
        let composedNote: String? = {
            switch logType {
            case .meal:
                let foodText = mealName.trimmingCharacters(in: .whitespacesAndNewlines)
                let caloriesText = mealCalories.trimmingCharacters(in: .whitespacesAndNewlines)
                let pieces = [
                    foodText.isEmpty ? nil : "食物: \(foodText)",
                    caloriesText.isEmpty ? nil : "热量: \(caloriesText) kcal",
                    note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note,
                ].compactMap { $0 }
                return pieces.isEmpty ? nil : pieces.joined(separator: "；")
            case .bloodPressure:
                let sys = systolic.trimmingCharacters(in: .whitespacesAndNewlines)
                let dia = diastolic.trimmingCharacters(in: .whitespacesAndNewlines)
                let bp = sys.isEmpty && dia.isEmpty ? nil : "\(sys)/\(dia) mmHg"
                let userNote = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
                let pieces = [bp, userNote].compactMap { $0 }
                return pieces.isEmpty ? nil : pieces.joined(separator: "；")
            case .bloodSugar:
                let sugar = bloodSugarValue.trimmingCharacters(in: .whitespacesAndNewlines)
                let sugarText = sugar.isEmpty ? nil : "血糖: \(sugar) mg/dL"
                let userNote = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
                let pieces = [sugarText, userNote].compactMap { $0 }
                return pieces.isEmpty ? nil : pieces.joined(separator: "；")
            default:
                return note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
            }
        }()

        Task {
            do {
                _ = try await APIClient.shared.request(
                    .createLog(type: logType.rawValue, value: numericValue, tags: tags, notes: composedNote),
                    responseType: EmptyResponse.self
                )
            } catch {
                print("提交记录失败: \(error)")
            }

            await MainActor.run {
                isPresented = false
            }
        }
    }
}

// MARK: - 标签芯片
struct TagChip: View {
    let label: String
    var accent: Color = Color.accentColor
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    Capsule(style: .continuous)
                        .fill(isSelected ? accent : Color(.secondarySystemGroupedBackground))
                }
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(accent.opacity(isSelected ? 0 : 0.14), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - 饮食输入区
struct MealInputSection: View {
    @Binding var foodName: String
    @Binding var calories: String
    let onScanPhoto: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("摄入食物")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 12) {
                TextField("名称", text: $foodName)
                    .textFieldStyle(.roundedBorder)

                TextField("千卡", text: $calories)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 88)
                    .multilineTextAlignment(.trailing)
            }

            Button(action: onScanPhoto) {
                Label("拍照识别", systemImage: "camera.fill")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.borderless)
        }
    }
}

// MARK: - 饮水输入区（滑块样式对齐个人中心 · 健康目标 `GoalAdjustableRow`）
struct WaterInputSection: View {
    @Binding var milliliters: Float

    private let range: ClosedRange<Float> = 0...4000

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GoalAdjustableRow(
                icon: "drop.fill",
                title: "饮水量",
                value: "\(Int(milliliters)) ml",
                color: .androidBlue,
                val: $milliliters,
                range: range
            )

            FlowLayout(spacing: 8) {
                ForEach([250, 500, 750, 1000], id: \.self) { ml in
                    Button {
                        milliliters = Float(ml)
                    } label: {
                        Text("\(ml) ml")
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 心情输入区
struct MoodInputSection: View {
    private let moods: [(symbol: String, label: String, color: Color)] = [
        ("face.smiling.fill", "开心", .successGreen),
        ("cloud.fill", "平静", .androidBlue),
        ("exclamationmark.triangle.fill", "焦虑", .orangeWarm),
        ("moon.zzz.fill", "疲惫", .purpleSoft),
        ("bolt.heart.fill", "兴奋", .yellowBright),
        ("cloud.rain.fill", "难过", .errorRed),
    ]

    @State private var selectedMood: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 10)], spacing: 10) {
                ForEach(moods, id: \.label) { mood in
                    Button {
                        selectedMood = mood.label
                    } label: {
                        VStack(spacing: 6) {
                            Image(safeSystemName: mood.symbol, fallback: "circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(mood.color)
                            Text(mood.label)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedMood == mood.label ? mood.color.opacity(0.14) : Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(selectedMood == mood.label ? mood.color : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - 运动输入区（滑块样式对齐健康目标）
struct ExerciseInputSection: View {
    @Binding var minutes: Float

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GoalAdjustableRow(
                icon: "figure.run",
                title: "运动时长",
                value: "\(Int(minutes)) 分钟",
                color: .androidGreen,
                val: $minutes,
                range: 5...180
            )

            FlowLayout(spacing: 8) {
                ForEach([15, 30, 45, 60], id: \.self) { m in
                    Button {
                        minutes = Float(m)
                    } label: {
                        Text("\(m) 分")
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 睡眠输入区（滑块样式对齐健康目标）
struct SleepInputSection: View {
    @Binding var totalHours: Float

    private let range: ClosedRange<Float> = 0...14

    private var displayDuration: String {
        let h = Int(floor(totalHours))
        let m = Int(round((totalHours - Float(h)) * 60))
        return "\(h) 小时 \(m) 分"
    }

    private var sleepQuality: String {
        switch totalHours {
        case ..<5: return "偏少"
        case 5..<7: return "一般"
        case 7..<9: return "良好"
        default: return "充足"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GoalAdjustableRow(
                icon: "moon.zzz.fill",
                title: "睡眠时长",
                value: displayDuration,
                color: .androidPurple,
                val: $totalHours,
                range: range
            )

            HStack {
                Spacer(minLength: 0)
                Label(sleepQuality, systemImage: totalHours >= 7 ? "moon.stars.fill" : "moon.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 通用输入区
struct GenericInputSection: View {
    @Binding var value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("输入数值")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                TextField("0", text: $value)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()

                Text(unit)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// MARK: - 头痛输入区
struct HeadacheInputSection: View {
    @Binding var intensity: Float

    private let range: ClosedRange<Float> = 0...10

    private var intensityLabel: String {
        switch intensity {
        case ..<3: return "轻微"
        case 3..<6: return "中等"
        case 6..<8: return "较严重"
        default: return "剧烈"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GoalAdjustableRow(
                icon: "cross.case.fill",
                title: "头痛程度",
                value: "\(Int(intensity))/10 - \(intensityLabel)",
                color: .errorRed,
                val: $intensity,
                range: range
            )

            HStack(spacing: 8) {
                ForEach([1, 4, 7, 10], id: \.self) { level in
                    Button {
                        intensity = Float(level)
                    } label: {
                        Text(String(level))
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 血压输入区
struct BloodPressureInputSection: View {
    @Binding var systolic: String
    @Binding var diastolic: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("血压读数（mmHg）")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("收缩压")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextField("120", text: $systolic)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }

                Text("/")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 22)

                VStack(alignment: .leading, spacing: 6) {
                    Text("舒张压")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextField("80", text: $diastolic)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
            }

            HStack(spacing: 8) {
                Button {
                    systolic = "120"
                    diastolic = "80"
                } label: {
                    Text("正常")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    systolic = "130"
                    diastolic = "85"
                } label: {
                    Text("偏高")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    systolic = "140"
                    diastolic = "90"
                } label: {
                    Text("高血压")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 血糖输入区
struct BloodSugarInputSection: View {
    @Binding var value: String

    private var sugarLevel: String {
        guard let num = Int(value) else { return "未知" }
        switch num {
        case ..<70: return "偏低"
        case 70..<100: return "正常空腹"
        case 100..<126: return "空腹血糖受损"
        case 126...: return "可能糖尿病"
        default: return "异常"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("血糖值（mg/dL）")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                TextField("100", text: $value)
                    .keyboardType(.numberPad)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()

                Text("mg/dL")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 2) {
                Image(systemName: value.isEmpty ? "questionmark.circle.fill" : "info.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(sugarLevel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)

            HStack(spacing: 6) {
                Button { value = "70" } label: { Text("70").font(.caption.weight(.semibold)) }.buttonStyle(.bordered).controlSize(.small)
                Button { value = "100" } label: { Text("100").font(.caption.weight(.semibold)) }.buttonStyle(.bordered).controlSize(.small)
                Button { value = "140" } label: { Text("140").font(.caption.weight(.semibold)) }.buttonStyle(.bordered).controlSize(.small)
                Button { value = "200" } label: { Text("200").font(.caption.weight(.semibold)) }.buttonStyle(.bordered).controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 冥想输入区
struct MeditationInputSection: View {
    @Binding var minutes: Float

    private let range: ClosedRange<Float> = 1...120

    private var meditationType: String {
        switch minutes {
        case ..<5: return "快速冥想"
        case 5..<15: return "短时冥想"
        case 15..<30: return "标准冥想"
        default: return "深度冥想"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GoalAdjustableRow(
                icon: "brain.head.profile",
                title: "冥想时长",
                value: "\(Int(minutes)) 分钟",
                color: .tealDeep,
                val: $minutes,
                range: range
            )

            HStack {
                Spacer(minLength: 0)
                Label(meditationType, systemImage: "sparkles")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }

            FlowLayout(spacing: 8) {
                ForEach([5, 10, 15, 20, 30], id: \.self) { m in
                    Button {
                        minutes = Float(m)
                    } label: {
                        Text("\(m) 分")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 经期输入区
struct MenstrualInputSection: View {
    @Binding var day: Int

    private let dayRange: ClosedRange<Int> = 1...10

    private var phaseDescription: String {
        switch day {
        case 1...5: return "月经期"
        case 6...8: return "卵泡期"
        case 9...14: return "排卵期"
        default: return "黄体期"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("月经周期日期")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Stepper(
                    value: $day,
                    in: dayRange,
                    label: {
                        HStack(spacing: 12) {
                            Text("第")
                                .font(.body.weight(.medium))
                            TextField("1", value: $day, format: .number)
                                .keyboardType(.numberPad)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                                .monospacedDigit()
                                .frame(width: 50)
                            Text("天")
                                .font(.body.weight(.medium))
                        }
                    }
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 2) {
                Image(systemName: "calendar.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(phaseDescription)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)

            FlowLayout(spacing: 8) {
                ForEach(1...5, id: \.self) { d in
                    Button {
                        day = d
                    } label: {
                        Text("第\(d)天")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 预览
#Preview {
    LogBottomSheet(logType: .water, isPresented: .constant(true))
}
