#!/usr/bin/env bash
set -u -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

CATALOG_URL="${CATALOG_URL:-https://chrisjdimarco.github.io/park-ridge-connect-catalog/place-directory/park-ridge-places.json}"
PRIVACY_URL="${PRIVACY_URL:-https://chrisjdimarco.github.io/park-ridge-connect-catalog/privacy/}"
SUPPORT_URL="${SUPPORT_URL:-https://chrisjdimarco.github.io/park-ridge-connect-catalog/support/}"
SCREENSHOT_DIR="${SCREENSHOT_DIR:-/Users/chrisdimarco/Documents/Codex/2026-06-16/i-know-i-made-a-visual/outputs/app-store-screenshots}"
DERIVED_DATA="${DERIVED_DATA:-DerivedData}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$DERIVED_DATA/Archive/ParkRidgeConnect.xcarchive}"
SIMULATOR_DESTINATION="${SIMULATOR_DESTINATION:-platform=iOS Simulator,name=iPhone 17}"
MINIMUM_PLACE_COUNT="${MINIMUM_PLACE_COUNT:-50}"

failures=0

log() {
  printf '\n==> %s\n' "$1"
}

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "Missing required command: $1"
    return 1
  fi
  return 0
}

http_status() {
  curl -L -s -o /dev/null -w '%{http_code}' "$1"
}

check_local_catalog() {
  log "Checking local catalog files"
  python3 -m py_compile Tools/place-directory/build_catalog.py || fail "Catalog builder does not compile"
  python3 -m json.tool Docs/place-directory/park-ridge-places.json >/dev/null || fail "Checked-in catalog is invalid JSON"
  python3 -m json.tool Docs/place-directory/park-ridge-supplemental-places.json >/dev/null || fail "Supplemental catalog is invalid JSON"

  if jq -e --argjson minimum "$MINIMUM_PLACE_COUNT" '
    (.places | length) >= $minimum and
    (([.places[].category] | unique) as $categories |
      ["Food", "Services", "Schools", "Library", "Kids", "Recreation"] |
      all(. as $required | $categories | index($required)))
  ' Docs/place-directory/park-ridge-places.json >/dev/null; then
    pass "Checked-in catalog has enough places and required categories"
  else
    fail "Checked-in catalog is missing required place count or categories"
  fi
}

check_live_urls() {
  log "Checking public URLs"
  local status

  status="$(http_status "$PRIVACY_URL")"
  [[ "$status" == "200" ]] && pass "Privacy URL returns HTTP 200" || fail "Privacy URL returned HTTP $status"

  status="$(http_status "$SUPPORT_URL")"
  [[ "$status" == "200" ]] && pass "Support URL returns HTTP 200" || fail "Support URL returned HTTP $status"

  local live_catalog
  live_catalog="$(mktemp)"
  if curl -L -f -s "$CATALOG_URL" -o "$live_catalog"; then
    if jq -e --argjson minimum "$MINIMUM_PLACE_COUNT" '
      (.places | length) >= $minimum and
      (([.places[].category] | unique) as $categories |
        ["Food", "Services", "Schools", "Library", "Kids", "Recreation"] |
        all(. as $required | $categories | index($required)))
    ' "$live_catalog" >/dev/null; then
      pass "Live catalog has enough places and required categories"
    else
      fail "Live catalog is missing required place count or categories"
    fi
  else
    fail "Live catalog URL could not be fetched"
  fi
  rm -f "$live_catalog"
}

check_screenshots() {
  log "Checking App Store screenshots"
  local expected=(
    park-ridge-connect-today-iphone-17-pro-max.png
    park-ridge-connect-explore-iphone-17-pro-max.png
    park-ridge-connect-ask-iphone-17-pro-max.png
    park-ridge-connect-services-iphone-17-pro-max.png
  )

  if [[ ! -d "$SCREENSHOT_DIR" ]]; then
    fail "Screenshot directory not found: $SCREENSHOT_DIR"
    return
  fi

  local screenshot width height
  for screenshot in "${expected[@]}"; do
    local path="$SCREENSHOT_DIR/$screenshot"
    if [[ ! -f "$path" ]]; then
      fail "Missing screenshot: $path"
      continue
    fi

    width="$(sips -g pixelWidth "$path" 2>/dev/null | awk '/pixelWidth/ { print $2 }')"
    height="$(sips -g pixelHeight "$path" 2>/dev/null | awk '/pixelHeight/ { print $2 }')"
    if [[ "$width" == "1320" && "$height" == "2868" ]]; then
      pass "$screenshot is 1320 x 2868"
    else
      fail "$screenshot is ${width:-unknown} x ${height:-unknown}, expected 1320 x 2868"
    fi
  done
}

