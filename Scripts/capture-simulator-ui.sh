#!/usr/bin/env bash
# Build AegisFlow for iOS Simulator — full gallery + product flows + long-page scrolls.
# Spec: 简历制作/AegisFlow-全界面可视化策划.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${OUT_DIR:-$ROOT/docs/media/simulator}"
DERIVED="${DERIVED_DATA:-$ROOT/build/DerivedData}"
BUNDLE_ID="com.test.iOS-profile"
SCHEME="AegisFlow"
PROJECT="$ROOT/AegisFlow.xcodeproj"
APP_NAME="AegisFlow.app"

mkdir -p "$OUT" "$OUT/flows" "$DERIVED"

echo "==> Prefer an available iPhone simulator"
UDID="$(xcrun simctl list devices available -j | python3 -c '
import json, sys
data = json.load(sys.stdin)
prefer = ("iPhone 16", "iPhone 15", "iPhone 14", "iPhone")
cands = []
for runtime, devices in data.get("devices", {}).items():
    if "iOS" not in runtime:
        continue
    for d in devices:
        if d.get("isAvailable") and str(d.get("name", "")).startswith("iPhone"):
            cands.append(d)
if not cands:
    raise SystemExit("No available iPhone simulator")
def rank(d):
    name = d["name"]
    for i, p in enumerate(prefer):
        if name.startswith(p):
            return i
    return 99
cands.sort(key=rank)
print(cands[0]["udid"])
')"
echo "Using simulator UDID=$UDID"

echo "==> Build (Simulator, no code sign)"
set -o pipefail
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath "$DERIVED" \
  SYMROOT="$DERIVED/Build/Products" \
  OBJROOT="$DERIVED/Build/Intermediates" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build | tee "$OUT/xcodebuild.log" | tail -n 40

APP_PATH="$(
  find "$DERIVED" /tmp/AegisFlow -name "$APP_NAME" -type d 2>/dev/null | head -1 || true
)"
if [[ -z "$APP_PATH" ]]; then
  echo "ERROR: AegisFlow.app not found" >&2
  exit 1
fi
echo "App: $APP_PATH"

echo "==> Boot simulator"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override \
  --time "9:41" \
  --batteryState charged --batteryLevel 100 \
  --cellularMode active --cellularBars 4 \
  --wifiMode active --wifiBars 3 \
  --dataNetwork wifi || true

xcrun simctl uninstall "$UDID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl install "$UDID" "$APP_PATH"

capture_still() {
  local outfile="$1"; shift
  local settle=5
  if [[ "$*" == *"-uiDemoRoute"* ]] || [[ "$*" == *"-uiDemoPage"* ]]; then
    settle=7
  fi
  if [[ "$*" == *"-uiDemoRoute log"* ]] || [[ "$*" == *"logpicker"* ]] || [[ "$*" == *"-uiDemoRoute record"* ]]; then
    settle=8
  fi
  echo "==> Still $outfile :: $* (settle ${settle}s)"
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 1
  xcrun simctl launch "$UDID" "$BUNDLE_ID" "$@"
  sleep "$settle"
  xcrun simctl io "$UDID" screenshot "$OUT/$outfile"
  echo "saved $OUT/$outfile"
}

capture_scroll_video() {
  local outfile="$1"; shift
  echo "==> Scroll video $outfile :: $*"
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 1
  xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$OUT/$outfile" &
  local REC_PID=$!
  sleep 1
  xcrun simctl launch "$UDID" "$BUNDLE_ID" "$@"
  sleep 7
  kill -INT "$REC_PID" 2>/dev/null || true
  wait "$REC_PID" 2>/dev/null || true
  sleep 1
  echo "saved $OUT/$outfile"
}

# Concatenate cold-start scenes into one mp4 (terminate + relaunch per beat).
capture_flow() {
  local outfile="$1"
  shift
  # remaining: "args|seconds" pairs as single strings
  echo "==> Flow $outfile (${#} beats)"
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 1
  xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$OUT/$outfile" &
  local REC_PID=$!
  sleep 1
  local beat
  for beat in "$@"; do
    local args="${beat%%|*}"
    local secs="${beat##*|}"
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
    sleep 0.5
    # shellcheck disable=SC2086
    xcrun simctl launch "$UDID" "$BUNDLE_ID" $args
    sleep "$secs"
  done
  kill -INT "$REC_PID" 2>/dev/null || true
  wait "$REC_PID" 2>/dev/null || true
  sleep 1
  echo "saved $OUT/$outfile"
}

