# Contributing

感谢关注 AegisFlow。欢迎提 Issue、修文档、补截图或小功能 PR。

## 开发环境

- macOS + Xcode 15+
- 用 Xcode 打开 `AegisFlow.xcodeproj`
- 模拟器建议 iOS 16+

## 分支

- `main`：可编译的稳定线
- `feature/简述`：新功能
- `fix/简述`：缺陷修复
- `docs/简述`：文档与媒体

## 提交

小步提交，前缀建议：`feat` / `fix` / `docs` / `chore`。

```bash
git checkout -b feature/chat-suggestion-chips
git commit -m "feat(chat): add suggestion chips for CHAT mode"
```

## PR 请说明

1. 改了什么、为什么  
2. 如何验证（模拟器型号、步骤、截图）  
3. 是否影响 HealthKit 权限、登录态或 API 契约  

## 截图与录屏

按 [docs/media/README.md](docs/media/README.md) 投放，文件名保持约定，便于 README 引用。

## 行为约定

- 不提交密钥、证书、真实用户健康数据  
- 不编造评测数字或未实现的能力  
- AI 辅助生成的代码请自行跑通再提交  
