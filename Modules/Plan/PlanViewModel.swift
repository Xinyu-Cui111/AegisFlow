import SwiftUI
import Combine

class PlanViewModel: ObservableObject {
    private let baseURL = APIConfig.baseURL
    private var token: String? {
        UserDefaults.standard.string(forKey: APIConfig.accessTokenKey)
    }

    // Exercise plans
    @Published var exercisePlans: [ExercisePlanItem] = []
    @Published var isLoading: Bool = false
    @Published var isGeneratingPlan: Bool = false
    @Published var error: String? = nil
    @Published var showAIPlanProfileForm: Bool = false
    @Published var aiPlanPrompt: String = ""
    @Published var fitnessLevel: String = "BEGINNER"
    @Published var healthGoal: String = "GENERAL"
    @Published var planWeeklyFrequency: Int = 3
    @Published var planSessionDuration: Int = 45
    @Published var healthLimitations: String = ""

    // Micro exercises
    @Published var microExercises: [MicroExerciseItem] = []
    @Published var filteredMicroExercises: [MicroExerciseItem] = []
    @Published var currentScene: String = "工位"

    // Habits
    @Published var habits: [PlanHabitItem] = []
    @Published var todayTaskCompleted: Bool = false
    @Published var todayTaskText: String = ""

    // AI adjustment
    @Published var adjustmentInput: String = ""
    @Published var selectedAdjustPlanId: String? = nil
    @Published var isAdjusting: Bool = false
    @Published var adjustablePlans: [AdjustablePlanItem] = []
    @Published var adjustmentResult: AdjustmentResultItem? = nil
    @Published var isAiProcessing: Bool = false

    // Micro exercise dialogs
    @Published var selectedMicroExercise: MicroExerciseItem? = nil
    @Published var showAddMicroExercise: Bool = false

    func loadData() {
        isLoading = true
        reloadContent()
        isLoading = false
    }

