# AegisFlow iOS 项目

基于安卓应用 AegisFlow 的 iOS 复刻版本，使用 SwiftUI 开发。

## 项目概述

AegisFlow 是一款智能健康管理应用，提供以下核心功能：

- **智能仪表盘**: 全面展示健康指标、趋势分析和AI建议
- **AI健康助手**: 智能对话，支持下单、对话、页面生成三种模式
- **运动计划**: 专业运动计划、微运动、习惯养成
- **个人中心**: 用户资料、设备管理、设置

## 技术栈

| 组件 | 技术 |
|------|------|
| 框架 | SwiftUI |
| 语言 | Swift 5.9+ |
| 最低版本 | iOS 16.0 |
| 数据库 | GRDB.swift |
| 网络 | URLSession (可扩展为Alamofire) |
| 存储 | UserDefaults + Keychain |
| 通知 | UserNotifications framework |
| 健康数据 | HealthKit |

## 项目结构

```
AegisFlow_iOS/
├── AppMain.swift                         # 应用入口 + APNs推送 + 路由分发
├── GlobalManager/
│   ├── MainTabView.swift                # 主Tab导航 + 路由目标 + 底部栏
│   ├── DataManager.swift                # 全局数据管理 + AppRoute枚举
│   └── NavigationCoordinator.swift      # 集中式路由管理 (NavigationPath)
├── Modules/
│   ├── Dashboard/
│   │   ├── DashboardView.swift          # 仪表盘 (Hero弧形+主题纹样)
│   │   ├── DashboardViewModel.swift
│   │   ├── StatisticsViewModel.swift
│   │   ├── NotificationViewModel.swift
│   │   ├── InsightDetailView.swift      # 健康洞察详情
│   │   ├── TeammateHomeView.swift       # 健康团队
│   │   ├── NotificationCenterView.swift
│   │   ├── StatisticsScreen.swift
│   │   ├── FoodAnalysisView.swift
│   │   ├── KnowledgeGraphView.swift
│   │   └── Components/LogBottomSheet.swift
│   ├── Plan/
│   │   ├── PlanView.swift
│   │   └── PlanViewModel.swift
│   ├── Chat/
│   │   ├── ChatView.swift               # 聊天 (侧滑面板+模式切换+语音)
│   │   ├── GeneratedPageView.swift
│   │   ├── ElemeOrderWebView.swift      # 外卖WebView
│   │   └── ChatSubFeatures.swift
│   ├── Profile/
│   │   ├── ProfileView.swift            # 统一Profile + 子页面导航
│   │   ├── ProfileViewModel.swift
│   │   ├── SettingsViewModel.swift
│   │   ├── GamificationViewModels.swift # Level/Reward/Premium VM
│   │   ├── UserInsightCard.swift        # 用户画像卡片
│   │   ├── GamificationViews.swift
│   │   ├── SettingsViews.swift
│   │   └── ReminderSettingsView.swift
│   ├── DeskPet/
│   │   └── DeskPetFloatingOverlay.swift # 桌宠悬浮组件
│   ├── Onboarding/OnboardingView.swift
│   ├── Auth/AuthViews.swift
│   ├── Avatar/Twin3DView.swift
│   ├── iOS_Data/                        # 健康数据页 (新版)
│   └── iOS_Profile/                     # Profile子页面 (Level/Rewards/Premium等)
├── Services/
│   ├── APIClient.swift                  # 35+端点 + token自动刷新
│   ├── DatabaseManager.swift
│   ├── StorageManager.swift
│   ├── NotificationService.swift        # 本地通知 + APNs
│   └── HealthDataService.swift
└── ShareComponents/
    ├── Extensions.swift                 # 颜色/字体/间距/卡片样式
    ├── LoadingStates.swift              # 空状态/加载/错误/骨架屏
    ├── WeekDatePicker.swift
    └── IndicatorCard.swift
```

## 主题色系

### 品牌色
- Sage Light: `#A7CDB8`
- Sage Bright: `#A5D23D`
- Teal Deep: `#306E6F`

### 周主题色（7种日间主题）
| 星期 | Primary | Secondary | 主题 |
|------|---------|-----------|------|
| 周日 | #2F97A3 | #5BC2D2 | 周期修复 |
| 周一 | #B85E8E | #DB87B3 | 关节激活 |
| 周二 | #5B73C8 | #8FA3E8 | 睡眠改善 |
| 周三 | #3C8E79 | #69B9A4 | 训练恢复 |
| 周四 | #A6A01B | #CCC82A | 压力疏导 |
| 周五 | #C8676E | #E3878D | 心肺唤醒 |
| 周六 | #2B97A5 | #56C0CC | 轻松收束 |