echo "==> Gallery stills (full coverage, one frame per screen)"
# A 准入
capture_still 01-login.png -uiDemo -uiDemoRoute auth
capture_still 02-onboarding.png -uiDemo -uiDemoRoute onboarding
# B 五 Tab
capture_still 03-dashboard.png -uiDemo -uiDemoTab dashboard
capture_still 04-plan.png -uiDemo -uiDemoTab plan
capture_still 05-health-data.png -uiDemo -uiDemoTab data
capture_still 06-chat-chat.png -uiDemo -uiDemoTab chat -uiDemoMode CHAT
capture_still 07-chat-order.png -uiDemo -uiDemoTab chat -uiDemoMode ORDER
capture_still 08-chat-page-mode.png -uiDemo -uiDemoTab chat -uiDemoMode PAGE
capture_still 09-page-generated.png -uiDemo -uiDemoTab chat -uiDemoPage
capture_still 10-profile.png -uiDemo -uiDemoTab profile
# D 记录操作
capture_still 11-log-picker.png -uiDemo -uiDemoTab dashboard -uiDemoRoute log
# E 子页
capture_still 12-settings.png -uiDemo -uiDemoRoute settings
capture_still 13-statistics.png -uiDemo -uiDemoRoute statistics
capture_still 14-notifications.png -uiDemo -uiDemoRoute notificationcenter
capture_still 15-level.png -uiDemo -uiDemoRoute level
capture_still 16-rewards.png -uiDemo -uiDemoRoute rewards
capture_still 17-premium.png -uiDemo -uiDemoRoute premium
capture_still 18-health-goals.png -uiDemo -uiDemoRoute healthgoals
capture_still 19-privacy.png -uiDemo -uiDemoRoute privacy
capture_still 20-help.png -uiDemo -uiDemoRoute help
capture_still 21-knowledge.png -uiDemo -uiDemoRoute knowledge
capture_still 22-food-analysis.png -uiDemo -uiDemoRoute food
capture_still 23-twin3d.png -uiDemo -uiDemoRoute twin3d
capture_still 24-edit-profile.png -uiDemo -uiDemoRoute editprofile

# README hero aliases (no duplicate story — just names)
cp "$OUT/03-dashboard.png" "$OUT/dashboard.png"
cp "$OUT/06-chat-chat.png" "$OUT/chat-modes.png"
cp "$OUT/09-page-generated.png" "$OUT/page-generated.png"

echo "==> Product flows (operations, not redundant stills)"
capture_flow flows/01-enter.mp4 \
  "-uiDemo -uiDemoRoute auth|2.2" \
  "-uiDemo -uiDemoRoute onboarding|2.4" \
  "-uiDemo -uiDemoTab dashboard|2.8"

capture_flow flows/02-tabs.mp4 \
  "-uiDemo -uiDemoTab dashboard|2.2" \
  "-uiDemo -uiDemoTab plan|2.2" \
  "-uiDemo -uiDemoTab data|2.2" \
  "-uiDemo -uiDemoTab chat -uiDemoMode CHAT|2.2" \
  "-uiDemo -uiDemoTab profile|2.2"

capture_flow flows/03-ai-modes.mp4 \
  "-uiDemo -uiDemoTab chat -uiDemoMode CHAT|2.5" \
  "-uiDemo -uiDemoTab chat -uiDemoMode ORDER|2.5" \
  "-uiDemo -uiDemoTab chat -uiDemoMode PAGE|2.5" \
  "-uiDemo -uiDemoTab chat -uiDemoPage|3.0"

capture_flow flows/04-record.mp4 \
  "-uiDemo -uiDemoTab dashboard|2.2" \
  "-uiDemo -uiDemoTab dashboard -uiDemoRoute log|3.5" \
  "-uiDemo -uiDemoTab dashboard|2.0"