    /// 下拉刷新：保留完整数据流，并带短暂等待以呈现系统刷新控件
    @MainActor
    func refresh() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 450_000_000)
        reloadContent()
        isLoading = false
    }

    private func reloadContent() {
        detectScene()
        loadExercisePlans()
        loadMicroExercises()
        loadHabits()
        loadAdjustablePlans()
        generateTodayTask()
    }

    var microExerciseCount: (工位: Int, 通勤: Int, 居家: Int) {
        let w = microExercises.filter { $0.scene == "工位" }.count
        let c = microExercises.filter { $0.scene == "通勤" }.count
        let h = microExercises.filter { $0.scene == "居家" }.count
        return (w, c, h)
    }

    var habitsCheckedInToday: Int {
        habits.filter(\.isCompletedToday).count
    }

    private func detectScene() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 7...9: currentScene = "通勤"
        case 9...18: currentScene = "工位"
        default: currentScene = "居家"
        }
    }

    // MARK: - Exercise Plans

    func loadExercisePlans() {
        exercisePlans = [
            ExercisePlanItem(id: "1", name: "基础健身", duration: "45min", calories: "250kcal",
                             intensity: "低", emoji: "", imageUrl: nil, isCompleted: false,
                             sportType: "BASIC_FITNESS",
                             guidanceTips: ["循序渐进", "注意呼吸", "保持节奏"],
                             techniqueSteps: ["热身10分钟", "徒手训练20分钟", "核心激活10分钟", "拉伸5分钟"],
                             weeklySchedule: [
                                 WeeklyScheduleItem(day: "周一", focus: "休息", details: "基础力量训练", duration: ""),
                                 WeeklyScheduleItem(day: "周二", focus: "训练", details: "全身基础训练", duration: "45min"),
                                 WeeklyScheduleItem(day: "周三", focus: "休息", details: "基础力量训练", duration: ""),
                                 WeeklyScheduleItem(day: "周四", focus: "训练", details: "核心与下肢", duration: "45min"),
                                 WeeklyScheduleItem(day: "周五", focus: "休息", details: "基础力量训练", duration: ""),
                                 WeeklyScheduleItem(day: "周六", focus: "训练", details: "全身循环训练", duration: "45min"),
                             ]),
            ExercisePlanItem(id: "2", name: "进阶健身", duration: "45min", calories: "350kcal",
                             intensity: "高", emoji: "", imageUrl: nil, isCompleted: false,
                             sportType: "ADVANCED_FITNESS",
                             guidanceTips: ["挑战自我", "持续进步", "享受过程"],
                             techniqueSteps: ["热身 10 分钟", "高强度间歇20分钟", "拉伸 10 分钟"],
                             weeklySchedule: [
                                 WeeklyScheduleItem(day: "周一", focus: "力量", details: "全身力量+负重", duration: "45min"),
                                 WeeklyScheduleItem(day: "周二", focus: "有氧", details: "变速快走/跑步", duration: "45min"),
                                 WeeklyScheduleItem(day: "周六", focus: "休息", details: "热身+主训+放松", duration: ""),
                                 WeeklyScheduleItem(day: "周日", focus: "恢复", details: "瑜伽/HIIT恢复", duration: "45min"),
                             ]),
        ]
    }

    func generateAIPlan() {
        isGeneratingPlan = true
        guard token != nil, let url = URL(string: "\(baseURL)/insights/generate-plan") else {
            simulateAIGeneration()
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let prompt = aiPlanPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalPrompt: String
        if prompt.isEmpty {
            finalPrompt = "我是\(fitnessLevel)，目标是\(healthGoal)，每周训练\(planWeeklyFrequency)次，每次\(planSessionDuration)分钟。"
        } else {
            finalPrompt = prompt
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "userRequest": finalPrompt,
            "fitnessLevel": fitnessLevel,
            "healthGoal": healthGoal,
            "weeklyFrequency": planWeeklyFrequency,
            "sessionDuration": planSessionDuration,
            "healthLimitations": healthLimitations
        ])

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                defer { self?.isGeneratingPlan = false }
                guard let data = data, error == nil,
                      let result = try? JSONDecoder().decode(GeneratedPlanResponse.self, from: data),
                      result.success, let plans = result.data?.plans, !plans.isEmpty else {
                    self?.simulateAIGeneration()
                    return
                }
                self?.exercisePlans = plans.enumerated().map { index, plan in
                    ExercisePlanItem(id: "gen-\(index)", name: plan.name, duration: plan.duration,
                                     calories: "\(plan.calories)kcal", intensity: plan.intensity.displayLabel,
                                     emoji: plan.sportType.emoji, imageUrl: nil, isCompleted: false,
                                     sportType: plan.sportType, guidanceTips: [], techniqueSteps: [], weeklySchedule: [],
                                     config: ExerciseConfig.defaultForSportType(plan.sportType))
                }
                self?.showAIPlanProfileForm = false
                self?.aiPlanPrompt = ""
            }
        }.resume()
    }

    private func simulateAIGeneration() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            self.loadExercisePlans()
            self.isGeneratingPlan = false
            self.showAIPlanProfileForm = false
        }
    }

    func toggleAIPlanProfileForm() {
        showAIPlanProfileForm.toggle()
    }

    func startPlan(_ plan: ExercisePlanItem) {
        if let index = exercisePlans.firstIndex(where: { $0.id == plan.id }) {
            exercisePlans[index].isCompleted = true
        }
    }

    // MARK: - Micro Exercises

    func loadMicroExercises() {
        microExercises = [
            MicroExerciseItem(
                id: "w1", name: "肩颈放松", duration: "3 min", scene: "工位", emoji: "🧘",
                steps: ["缓慢转动头部", "双肩耸起再放松", "颈部左右拉伸各15秒"],
                breathingTips: "转头时吸气，回正时呼气。",
                benefits: "缓解肩颈紧张，改善久坐不适。",
                commonMistakes: ["动作过快易头晕", "用力耸肩反而更紧"],
                scenarioTips: "每工作 45–60 分钟做一组，工位可原地完成。",
                progression: "习惯后可增加侧颈静态拉伸至 20 秒。",
                regression: "若有颈椎病史，只做小幅慢转，不做弹振。"
            ),
            MicroExerciseItem(
                id: "w2", name: "坐姿脊柱扭转", duration: "2 min", scene: "工位", emoji: "🔄",
                steps: ["坐直身体", "左手扶右膝扭转", "换侧重复"],
                breathingTips: "吸气拉长脊柱，呼气加深扭转。",
                benefits: "提高胸椎灵活性，缓解腰背僵硬。",
                commonMistakes: ["骨盆跟着转动", "扭转时憋气"],
                scenarioTips: "椅子有靠背时保持坐骨端正，双脚踩实地面。",
                progression: "手可扶椅背外侧增加温和阻力。",
                regression: "幅度减半，只做单侧各一次。"
            ),
            MicroExerciseItem(
                id: "w3", name: "眼部放松操", duration: "2 min", scene: "工位", emoji: "👁️",
                steps: ["闭眼深呼吸3次", "远眺20秒", "眼球上下左右转动"],
                breathingTips: "保持均匀呼吸，避免憋气。",
                benefits: "缓解视疲劳，改善干眼不适。",
                commonMistakes: ["紧盯屏幕不眨眼", "远眺距离不足"],
                scenarioTips: "遵循 20-20-20：每 20 分钟看 20 英尺外 20 秒。",
                progression: "加入轻柔眼周按压（勿压眼球）。",
                regression: "仅做闭眼与远眺两步亦可。"
            ),
            MicroExerciseItem(
                id: "w4", name: "手腕伸展", duration: "1 min", scene: "工位", emoji: "🤚",
                steps: ["掌心向前伸直手臂", "另一手轻拉手指", "反向压手背各 15 秒"],
                breathingTips: "拉伸时呼气，还原吸气。",
                benefits: "减轻鼠标手与前臂紧张。",
                scenarioTips: "打字间隙即可完成，勿暴力拉扯。",
                progression: "可在站立位配合肩部下沉。",
                regression: "仅做勾腕伸腕各一次。"
            ),
            MicroExerciseItem(
                id: "w5", name: "深呼吸练习", duration: "3 min", scene: "工位", emoji: "🌬️",
                steps: ["一手放胸一手放腹", "鼻吸 4 拍", "口呼 6 拍，重复 6–8 轮"],
                breathingTips: "呼气长于吸气，激活副交感神经。",
                benefits: "降压专注，缓解开会前焦虑。",
                scenarioTips: "会议开始前 2 分钟做一轮即可见效。",
                progression: "延长至呼 8 拍（无不适为前提）。",
                regression: "改为自然深呼吸，不强行计数。"
            ),
            MicroExerciseItem(
                id: "w6", name: "站立拉伸", duration: "5 min", scene: "工位", emoji: "🙆",
                steps: ["站起髋铰链触脚尖", "侧弯伸展各侧", "扩胸与肩胛后缩"],
                breathingTips: "前屈呼气，起身吸气。",
                benefits: "唤醒臀腿后侧链，抵消久坐屈曲姿势。",
                scenarioTips: "走廊或打印机旁即可完成。",
                progression: "增加小腿台阶拉伸（若有矮阶）。",
                regression: "坐姿前屈替代站立版。"
            ),
            MicroExerciseItem(
                id: "c1", name: "地铁站姿收腹", duration: "3 min", scene: "通勤", emoji: "🚇",
                steps: ["双脚与肩同宽", "微收肋骨与下腹", "鼻吸口呼保持"],
                breathingTips: "呼气时略收紧核心，勿憋气。",
                benefits: "站立稳定性提高，保护腰椎。",
                scenarioTips: "车辆晃动时降低幅度，扶稳栏杆。",
                progression: "单脚交替微抬脚跟（有扶手时）。",
                regression: "只做静态收腹 30 秒 × 3 组。"
            ),
            MicroExerciseItem(
                id: "c2", name: "扶手核心稳定", duration: "2 min", scene: "通勤", emoji: "💪",
                steps: ["轻扶竖杆", "肩胛下沉", "交替抬膝找肚脐"],
                breathingTips: "抬膝呼气，落脚吸气。",
                benefits: "激活深层腹肌与髋屈肌协同。",
                scenarioTips: "高峰车厢勿做大幅度动作。",
                progression: "停顿 1 秒再落脚增加控制。",
                regression: "原地踏步替代抬膝。"
            ),
            MicroExerciseItem(
                id: "c3", name: "提踵练习", duration: "2 min", scene: "通勤", emoji: "🦶",
                steps: ["扶稳", "慢起至最高点停 1 秒", "慢落至全程"],
                breathingTips: "上提呼气，下落吸气。",
                benefits: "促进小腿泵血，减轻久站水肿。",
                scenarioTips: "候车排队时亦可练习。",
                progression: "单腿提踵（扶墙平衡允许时）。",
                regression: "双脚下肢幅度减半。"
            ),
            MicroExerciseItem(
                id: "c4", name: "颈部放松", duration: "1 min", scene: "通勤", emoji: "🙂",
                steps: ["耳找肩侧弯", "收下巴后缩", "肩胛下沉"],
                breathingTips: "侧弯呼气，回正吸气。",
                benefits: "缓解低头看手机造成的颈肩紧张。",
                scenarioTips: "公交刹车多时减小动作幅度。",
                progression: "配合胸椎轻度旋转。",
                regression: "仅做收下巴（chin tuck）。"
            ),
            MicroExerciseItem(
                id: "h1", name: "晨起拉伸", duration: "5 min", scene: "居家", emoji: "☀️",
                steps: ["猫牛式活动脊柱", "站姿侧弯", "手臂过头伸展"],
                breathingTips: "伸展呼气，还原吸气。",
                benefits: "提升全天关节活动度与清醒度。",
                scenarioTips: "起床后先喝温水再动，避免低血糖眩晕。",
                progression: "加入世界最伟大的拉伸（弓步转体）。",
                regression: "坐姿替代站姿动作。"
            ),
            MicroExerciseItem(
                id: "h2", name: "平板支撑", duration: "2 min", scene: "居家", emoji: "🏋️",
                steps: ["前臂与肩对齐", "躯干一条线", "臀夹紧肚脐微收"],
                breathingTips: "自然呼吸，禁止憋气。",
                benefits: "核心耐力基础动作。",
                commonMistakes: ["塌腰翘臀", "头下垂"],
                scenarioTips: "镜子或手机自拍检查身体成线。",
                progression: "交替抬手或单脚点地。",
                regression: "膝盖跪地缩短力臂。"
            ),
            MicroExerciseItem(
                id: "h3", name: "深蹲练习", duration: "3 min", scene: "居家", emoji: "🦵",
                steps: ["脚略宽于肩", "髋膝踝协同下蹲", "膝盖顺脚尖方向"],
                breathingTips: "下蹲吸气，站起呼气。",
                benefits: "下肢与臀部力量，动作模式迁移至日常起身。",
                commonMistakes: ["膝盖内扣", "脚跟离地"],
                scenarioTips: "身后放椅子轻触即起可作为深度标记。",
                progression: "放慢离心 3 秒。",
                regression: "箱式深蹲或扶椅。"
            ),
            MicroExerciseItem(
                id: "h4", name: "睡前放松", duration: "5 min", scene: "居家", emoji: "🌙",
                steps: ["仰卧腹式呼吸", "仰卧扭转", "婴儿式或坐位前屈"],
                breathingTips: "鼻吸口呼，呼气延长。",
                benefits: "降低交感神经兴奋，帮助入睡。",
                scenarioTips: "调暗灯光，手机勿扰模式。",
                progression: "配合渐进式肌肉放松（脚趾到头顶）。",
                regression: "只做呼吸 3 分钟。"
            ),
            MicroExerciseItem(
                id: "h5", name: "开合跳", duration: "3 min", scene: "居家", emoji: "⭐",
                steps: ["热身踝腕关节", "小幅度先试", "落地屈膝缓冲"],
                breathingTips: "节奏稳定，避免张口乱喘。",
                benefits: "快速提升心率与协调。",
                scenarioTips: "楼下邻居敏感可改为踏步拍手。",
                progression: "加入高抬腿开合跳。",
                regression: "原地踏步提膝。"
            ),
            MicroExerciseItem(
                id: "h6", name: "腹部训练", duration: "4 min", scene: "居家", emoji: "🎯",
                steps: ["死虫式", "仰卧屈膝卷腹", "侧平板（单侧 20 秒）"],
                breathingTips: "用力阶段呼气，颈部放松不发力。",
                benefits: "核心抗伸展与抗旋转能力。",
                commonMistakes: ["用手拽脖子", "腰部拱离地面"],
                scenarioTips: "瑜伽垫或地毯保护脊柱。",
                progression: "死虫式伸直腿对抗弹力带。",
                regression: "全程死虫式仅屈膝小幅度。"
            ),
        ]
        filterMicroExercises(by: currentScene)
    }

    func filterMicroExercises(by scene: String) {
        currentScene = scene
        filteredMicroExercises = microExercises.filter { $0.scene == scene }
    }

    func startMicroExercise(_ exercise: MicroExerciseItem) {
        selectedMicroExercise = exercise
    }

    func dismissMicroExerciseGuide() {
        selectedMicroExercise = nil
    }

    func showAddMicroExerciseDialog() {
        showAddMicroExercise = true
    }

    func dismissAddMicroExerciseDialog() {
        showAddMicroExercise = false
    }

    func addCustomMicroExercise(name: String, durationMinutes: Int) {
        let prefix: String
        switch currentScene {
        case "工位": prefix = "w"
        case "通勤": prefix = "c"
        default: prefix = "h"
        }
        let id = "\(prefix)-custom-\(Int(Date().timeIntervalSince1970))"
        let item = MicroExerciseItem(
            id: id,
            name: name,
            duration: "\(durationMinutes) min",
            scene: currentScene,
            emoji: "🏃",
            steps: ["根据你的动作描述执行"],
            breathingTips: "动作中保持自然呼吸。",
            benefits: "帮助在碎片时间激活身体。"
        )
        microExercises.append(item)
        filterMicroExercises(by: currentScene)
        showAddMicroExercise = false
    }

    // MARK: - Habits

    func loadHabits() {
        habits = [
            PlanHabitItem(id: "h1", name: "减盐少油", emoji: "🧊", currentDays: 3, targetDays: 21),
            PlanHabitItem(id: "h2", name: "饭后散步", emoji: "🚶", currentDays: 2, targetDays: 30),
            PlanHabitItem(id: "h3", name: "冥想放松", emoji: "🧘", currentDays: 2, targetDays: 14),
        ]
    }

    func toggleHabit(_ habit: PlanHabitItem) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            if !habits[index].isCompletedToday {
                habits[index].isCompletedToday = true
                habits[index].currentDays += 1
            }
        }
    }

    func logTodayTask() {
        guard !todayTaskCompleted else { return }
        todayTaskCompleted = true
    }

    private func generateTodayTask() {
        let tasks = [
            "在早餐时加入一些新鲜蔬菜，比如胡萝卜或黄瓜片，增加营养摄入。",
            "今天尝试走楼梯代替电梯，增加日常活动量。",
            "午餐后散步15分钟，促进消化。",
            "睡前做5分钟深呼吸放松练习。",
        ]
        let hour = Calendar.current.component(.hour, from: Date())
        let index = hour % tasks.count
        todayTaskText = tasks[index]
    }

    // MARK: - AI Adjustment

    private func loadAdjustablePlans() {
        adjustablePlans = [
            AdjustablePlanItem(
                id: "a1",
                category: "饮食",
                name: "半糖奶茶坚持20天",
                description: "每天只喝半糖饮品",
                textColorHex: "#FF9800",
                bgColorHex: "#FFE0B2"
            ),
            AdjustablePlanItem(
                id: "a2",
                category: "睡眠",
                name: "11点前入睡",
                description: "保持规律作息",
                textColorHex: "#9C27B0",
                bgColorHex: "#E1BEE7"
            ),
            AdjustablePlanItem(
                id: "a3",
                category: "锻炼",
                name: "每周3次有氧",
                description: "跑步或游泳",
                textColorHex: "#4CAF50",
                bgColorHex: "#C8E6C9"
            )
        ]
    }

    func selectAdjustPlan(_ planId: String?) {
        selectedAdjustPlanId = planId
    }

    func updateAdjustmentInput(_ text: String) {
        adjustmentInput = text
    }

    func submitAdjustment() {
        guard let selectedAdjustPlanId, !adjustmentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        guard let planIndex = adjustablePlans.firstIndex(where: { $0.id == selectedAdjustPlanId }) else {
            return
        }

        isAiProcessing = true
        isAdjusting = true

        let original = adjustablePlans[planIndex]
        let lower = adjustmentInput.lowercased()
        let newName: String
        let newDesc: String
        let reason: String

        if lower.contains("难") || lower.contains("累") || lower.contains("坚持不") {
            newName = "温和版 · \(original.name)"
            newDesc = "降低门槛，减少阻力，优先保证可坚持性"
            reason = "根据你的反馈，先降低强度帮助你稳定建立习惯。"
        } else if lower.contains("加强") || lower.contains("提高") || lower.contains("挑战") {
            newName = "进阶版 · \(original.name)"
            newDesc = "提高执行标准，加入更明确的阶段目标"
            reason = "在现有基础上逐步进阶，帮助突破平台期。"
        } else {
            newName = "个性化版 · \(original.name)"
            newDesc = "结合你的偏好，对执行策略做定制化优化"
            reason = "已根据你的想法进行计划重排与执行路径微调。"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.adjustablePlans[planIndex].name = newName
            self.adjustablePlans[planIndex].description = newDesc
            self.adjustmentResult = AdjustmentResultItem(
                originalName: original.name,
                adjustedName: newName,
                adjustedDescription: newDesc,
                reason: reason
            )
            self.adjustmentInput = ""
            self.selectedAdjustPlanId = nil
            self.isAiProcessing = false
            self.isAdjusting = false
        }
    }

    func dismissAdjustmentResult() {
        adjustmentResult = nil
    }

    func updateConfig(for planId: String, transform: (inout ExerciseConfig) -> Void) {
        guard let idx = exercisePlans.firstIndex(where: { $0.id == planId }) else { return }
        var config = exercisePlans[idx].config
        transform(&config)
        exercisePlans[idx].config = config
    }
}

