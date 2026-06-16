# App Store Metadata Draft

Last updated: 2026-06-16

Use this copy in App Store Connect for the first iOS submission.

## App Information

- Name: Park Ridge Connect
- Subtitle: Your Park Ridge town guide
- SKU: park-ridge-connect-ios
- Bundle ID: com.chrisdimarco.ParkRidgeConnect
- Primary category: Lifestyle
- Secondary category: Reference
- Price: Free
- Content rights: Yes, the app has the rights or permissions needed for the public data it displays. The place catalog is generated from OpenStreetMap with attribution, weather comes from the National Weather Service, and borough/service links point to public official sources.
- Age rating recommendation: 4+
- Made for Kids: No

## Version Information

- Version: 1.0
- Copyright: 2026 Chris DiMarco
- Privacy Policy URL: https://chrisjdimarco.github.io/park-ridge-connect-catalog/privacy/
- Support URL: https://chrisjdimarco.github.io/park-ridge-connect-catalog/support/
- Marketing URL: https://chrisjdimarco.github.io/park-ridge-connect-catalog/support/

## Promotional Text

A fast Park Ridge resident guide with weather, borough updates, local places, civic workflows, and a town-focused assistant.

## Description

Park Ridge Connect helps Park Ridge, NJ residents quickly understand what is happening around town and what to do next.

Open the Today dashboard for current weather, borough updates, nearby local places, and practical resident suggestions. Explore restaurants, public places, services, transit, schools, library resources, recreation, and civic workflows from one native iPhone app.

Ask the town assistant typed or spoken questions like where to take the kids, what to do in rainy weather, where to find commuter information, or which town service handles a specific resident task. Answers are grounded in bundled and live public Park Ridge information, with source labels so residents can follow up directly.

Features:
- Today dashboard with weather-aware suggestions.
- Local place directory for food, services, recreation, schools, transit, library, and government resources.
- Civic workflows for newcomers, permits, emergency readiness, family planning, water and yard rules, and commuter needs.
- Town-focused assistant with typed questions and optional voice input.
- Public data refreshes for borough information, weather, and OpenStreetMap-based places.
- Cached and bundled fallbacks when a public source is temporarily unavailable.

Park Ridge Connect does not require an account, does not include ads, and does not use analytics or tracking SDKs.

## Keywords

Park Ridge,NJ,borough,town,restaurants,weather,events,civic,commute,family

## What's New

Initial release.

## App Privacy Answers

- Tracking: No
- Data collected: No
- Third-party advertising: No
- Analytics SDKs: No

Rationale: the submitted no-key build has no accounts, ads, analytics SDKs, tracking, or user-data backend. The app fetches public borough, weather, and place-directory data. Voice input is optional and uses Apple platform speech services; typed questions work without microphone access.

## App Review Notes

Park Ridge Connect is a free resident guide for Park Ridge, NJ. No login or account is required.

The app opens to the Today dashboard and fetches public borough, weather, and place-directory data. The place catalog is generated from OpenStreetMap and hosted as JSON at the TOWN_PLACE_CATALOG_URL build setting. If a public data source is temporarily unavailable, the app falls back to cached or bundled public town data and labels that status in the header.

Microphone and speech recognition are optional; the Ask tab also works entirely with typed questions.

## Screenshot Set

Upload one to ten iPhone screenshots. Recommended first set:

- Today dashboard
- Explore directory/search
- Ask assistant
- Services/Civic workflows

Apple screenshot specs currently require PNG/JPG/JPEG and one to ten screenshots per device display size.

## Official References

- App information fields: https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/
- Platform version fields: https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/
- App privacy fields: https://developer.apple.com/help/app-store-connect/reference/app-information/app-privacy/
- Screenshot specifications: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
