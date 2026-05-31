# AegisFlow API — 文档草稿

说明：本文件为根据前端代码反推的接口文档草稿，供前后端确认与联调使用。请以后端最终契约为准；我会根据后端反馈更新此文档。

基础信息
- 主接口 Base URL: `http://8.156.83.92:8080` （代码中默认 base 为 `http://8.156.83.92:8080/api/v1`，文档以 `/api/v1` 前缀为例）
- RAG / 知识库 Base URL: `http://8.156.83.92:8080`
- 全局响应包装：
  ```json
  {
    "success": true,
    "message": "可选消息",
    "data": { /* T */ },
    "errorCode": "可选错误码",
    "timestamp": "2026-..."
  }
  ```
- 鉴权：Bearer Token（HTTP Header: `Authorization: Bearer <access_token>`）
- 文档中的 `需要鉴权` 指需要在 Header 带 `Authorization`。

通用错误码与约定（建议配合后端确认）
- 401 / errorCode = `UNAUTHORIZED`：token 过期或未授权
- 400 / errorCode = `BAD_REQUEST`：参数错误
- 403 / errorCode = `FORBIDDEN`
- 500 / errorCode = `SERVER_ERROR`

重要接口（根据 `Services/APIClient.swift` 枚举与调用点整理）

## Auth（认证）
### POST /api/v1/auth/login
- 功能：用户登录
- 请求体（JSON）：
  ```json
  {"email": "user@example.com", "password": "xxx"}
  ```
- 返回 data 示例：
  ```json
  {
    "token": "<access_token>",
    "refreshToken": "<refresh_token>",
    "expiresIn": 3600,
    "user": {"id": "uuid", "email":"user@example.com", "name":"Name"}
  }
  ```
- 需要鉴权：否

### POST /api/v1/auth/register
- 功能：注册
- 请求体（JSON）：
  ```json
  {"email":"...","password":"...","name":"...","emailCode":"..."}
  ```
- 返回：注册后的登录凭证或提示（与后端对齐）
- 需要鉴权：否

### POST /api/v1/auth/refresh
- 功能：使用 refresh token 刷新 access token
- 请求体：
  ```json
  {"refreshToken":"..."}
  ```
- 返回 data：同 login（新的 accessToken + refreshToken + expiresIn）
- 需要鉴权：否

### POST /api/v1/auth/logout
- 功能：登出（撤销 refresh token）
- 请求体：
  ```json
  {"refreshToken":"..."}
  ```
- 需要鉴权：可选（建议需要）

## Users（用户）
### GET /api/v1/users/profile
- 功能：获取当前用户资料
- 需要鉴权：是
- 返回 data 示例：
  ```json
  {"id":"uuid","email":"...","name":"...","avatarUrl":"...","heightCm":180,"weightKg":70}
  ```

### PUT /api/v1/users/profile
- 功能：更新用户资料
- 请求体（JSON，字段可选）：
  ```json
  {"name":"...","heightCm":180,"weightKg":70}
  ```
- 需要鉴权：是

## Logs（健康记录）
### POST /api/v1/logs
- 功能：新增健康记录
- 需要鉴权：是
- 请求体示例（JSON）：
  ```json
  {"type":"meal","value":1, "tags":["breakfast"], "notes":"早餐鸡蛋"}
  ```
- 返回 data：新记录 id 或完整记录对象

### GET /api/v1/logs/history
- 功能：查询历史记录
- 支持参数：`type`、`startDate`、`endDate`、`limit`
- 需要鉴权：是
- 实测兼容说明：返回记录里的备注字段目前多为 `note`（单数），前端建议同时兼容 `note` 与 `notes`。

### DELETE /api/v1/logs/{id}
- 功能：删除记录
- 需要鉴权：是

## Chat（会话/消息）
> 重要：前端使用 `/api/v1/chat/completions` 发送消息并获取 AI 回复；历史接口为 `/api/v1/chat/history`。

### POST /api/v1/chat/completions
- 功能：发送消息并获取 AI/后端回复（支持 context/contextual info）
- 需要鉴权：视后端策略（建议需要）
- 请求体示例：
  ```json
  {"message":"我今天怎么吃","context": {"conversationId": "..."}}
  ```
