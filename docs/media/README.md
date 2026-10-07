# 媒体资源（真实 Simulator · 全界面）

分层（去冗余）：

| 层 | 目录 | 用途 |
| --- | --- | --- |
| L1 | `dashboard.png` / `chat-modes.png` / `page-generated.png` + `walkthrough.gif` | README 首屏 |
| L2 | `flows/` | 操作流动图（准入 / Tab / AI / 记录 / 我的） |
| L3 | `gallery/` | 全页静帧目录（一屏一图） |
| 附 | `scroll/` | 仅长页滚动短片 |

索引表见 [MANIFEST.md](MANIFEST.md)（CI 生成后回写）。

## 云端截取

[Actions → Simulator Screenshots](https://github.com/Xinyu-Cui111/AegisFlow/actions/workflows/simulator-screenshots.yml) → **Run workflow**

本地 Mac：

```bash
chmod +x Scripts/capture-simulator-ui.sh
Scripts/capture-simulator-ui.sh
```

## DEBUG 启动参数

| 参数 | 作用 |
| --- | --- |
| `-uiDemo` | 演示态（跳过真实登录） |
| `-uiDemoTab dashboard\|plan\|data\|chat\|profile` | 主 Tab |
| `-uiDemoRoute auth\|onboarding\|log\|settings\|…` | 子页 / 登录 / 引导 / 记录+ |
| `-uiDemoMode CHAT\|ORDER\|PAGE` | 助手模式 |
| `-uiDemoPage` | PAGE 生成页样例 |
| `-uiDemoScroll` | 长页自动滚动（供录屏） |

常用 `uiDemoRoute`：`auth` `onboarding` `log` `settings` `statistics` `notificationcenter` `level` `rewards` `premium` `healthgoals` `privacy` `help` `knowledge` `food` `twin3d` `editprofile` `device`
