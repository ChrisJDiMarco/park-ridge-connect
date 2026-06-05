# Park Ridge Connect

Native SwiftUI iOS app for Park Ridge, NJ residents.

## What It Includes

- Resident dashboard with borough alerts, meetings, recreation events, and daily actions.
- Local directory for restaurants, kid activities, recreation, adult/night-out spots, library, schools, transit, utilities, emergency, and government.
- Civic Action Center with guided workflows for new residents, emergency readiness, family planning, water/yard rules, commuter parking, and permits.
- Park Ridge AI concierge with local retrieval over the seeded town knowledge base and live borough refresh data.
- Voice input and read-aloud using Apple Speech/AVFoundation.
- Optional ElevenLabs text-to-speech client. Add `ELEVENLABS_API_KEY` and `ELEVENLABS_VOICE_ID` to the target build settings or generated Info.plist to enable it.

## Build

```sh
xcodebuild -project ParkRidgeConnect.xcodeproj -scheme ParkRidgeConnect -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Run In Simulator

```sh
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/ParkRidgeConnect.app
xcrun simctl launch booted com.chrisdimarco.ParkRidgeConnect
```
