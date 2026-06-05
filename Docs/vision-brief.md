# Park Ridge Connect Vision Brief

App name: Park Ridge Connect

Problem: Park Ridge residents need one trusted, easy place to know what is happening, what to do, where to eat, how to handle town services, and who to contact.

Target user: A Park Ridge, NJ resident, parent, commuter, senior, newcomer, or local visitor trying to make a fast town decision without opening six websites.

Core loop: Ask or browse "what should I know/do right now?" then act through a trusted local link, phone number, map, saved plan, or voice assistant response.

Platform targets: Native iOS first.

MVP features:
1. Resident dashboard with borough alerts, upcoming events, and quick civic actions.
2. Local guide for food, kids, recreation, adults/night out, library, schools, government, transit, utilities, and emergency services.
3. AI town concierge that answers from Park Ridge-specific seeded knowledge and live borough refresh results.
4. Voice input/output with Apple Speech + AVSpeechSynthesizer by default and an ElevenLabs TTS client that activates only when an API key is configured.
5. Source-aware cards with official links, phone numbers, Apple Maps deep links, and resident notes.

V2 wishlist:
- Push notifications for borough alerts, trash/recycling, school closings, and recreation signups.
- User accounts with household profiles, kids' ages, favorite places, and alert preferences.
- Server-side ingestion of borough calendar/news, school calendar, library calendar, NJ Transit status, and restaurant hours.
- Real LLM backend with retrieval over official sources and moderation.
- ElevenLabs conversational voice agent with streaming speech and fallback voices.

Stack recommendation:
Native SwiftUI app with URLSession for live borough refresh, Speech/AVFoundation for voice, and a small local retrieval assistant. This keeps the simulator demo useful immediately without backend credentials, while leaving clear seams for a production AI backend and ElevenLabs voice.

Source baseline:
- Borough: https://parkridgeboro.com/
- Recreation: https://parkridgeboro.com/departments/recreation
- Library: https://parkridgelibrarynj.org/
- Schools: https://www.parkridgeschools.org/
- Transportation: https://parkridgeboro.com/resident/transportation
- ElevenLabs TTS docs: https://elevenlabs.io/docs/overview/capabilities/text-to-speech

