#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/DerivedData/AppStoreSubmissionPackage}"
SCREENSHOT_DIR="${SCREENSHOT_DIR:-/Users/chrisdimarco/Documents/Codex/2026-06-16/i-know-i-made-a-visual/outputs/app-store-screenshots}"
IPA_PATH="${IPA_PATH:-$ROOT_DIR/DerivedData/AppStoreExport/ParkRidgeConnect.ipa}"

expected_screenshots=(
  park-ridge-connect-today-iphone-17-pro-max.png
  park-ridge-connect-explore-iphone-17-pro-max.png
  park-ridge-connect-ask-iphone-17-pro-max.png
  park-ridge-connect-services-iphone-17-pro-max.png
)

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/screenshots" "$OUTPUT_DIR/build"

cp Docs/app-store-metadata.md "$OUTPUT_DIR/AppStoreMetadata.md"
cp Docs/app-store-submission.md "$OUTPUT_DIR/AppStoreSubmissionRunbook.md"

for screenshot in "${expected_screenshots[@]}"; do
  cp "$SCREENSHOT_DIR/$screenshot" "$OUTPUT_DIR/screenshots/$screenshot"
done

if [[ -f "$IPA_PATH" ]]; then
  cp "$IPA_PATH" "$OUTPUT_DIR/build/ParkRidgeConnect.ipa"
fi

cat > "$OUTPUT_DIR/README.md" <<'README'
# Park Ridge Connect App Store Package

Use `AppStoreMetadata.md` as the App Store Connect copy sheet.

Upload the screenshots in `screenshots/` for the 6.9-inch iPhone display size.

After the App Store Connect app record exists for
`com.chrisdimarco.ParkRidgeConnect`, upload the build from the repo with:

```sh
ALLOW_PROVISIONING_UPDATES=1 Tools/app-store/upload_app_store_build.sh
```

If the IPA is present in `build/`, it was produced by the local App Store export
workflow and is included here for inspection/handoff.
README

printf 'Prepared App Store submission package: %s\n' "$OUTPUT_DIR"
find "$OUTPUT_DIR" -maxdepth 2 -type f | sort
