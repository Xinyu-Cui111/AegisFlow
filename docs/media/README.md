# 媒体资源（真实 Simulator · 全界面）

## 云端截取（推荐）

[Actions → Simulator Screenshots](https://github.com/Xinyu-Cui111/AegisFlow/actions/workflows/simulator-screenshots.yml) → **Run workflow**

会产出：

| 目录 | 内容 |
| --- | --- |
| `gallery/01…16-*.png` | 全部主界面静帧 |
| `scroll/scroll-*.mp4/.gif` | 首页 / 计划 / 数据 / 个人中心自动滚动短片 |
| `walkthrough.mp4/.gif` | 多 Tab 串联录屏 |
| `dashboard.png` 等 | README 顶栏三张速览图 |

本地 Mac：

```bash
chmod +x Scripts/capture-simulator-ui.sh
Scripts/capture-simulator-ui.sh
```

## DEBUG 启动参数

| 参数 | 作用 |
| --- | --- |
| `-uiDemo` | 跳过真实登录，进入演示态 |
| `-uiDemoTab dashboard\|plan\|data\|chat\|profile` | 主 Tab |
| `-uiDemoRoute auth\|onboarding\|settings\|statistics\|…` | 子页 / 登录 / 引导 |
| `-uiDemoMode CHAT\|ORDER\|PAGE` | 助手模式 |
| `-uiDemoPage` | PAGE 生成页样例 |
| `-uiDemoScroll` | 页面自动上下滚动（供录屏） |
