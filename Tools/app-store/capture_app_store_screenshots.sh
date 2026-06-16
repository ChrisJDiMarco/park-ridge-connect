#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

DEVICE_NAME="${DEVICE_NAME:-iPhone 17 Pro Max}"
DEVICE_ID="${DEVICE_ID:-}"
DERIVED_DATA="${DERIVED_DATA:-DerivedData/AppStoreScreenshots}"
CONFIGURATION="${CONFIGURATION:-Debug}"
OUTPUT_DIR="${OUTPUT_DIR:-/Users/chrisdimarco/Documents/Codex/2026-06-16/i-know-i-made-a-visual/outputs/app-store-screenshots}"
BUNDLE_ID="${BUNDLE_ID:-com.chrisdimarco.ParkRidgeConnect}"
APP_PATH="${APP_PATH:-$DERIVED_DATA/Build/Products/Debug-iphonesimulator/ParkRidgeConnect.app}"
CAPTURE_DELAY_SECONDS="${CAPTURE_DELAY_SECONDS:-5}"

if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(
    DEVICE_NAME="$DEVICE_NAME" python3 - <<'PY'
import json
import os
import subprocess
import sys

device_name = os.environ["DEVICE_NAME"]
data = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"]))
for devices in data.get("devices", {}).values():
    for device in devices:
        if device.get("isAvailable") and device.get("name") == device_name:
            print(device["udid"])
            sys.exit(0)
sys.exit(1)
PY
  )" || {
    printf 'Could not find an available Simulator named "%s".\n' "$DEVICE_NAME" >&2
    exit 1
  }
fi

mkdir -p "$OUTPUT_DIR"

printf 'Building %s for %s (%s)\n' "$BUNDLE_ID" "$DEVICE_NAME" "$DEVICE_ID"
xcodebuild build \
  -project ParkRidgeConnect.xcodeproj \
  -scheme ParkRidgeConnect \
  -configuration "$CONFIGURATION" \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -derivedDataPath "$DERIVED_DATA"

xcrun simctl boot "$DEVICE_ID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$DEVICE_ID" -b
xcrun simctl install "$DEVICE_ID" "$APP_PATH"
open -a Simulator

tabs=(today explore ask services)
for tab in "${tabs[@]}"; do
  output="$OUTPUT_DIR/park-ridge-connect-$tab-iphone-17-pro-max.png"
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" --args -screenshotTab "$tab" >/dev/null
  sleep "$CAPTURE_DELAY_SECONDS"
  xcrun simctl io "$DEVICE_ID" screenshot "$output" >/dev/null

  width="$(sips -g pixelWidth "$output" 2>/dev/null | awk '/pixelWidth/ { print $2 }')"
  height="$(sips -g pixelHeight "$output" 2>/dev/null | awk '/pixelHeight/ { print $2 }')"
  if [[ "$width" != "1320" || "$height" != "2868" ]]; then
    printf 'Unexpected screenshot size for %s: %sx%s\n' "$output" "${width:-unknown}" "${height:-unknown}" >&2
    exit 1
  fi
  printf 'Captured %s (%sx%s)\n' "$output" "$width" "$height"
done

printf 'App Store screenshots ready in %s\n' "$OUTPUT_DIR"
