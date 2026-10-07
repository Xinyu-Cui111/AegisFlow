# 媒体资源（截图 / 录屏）

## 当前文件

| 文件 | 说明 |
| --- | --- |
| `banner.svg` | README 顶栏 |
| `dashboard.png` / `chat-modes.png` / `page-generated.png` | 设计 token 忠实预览（HTML → Playwright） |
| `walkthrough.gif` | 三屏轮播短动图 |
| `preview.html` | 预览源文件 |
| `app-icon.png` | 工程内 App Icon |

重新生成预览：

```bash
node Scripts/capture-media-preview.mjs
```

## 用 Mac Simulator 替换（可选，更高可信）

1. Xcode Run → iPhone 15 / iOS 16+ Simulator  
2. `xcrun simctl io booted screenshot docs/media/dashboard.png`  
3. 同理截取助手三模式与 PAGE 页  
4. 控制单张 PNG < 800KB；GIF 可用 `ffmpeg` 合成  

替换后 README 图床路径不用改。