// MARK: - Data Models

struct ExercisePlanItem: Identifiable {
    let id: String
    let name: String
    let duration: String
    let calories: String
    let intensity: String
    let emoji: String
    let imageUrl: String?
    var isCompleted: Bool
    var sportType: String = "GENERIC"
    var guidanceTips: [String] = []
    var techniqueSteps: [String] = []
    var weeklySchedule: [WeeklyScheduleItem] = []
    var config: ExerciseConfig = .init()
}

struct WeeklyScheduleItem: Identifiable {
    let id = UUID()
    let day: String
    let focus: String
    let details: String
    let duration: String
    var isActive: Bool { !duration.isEmpty }
}

struct MicroExerciseItem: Identifiable {
    let id: String
    let name: String
    let duration: String
    let scene: String
    let emoji: String
    var steps: [String] = []
    var breathingTips: String = ""
    var benefits: String = ""
    var commonMistakes: [String] = []
    var scenarioTips: String = ""
    var progression: String = ""
    var regression: String = ""
}

extension MicroExerciseItem {
    /// 列表 / 引导页统一使用的 SF Symbol，避免 emoji 字体缺失时出现占位符。
    var displaySFPlanSymbol: String {
        switch id {
        case "w1": return "figure.arms.open"
        case "w2": return "figure.flexibility"
        case "w3": return "eye.fill"
        case "w4": return "hand.raised.fill"
        case "w5": return "wind"
        case "w6": return "figure.stand"
        case "c1": return "figure.stand"
        case "c2": return "figure.core.training"
        case "c3": return "figure.walk"
        case "c4": return "figure.mind.and.body"
        case "h1": return "sun.max.fill"
        case "h2": return "figure.core.training"
        case "h3": return "figure.strengthtraining.traditional"
        case "h4": return "moon.zzz.fill"
        case "h5": return "figure.jumprope"
        case "h6": return "figure.core.training"
        default: return "figure.walk"
        }
    }
}

