#!/usr/bin/env bash
# Build AegisFlow for iOS Simulator, launch with -uiDemo, capture real screenshots + short video.
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
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build | tail -n 60

APP_PATH="$(find "$DERIVED/Build/Products" -name "$APP_NAME" -type d | head -1)"
test -n "$APP_PATH"
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

capture() {
  local outfile="$1"; shift
  echo "==> Launch for $outfile: $*"
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 1
  xcrun simctl launch "$UDID" "$BUNDLE_ID" "$@"
  sleep 5
  xcrun simctl io "$UDID" screenshot "$OUT/$outfile"
  echo "saved $OUT/$outfile"
}

capture dashboard.png -uiDemo -uiDemoTab dashboard
capture chat-modes.png -uiDemo -uiDemoTab chat -uiDemoMode CHAT
capture page-generated.png -uiDemo -uiDemoTab chat -uiDemoPage

echo "==> Record short walkthrough video"
xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
sleep 1
xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$OUT/walkthrough.mp4" &
REC_PID=$!
sleep 1
xcrun simctl launch "$UDID" "$BUNDLE_ID" -uiDemo -uiDemoTab dashboard
sleep 3
xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
sleep 1
xcrun simctl launch "$UDID" "$BUNDLE_ID" -uiDemo -uiDemoTab chat -uiDemoMode CHAT
sleep 3
xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
sleep 1
xcrun simctl launch "$UDID" "$BUNDLE_ID" -uiDemo -uiDemoTab chat -uiDemoPage
sleep 3
kill -INT "$REC_PID" 2>/dev/null || true
wait "$REC_PID" 2>/dev/null || true
sleep 1

ls -la "$OUT"
echo "DONE"