capture_flow flows/05-profile-stack.mp4 \
  "-uiDemo -uiDemoTab profile|2.2" \
  "-uiDemo -uiDemoRoute settings|2.4" \
  "-uiDemo -uiDemoRoute statistics|2.4" \
  "-uiDemo -uiDemoRoute healthgoals|2.4"

echo "==> Scroll (long pages only)"
capture_scroll_video scroll-dashboard.mp4 -uiDemo -uiDemoTab dashboard -uiDemoScroll
capture_scroll_video scroll-plan.mp4 -uiDemo -uiDemoTab plan -uiDemoScroll
capture_scroll_video scroll-health-data.mp4 -uiDemo -uiDemoTab data -uiDemoScroll
capture_scroll_video scroll-profile.mp4 -uiDemo -uiDemoTab profile -uiDemoScroll

# L1 overview = enter + tabs + ai (replaces old walkthrough soup)
capture_flow walkthrough.mp4 \
  "-uiDemo -uiDemoRoute auth|1.8" \
  "-uiDemo -uiDemoRoute onboarding|1.8" \
  "-uiDemo -uiDemoTab dashboard|2.0" \
  "-uiDemo -uiDemoTab plan|1.6" \
  "-uiDemo -uiDemoTab data|1.6" \
  "-uiDemo -uiDemoTab chat -uiDemoMode CHAT|1.8" \
  "-uiDemo -uiDemoTab chat -uiDemoMode ORDER|1.8" \
  "-uiDemo -uiDemoTab chat -uiDemoPage|2.2" \
  "-uiDemo -uiDemoTab profile|1.8"

# MANIFEST for promote step / docs
cat > "$OUT/MANIFEST.md" <<'EOF'
# AegisFlow Simulator media manifest

## Gallery (one still per screen)

| ID | File | Screen |
| --- | --- | --- |
| A1 | 01-login.png | 登录 |
| A2 | 02-onboarding.png | 引导 |
| B1 | 03-dashboard.png | 首页 |
| B2 | 04-plan.png | 计划 |
| B3 | 05-health-data.png | 数据 |
| C1 | 06-chat-chat.png | 助理 · CHAT |
| C2 | 07-chat-order.png | 助理 · ORDER |
| C3 | 08-chat-page-mode.png | 助理 · PAGE 对话 |
| C4 | 09-page-generated.png | PAGE 生成页 |
| B5 | 10-profile.png | 我的 |
| D1 | 11-log-picker.png | 首页 · 记录类型（+） |
| E1 | 12-settings.png | 设置 |
| E2 | 13-statistics.png | 统计 |
| E3 | 14-notifications.png | 通知中心 |
| E4 | 15-level.png | 等级 |
| E5 | 16-rewards.png | 奖励 |
| E6 | 17-premium.png | 会员 |
| E7 | 18-health-goals.png | 健康目标 |
| E8 | 19-privacy.png | 隐私 |
| E9 | 20-help.png | 帮助 |
| E10 | 21-knowledge.png | 知识图谱 |
| E11 | 22-food-analysis.png | 食物分析 |
| E12 | 23-twin3d.png | 数字分身 |
| E13 | 24-edit-profile.png | 编辑资料 |

## Flows (operations)

| File | Story |
| --- | --- |
| flows/01-enter.mp4 | 登录 → 引导 → 首页 |
| flows/02-tabs.mp4 | 五 Tab 一览 |
| flows/03-ai-modes.mp4 | CHAT → ORDER → PAGE → 生成页 |
| flows/04-record.mp4 | 首页 → 记录+ → 回首页 |
| flows/05-profile-stack.mp4 | 我的 → 设置 → 统计 → 健康目标 |

## Scroll (long pages only)

| File | Screen |
| --- | --- |
| scroll-dashboard.mp4 | 首页 |
| scroll-plan.mp4 | 计划 |
| scroll-health-data.mp4 | 数据 |
| scroll-profile.mp4 | 我的 |

## README hero aliases

`dashboard.png` ← 03 · `chat-modes.png` ← 06 · `page-generated.png` ← 09 · `walkthrough.*` ← 精剪总览
EOF

ls -la "$OUT" "$OUT/flows"
echo "DONE"
