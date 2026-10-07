# 媒体资源（真实 Simulator）

## 推荐：云端截取（无需本机 Mac）

仓库已配置 GitHub Actions：`.github/workflows/simulator-screenshots.yml`

1. 打开 https://github.com/Xinyu-Cui111/AegisFlow/actions  
2. 选择 **Simulator Screenshots** → **Run workflow**  
3. 跑完后会把 `dashboard.png` / `chat-modes.png` / `page-generated.png` / `walkthrough.mp4` 提交进 `docs/media/`  

本地也可：

```bash
# 需 macOS + Xcode
chmod +x Scripts/capture-simulator-ui.sh
Scripts/capture-simulator-ui.sh
```

DEBUG 启动参数（仅 Debug）：

| 参数 | 作用 |
| --- | --- |
| `-uiDemo` | 跳过登录/引导，直达主界面 |
| `-uiDemoTab dashboard\|chat\|…` | 指定 Tab |
| `-uiDemoMode CHAT\|ORDER\|PAGE` | 助手模式 |
| `-uiDemoPage` | 打开 PAGE 生成页样例 |

## 文件

| 文件 | 说明 |
| --- | --- |
| `dashboard.png` 等 | Simulator 截图（CI 产出后替换 HTML 预览） |
| `walkthrough.mp4` / `.gif` | 短录屏 |
| `simulator/` | CI 原始输出目录 |
| `preview.html` | 旧 HTML 预览（仅兜底，不算真实界面） |
