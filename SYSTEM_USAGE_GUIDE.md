# Tempo (Aegis Flow) 系统运行指南

## 🎯 项目概述
Tempo 是一款跨平台健康追踪应用，包含：
- **Web 前端**：React 18 + TypeScript + Vite（离线优先 PWA）
- **后端 API**：Node.js + Express（RESTful，支持 Mock 模式）
- **Android 原生**：Kotlin + Jetpack Compose（开发中）

## ⚡ 快速启动

### 前置要求
- Node.js 16+ 
- npm 或 yarn
- 现代浏览器（Chrome/Edge/Safari）

### 1. 启动后端服务

```powershell
# 进入后端目录
cd backend

# 安装依赖（首次运行）
npm install

# 启动服务（Mock 模式，无需数据库）
node server.js
```

**后端将在 http://localhost:8080 启动**

验证：访问 http://localhost:8080/health 应返回：
```json
{
  "success": true,
  "message": "Tempo Backend API is running",
  "version": "1.0.0"
}
```

### 2. 启动 Web 前端

**新建终端窗口**，运行：

```powershell
# 进入前端目录
cd starter-1769349670

# 安装依赖（首次运行）
npm install

# 启动开发服务器
npm run dev
```

**前端将在 http://localhost:5173 启动**

## 🔐 用户流程演示

### 完整操作步骤

1. **访问应用**  
   浏览器打开：http://localhost:5173

2. **隐私协议页面**  
   - 自动显示（2 秒后）
   - 点击 "Accept & Continue" 进入登录页

3. **注册/登录**  
   - **快速测试**：点击 "🧪 快速测试登录" 按钮
   - **手动注册**：
     - 切换到"注册"标签
     - 填写姓名、邮箱、密码（最少6位）
     - 点击"注册"
   - **手动登录**：
     - 使用已注册的邮箱密码登录

4. **仪表板（Dashboard）**  
   - 查看今日健康数据（步数、饮水、卡路里、睡眠）
   - 点击底部快速记录图标添加数据
   - 查看动态洞察卡片
   - 滚动查看营养概览、心率分布

5. **快速记录（Quick Log）**  
   - 点击底部工具栏图标（🍎 🥤 💊 😊 🏃）
   - 选择标签（多选）
   - 保存后自动更新仪表板

6. **统计页面（Statistics）**  
   - 底部导航切换到"统计"
   - 查看周数据柱状图
   - 点击日期查看详细指标卡片

7. **AI 聊天（Chat）**  
   - 底部导航切换到"聊天"
   - 发送健康相关问题
   - AI 返回建议（模拟响应）
   - 支持快速回复按钮

8. **个人资料（Profile）**  
   - 查看和编辑身高、体重
   - 自动计算 BMI
   - 查看健康目标进度

## 📡 API 端点测试

### 使用 PowerShell 测试

后端提供了完整的 REST API，可以独立测试：

```powershell
# 健康检查
Invoke-RestMethod -Uri "http://localhost:8080/health"

# 注册用户
$body = @{
    email = "test@example.com"
    password = "Test1234!"
    name = "测试用户"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/register" `
    -Method Post -ContentType "application/json" -Body $body

