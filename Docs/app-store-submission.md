# App Store Submission Runbook

Last updated: 2026-06-16

## Build Identity

- App name: Park Ridge Connect
- Bundle ID: `com.chrisdimarco.ParkRidgeConnect`
- Version: `1.0`
- Build: `1`
- Category: Lifestyle
- Minimum iOS: 17.0
- Devices: iPhone

## Required Backend Setting

The app can run without API keys, but the App Store build should point at the
public Park Ridge place catalog so restaurants and businesses stay current.
Do not scrape Google Maps pages for this catalog. The checked-in backend uses
OpenStreetMap/Overpass, a free community-maintained source, and preserves
OpenStreetMap attribution on every generated place.

Use a public HTTPS URL that loads without authentication:

```text
TOWN_PLACE_CATALOG_URL=https://chrisjdimarco.github.io/park-ridge-connect/place-directory/park-ridge-places.json
```

Current remote status checked on 2026-06-16: GitHub Pages is not enabled for
`ChrisJDiMarco/park-ridge-connect` yet (`GET /repos/.../pages` returned 404).
The repo now includes a Pages deployment workflow that publishes only
`Docs/place-directory` files into a public artifact, but the final public URL
still needs to be enabled or hosted elsewhere.

Archive command once the final public URL is live:

```sh
xcodebuild archive \
  -project ParkRidgeConnect.xcodeproj \
  -scheme ParkRidgeConnect \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/ParkRidgeConnect.xcarchive \
  TOWN_PLACE_CATALOG_URL='https://PUBLIC_HOST/place-directory/park-ridge-places.json'
```

Do not submit until that URL has been opened in a private/incognito browser and
returns JSON.

## Current Verification

Checked on 2026-06-16:

- `Docs/place-directory/park-ridge-places.json` is valid JSON and contains 35
  decoded Park Ridge places.
- `Tools/place-directory/build_catalog.py` compiles and keeps the last-good
  catalog when live Overpass endpoints are unavailable.
- `xcodebuild test` passed 29 tests on the iPhone 17 simulator, including the
  checked-in catalog decode test.
- Release simulator build succeeded with store validation enabled.
- iOS archive succeeded for bundle `com.chrisdimarco.ParkRidgeConnect`, version
  `1.0`, build `1`, minimum iOS `17.0`.

The current archive is not ready to upload because it signed with
`Apple Development: Chris DiMarco (R5FQ2HG7F5)` and no Apple Distribution
identity is installed locally. The verification archive also did not include
`TOWN_PLACE_CATALOG_URL`, because the public catalog URL is not live yet.

## App Privacy Answers

Recommended answer for the current no-key build:

- Tracking: No
- Data collected: No
- Third-party advertising or analytics SDKs: None

Rationale: the app has no accounts, ads, analytics SDKs, tracking, or user-data
backend. Weather and borough/place refreshes fetch public data. The assistant is
local retrieval over bundled/live public town data. Speech input is optional and
uses Apple platform speech APIs.

If `ELEVENLABS_API_KEY` is set for a release build, re-answer privacy before
submission because spoken/read-aloud prompts may send text to ElevenLabs.

Privacy policy URL is still required in App Store Connect for iOS apps.

Official privacy guidance:

- https://developer.apple.com/app-store/app-privacy-details/
- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/

## Review Notes

Use this in App Review notes:

```text
Park Ridge Connect is a free resident guide for Park Ridge, NJ. No login or account is required.

The app opens to the Today dashboard and fetches public borough, weather, and place-directory data. The place catalog is generated from OpenStreetMap and hosted as JSON at the TOWN_PLACE_CATALOG_URL build setting. If a public data source is temporarily unavailable, the app falls back to cached or bundled public town data and labels that status in the header.

Microphone and speech recognition are optional; the Ask tab also works entirely with typed questions.
```

## Screenshots

Apple requires screenshots/app previews to be uploaded in App Store Connect.
Capture at least the highest-resolution iPhone screenshots for:

- Today dashboard
- Explore directory/search
- Ask assistant
- Services/Civic workflows

Official screenshot upload guidance:
https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/

## Pre-Submit Checklist

- Public catalog URL loads without authentication.
- `TOWN_PLACE_CATALOG_URL` is set for the archive submitted to App Store Connect.
- App Store distribution signing/export succeeds, not just local development signing.
- App Privacy answers are published and match the exact build configuration.
- Privacy policy URL is present in App Store Connect.
- Screenshots are uploaded.
- Review notes include the data-source/cached-fallback explanation above.