struct PlanHabitItem: Identifiable {
    let id: String
    let name: String
    let emoji: String
    var currentDays: Int
    let targetDays: Int
    var isCompletedToday: Bool = false
}

struct AdjustablePlanItem: Identifiable {
    let id: String
    let category: String
    var name: String
    var description: String
    let textColorHex: String
    let bgColorHex: String
}

struct AdjustmentResultItem: Identifiable {
    let id = UUID()
    let originalName: String
    let adjustedName: String
    let adjustedDescription: String
    let reason: String
}

struct ExerciseConfig {
    var targetCalories: Double = 300
    var targetTime: Double = 45
    var weeklyFrequency: Double = 3

    // Running
    var runningGoalType: String = "DISTANCE"
    var targetDistance: Double = 5
    var targetPace: Double = 6
    var runningTerrain: Int = 0

    // Cycling
    var cyclingDistance: Double = 20
    var cyclingCadence: Double = 80
    var cyclingTerrain: Int = 0

    // Yoga
    var yogaStyle: Int = 0
    var yogaDifficulty: Int = 0
    var meditationMinutes: Double = 5

    // Swimming
    var swimmingStroke: Int = 0
    var swimDistance: Double = 500
    var restPerLap: Double = 15

    // Hiking
    var hikingDifficulty: Int = 1
    var hikingElevationGain: Double = 300
    var hikingPackWeight: Double = 5