run_tests() {
  if [[ "${SKIP_XCODE_TESTS:-0}" == "1" ]]; then
    log "Skipping xcodebuild test"
    return
  fi

  log "Running simulator tests"
  if xcodebuild test \
    -project ParkRidgeConnect.xcodeproj \
    -scheme ParkRidgeConnect \
    -destination "$SIMULATOR_DESTINATION" \
    -derivedDataPath "$DERIVED_DATA"; then
    pass "xcodebuild test succeeded"
  else
    fail "xcodebuild test failed"
  fi
}

run_archive() {
  if [[ "${SKIP_XCODE_ARCHIVE:-0}" == "1" ]]; then
    log "Skipping xcodebuild archive"
    return
  fi

  log "Building iOS archive"
  if xcodebuild archive \
    -project ParkRidgeConnect.xcodeproj \
    -scheme ParkRidgeConnect \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    -derivedDataPath "$DERIVED_DATA"; then
    pass "xcodebuild archive succeeded"
  else
    fail "xcodebuild archive failed"
    return
  fi

  local app_path="$ARCHIVE_PATH/Products/Applications/ParkRidgeConnect.app"
  local plist="$app_path/Info.plist"

  local bundle_id version build minimum_os catalog_url
  bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist" 2>/dev/null || true)"
  version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist" 2>/dev/null || true)"
  build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist" 2>/dev/null || true)"
  minimum_os="$(/usr/libexec/PlistBuddy -c 'Print :MinimumOSVersion' "$plist" 2>/dev/null || true)"
  catalog_url="$(/usr/libexec/PlistBuddy -c 'Print :TOWN_PLACE_CATALOG_URL' "$plist" 2>/dev/null || true)"

  [[ "$bundle_id" == "com.chrisdimarco.ParkRidgeConnect" ]] && pass "Bundle ID is $bundle_id" || fail "Unexpected bundle ID: $bundle_id"
  [[ "$version" == "1.0" ]] && pass "Version is $version" || fail "Unexpected version: $version"
  [[ "$build" == "1" ]] && pass "Build number is $build" || fail "Unexpected build number: $build"
  [[ "$minimum_os" == "17.0" ]] && pass "Minimum iOS is $minimum_os" || fail "Unexpected minimum iOS: $minimum_os"
  [[ "$catalog_url" == "$CATALOG_URL" ]] && pass "Archive points at production catalog URL" || fail "Archive catalog URL mismatch: $catalog_url"

  local signature
  signature="$(codesign -dvv "$app_path" 2>&1 || true)"
  if grep -q 'Authority=Apple Distribution:' <<<"$signature"; then
    pass "Archive is signed with Apple Distribution"
  else
    fail "Archive is not signed with Apple Distribution"
    printf '%s\n' "$signature" | grep 'Authority=' || true
  fi
}

check_signing_identity() {
  log "Checking local code-signing identities"
  local identities
  identities="$(security find-identity -v -p codesigning 2>&1 || true)"
  printf '%s\n' "$identities"
  if grep -q 'Apple Distribution:' <<<"$identities"; then
    pass "Apple Distribution identity is installed"
  else
    fail "Apple Distribution identity is not installed"
  fi
}

require_command curl
require_command jq
require_command python3
require_command sips
require_command xcodebuild
require_command security
require_command codesign

check_local_catalog
check_live_urls
check_screenshots
run_tests
run_archive
check_signing_identity

if (( failures > 0 )); then
  printf '\nSubmission readiness failed with %d issue(s).\n' "$failures" >&2
  exit 1
fi

printf '\nSubmission readiness checks passed.\n'
