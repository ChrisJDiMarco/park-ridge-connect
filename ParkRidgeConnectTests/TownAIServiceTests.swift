import XCTest
@testable import ParkRidgeConnect

final class TownAIServiceTests: XCTestCase {
    private let juneThird2026 = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 6, day: 3, hour: 12))!
    private let juneSixteenth2026 = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 6, day: 16, hour: 12))!

    private var sampleWeather: TownWeatherSnapshot {
        TownWeatherSnapshot(
            temperature: 73,
            temperatureUnit: "F",
            shortForecast: "Sunny",
            precipitationChance: 1,
            windSpeed: "7 mph",
            windDirection: "N",
            generatedAt: juneThird2026,
            source: ParkRidgeSeedData.weather
        )
    }

    private var rainyWeather: TownWeatherSnapshot {
        TownWeatherSnapshot(
            temperature: 61,
            temperatureUnit: "F",
            shortForecast: "Rain Showers",
            precipitationChance: 78,
            windSpeed: "11 mph",
            windDirection: "NE",
            generatedAt: juneThird2026,
            source: ParkRidgeSeedData.weather
        )
    }

    func testFoodQuestionReturnsRestaurantSources() {
        let service = TownAIService()
        let response = service.answer(
            question: "Where should we get dinner and drinks?",
            places: ParkRidgeSeedData.places,
            services: ParkRidgeSeedData.services,
            events: ParkRidgeSeedData.events,
            alerts: ParkRidgeSeedData.alerts,
            notices: ParkRidgeSeedData.notices
        )

        XCTAssertTrue(response.text.contains("Park Ridge food"))
        XCTAssertFalse(response.sourceTitles.isEmpty)
    }

    func testTransitQuestionRoutesToTransportationServices() {
        let service = TownAIService()
        let response = service.answer(
            question: "How do I get the train and commuter parking?",
            places: ParkRidgeSeedData.places,
            services: ParkRidgeSeedData.services,
            events: ParkRidgeSeedData.events,
            alerts: ParkRidgeSeedData.alerts,
            notices: ParkRidgeSeedData.notices
        )

        XCTAssertTrue(response.text.localizedCaseInsensitiveContains("Transit") || response.text.localizedCaseInsensitiveContains("parking"))
        XCTAssertTrue(response.sourceTitles.contains("Park Ridge Public Transportation"))
    }

    func testPlacePlanFocusesOnSelectedPlace() {
        let service = TownAIService()
        let place = ParkRidgeSeedData.places[0]
        let response = service.placePlan(
            for: place,
            nearbyPlaces: ParkRidgeSeedData.places,
            events: ParkRidgeSeedData.events
        )

        XCTAssertTrue(response.text.contains(place.name))
        XCTAssertTrue(response.text.localizedCaseInsensitiveContains("best fit"))
        XCTAssertFalse(response.text.localizedCaseInsensitiveContains("Closest Park Ridge matches"))
        XCTAssertTrue(response.sourceTitles.contains(place.source.title))
    }

    func testParentBriefPromptReturnsFamilyPlan() {
        let service = TownAIService()
        let response = service.answer(
            question: "Give me a practical Park Ridge Parent brief for right now.",
            places: ParkRidgeSeedData.places,
            services: ParkRidgeSeedData.services,
            events: ParkRidgeSeedData.events,
            alerts: ParkRidgeSeedData.alerts,
            notices: ParkRidgeSeedData.notices
        )

        XCTAssertTrue(response.text.localizedCaseInsensitiveContains("Best family plan"))
        XCTAssertTrue(response.text.contains("Park Ridge Public Library"))
    }

    func testWeatherQuestionUsesCurrentSnapshot() {
        let service = TownAIService()
        let response = service.answer(
            question: "Is it good weather to take kids outside in Park Ridge?",
            places: ParkRidgeSeedData.places,
            services: ParkRidgeSeedData.services,
            events: ParkRidgeSeedData.events,
            alerts: ParkRidgeSeedData.alerts,
            notices: ParkRidgeSeedData.notices,
            weather: sampleWeather
        )

        XCTAssertTrue(response.text.contains("73°F"))
        XCTAssertTrue(response.text.localizedCaseInsensitiveContains("Sunny"))
        XCTAssertTrue(response.text.localizedCaseInsensitiveContains("Memorial Park"))
        XCTAssertTrue(response.sourceTitles.contains("National Weather Service"))
    }

    func testWeatherParserBuildsSnapshotFromHourlyForecast() throws {
        let json = """
        {
          "properties": {
            "generatedAt": "2026-06-03T14:54:09+00:00",
            "periods": [
              {
                "temperature": 73,
                "temperatureUnit": "F",
                "probabilityOfPrecipitation": { "value": 1 },
                "windSpeed": "7 mph",
                "windDirection": "N",
                "shortForecast": "Sunny"
              }
            ]
          }
        }
        """

        let snapshot = try ParkRidgeWeatherService.parseHourlyForecast(Data(json.utf8))

        XCTAssertEqual(snapshot.temperatureText, "73°F")
        XCTAssertEqual(snapshot.precipitationText, "Rain 1%")
        XCTAssertEqual(snapshot.windText, "N 7 mph")
        XCTAssertEqual(snapshot.shortForecast, "Sunny")
    }

    @MainActor
    func testWeatherRefreshStoresSnapshot() async {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = TownStore(defaults: defaults, weatherService: StubWeatherService(snapshot: sampleWeather))

        await store.refreshWeather()

        XCTAssertEqual(store.weatherSnapshot?.temperatureText, "73°F")
        XCTAssertEqual(store.weatherStatus, "NWS forecast updated")
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testLiveAlertsFilterPastDatedHomepageItems() {
        let service = BoroughRefreshService(referenceDate: juneThird2026)
        let alerts = service.extractAlerts(
            from: [
                "2026 Budget Public Hearing Livestream - 5/26/26 at 8PM",
                "Mandatory water restrictions effective April 1 through September 1"
            ],
            source: ParkRidgeSeedData.borough
        )

        XCTAssertFalse(alerts.contains { $0.title.contains("5/26/26") })
        XCTAssertTrue(alerts.contains { $0.title.localizedCaseInsensitiveContains("water restrictions") })
    }

    func testLiveCalendarFiltersPastDatedRows() {
        let service = BoroughRefreshService(referenceDate: juneThird2026)
        let events = service.extractCalendar(
            from: [
                "Borough Calendar",
                "26 May",
                "Budget Public Hearing Livestream",
                "Date 05.26.2026 8:00 PM",
                "09 Jun",
                "Mayor & Council Public Meeting",
                "Date 06.09.2026 8:00 PM"
            ],
            source: ParkRidgeSeedData.borough
        )

        XCTAssertFalse(events.contains { $0.title.contains("Budget") })
        XCTAssertTrue(events.contains { $0.title.contains("Mayor") })
    }

    @MainActor
    func testFeaturedEventsOnlyShowsUpcomingEventsFromToday() {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let referenceDate = juneSixteenth2026
        let store = TownStore(defaults: defaults, now: { referenceDate })

        let titles = store.featuredEvents.map(\.title)

        XCTAssertEqual(Array(titles.prefix(3)), [
            "Park Ridge Summer Camp",
            "Summer Concert - Rhyme or Reason",
            "Summer Concert - The Kootz"
        ])
        XCTAssertFalse(titles.contains("Town Picnic"))
        XCTAssertFalse(titles.contains("Mayor & Council Public Meeting"))
        XCTAssertTrue(store.featuredEvents.allSatisfy { $0.isUpcoming(relativeTo: referenceDate) })
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testMultiDayEventStaysUpcomingUntilItsEndDate() throws {
        let calendar = Calendar(identifier: .gregorian)
        let event = try XCTUnwrap(ParkRidgeSeedData.events.first { $0.id == "summer-camp-2026" })
        let range = try XCTUnwrap(event.dateRange(calendar: calendar))
        let start = calendar.dateComponents([.year, .month, .day], from: range.lowerBound)
        let end = calendar.dateComponents([.year, .month, .day], from: range.upperBound)
        let julyFifteenth = calendar.date(from: DateComponents(year: 2026, month: 7, day: 15, hour: 12))!

        XCTAssertEqual(start.year, 2026)
        XCTAssertEqual(start.month, 6)
        XCTAssertEqual(start.day, 29)
        XCTAssertEqual(end.year, 2026)
        XCTAssertEqual(end.month, 7)
        XCTAssertEqual(end.day, 31)
        XCTAssertTrue(event.isUpcoming(relativeTo: julyFifteenth, calendar: calendar))
    }

    func testTownPulseExcludesPastEventsFromSeedData() {
        let referenceDate = juneSixteenth2026
        let service = TownAIService(townName: "Park Ridge", now: { referenceDate })
        let response = service.answer(
            question: "What events are coming up this week?",
            places: ParkRidgeSeedData.places,
            services: ParkRidgeSeedData.services,
            events: ParkRidgeSeedData.events,
            alerts: ParkRidgeSeedData.alerts,
            notices: ParkRidgeSeedData.notices
        )

        XCTAssertTrue(response.text.contains("Park Ridge Summer Camp"))
        XCTAssertFalse(response.text.contains("Town Picnic"))
        XCTAssertFalse(response.text.contains("Jun 13"))
        XCTAssertFalse(response.text.contains("Mayor & Council Public Meeting"))
    }

    @MainActor
    func testAlertMergeSkipsSemanticDuplicates() {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = TownStore(defaults: defaults)
        let incoming = TownAlert(
            id: "live-water-copy",
            title: "The Park Ridge Water Dept. is implementing mandatory water restrictions Effective April 1st through Sept. 1st.",
            severity: .advisory,
            summary: "Live item detected on the official borough homepage.",
            effectiveText: "Latest borough item",
            source: ParkRidgeSeedData.borough
        )

        let merged = store.mergeAlerts(existing: [ParkRidgeSeedData.alerts[0]], incoming: [incoming])

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].id, ParkRidgeSeedData.alerts[0].id)
        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    func testResidentLensPersistsAcrossStoreInstances() {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = TownStore(defaults: defaults)
        store.selectLens(.homeowner)

        let reloadedStore = TownStore(defaults: defaults)
        XCTAssertEqual(reloadedStore.selectedLens, .homeowner)
        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    func testParentLensBriefPrioritizesFamilyResources() {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = TownStore(defaults: defaults)

        store.selectLens(.parent)
        let brief = store.residentBriefItems

        XCTAssertEqual(brief.first?.title, "Park Ridge Public Library")
        XCTAssertTrue(brief.contains { $0.title == "Park Ridge Summer Camp" })
        XCTAssertTrue(brief.allSatisfy { [.kids, .library, .recreation, .schools].contains($0.category) })
        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    func testCommuterLensBriefPrioritizesTransit() {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = TownStore(defaults: defaults)

        store.selectLens(.commuter)
        let brief = store.residentBriefItems

        XCTAssertEqual(brief.first?.title, "Commuter Parking and Transit")
        XCTAssertTrue(brief.prefix(2).allSatisfy { $0.category == .transit })
        XCTAssertTrue(brief.first?.source.title == "Park Ridge Public Transportation")
        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    func testParentSmartPlanUsesOutdoorPlaceWhenWeatherIsGood() {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = TownStore(defaults: defaults, weatherService: StubWeatherService(snapshot: sampleWeather))

        store.selectLens(.parent)
        store.weatherSnapshot = sampleWeather
        let plan = store.smartPlanItems

        XCTAssertEqual(plan.first?.title, "Memorial Park and Pavilion")
        XCTAssertTrue(plan.first?.summary.contains("73°F") == true)
        XCTAssertEqual(plan.first?.placeID, "memorial-park")
        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    func testParentSmartPlanUsesLibraryWhenWeatherIsWet() {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = TownStore(defaults: defaults, weatherService: StubWeatherService(snapshot: rainyWeather))

        store.selectLens(.parent)
        store.weatherSnapshot = rainyWeather
        let plan = store.smartPlanItems

        XCTAssertEqual(plan.first?.title, "Park Ridge Public Library")
        XCTAssertTrue(plan.first?.summary.localizedCaseInsensitiveContains("Rain 78%") == true)
        XCTAssertEqual(plan.first?.placeID, "library")
        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    func testCommuterSmartPlanPrioritizesTransitService() {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = TownStore(defaults: defaults, weatherService: StubWeatherService(snapshot: sampleWeather))

        store.selectLens(.commuter)
        store.weatherSnapshot = sampleWeather
        let plan = store.smartPlanItems

        XCTAssertEqual(plan.first?.title, "Commuter Parking and Transit")
        XCTAssertEqual(plan.first?.serviceID, "commuter")
        XCTAssertTrue(plan.first?.summary.localizedCaseInsensitiveContains("commute") == true)
        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    func testSmartPlanPromptIncludesSlotsAndSources() {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = TownStore(defaults: defaults, weatherService: StubWeatherService(snapshot: sampleWeather))

        store.selectLens(.parent)
        store.weatherSnapshot = sampleWeather
        let prompt = store.assistantPromptForSmartPlan()

        XCTAssertTrue(prompt.contains("Smart Town Plan"))
        XCTAssertTrue(prompt.contains("Do now"))
        XCTAssertTrue(prompt.contains("Memorial Park and Pavilion"))
        XCTAssertTrue(prompt.contains("National Weather Service"))
        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    func testSmartPlanPromptReturnsSlotBasedAnswer() {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = TownStore(defaults: defaults, weatherService: StubWeatherService(snapshot: sampleWeather))
        let service = TownAIService()

        store.selectLens(.today)
        store.weatherSnapshot = sampleWeather
        let response = service.answer(
            question: store.assistantPromptForSmartPlan(),
            places: ParkRidgeSeedData.places,
            services: ParkRidgeSeedData.services,
            events: ParkRidgeSeedData.events,
            alerts: ParkRidgeSeedData.alerts,
            notices: ParkRidgeSeedData.notices,
            weather: sampleWeather
        )

        XCTAssertTrue(response.text.contains("Smart Town Plan"))
        XCTAssertTrue(response.text.contains("Do now"))
        XCTAssertTrue(response.text.contains("Plan next"))
        XCTAssertTrue(response.text.contains("Memorial Park and Pavilion"))
        XCTAssertFalse(response.text.localizedCaseInsensitiveContains("Best local calls"))
        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    func testLensPromptUsesSelectedResidentLens() {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = TownStore(defaults: defaults)

        store.selectLens(.parent)
        let prompt = store.assistantPromptForSelectedLens()

        XCTAssertTrue(prompt.contains("Parent"))
        XCTAssertTrue(prompt.localizedCaseInsensitiveContains("Park Ridge"))
        XCTAssertTrue(prompt.localizedCaseInsensitiveContains("brief"))
        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    func testBriefItemPromptCarriesItemAndLensContext() {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = TownStore(defaults: defaults)

        store.selectLens(.parent)
        let summerCamp = store.residentBriefItems.first { $0.title == "Park Ridge Summer Camp" }!
        let prompt = store.assistantPrompt(for: summerCamp)

        XCTAssertTrue(prompt.contains("Park Ridge Summer Camp"))
        XCTAssertTrue(prompt.contains("Parent"))
        XCTAssertTrue(prompt.contains("Park Ridge Recreation"))
        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    func testQueuedAssistantPromptIsConsumedOnce() {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = TownStore(defaults: defaults)

        store.queueAssistantPrompt("Give me a Park Ridge plan")

        XCTAssertEqual(store.consumeQueuedAssistantPrompt(), "Give me a Park Ridge plan")
        XCTAssertNil(store.consumeQueuedAssistantPrompt())
        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    func testNewcomerLensPrioritizesNewResidentWorkflow() {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = TownStore(defaults: defaults)

        store.selectLens(.newcomer)
        let workflow = store.recommendedCivicWorkflows.first

        XCTAssertEqual(workflow?.id, "new-resident-setup")
        XCTAssertTrue(workflow?.steps.contains { $0.serviceID == "borough-hall" } == true)
        XCTAssertTrue(workflow?.steps.contains { $0.serviceID == "alerts" } == true)
        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    func testWorkflowPromptIncludesStepsAndSources() {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = TownStore(defaults: defaults)
        let workflow = ParkRidgeSeedData.civicWorkflows.first { $0.id == "permits-renovation" }!

        let prompt = store.assistantPrompt(for: workflow)

        XCTAssertTrue(prompt.contains("Civic Workflow"))
        XCTAssertTrue(prompt.contains("Permits"))
        XCTAssertTrue(prompt.contains("Resident Forms and Permits"))
        XCTAssertTrue(prompt.contains("Park Ridge Borough"))
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testCivicWorkflowQuestionReturnsGuidedActionPlan() {
        let service = TownAIService()
        let response = service.answer(
            question: "I just moved here. What should I set up first as a new resident?",
            places: ParkRidgeSeedData.places,
            services: ParkRidgeSeedData.services,
            events: ParkRidgeSeedData.events,
            alerts: ParkRidgeSeedData.alerts,
            notices: ParkRidgeSeedData.notices,
            workflows: ParkRidgeSeedData.civicWorkflows
        )

        XCTAssertTrue(response.text.contains("Civic Workflow"))
        XCTAssertTrue(response.text.contains("New Resident Setup"))
        XCTAssertTrue(response.text.contains("Borough Hall"))
        XCTAssertTrue(response.sourceTitles.contains("Park Ridge Borough"))
        XCTAssertFalse(response.text.localizedCaseInsensitiveContains("Closest Park Ridge matches"))
    }

    func testWorkflowPromptReturnsSameWorkflowSteps() {
        let workflow = ParkRidgeSeedData.civicWorkflows.first { $0.id == "emergency-ready" }!
        let service = TownAIService()
        let response = service.answer(
            question: """
            Turn this Civic Workflow into a concise Park Ridge action plan.
            Civic Workflow: \(workflow.title)
            \(workflow.steps.map { "- \($0.title): \($0.detail) Source: \($0.source.title)" }.joined(separator: "\n"))
            """,
            places: ParkRidgeSeedData.places,
            services: ParkRidgeSeedData.services,
            events: ParkRidgeSeedData.events,
            alerts: ParkRidgeSeedData.alerts,
            notices: ParkRidgeSeedData.notices,
            workflows: ParkRidgeSeedData.civicWorkflows
        )

        XCTAssertTrue(response.text.contains("Civic Workflow"))
        XCTAssertTrue(response.text.contains("Emergency Ready"))
        XCTAssertTrue(response.text.contains("Emergency Alert Signup"))
        XCTAssertTrue(response.sourceTitles.contains("Park Ridge Borough"))
    }

    @MainActor
    func testFavoritePlacesToggleAndPersist() {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let place = ParkRidgeSeedData.places[0]

        let store = TownStore(defaults: defaults)
        XCTAssertFalse(store.isFavorite(place))
        XCTAssertTrue(store.favoritePlaces.isEmpty)

        store.toggleFavorite(place)
        XCTAssertTrue(store.isFavorite(place))
        XCTAssertEqual(store.favoritePlaces.map(\.id), [place.id])

        let reloadedStore = TownStore(defaults: defaults)
        XCTAssertTrue(reloadedStore.isFavorite(place))
        XCTAssertEqual(reloadedStore.favoritePlaces.map(\.id), [place.id])

        reloadedStore.toggleFavorite(place)
        XCTAssertFalse(reloadedStore.isFavorite(place))
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testOpenStreetMapPlaceParserBuildsLocalPlace() throws {
        let json = """
        {
          "elements": [
            {
              "type": "node",
              "id": 12345,
              "tags": {
                "name": "Bean There Cafe",
                "amenity": "cafe",
                "cuisine": "coffee_shop",
                "addr:housenumber": "10",
                "addr:street": "Park Avenue",
                "addr:city": "Park Ridge",
                "addr:state": "NJ",
                "addr:postcode": "07656",
                "phone": "201-555-0100",
                "website": "beanthere.example"
              }
            }
          ]
        }
        """

        let places = try PlaceDirectoryRefreshService.parseOpenStreetMapPlaces(
            Data(json.utf8),
            source: KnowledgeSource(
                id: "openstreetmap",
                title: "OpenStreetMap",
                url: URL(string: "https://www.openstreetmap.org/copyright")!,
                summary: "Community-maintained place data."
            )
        )

        XCTAssertEqual(places.count, 1)
        XCTAssertEqual(places[0].id, "osm-node-12345")
        XCTAssertEqual(places[0].name, "Bean There Cafe")
        XCTAssertEqual(places[0].category, .food)
        XCTAssertEqual(places[0].address, "10 Park Avenue, Park Ridge, NJ, 07656")
        XCTAssertEqual(places[0].phone, "201-555-0100")
        XCTAssertEqual(places[0].website?.absoluteString, "https://beanthere.example")
        XCTAssertEqual(places[0].source.title, "OpenStreetMap")
    }

    func testCheckedInPlaceCatalogDecodesForApp() throws {
        let testsFolder = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let projectRoot = testsFolder.deletingLastPathComponent()
        let catalogURL = projectRoot
            .appendingPathComponent("Docs")
            .appendingPathComponent("place-directory")
            .appendingPathComponent("park-ridge-places.json")
        let data = try Data(contentsOf: catalogURL)
        let catalog = try JSONDecoder().decode(CheckedInPlaceCatalog.self, from: data)
        let neighboringTownNames = ["Montvale", "Westwood", "Hillsdale", "Woodcliff", "Emerson"]
        let categories = Set(catalog.places.map(\.category))

        XCTAssertGreaterThanOrEqual(catalog.places.count, 20)
        XCTAssertTrue(categories.isSuperset(of: [.food, .services, .schools, .library, .kids, .recreation]))
        XCTAssertTrue(catalog.places.allSatisfy { !$0.source.title.isEmpty })
        XCTAssertTrue(catalog.places.contains { $0.source.title == "OpenStreetMap" })
        XCTAssertTrue(catalog.places.contains { $0.source.title != "OpenStreetMap" })
        XCTAssertFalse(catalog.places.contains { place in
            neighboringTownNames.contains { place.name.localizedCaseInsensitiveContains($0) }
        })
    }

    @MainActor
    func testPlaceDirectoryRefreshMergesAndUpdatesSearchCache() async {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let livePlace = LocalPlace(
            id: "osm-node-987",
            name: "New Park Ridge Bakery",
            category: .food,
            subcategory: "Bakery",
            summary: "Fresh listing from OpenStreetMap.",
            address: "99 Park Avenue, Park Ridge, NJ 07656",
            phone: nil,
            website: URL(string: "https://bakery.example"),
            imageURL: nil,
            highlights: ["Bakery", "OpenStreetMap listing"],
            tags: ["food", "bakery"],
            source: KnowledgeSource(
                id: "openstreetmap",
                title: "OpenStreetMap",
                url: URL(string: "https://www.openstreetmap.org/copyright")!,
                summary: "Community-maintained place data."
            )
        )
        let store = TownStore(
            defaults: defaults,
            placeDirectoryService: StubPlaceDirectoryService(result: PlaceDirectoryRefreshResult(
                places: [livePlace],
                fetchedAt: juneThird2026,
                usedCachedData: false
            ))
        )

        await store.refreshPlaceDirectory(force: true)

        XCTAssertEqual(store.directoryStatus, "Live place directory updated")
        XCTAssertNotNil(store.place(withID: livePlace.id))
        XCTAssertTrue(store.filteredPlaces(searchText: "bakery", category: nil).contains { $0.id == livePlace.id })
        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    func testManualRefreshForcesPlaceDirectoryRefresh() async {
        let suiteName = "ParkRidgeConnectTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let placeDirectoryService = RecordingPlaceDirectoryService(result: PlaceDirectoryRefreshResult(
            places: ParkRidgeSeedData.places,
            fetchedAt: juneThird2026,
            usedCachedData: false
        ))
        let store = TownStore(
            defaults: defaults,
            refreshService: StubBoroughRefreshService(result: BoroughRefreshResult(
                notices: [],
                events: [],
                alerts: [],
                fetchedAt: juneThird2026
            )),
            weatherService: StubWeatherService(snapshot: sampleWeather),
            placeDirectoryService: placeDirectoryService
        )

        await store.refresh()
        await store.refresh(forcePlaceDirectory: true)

        let forceValues = await placeDirectoryService.recordedForceValues()
        XCTAssertEqual(forceValues, [false, true])
        defaults.removePersistentDomain(forName: suiteName)
    }
}

private struct CheckedInPlaceCatalog: Decodable {
    let places: [LocalPlace]
}

private struct StubWeatherService: WeatherFetching {
    let snapshot: TownWeatherSnapshot

    func refreshSnapshot() async throws -> TownWeatherSnapshot {
        snapshot
    }
}

private struct StubBoroughRefreshService: BoroughRefreshing {
    let result: BoroughRefreshResult

    func refresh() async throws -> BoroughRefreshResult {
        result
    }
}

private struct StubPlaceDirectoryService: PlaceDirectoryFetching {
    let result: PlaceDirectoryRefreshResult

    func refresh(force: Bool) async throws -> PlaceDirectoryRefreshResult {
        result
    }
}

private actor RecordingPlaceDirectoryService: PlaceDirectoryFetching {
    private let result: PlaceDirectoryRefreshResult
    private var forceValues: [Bool] = []

    init(result: PlaceDirectoryRefreshResult) {
        self.result = result
    }

    func refresh(force: Bool) async throws -> PlaceDirectoryRefreshResult {
        forceValues.append(force)
        return result
    }

    func recordedForceValues() -> [Bool] {
        forceValues
    }
}