    static func defaultForSportType(_ sportType: String) -> ExerciseConfig {
        var base = ExerciseConfig()
        switch sportType {
        case "RUNNING":
            base.targetTime = 30
            base.targetCalories = 350
        case "SWIMMING":
            base.targetTime = 40
            base.targetCalories = 400
            base.swimDistance = 800
        case "YOGA":
            base.targetTime = 60
            base.targetCalories = 180
        case "HIKING":
            base.targetTime = 90
            base.targetCalories = 450
        case "CYCLING":
            base.targetTime = 45
            base.targetCalories = 300
        default:
            break
        }
        return base
    }
}

// MARK: - Network Response Structs

struct GeneratedPlanResponse: Codable {
    let success: Bool
    let message: String
    let data: GeneratedPlanPayload?
}

struct GeneratedPlanPayload: Codable {
    let generated: Bool
    let plans: [GeneratedPlanItem]?
}

struct GeneratedPlanItem: Codable {
    let name: String
    let calories: Int
    let intensity: String
    let duration: String
    let sportType: String
}

private extension String {
    var displayLabel: String {
        switch self {
        case "LOW": return "低强度"
        case "HIGH": return "高强度"
        default: return "中等"
        }
    }
    var emoji: String {
        switch self {
        case "RUNNING": return "🏃"
        case "YOGA": return "🧘"
        case "BADMINTON": return "🏸"
        case "SWIMMING": return "🏊"
        case "HIKING": return "🥾"
        case "CYCLING": return "🚴"
        default: return "💪"
        }
    }
}