## 已完成模块

### 1. 项目基础配置
- 完整颜色系统
- 字体规范
- 圆角规范
- 间距规范
- 阴影规范
- 通用UI组件样式

### 2. 主导航
- TabView 底部导航栏
- 5个主要页面入口

### 3. 启动页
- 品牌Logo动画
- 渐变背景

### 4. Onboarding引导流程
- 欢迎页
- 性别选择
- 健康目标选择
- 活动水平选择
- 职业选择
- 爱好选择

### 5. Dashboard仪表盘
- Hero区域（周主题渐变）
- 记录模块（10种记录类型）
- 目标进度卡片
- 生理指标面板
- 营养概览
- 健康趋势图表
- 今日目标网格
- 健康见解轮播

### 6. 记录弹窗
- 饮食记录
- 饮水记录
- 心情记录
- 运动记录
- 睡眠记录
- 其他记录类型

### 7. 计划模块
- 运动计划Tab
- 微运动Tab
- 习惯养成Tab

### 8. Chat聊天页面
- 消息气泡
- 输入区域
- AI头像和状态
- 对话列表面板
- 打字指示器

### 9. Profile个人中心
- 用户资料卡片
- 身体数据管理
- 设备管理
- 设置列表

### 10. 认证模块
- 登录页面
- 注册页面
- 忘记密码页面

### 11. 服务层
- API客户端
- 数据库管理器（GRDB）
- 存储管理器（UserDefaults + Keychain）
- 通知服务
- HealthKit服务

## Android 一比一复刻进度

### 已完成 (Phase 1-4)
- [x] 集中式路由管理 (NavigationCoordinator + NavigationPath)
- [x] 18个路由全部对齐Android NavHost
- [x] AppMain启动逻辑：token检测 + 条件路由 (Auth/Onboarding/Main)
- [x] APIClient完善：35+端点全覆盖 + token自动刷新 + 多部分上传
- [x] 所有ViewModel补全 (Plan, Statistics, Settings, Gamification, Notification)
- [x] Dashboard Hero弧形裁切 (HeroBottomArcShape) + 7种CardPatternStyle
- [x] 底部导航栏：SageBright实色胶囊 + 白色图标 + 1.1x缩放动画 + shadow
- [x] Chat侧滑面板改为右侧overlay + ORDER/CHAT/PAGE模式切换 + 语音输入
- [x] Profile统一实现 + 子页面导航 (Level/Rewards/Premium/Settings)
- [x] DeskPet桌宠悬浮组件
- [x] ElemeOrder外卖WebView
- [x] InsightDetail健康洞察详情页
- [x] TeammateHome健康团队页
- [x] UserInsightCard用户画像卡片
- [x] APNs推送通知 (替代Android FCM)
- [x] 空状态/加载状态/错误横幅组件 (LoadingStates.swift)

### 已完成 (补充)
- [x] 数据库实际读写 (GRDB: 会话/消息/健康指标/活动日志/用户偏好)
- [x] HealthKit数据同步 (步数/心率/睡眠/卡路里/体重/身高/周趋势+后台观察者)
- [x] 图表组件 (折线图/环形进度/柱状图/营养条/迷你柱状图 - Swift Charts)
- [x] Twin3D完整流程 (选项获取/描述提交/轮询查询/模型加载/截图分享)

### 测试
- [ ] 单元测试
- [ ] UI测试
- [ ] 集成测试

### 发布准备
- [ ] App Store配置
- [ ] 图标和启动屏
- [ ] 隐私政策和使用条款
- [ ] 本地化支持

## 开发指南

### 添加新页面
1. 在 `Modules/` 下创建新模块目录
2. 创建 `XXXView.swift` 和 `XXXViewModel.swift`
3. 在 `MainTabView.swift` 添加Tab入口

### 使用主题色
```swift
// 使用周主题色
let themeColors = Color.weekThemeColor(for: dayOfWeek)
RoundedRectangle()
    .fill(LinearGradient(
        colors: [themeColors.primary, themeColors.secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    ))

// 使用品牌色
Color.sageBright
Color.tealDeep
```

### 数据持久化
```swift
// 使用PreferencesStorage
PreferencesStorage.shared.isLoggedIn = true

// 使用TokenStorage（Keychain）
TokenStorage.shared.accessToken = "token"

// 使用DatabaseManager
try DatabaseManager.shared.insertSession(session)
```

## 后端API

基础URL: `http://8.156.83.92:8080/api/v1`

详见 `docs/API_Documentation.md`

## 许可证

MIT License
