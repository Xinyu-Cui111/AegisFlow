#!/usr/bin/env bash
# Build AegisFlow for iOS Simulator and capture ALL main screens + scroll videos.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${OUT_DIR:-$ROOT/docs/media/simulator}"
DERIVED="${DERIVED_DATA:-$ROOT/build/DerivedData}"
BUNDLE_ID="com.test.iOS-profile"
SCHEME="AegisFlow"
PROJECT="$ROOT/AegisFlow.xcodeproj"
APP_NAME="AegisFlow.app"

mkdir -p "$OUT" "$DERIVED"

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
  echo "==> Still $outfile :: $*"
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 1
  xcrun simctl launch "$UDID" "$BUNDLE_ID" "$@"
  sleep 5
  xcrun simctl io "$UDID" screenshot "$OUT/$outfile"
  echo "saved $OUT/$outfile"
}

# Record while app auto-scrolls (-uiDemoScroll ~6s motion)
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

echo "==> Stills: 5 tabs + auth/onboarding + chat modes + key routes"
capture_still 01-dashboard.png -uiDemo -uiDemoTab dashboard
capture_still 02-plan.png -uiDemo -uiDemoTab plan
capture_still 03-health-data.png -uiDemo -uiDemoTab data
capture_still 04-chat-chat.png -uiDemo -uiDemoTab chat -uiDemoMode CHAT
capture_still 05-chat-order.png -uiDemo -uiDemoTab chat -uiDemoMode ORDER
capture_still 06-chat-page-mode.png -uiDemo -uiDemoTab chat -uiDemoMode PAGE
capture_still 07-page-generated.png -uiDemo -uiDemoTab chat -uiDemoPage
capture_still 08-profile.png -uiDemo -uiDemoTab profile
capture_still 09-login.png -uiDemo -uiDemoRoute auth
capture_still 10-onboarding.png -uiDemo -uiDemoRoute onboarding
capture_still 11-settings.png -uiDemo -uiDemoRoute settings
capture_still 12-statistics.png -uiDemo -uiDemoRoute statistics
capture_still 13-notifications.png -uiDemo -uiDemoRoute notificationcenter
capture_still 14-level.png -uiDemo -uiDemoRoute level
capture_still 15-rewards.png -uiDemo -uiDemoRoute rewards
capture_still 16-premium.png -uiDemo -uiDemoRoute premium

# Back-compat names used by README gallery
cp "$OUT/01-dashboard.png" "$OUT/dashboard.png"
cp "$OUT/04-chat-chat.png" "$OUT/chat-modes.png"
cp "$OUT/07-page-generated.png" "$OUT/page-generated.png"

echo "==> Scroll / walkthrough videos"
capture_scroll_video scroll-dashboard.mp4 -uiDemo -uiDemoTab dashboard -uiDemoScroll
capture_scroll_video scroll-plan.mp4 -uiDemo -uiDemoTab plan -uiDemoScroll
capture_scroll_video scroll-health-data.mp4 -uiDemo -uiDemoTab data -uiDemoScroll
capture_scroll_video scroll-profile.mp4 -uiDemo -uiDemoTab profile -uiDemoScroll

# Full tour: tabs + page
xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
sleep 1
xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$OUT/walkthrough.mp4" &
REC_PID=$!
sleep 1
for args in \
  "-uiDemo -uiDemoTab dashboard -uiDemoScroll" \
  "-uiDemo -uiDemoTab plan" \
  "-uiDemo -uiDemoTab data" \
  "-uiDemo -uiDemoTab chat -uiDemoMode CHAT" \
  "-uiDemo -uiDemoTab chat -uiDemoPage" \
  "-uiDemo -uiDemoTab profile -uiDemoScroll"
do
  # shellcheck disable=SC2086
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 0.6
  # shellcheck disable=SC2086
  xcrun simctl launch "$UDID" "$BUNDLE_ID" $args
  sleep 4
done
kill -INT "$REC_PID" 2>/dev/null || true
wait "$REC_PID" 2>/dev/null || true
sleep 1

ls -la "$OUT"
echo "DONE"
