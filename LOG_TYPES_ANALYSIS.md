# AegisFlow iOS 日志类型实现详细清单

**分析日期**: 2026-05-14  
**项目**: AegisFlow iOS（版本95）  
**范围**: 首页（Dashboard）展示的5个日志类型

---

## 📋 执行摘要

首页"我的记录"区域展示了 **5个核心日志类型**。这5个类型被定义在 `DataManager.swift` 中的 `LogType` 枚举，并在 `DashboardV2RecordsSection` 中的快速入口显示。每个类型都包含完整的表单、API、显示、和数据流处理。

---

## 1️⃣ **饮食 (Meal)**

### 基础信息
| 字段 | 值 |
|------|-----|
| **标识符** | `meal` |
| **显示名称** | "饮食" |
| **图标** | `fork.knife` (SF Symbols) |
| **颜色** | `.orangeWarm` |
| **Emoji** | 🍽️ |

### 实现位置

#### 🔹 定义
- **文件**: [GlobalManager/DataManager.swift](GlobalManager/DataManager.swift#L205)
- **行号**: 205-275
- **核心代码**:
  ```swift
  enum LogType: String, CaseIterable, Identifiable {
      case meal = "meal"
      
      var title: String {
          case .meal: return "饮食"
      }
      
      var icon: String {
          case .meal: return "fork.knife"
      }
      
      var color: Color {
          case .meal: return .orangeWarm
      }
  }
  ```

#### 🔹 首页快速入口
- **文件**: [Modules/Dashboard/Components/DashboardV2Sections.swift](Modules/Dashboard/Components/DashboardV2Sections.swift#L9)
- **行号**: 9（列表定义）/ 50-90（卡片UI）
- **实现**:
  - 在 `DashboardV2RecordsSection` 中定义快速入口数组
  - 每个类型显示为 `RecordQuickEntryTile` 组件
  - 点击打开记录表单

#### 🔹 记录表单 - 输入字段
- **文件**: [Modules/Dashboard/Components/LogBottomSheet.swift](Modules/Dashboard/Components/LogBottomSheet.swift#L85)
- **行号**: 85-115（MealInputSection）
- **字段**:
  | 字段 | 类型 | 约束 | 说明 |
  |-----|------|------|------|
  | `mealName` | String | 无限制 | 食物名称 |
  | `mealCalories` | String → Int | 0-∞ | 热量（千卡） |
  | `value` (提交) | Int | - | 实际提交的数值 = `Int(mealCalories)` |

- **标签** (L310-311):
  ```swift
  case .meal:
      return ["早餐", "午餐", "晚餐", "加餐", "零食", "水果", "蔬菜", "主食", "肉类", "饮品"]
  ```
  - 共 **10个预设标签**
  - 可多选
  - 类型：`Set<String>`

#### 🔹 拍照识别
- **位置**: LogBottomSheet.swift L110-113
- **功能**: "拍照识别" 按钮触发 `FoodAnalysisView`
- **集成**: 通过 `@State private var showFoodAnalysis` 控制弹层

#### 🔹 数据提交
- **文件**: [Modules/Dashboard/Components/LogBottomSheet.swift](Modules/Dashboard/Components/LogBottomSheet.swift#L320-355)
- **行号**: 320-355 (`submitLog()` 方法)
- **流程**:
  ```swift
  // 1. 提取字段值
  numericValue = Int(mealCalories)
  
  // 2. 组合备注（食物名 + 热量 + 用户备注）
  let composedNote = [
      "食物: \(mealName)",
      "热量: \(mealCalories) kcal",
      note
  ].compactMap { $0 }.joined(separator: "；")
  
  // 3. 调用 API
  APIClient.shared.request(
      .createLog(
          type: "meal",
          value: numericValue,
          tags: tags,
          notes: composedNote
      ),
      responseType: EmptyResponse.self
  )
  ```

#### 🔹 API 端点
- **文件**: [Services/APIClient.swift](Services/APIClient.swift#L35)
- **行号**: 35（枚举定义）/ 96（路径定义）
- **端点**: `POST /logs`
- **请求体**:
  ```swift
  case createLog(type: String, value: Int?, tags: [String]?, notes: String?)
  ```
- **示例**:
  ```json
  {
      "type": "meal",
      "value": 650,
      "tags": ["午餐", "肉类"],
      "notes": "食物: 红烧鸡; 热量: 650 kcal; 油少了点"
  }
  ```

#### 🔹 ViewModel 处理
- **文件**: [Modules/Dashboard/DashboardViewModel.swift](Modules/Dashboard/DashboardViewModel.swift#L1)
- **相关属性**:
  - `@Published var currentLogType: LogType?` - 当前选中类型
  - `@Published var showLogSheet: Bool` - 表单显示状态
- **方法** (L226-228):
  ```swift
  func openLogSheet(type: LogType) {
      currentLogType = type
      showLogSheet = true
  }
  ```

---

## 2️⃣ **饮水 (Water)**

### 基础信息
| 字段 | 值 |
|------|-----|
| **标识符** | `water` |
| **显示名称** | "饮水" |
| **图标** | `drop.fill` |
| **颜色** | `.androidBlue` |
| **Emoji** | 💧 |

### 实现位置

#### 🔹 定义
- **文件**: [GlobalManager/DataManager.swift](GlobalManager/DataManager.swift#L205)
- **行号**: 206

#### 🔹 首页快速入口
- **文件**: [Modules/Dashboard/Components/DashboardV2Sections.swift](Modules/Dashboard/Components/DashboardV2Sections.swift#L9)
- **行号**: 9

#### 🔹 记录表单 - 输入字段
- **文件**: [Modules/Dashboard/Components/LogBottomSheet.swift](Modules/Dashboard/Components/LogBottomSheet.swift#L117-155)
- **行号**: 14（初始化）/ 117-155（WaterInputSection）
- **字段**:
  | 字段 | 类型 | 范围 | 说明 |
  |-----|------|------|------|
  | `waterMl` | Float | 0-4000 | 毫升数，使用滑块 |
  | `value` (提交) | Int | - | = `Int(waterMl)` |

- **快速按钮** (L147-153):
  - 250 ml
  - 500 ml
  - 750 ml
  - 1000 ml

- **标签** (L312-313):
  ```swift
  case .water:
      return ["早起", "运动后", "餐前", "餐后", "睡前"]
  ```
  - 共 **5个预设标签**

#### 🔹 输入组件
- **使用**: `GoalAdjustableRow` 滑块组件
- **对齐**: 个人中心"健康目标"页面的相同控件
- **范围**: 0-4000 ml

#### 🔹 数据提交
- **行号**: 328-330
- **流程**:
  ```swift
  case .water:
      numericValue = Int(waterMl)  // 直接取整
  ```

#### 🔹 API 端点
- **端点**: `POST /logs`
- **请求体**:
  ```json
  {
      "type": "water",
      "value": 500,
      "tags": ["早起"],
      "notes": null
  }
  ```

---

## 3️⃣ **心情 (Mood)**

### 基础信息
| 字段 | 值 |
|------|-----|
| **标识符** | `mood` |
| **显示名称** | "心情" |
| **图标** | `face.smiling` |
| **颜色** | `.yellowBright` |
| **Emoji** | 😊 |

### 实现位置

#### 🔹 定义
- **文件**: [GlobalManager/DataManager.swift](GlobalManager/DataManager.swift#L205)
- **行号**: 207

#### 🔹 首页快速入口
- **文件**: [Modules/Dashboard/Components/DashboardV2Sections.swift](Modules/Dashboard/Components/DashboardV2Sections.swift#L9)
- **行号**: 9

#### 🔹 记录表单 - 情绪选择
- **文件**: [Modules/Dashboard/Components/LogBottomSheet.swift](Modules/Dashboard/Components/LogBottomSheet.swift#L157-215)
- **行号**: 93（初始化）/ 157-215（MoodInputSection）
- **UI类型**: 栅格网格（LazyVGrid），6个情绪按钮
- **情绪选项**:
  ```swift
  let moods: [(symbol: String, label: String, color: Color)] = [
      ("face.smiling.fill", "开心", .successGreen),        // 绿色
      ("cloud.fill", "平静", .androidBlue),                // 蓝色
      ("exclamationmark.triangle.fill", "焦虑", .orangeWarm),  // 橙色
      ("moon.zzz.fill", "疲惫", .purpleSoft),              // 紫色
      ("bolt.heart.fill", "兴奋", .yellowBright),          // 黄色
      ("cloud.rain.fill", "难过", .errorRed),              // 红色
  ]
  ```

- **标签** (L314-315):
  ```swift
  case .mood:
      return ["开心", "平静", "焦虑", "疲惫", "兴奋", "难过", "压力大"]
  ```
  - 共 **7个预设标签**
  - **注**：标签与情绪选择有重叠，用户可同时选情绪+标签

#### 🔹 状态管理
- **选中状态**: `@State private var selectedMood: String?`
- **存储**: 情绪标签存入 `selectedTags` 中

#### 🔹 数据提交
- **行号**: 331-332
- **流程**:
  ```swift
  case .mood:
      // 心情类型本身无数值，仅通过标签和备注记录
      // selectedTags 包含了情绪标签（如"开心"、"焦虑"等）
  ```

#### 🔹 API 端点
- **端点**: `POST /logs`
- **请求体**:
  ```json
  {
      "type": "mood",
      "value": null,
      "tags": ["开心", "压力大"],
      "notes": "工作完成后很开心，但还是有点压力"
  }
  ```

---

## 4️⃣ **运动 (Exercise)**

### 基础信息
| 字段 | 值 |
|------|-----|
| **标识符** | `exercise` |
| **显示名称** | "运动" |
| **图标** | `figure.run` |
| **颜色** | `.successGreen` |
| **Emoji** | 🏃 |

### 实现位置

#### 🔹 定义
- **文件**: [GlobalManager/DataManager.swift](GlobalManager/DataManager.swift#L205)
- **行号**: 208

#### 🔹 首页快速入口
- **文件**: [Modules/Dashboard/Components/DashboardV2Sections.swift](Modules/Dashboard/Components/DashboardV2Sections.swift#L9)
- **行号**: 9

#### 🔹 记录表单 - 输入字段
- **文件**: [Modules/Dashboard/Components/LogBottomSheet.swift](Modules/Dashboard/Components/LogBottomSheet.swift#L217-240)
- **行号**: 15（初始化）/ 217-240（ExerciseInputSection）
- **字段**:
  | 字段 | 类型 | 范围 | 说明 |
  |------|------|------|------|
  | `exerciseMinutes` | Float | 5-180 | 运动时长（分钟），使用滑块 |
  | `value` (提交) | Int | - | = `Int(exerciseMinutes)` |

- **快速按钮** (L232-238):
  - 15 分钟
  - 30 分钟
  - 45 分钟
  - 60 分钟

- **标签** (L316-317):
  ```swift
  case .exercise:
      return ["跑步", "瑜伽", "游泳", "健身", "骑行", "散步", "跳舞", "冥想"]
  ```
  - 共 **8个预设标签**

#### 🔹 输入组件
- **使用**: `GoalAdjustableRow` 滑块组件
- **默认值**: 30 分钟
- **范围**: 5-180 分钟

#### 🔹 数据提交
- **行号**: 333-334
- **流程**:
  ```swift
  case .exercise:
      numericValue = Int(exerciseMinutes)
  ```

#### 🔹 API 端点
- **端点**: `POST /logs`
- **请求体**:
  ```json
  {
      "type": "exercise",
      "value": 45,
      "tags": ["跑步", "户外"],
      "notes": "早晨跑步5公里，天气很好"
  }
  ```

---

## 5️⃣ **睡眠 (Sleep)**

### 基础信息
| 字段 | 值 |
|------|-----|
| **标识符** | `sleep` |
| **显示名称** | "睡眠" |
| **图标** | `bed.double.fill` |
| **颜色** | `.purpleSoft` |
| **Emoji** | 😴 |

### 实现位置

#### 🔹 定义
- **文件**: [GlobalManager/DataManager.swift](GlobalManager/DataManager.swift#L205)
- **行号**: 209

#### 🔹 首页快速入口
- **文件**: [Modules/Dashboard/Components/DashboardV2Sections.swift](Modules/Dashboard/Components/DashboardV2Sections.swift#L9)
- **行号**: 9

#### 🔹 记录表单 - 输入字段
- **文件**: [Modules/Dashboard/Components/LogBottomSheet.swift](Modules/Dashboard/Components/LogBottomSheet.swift#L17 + 后续行)
- **行号**: 17（初始化）/ 后续（SleepInputSection）
- **字段**:
  | 字段 | 类型 | 范围 | 说明 |
  |------|------|------|------|
  | `sleepHoursTotal` | Float | ? | 睡眠时长（小时），使用滑块 |
  | `value` (提交) | Int | - | = `Int(sleepHoursTotal)` |

- **标签** (L319-320):
  ```swift
  case .sleep:
      return ["深睡眠", "浅睡眠", "做梦", "醒来", "翻身多"]
  ```
  - 共 **5个预设标签**

#### 🔹 输入组件
- **使用**: `SleepInputSection` - 类似于 `GoalAdjustableRow` 的滑块
- **单位**: 小时

#### 🔹 数据提交
- **行号**: 335-337
- **流程**:
  ```swift
  case .sleep:
      // 以小时为单位上传（后端可按需转换）
      numericValue = Int(sleepHoursTotal)
  ```

#### 🔹 API 端点
- **端点**: `POST /logs`
- **请求体**:
  ```json
  {
      "type": "sleep",
      "value": 8,
      "tags": ["深睡眠"],
      "notes": "昨晚睡眠质量不错"
  }
  ```

---

## 🔄 完整数据流链路

### 用户交互流程
```
1. 首页 DashboardView
   ↓
2. 点击快速入口卡片 (RecordQuickEntryTile)
   ↓
3. 打开 LogBottomSheet
   ↓
4. 填写表单（MealInputSection / WaterInputSection / MoodInputSection 等）
   ↓
5. 选择标签 (tagsForType)
   ↓
6. 点击"保存记录"按钮
   ↓
7. submitLog() 方法处理
   ↓
8. APIClient.shared.request(.createLog(...))
   ↓
9. POST /logs 端点
   ↓
10. 关闭 Sheet，返回首页
```

### 类型选择流程
```
点击 "+" 按钮
   ↓
toggleTypePicker() 显示 RecordTypePickerSheet
   ↓
选择类型（grid 网格显示所有类型）
   ↓
onSelect 回调
   ↓
openLogSheet(type) 打开该类型的表单
```

---

## 📊 类型统计表

| 类型 | 标识符 | 图标 | 颜色 | 输入方式 | 标签数 | 数值类型 | 默认值 |
|------|--------|------|------|---------|--------|---------|--------|
| **饮食** | `meal` | fork.knife | orangeWarm | 文本框 (名称+热量) | 10 | Int (kcal) | - |
| **饮水** | `water` | drop.fill | androidBlue | 滑块 | 5 | Int (ml) | 500 |
| **心情** | `mood` | face.smiling | yellowBright | 6选1 按钮 | 7 | null | - |
| **运动** | `exercise` | figure.run | successGreen | 滑块 | 8 | Int (min) | 30 |
| **睡眠** | `sleep` | bed.double.fill | purpleSoft | 滑块 | 5 | Int (hour) | 7 |

---

## 📁 关键文件位置总结

| 功能 | 文件 | 行号 |
|------|------|------|
| **类型定义** | GlobalManager/DataManager.swift | 205-275 |
| **快速入口数组** | Modules/Dashboard/Components/DashboardV2Sections.swift | 9 |
| **首页卡片UI** | Modules/Dashboard/Components/DashboardV2Sections.swift | 50-90 |
| **表单 Sheet** | Modules/Dashboard/Components/LogBottomSheet.swift | 4-380+ |
| **类型选择器** | Modules/Dashboard/Components/RecordTypePickerSheet.swift | 4-70 |
| **表单输入组件** | Modules/Dashboard/Components/LogBottomSheet.swift | 85-240 |
| **标签定义** | Modules/Dashboard/Components/LogBottomSheet.swift | 310-321 |
| **数据提交逻辑** | Modules/Dashboard/Components/LogBottomSheet.swift | 320-355 |
| **ViewModel 集成** | Modules/Dashboard/DashboardViewModel.swift | 1-50 |
| **API 定义** | Services/APIClient.swift | 35 + 96 |

---

## 🎨 颜色定义

所有颜色定义在全局颜色扩展中（推测在 ShareComponents/Extensions.swift）：
- `.orangeWarm` - 饮食
- `.androidBlue` - 饮水
- `.yellowBright` - 心情
- `.successGreen` - 运动
- `.purpleSoft` - 睡眠

---

## 🔗 相关数据模型（待确认）

根据 API 调用模式，推测的数据模型：
```swift
struct LogRecord: Codable {
    let id: String
    let type: String          // "meal", "water", "mood", "exercise", "sleep"
    let value: Int?           // 数值（可选）
    let tags: [String]?       // 标签列表
    let notes: String?        // 备注
    let recordedAt: String    // ISO 8601 时间戳
    let createdAt: String     // 创建时间
}

struct CreateLogRequest: Codable {
    let type: String
    let value: Int?
    let tags: [String]?
    let notes: String?
}
```

---

## 📝 备注

1. **心情类型特殊性**: 心情类型（mood）本身无数值字段，仅通过标签和备注记录情绪状态。

2. **标签灵活性**: 每个类型的标签是预设的，但用户可以通过 Tag Chip 组件自由多选。

3. **表单日期上下文**: 当用户在非当日日期填写记录时，LogBottomSheet 会显示 `dateContextLine` 说明（via DashboardViewModel.logSheetDateContextLine）。

4. **API 一致性**: 所有类型统一使用 `POST /logs` 端点，后端通过 `type` 字段区分。

5. **拍照识别**: 仅饮食类型支持拍照食物识别功能（触发 FoodAnalysisView）。

6. **滑块组件**: 饮水和运动类型使用统一的 `GoalAdjustableRow` 组件，与健康目标页面设计一致。

---

**生成工具**: GitHub Copilot - AI 代码分析  
**分析方式**: 彻底的代码追踪和交叉引用
