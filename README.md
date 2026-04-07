# Aegis Flow (Tempo) - 项目总览

**版本**: 2.0.0
**状态**: ✅ 纯 Node.js 后端迭代版本
**日期**: 2026-03-05

---

## 项目结构

`
项目根目录/
├── frontend/                # Android 原生客户端 (Jetpack Compose)
│   ├── app/
│   │   └── src/main/
│   │       ├── java/com/aegisflow/
│   │       │   ├── AegisFlowApp.kt
│   │       │   ├── data/             # 远程与本地数据源
│   │       │   └── ui/               # 仪表盘、统计、AI 聊天、个人资料
│   │       └── res/
│   ├── build.gradle.kts
│   └── settings.gradle.kts
│
├── backend/                  # Node.js + Express + PostgreSQL 后端
│   ├── server.js              # 主入口
│   ├── db/                    # 数据库连接池与迁移脚本
│   │   ├── migrations/        # SQL 迁移文件
│   │   └── pool.js
│   ├── routes/                # API 路由 (Auth, Health, Logs, Chat, Users, etc.)
│   ├── services/              # 业务逻辑 (Email, Captcha, Gemini AI, etc.)
│   ├── middleware/            # 中间件 (Auth, RateLimiter, Validate)
│   ├── utils/                 # 工具类
│   ├── .env                   # 环境变量配置
│   └── package.json           # 依赖管理
│
└── docs/                     # 项目文档
    ├── PRD.md                 # 产品需求文档
    ├── API_Documentation.md   # 完整 API 文档
    └── DESIGN_SPEC.md         # 后端架构设计规范
`

---

## 🎯 项目特点

### 技术栈更新
- ✅ **Backend**: Node.js (Express) + PostgreSQL
- ✅ **Frontend**: Kotlin + Jetpack Compose + Material 3
- 🔐 **认证**: JWT + Refresh Token
- 📧 **服务**: QQ 邮箱验证码发送 + 智能 AI 洞察集成

---

## 🚀 快速开始

### 1. 准备数据库 (PostgreSQL)
确保本地 PostgreSQL 已启动（默认端口 5433），并创建 aegisflow 数据库。

### 2. 启动后端服务
`powershell
cd backend
npm install
npm run migrate    # 初始化数据库表
npm start          # 启动服务 http://localhost:8080
`

### 3. 运行 Android 应用
1. 用 Android Studio 打开 frontend/ 目录。
2. 确保模拟器已启动或真机已连接。
3. 点击 Run。

---

## 🔌 后端 API 概览

### 认证 (Auth)
- POST /api/v1/auth/captcha    # 获取图形验证码
- POST /api/v1/auth/send-code  # 发送邮件验证码
- POST /api/v1/auth/register   # 注册
- POST /api/v1/auth/login      # 登录

### 核心功能
- GET  /api/v1/health/daily    # 每日健康指标
- POST /api/v1/logs            # 记录运动/饮水/心情
- POST /api/v1/chat/completions # AI 健康助手对话
- GET  /api/v1/users/profile   # 用户资料管理

---

## 📄 许可证

MIT License

**最后更新**: 2026-03-05
