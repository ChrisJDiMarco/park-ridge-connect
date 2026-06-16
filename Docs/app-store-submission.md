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
- Privacy Policy URL:
  `https://chrisjdimarco.github.io/park-ridge-connect-catalog/privacy/`
- Support URL:
  `https://chrisjdimarco.github.io/park-ridge-connect-catalog/support/`

Use `Docs/app-store-metadata.md` as the App Store Connect copy sheet.

## Required Backend Setting

The app can run without API keys, but the App Store build should point at the
public Park Ridge place catalog so restaurants and businesses stay current.
Do not scrape Google Maps pages for this catalog. The checked-in backend uses
OpenStreetMap/Overpass, a free community-maintained source, and preserves
OpenStreetMap attribution on every generated place.

Use a public HTTPS URL that loads without authentication:

```text
TOWN_PLACE_CATALOG_URL=https://chrisjdimarco.github.io/park-ridge-connect-catalog/place-directory/park-ridge-places.json
```

Current production URL checked on 2026-06-16: the public catalog URL returns
HTTP 200 and 54 places. It is hosted from the public
`ChrisJDiMarco/park-ridge-connect-catalog` repository so the app source can
remain private while App Review can load the JSON without authentication.

Archive command once the final public URL is live:

```sh
xcodebuild archive \
  -project ParkRidgeConnect.xcodeproj \
  -scheme ParkRidgeConnect \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/ParkRidgeConnect.xcarchive
```

The Xcode target now sets `TOWN_PLACE_CATALOG_URL` to the production URL for
Debug and Release builds. Before submitting, open that URL in a
private/incognito browser and confirm it returns JSON.

## Current Verification

Checked on 2026-06-16:

- Production catalog URL is live:
  `https://chrisjdimarco.github.io/park-ridge-connect-catalog/place-directory/park-ridge-places.json`
  returns HTTP 200 and 54 places.
- Privacy policy and support URLs are live and return HTTP 200.
- `Docs/place-directory/park-ridge-places.json` is valid JSON and contains 54
  decoded Park Ridge places across food, services, schools, library, kids,
  recreation, and adult categories.
- `Tools/place-directory/build_catalog.py` compiles and keeps the last-good
  catalog when live Overpass endpoints are unavailable.
- `xcodebuild test` passed 30 tests on the iPhone 17 simulator, including the
  checked-in catalog decode test and manual place-directory refresh coverage.
- Release simulator build succeeded with store validation enabled.
- iOS archive succeeded for bundle `com.chrisdimarco.ParkRidgeConnect`, version
  `1.0`, build `1`, minimum iOS `17.0`, and includes the production
  `TOWN_PLACE_CATALOG_URL` in its generated Info.plist.
- App Store Connect export succeeded with Xcode-managed provisioning enabled,
  produced `DerivedData/AppStoreExport/ParkRidgeConnect.ipa`, and the exported
  IPA is signed with Apple Distribution.
- App Store Connect upload was attempted with Xcode-managed provisioning, but
  App Store Connect returned no app record for bundle ID
  `com.chrisdimarco.ParkRidgeConnect`. Create the app record first, then rerun
  the upload command below.
- iPhone 17 Pro Max screenshots were captured at 1320 x 2868 pixels for Today,
  Explore, Ask, and Services.

The local keychain currently shows only
`Apple Development: Chris DiMarco (R5FQ2HG7F5)`, but Xcode-managed App Store
export can still create an Apple Distribution-signed IPA. With automatic
signing, the raw `.xcarchive` may be development-signed; the final submission
gate is that the App Store Connect export succeeds and the exported IPA is
signed with Apple Distribution.

Run the local gate before submission:

```sh
Tools/app-store/verify_submission_readiness.sh
```

The script checks local catalog JSON, the live catalog/privacy/support URLs,
App Store screenshots, simulator tests, archive Info.plist values, and App
Store Connect IPA export/signing. On this machine, use
`ALLOW_PROVISIONING_UPDATES=1` so Xcode can create or download managed signing
assets during export:

```sh
ALLOW_PROVISIONING_UPDATES=1 Tools/app-store/verify_submission_readiness.sh
```

Export an uploadable IPA with:

```sh
Tools/app-store/export_app_store_ipa.sh
```

If Xcode has your Apple Developer account configured but needs to create or
download managed signing assets, opt in to portal access:

```sh
ALLOW_PROVISIONING_UPDATES=1 Tools/app-store/export_app_store_ipa.sh
```

After the App Store Connect app record exists, upload the build with:

```sh
ALLOW_PROVISIONING_UPDATES=1 Tools/app-store/upload_app_store_build.sh
```

If you have an App Store Connect API key, verify that the app record exists
before uploading:

```sh
Tools/app-store/check_app_store_connect_record.py \
  --key-id YOUR_KEY_ID \
  --issuer-id YOUR_ISSUER_ID \
  --private-key-path /path/to/AuthKey_YOUR_KEY_ID.p8
```

The current Apple OpenAPI spec exposes `GET /v1/apps` with `filter[bundleId]`
for lookup, but no `POST /v1/apps` create operation. Create the initial app
record in App Store Connect, then use this checker and the upload command.

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

Privacy policy URL to enter in App Store Connect:
`https://chrisjdimarco.github.io/park-ridge-connect-catalog/privacy/`

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

The app supports a screenshot-only launch argument for selecting the initial
tab:

```sh
xcrun simctl launch booted com.chrisdimarco.ParkRidgeConnect --args -screenshotTab explore
```

Valid tab values: `today`, `explore`, `ask`, `services`.

Current local capture set:

```text
outputs/app-store-screenshots/park-ridge-connect-today-iphone-17-pro-max.png
outputs/app-store-screenshots/park-ridge-connect-explore-iphone-17-pro-max.png
outputs/app-store-screenshots/park-ridge-connect-ask-iphone-17-pro-max.png
outputs/app-store-screenshots/park-ridge-connect-services-iphone-17-pro-max.png
```

Official screenshot upload guidance:
https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/

## Pre-Submit Checklist

- [x] Public catalog URL loads without authentication.
- [x] `TOWN_PLACE_CATALOG_URL` is set for the archive submitted to App Store Connect.
- [x] Public privacy policy URL exists.
- [x] Public support URL exists.
- [x] App Store metadata draft is prepared in `Docs/app-store-metadata.md`.
- [x] 6.9-inch iPhone screenshot assets are captured locally.
- [x] App Store distribution signing/export succeeds and produces an IPA.
- [ ] App Store Connect app record exists for `com.chrisdimarco.ParkRidgeConnect`.
- [ ] Build is uploaded to App Store Connect.
- [ ] App Privacy answers are published and match the exact build configuration.
- [ ] Privacy policy and support URLs are entered in App Store Connect.
- [ ] Screenshots are uploaded.
- [ ] Review notes include the data-source/cached-fallback explanation above.
