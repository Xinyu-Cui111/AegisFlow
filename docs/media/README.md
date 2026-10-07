# 媒体资源（截图 / 录屏）

高收藏仓库几乎都靠**首屏视觉**建立信任。请在 Mac 模拟器上补齐下列文件（提交到本目录）：

| 文件 | 内容建议 |
| --- | --- |
| `dashboard.png` | 仪表盘（含 HealthKit 或演示数据） |
| `chat-modes.png` | 助手页，能看出 CHAT / ORDER / PAGE 切换 |
| `page-generated.png` | PAGE 模式生成页 |
| `walkthrough.gif` 或 `.mp4` | 15–30 秒：打开 → 仪表盘 → 切模式 → 一条对话 |

### 截取步骤（简版）

1. Xcode Run → iPhone 15 / iOS 16+ Simulator  
2. `⌘S` 保存截图，或 `xcrun simctl io booted screenshot docs/media/dashboard.png`  
3. 录屏可用 QuickTime / `xcrun simctl io booted recordVideo`  
4. 控制单张 PNG < 800KB，GIF < 5MB，避免拖慢 GitHub 渲染  

补齐后把 README「界面预览」表的占位说明换成图片链接即可。
