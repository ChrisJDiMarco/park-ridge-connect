# Park Ridge Connect PRD

## User Stories

As a resident, I want a daily town pulse so I can see alerts, meetings, events, and useful notices in one place.

As a parent, I want kid-friendly places and programs so I can decide where to go after school, on weekends, or during breaks.

As a commuter, I want transit and parking details so I can quickly find the train, buses, senior ride rules, and commuter lot information.

As a newcomer, I want a complete town directory so I can find restaurants, recreation, schools, library resources, emergency services, departments, forms, payments, and alerts.

As anyone in town, I want to ask an AI assistant in plain English so I can get a fast answer without knowing which department or website owns the information.

## Acceptance Criteria

- The app opens directly into a Park Ridge dashboard with current-feeling alerts, events, and actions.
- Every guide item shows category, practical note, trusted source, and an action such as Open, Call, or Map.
- Search filters the local guide and powers AI suggestions.
- The AI assistant answers from local data, includes suggested follow-ups, and supports voice dictation/read-aloud.
- The app builds and launches in an iOS simulator without external API keys.
- No secrets are hardcoded. ElevenLabs is optional and configured through Info.plist/build settings.

## Data Model

- TownEvent: title, date, time, category, sourceURL, summary, audience, priority.
- LocalPlace: name, category, subcategory, address, phone, websiteURL, mapQuery, highlights, tags, sourceName.
- CivicService: name, department, summary, phone, websiteURL, actionLabel, tags.
- TownAlert: title, severity, summary, effectiveDate, sourceURL.
- ChatMessage: role, text, timestamp, relatedSourceTitles.
- KnowledgeSource: title, kind, url, summary.

## Screen Inventory

- Home: dashboard, alerts, events, ask-AI launcher, fast action grid.
- Explore: searchable directory across food, kids, recreation, adults, library, schools, transit, government, utilities, and emergency.
- Assistant: chat and voice UI with suggested resident prompts.
- Services: government and resident service hub.
- Detail Sheet: map/call/open link actions for any place or service.

## Edge Cases

- Borough HTML refresh fails: show seeded data and clear "seeded local cache" context.
- Speech authorization denied: keep text chat available and explain microphone permission.
- ElevenLabs key absent or API fails: fall back to Apple voice.
- Long AI responses: keep them scannable and source-aware.
- No search results: show suggested prompts and core borough links.