- 返回 data：AI 回复的消息或完整对话段

### GET /api/v1/chat/history?limit=20&offset=0
- 功能：获取会话历史（分页）
- 需要鉴权：是
- 返回 data：会话数组，包含消息、时间、会话 id 等

## Notifications / Devices
### POST /api/v1/devices/register-fcm
- 功能：注册 FCM token（APNs token）
- 请求体：`{"token":"..."}`
- 需要鉴权：可选（推荐需要）

### POST /api/v1/notifications/action
- 功能：记录用户点击通知的行为（analytics）
- 请求体：`{"notificationId":"...","action":"..."}`
- 需要鉴权：建议需要

## Avatar / 头像 与 Twin 3D
### GET /api/v1/avatar
- 功能：获取头像 / 个性化信息
- 需要鉴权：是

### POST /api/v1/avatar/save
- 功能：保存 avatar 的配置（JSON）
- 需要鉴权：是

### 图片上传（分析 / twin / 食物识别）
- 接口：`/api/v1/analysis/food`（`isMultipart: true`） 和 `/api/v1/twin/generate-3d/photo`
- 方法：POST，Content-Type: multipart/form-data
- 字段示例：`file` (image)，`meta` (json string)
- 返回 data：分析结果或 job id
- 待确认：单文件最大尺寸（建议 5-10MB）、支持格式（jpg/png/heic）

## Analysis / Insights
- /api/v1/insights/* 系列接口支持智能推荐、习惯生成、多模态分析等
- 具体请求字段由前端传入的示例可以在 `AegisAPI` 枚举中看到（例如 `getMotivation(steps:stepsGoal:...)`）——请后端确认字段名与类型。

## Twin 3D / Avatar 任务
- 提交 3D 任务：`POST /api/v1/twin/generate-3d`（body: description 或 profile）
- 查询任务：`GET /api/v1/twin/query-3d?jobId=...` / `/wait`

## JD Demo（外部）
- 这些接口使用 `jdDemoBaseURL`（`http://8.156.83.92:8080`）或外部 URL，与主业务分离。

## RAG / 知识库服务（独立，base: http://8.156.83.92:8080）
- 暂无在前端显式枚举的具体路径（代码中 `APIConfig.ragBaseURL` 已配置）。建议后端提供 RAG 的路由清单，例如：
  - POST /rag/query  (请求：{"query":"...","top_k":5})
  - POST /rag/semantic-search
  - POST /rag/chat-completion
- 我会把这些作为占位，等待后端契约补充。


# 示例：登录流程与 token 存储
1. 客户端 POST /api/v1/auth/login -> 返回 `data.token` 和 `data.refreshToken` 与 `expiresIn`
2. 客户端把 `accessToken` 存入 `APIConfig.accessTokenKey`（UserDefaults 或更安全的 Keychain）
3. 请求带 `Authorization: Bearer <token>`。
4. 若 401，客户端调用 `POST /api/v1/auth/refresh` 用 `refreshToken` 换取新 token


# 测试与联调建议（接下来我会做）
1. 请求后端确认：
   - 上文每个接口的必选字段、可选字段、数据类型
   - 文件上传限制与返回 URL 格式
   - RAG 服务的具体路由
2. 提供一个测试账号或短期 token（建议 24 小时）给我，我会：
   - 登录并验证 token 刷新
   - 测试 `/chat/completions` 的读写
   - 测试 `/logs` 的新增/查询/删除
   - 测试图片上传分析和头像保存
3. 我会在 `docs/AEGIS_API_DRAFT.md` 基础上做迭代更新并提交差异清单


# 待确认项（需要后端回答）
- 文件上传：字段名、最大尺寸、允许格式、是否返回可直链 URL
- Chat 会话数据模型：message 对象字段（id、senderId、text、role、createdAt、metadata）
- createLog 字段类型和枚举（type 的枚举值列表）
- 是否所有写操作都需要鉴权
- RAG 路由及输入输出格式


----
如你同意，我会把这份草稿保存到仓库（已完成），下一步我可以：
- 使用注册接口代建测试账号（若你提供注册 URL 或允许我调用）
- 或等待你在测试环境手动创建账号并把凭证发我

我现在会更新 TODO 状态并等待你的选择.
