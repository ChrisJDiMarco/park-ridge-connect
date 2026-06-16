#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

DERIVED_DATA="${DERIVED_DATA:-DerivedData}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$DERIVED_DATA/Archive/ParkRidgeConnect.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-$DERIVED_DATA/AppStoreExport}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-Tools/app-store/ExportOptions-AppStoreConnect.plist}"

provisioning_args=()
if [[ "${ALLOW_PROVISIONING_UPDATES:-0}" == "1" ]]; then
  provisioning_args=(-allowProvisioningUpdates)
fi

rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

xcodebuild archive \
  -project ParkRidgeConnect.xcodeproj \
  -scheme ParkRidgeConnect \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  -derivedDataPath "$DERIVED_DATA" \
  ${provisioning_args[@]+"${provisioning_args[@]}"}

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
  ${provisioning_args[@]+"${provisioning_args[@]}"}

printf '\nCreated App Store export in %s\n' "$EXPORT_PATH"
find "$EXPORT_PATH" -maxdepth 1 -name '*.ipa' -print