# 登录获取 Token
$loginBody = @{
    email = "test@example.com"
    password = "Test1234!"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" `
    -Method Post -ContentType "application/json" -Body $loginBody

$token = $response.data.token

# 获取今日健康数据
$headers = @{ Authorization = "Bearer $token" }
Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health/daily" `
    -Headers $headers

# 创建活动记录
$logBody = @{
    type = "water"
    tags = @("morning", "250ml")
    value = 250
    unit = "ml"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/api/v1/logs" `
    -Method Post -Headers $headers `
    -ContentType "application/json" -Body $logBody
```

## 🗄️ 数据存储

### 后端 Mock 模式
- 所有数据存储在**内存**中（Map 对象）
- 服务重启后数据丢失
- 适合开发和演示

### 前端 IndexedDB
- **离线优先**架构
- 数据自动缓存到浏览器 IndexedDB
- 支持离线操作，联网时自动同步
- 打开浏览器开发者工具 → Application → IndexedDB 查看数据

### 清除数据
```javascript
// 浏览器控制台执行
indexedDB.deleteDatabase('TempoHealthDB');
sessionStorage.clear();
localStorage.clear();
location.reload();
```

## 🎨 设计系统

### Aegis 配色方案
- **Primary Green**: `#A5D23D` (sage-bright)
- **Deep Teal**: `#306E6F` (teal-deep)
- **Cream Background**: `#ECECEC`
- **Yellow Accent**: `#EBE038` (yellow-bright)
- **Blue**: `#6ED4DF`
- **Orange**: `#FFA83F`

### 字体
- **标题**：Plus Jakarta Sans ExtraBold (800)
- **正文**：Manrope Regular/Medium
- **数据**：JetBrains Mono

### 动画
- 入场动画：`fade-in` + `slide-up`
- 交互反馈：`active:scale-95`
- 延迟分层：`animation-delay: 100ms/200ms/300ms`

## 🐛 常见问题

### 后端启动失败
- **端口占用**：修改 `backend/.env` 中的 `PORT=8080`
- **依赖错误**：删除 `node_modules` 重新 `npm install`

### 前端编译错误
- **Vite 未找到**：确保在 `starter-1769349670` 目录运行
- **类型错误**：检查 TypeScript 版本，运行 `npm install`

### 登录失败
- **Token 过期**：清除浏览器缓存，重新登录
- **后端未启动**：确保 http://localhost:8080 可访问

### 数据不显示
1. 打开浏览器开发者工具（F12）
2. 查看 Console 是否有错误
3. 检查 Network 标签，确认 API 请求成功
4. 验证后端日志输出

## 📱 Android 版本（开发中）

Android 原生代码位于 `frontend/` 目录：

```bash
# 使用 Android Studio 打开
frontend/

# 同步 Gradle
./gradlew clean build
```

**注意**：Android 版本当前仅有框架代码，UI 组件需参考 Web 版本实现。

## 🚀 生产部署

### 前端构建
```bash
cd starter-1769349670
npm run build
# 输出到 dist/ 目录
```

### 后端配置
1. 修改 `.env` 文件：
   ```env
   NODE_ENV=production
   USE_MOCK_DATA=false
   SUPABASE_URL=your_project_url
   SUPABASE_ANON_KEY=your_anon_key
   ```

2. 部署到云平台（Vercel/Railway/Heroku）

## 📊 监控与日志

### 查看后端日志
```bash
# 实时日志
tail -f backend/logs/tempo-backend.log

# 筛选错误
grep "ERROR" backend/logs/tempo-backend.log
```

### 前端性能监控
- 打开 Chrome DevTools → Lighthouse
- 运行性能审计
- 目标：Performance Score > 90

## 🔗 相关文档

- [PRD 产品需求文档](docs/PRD.md)
- [API 接口文档](docs/API_Documentation.md)
- [后端设计规范](backend/DESIGN_SPEC.md)
- [前端设计规范](frontend/DESIGN_SPEC.md)
- [Android 实现计划](docs/Android_Implementation_Plan.md)

## 💡 开发技巧

### 热重载
- 前端：修改 `.tsx` 文件自动刷新
- 后端：使用 `nodemon` 监听文件变化（已配置）

### 调试技巧
```typescript
// 前端：查看 API 响应
import { HealthAPI } from './services/api';
HealthAPI.getDailyMetrics().then(console.log);

// 后端：添加日志
console.log('[DEBUG]', JSON.stringify(data, null, 2));
```

### 模拟数据
编辑 `backend/routes/*.js` 中的 Mock 数据生成逻辑。

---

**🎉 现在你已经可以完整运行 Tempo 系统了！**

如有问题，请查看：
- 后端终端输出（端口 8080）
- 前端终端输出（端口 5173）
- 浏览器开发者工具 Console
