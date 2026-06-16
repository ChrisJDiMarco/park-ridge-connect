import Foundation
import Observation

@MainActor
@Observable
final class TownStore {
    private static let favoritePlaceIDsKey = "favoritePlaceIDs"
    private static let selectedLensKey = "selectedLens"

    /// Active town configuration — the app is a generic engine over this.
    let config: TownConfig

    var alerts: [TownAlert]
    var notices: [TownNotice]
    var events: [TownEvent]
    var places: [LocalPlace]
    var services: [CivicService]
    var civicWorkflows: [CivicWorkflow]
    var messages: [ChatMessage]
    var isRefreshing = false
    var refreshStatus = "Seeded local guide"
    var lastRefresh: Date?
    var directoryStatus = "Seeded place directory"
    var lastDirectoryRefresh: Date?
    var requestedExploreCategory: TownCategory?
    var requestedExploreSearchText: String?
    var favoritePlaceIDs: Set<String>
    var selectedLens: ResidentLens
    var queuedAssistantPrompt: String?
    var weatherSnapshot: TownWeatherSnapshot?
    var isLoadingWeather = false
    var weatherStatus = "NWS forecast not loaded"

    var homeStatusText: String {
        if refreshStatus == directoryStatus {
            return refreshStatus
        }
        return "\(refreshStatus) - \(directoryStatus)"
    }

    private let defaults: UserDefaults
    private let refreshService: BoroughRefreshService
    private let placeDirectoryService: any PlaceDirectoryFetching
    private let aiService: TownAIService
    private let weatherService: any WeatherFetching

    // Lookup + search caches keep filtering/sorting off the per-frame hot path.
    // Place caches are rebuilt after live directory merges.
    @ObservationIgnored private var placesByID: [String: LocalPlace] = [:]
    @ObservationIgnored private var servicesByID: [String: CivicService] = [:]
    @ObservationIgnored private var placeSearchCache: [String: String] = [:]
    @ObservationIgnored private var serviceSearchCache: [String: String] = [:]
    @ObservationIgnored private var workflowSearchCache: [String: String] = [:]
    @ObservationIgnored private var workflowTokenCache: [String: Set<String>] = [:]

    init(
        pack: TownPack = TownPackLoader.load(),
        defaults: UserDefaults = .standard,
        weatherService: (any WeatherFetching)? = nil,
        placeDirectoryService: (any PlaceDirectoryFetching)? = nil
    ) {
        self.config = pack.config
        self.alerts = pack.alerts
        self.notices = pack.notices
        self.events = pack.events
        self.places = pack.places
        self.services = pack.services
        self.civicWorkflows = pack.civicWorkflows
        self.messages = [
            ChatMessage(
                role: .assistant,
                text: pack.config.assistantWelcome,
                relatedSourceTitles: pack.config.assistantWelcomeSourceTitles
            )
        ]
        self.defaults = defaults
        self.weatherService = weatherService ?? ParkRidgeWeatherService(config: pack.config.weather)
        self.refreshService = BoroughRefreshService(config: pack.config.refresh)
        self.placeDirectoryService = placeDirectoryService ?? PlaceDirectoryRefreshService(
            config: pack.config.placeDirectory ?? .parkRidgeDefault,
            defaults: defaults
        )
        self.aiService = TownAIService(townName: pack.config.townName)
        self.favoritePlaceIDs = Set(defaults.stringArray(forKey: Self.favoritePlaceIDsKey) ?? [])
        let lensRawValue = defaults.string(forKey: Self.selectedLensKey) ?? ResidentLens.today.rawValue
        self.selectedLens = ResidentLens(rawValue: lensRawValue) ?? .today
        rebuildLookupCaches()
    }

    // MARK: - Anchor lookups

    private func anchorPlace(_ keyPath: KeyPath<TownAnchors, String?>) -> LocalPlace? {
        config.anchors[keyPath: keyPath].flatMap { place(withID: $0) }
    }

    private func anchorService(_ keyPath: KeyPath<TownAnchors, String?>) -> CivicService? {
        config.anchors[keyPath: keyPath].flatMap { service(withID: $0) }
    }

    var featuredEvents: [TownEvent] {
        events.sorted { $0.priority > $1.priority }.prefix(6).map { $0 }
    }

    var topPlaces: [LocalPlace] {
        places.filter { [.food, .kids, .recreation, .adults, .library].contains($0.category) }.prefix(8).map { $0 }
    }

    var favoritePlaces: [LocalPlace] {
        places.filter { favoritePlaceIDs.contains($0.id) }
    }

    var residentBriefItems: [ResidentBriefItem] {
        briefItems(for: selectedLens)
    }

    var smartPlanItems: [TownPlanItem] {
        smartPlanItems(for: selectedLens)
    }

    var recommendedCivicWorkflows: [CivicWorkflow] {
        civicWorkflows(for: selectedLens)
    }

    func selectLens(_ lens: ResidentLens) {
        selectedLens = lens
        defaults.set(lens.rawValue, forKey: Self.selectedLensKey)
    }

    func assistantPromptForSelectedLens() -> String {
        """
        Give me a practical \(config.townName) \(selectedLens.rawValue) brief for right now. Use the current resident lens items, borough alerts, events, places, and services. Keep it concise, include what to do first, and mention trusted sources.
        """
    }

    func assistantPromptForSmartPlan() -> String {
        let planLines = smartPlanItems.map { item in
            "- \(item.slot): \(item.title) - \(item.summary) Source: \(item.source.title)"
        }.joined(separator: "\n")
        let weatherLine = weatherSnapshot.map { "Weather: \($0.summaryLine) Source: \($0.source.title)" } ?? "Weather: not loaded"

        return """
        Turn this Smart Town Plan into a concise \(config.townName) action plan for the \(selectedLens.rawValue) lens. Keep the same slots, explain why each step matters, and mention trusted sources.
        \(weatherLine)
        Smart Town Plan:
        \(planLines)
        """
    }

    func assistantPromptForWeather() -> String {
        guard let weatherSnapshot else {
            return "Use the \(config.townName) National Weather Service forecast if available and tell me what to do outside, with kids, errands, commuting, and evening plans."
        }

        return """
        Use this current \(config.townName) weather snapshot: \(weatherSnapshot.summaryLine) \(weatherSnapshot.outdoorAdvice) Give me the best town plan for the next few hours, including kids, errands, commute, and outdoor options.
        """
    }

    func assistantPrompt(for item: ResidentBriefItem) -> String {
        """
        Help me act on \(item.title) for the \(selectedLens.rawValue) lens in \(config.townName). Context: \(item.summary) Source: \(item.source.title). Give me the best next step, useful timing, and any nearby or related town resources.
        """
    }

    func assistantPrompt(for workflow: CivicWorkflow) -> String {
        let stepLines = workflow.steps.map { step in
            "- \(step.title): \(step.detail) Source: \(step.source.title)"
        }.joined(separator: "\n")

        return """
        Turn this Civic Workflow into a concise \(config.townName) action plan for the \(selectedLens.rawValue) lens. Keep the steps practical, say what to do first, and mention trusted sources.
        Civic Workflow: \(workflow.title)
        \(workflow.summary)
        Steps:
        \(stepLines)
        """
    }

    func queueAssistantPrompt(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        queuedAssistantPrompt = trimmed.isEmpty ? nil : trimmed
    }

    func consumeQueuedAssistantPrompt() -> String? {
        defer { queuedAssistantPrompt = nil }
        return queuedAssistantPrompt
    }

    func isFavorite(_ place: LocalPlace) -> Bool {
        favoritePlaceIDs.contains(place.id)
    }

    func toggleFavorite(_ place: LocalPlace) {
        if favoritePlaceIDs.contains(place.id) {
            favoritePlaceIDs.remove(place.id)
        } else {
            favoritePlaceIDs.insert(place.id)
        }
        persistFavoritePlaces()
    }

    func filteredPlaces(searchText: String, category: TownCategory?) -> [LocalPlace] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return places.filter { place in
            let matchesCategory: Bool
            if let category {
                matchesCategory = category == .food
                    ? [.food, .adults].contains(place.category)
                    : place.category == category
            } else {
                matchesCategory = true
            }
            guard matchesCategory else { return false }
            guard !query.isEmpty else { return true }
            return (placeSearchCache[place.id] ?? Self.searchableText(for: place)).contains(query)
        }
    }

    func filteredServices(searchText: String, category: TownCategory?) -> [CivicService] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return services.filter { service in
            guard category == nil || service.category == category else { return false }
            guard !query.isEmpty else { return true }
            return (serviceSearchCache[service.id] ?? Self.searchableText(for: service)).contains(query)
        }
    }

    func filteredCivicWorkflows(searchText: String, category: TownCategory?) -> [CivicWorkflow] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base = query.isEmpty ? recommendedCivicWorkflows : civicWorkflows

        return base.filter { workflow in
            let matchesCategory = category == nil || workflow.category == category
            guard !query.isEmpty else { return matchesCategory }
            return matchesCategory && (workflowSearchCache[workflow.id] ?? Self.searchableText(for: workflow)).contains(query)
        }
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let result = try await refreshService.refresh()
            notices = merge(existing: notices, incoming: result.notices)
            events = merge(existing: events, incoming: result.events)
            alerts = mergeAlerts(existing: alerts, incoming: result.alerts)
            lastRefresh = result.fetchedAt
            refreshStatus = "Live borough refresh complete"
        } catch {
            refreshStatus = "Using seeded guide; borough refresh unavailable"
        }

        await refreshPlaceDirectory()
        await refreshWeather()
    }

    func refreshPlaceDirectory(force: Bool = false) async {
        do {
            let result = try await placeDirectoryService.refresh(force: force)
            if !result.places.isEmpty {
                places = mergePlaces(existing: places, incoming: result.places)
                rebuildPlaceCaches()
            }
            lastDirectoryRefresh = result.fetchedAt
            directoryStatus = result.usedCachedData ? "Using cached place directory" : "Live place directory updated"
        } catch {
            directoryStatus = "Using seeded places; directory refresh unavailable"
        }
    }

    func refreshWeather() async {
        isLoadingWeather = true
        defer { isLoadingWeather = false }

        do {
            weatherSnapshot = try await weatherService.refreshSnapshot()
            weatherStatus = "NWS forecast updated"
        } catch {
            weatherStatus = "NWS forecast unavailable"
        }
    }

    func send(_ text: String) -> ChatMessage {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ChatMessage(role: .assistant, text: "Ask me what you want to do, find, attend, or handle in \(config.townName).")
        }

        messages.append(ChatMessage(role: .user, text: trimmed))
        let response = aiService.answer(
            question: trimmed,
            places: places,
            services: services,
            events: events,
            alerts: alerts,
            notices: notices,
            workflows: civicWorkflows,
            weather: weatherSnapshot
        )
        let message = ChatMessage(role: .assistant, text: response.text, relatedSourceTitles: response.sourceTitles)
        messages.append(message)
        return message
    }

    func previewAnswer(_ text: String) -> TownAIResponse {
        aiService.answer(
            question: text,
            places: places,
            services: services,
            events: events,
            alerts: alerts,
            notices: notices,
            workflows: civicWorkflows,
            weather: weatherSnapshot
        )
    }

    func placePlan(for place: LocalPlace) -> TownAIResponse {
        aiService.placePlan(for: place, nearbyPlaces: places, events: events)
    }

    func place(withID id: String) -> LocalPlace? {
        placesByID[id]
    }

    func service(withID id: String) -> CivicService? {
        servicesByID[id]
    }

    private static func searchableText(for place: LocalPlace) -> String {
        ([place.name, place.subcategory, place.summary, place.address ?? ""] + place.highlights + place.tags)
            .joined(separator: " ")
            .lowercased()
    }

    private static func searchableText(for service: CivicService) -> String {
        ([service.name, service.department, service.summary] + service.tags)
            .joined(separator: " ")
            .lowercased()
    }

    private static func searchableText(for workflow: CivicWorkflow) -> String {
        ([workflow.title, workflow.kicker, workflow.summary, workflow.category.rawValue] + workflow.tags + workflow.steps.flatMap { [$0.title, $0.detail, $0.source.title] })
            .joined(separator: " ")
            .lowercased()
    }

    private func rebuildLookupCaches() {
        rebuildPlaceCaches()
        servicesByID = Dictionary(uniqueKeysWithValues: services.map { ($0.id, $0) })
        serviceSearchCache = Dictionary(uniqueKeysWithValues: services.map { ($0.id, Self.searchableText(for: $0)) })
        workflowSearchCache = Dictionary(uniqueKeysWithValues: civicWorkflows.map { ($0.id, Self.searchableText(for: $0)) })
        workflowTokenCache = workflowSearchCache.mapValues { text in
            Set(text.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty })
        }
    }

    private func rebuildPlaceCaches() {
        placesByID = Dictionary(uniqueKeysWithValues: places.map { ($0.id, $0) })
        placeSearchCache = Dictionary(uniqueKeysWithValues: places.map { ($0.id, Self.searchableText(for: $0)) })
        favoritePlaceIDs = favoritePlaceIDs.filter { placesByID[$0] != nil }
    }

    private func persistFavoritePlaces() {
        defaults.set(favoritePlaceIDs.sorted(), forKey: Self.favoritePlaceIDsKey)
    }

    private func civicWorkflows(for lens: ResidentLens) -> [CivicWorkflow] {
        let lensTerms = workflowTerms(for: lens)
        // Score once per workflow, not once per sort comparison.
        let scored = civicWorkflows.map { (workflow: $0, score: workflowScore($0, lensTerms: lensTerms)) }
        return scored
            .sorted { lhs, rhs in
                lhs.score == rhs.score ? lhs.workflow.title < rhs.workflow.title : lhs.score > rhs.score
            }
            .map(\.workflow)
    }

    private func workflowScore(_ workflow: CivicWorkflow, lensTerms: Set<String>) -> Int {
        let tokens = workflowTokenCache[workflow.id] ?? []
        return workflow.priority + (tokens.intersection(lensTerms).count * 40)
    }

    private func workflowTerms(for lens: ResidentLens) -> Set<String> {
        switch lens {
        case .today:
            return ["today", "alerts", "weather", "emergency", "resident"]
        case .parent:
            return ["parent", "family", "kids", "school", "camp", "library"]
        case .commuter:
            return ["commuter", "commute", "train", "bus", "parking", "nyc"]
        case .homeowner:
            return ["homeowner", "water", "yard", "permits", "trash", "recycling", "dpw"]
        case .newcomer:
            return ["newcomer", "new", "resident", "moved", "setup", "schools", "library"]
        case .nightOut:
            return ["recreation", "alerts", "parking", "weather", "resident"]
        }
    }

    private func smartPlanItems(for lens: ResidentLens) -> [TownPlanItem] {
        // Compute the brief once and share it with all three slots; each slot
        // previously recomputed the full brief list for its fallback.
        let brief = briefItems(for: lens)
        return [
            smartPlanNowItem(for: lens, brief: brief),
            smartPlanNextItem(for: lens, brief: brief),
            smartPlanWatchItem(for: lens, brief: brief)
        ].compactMap { $0 }
    }

    private func smartPlanNowItem(for lens: ResidentLens, brief: [ResidentBriefItem]) -> TownPlanItem? {
        switch lens {
        case .parent:
            if shouldUseIndoorFallback,
               let library = anchorPlace(\.indoorFallbackPlaceID) {
                return placePlanItem(
                    library,
                    slot: "Do now",
                    summary: "Use the indoor fallback. \(weatherContext) Good for storytime, museum passes, digital resources, or a low-friction reset.",
                    actionLabel: "Open place"
                )
            }
            if let park = anchorPlace(\.outdoorParkPlaceID) {
                return placePlanItem(
                    park,
                    slot: "Do now",
                    summary: "\(weatherContext) Use the outdoor window for playground time, fields, or after-school energy.",
                    actionLabel: "Open place"
                )
            }
        case .commuter:
            if let commuter = anchorService(\.commuterServiceID) {
                return servicePlanItem(
                    commuter,
                    slot: "Do now",
                    summary: "\(weatherContext) Check train, bus, and commuter parking details before the commute window.",
                    actionLabel: "Transit info"
                )
            }
        case .homeowner:
            if let waterAlert = alerts.first(where: { $0.title.localizedCaseInsensitiveContains("water") }) {
                return alertPlanItem(
                    waterAlert,
                    slot: "Do now",
                    summary: "Water restrictions are active. \(weatherContext) Check this before irrigation, outdoor work, or contractor scheduling."
                )
            }
        case .newcomer:
            if let boroughHall = anchorService(\.townHallServiceID) {
                return servicePlanItem(
                    boroughHall,
                    slot: "Do now",
                    summary: "Start with the official borough path for forms, resident routing, parking, and general questions.",
                    actionLabel: boroughHall.actionLabel
                )
            }
        case .nightOut:
            if let fourLeaves = anchorPlace(\.nightOutPlaceID) {
                return placePlanItem(
                    fourLeaves,
                    slot: "Do now",
                    summary: "\(weatherContext) Anchor drinks, brunch, or a casual night-out plan downtown.",
                    actionLabel: "Open place"
                )
            }
        case .today:
            if shouldUseIndoorFallback,
               let library = anchorPlace(\.indoorFallbackPlaceID) {
                return placePlanItem(
                    library,
                    slot: "Do now",
                    summary: "Weather favors an indoor fallback. \(weatherContext) Use the library as the easiest community stop.",
                    actionLabel: "Open place"
                )
            }
            if let park = anchorPlace(\.outdoorParkPlaceID) {
                return placePlanItem(
                    park,
                    slot: "Do now",
                    summary: "\(weatherContext) Best immediate local move for outdoor time or a quick reset.",
                    actionLabel: "Open place"
                )
            }
        }

        return brief.first.map { planItem(from: $0, slot: "Do now") }
    }

    private func smartPlanNextItem(for lens: ResidentLens, brief: [ResidentBriefItem]) -> TownPlanItem? {
        let event: TownEvent?
        switch lens {
        case .parent:
            event = featuredEvents.first { [.kids, .recreation].contains($0.category) }
        case .commuter:
            event = featuredEvents.first { $0.category == .government }
        case .nightOut:
            event = featuredEvents.first { $0.category == .recreation }
        default:
            event = featuredEvents.first
        }

        if let event {
            return eventPlanItem(event, slot: "Plan next")
        }

        return brief.dropFirst().first.map { planItem(from: $0, slot: "Plan next") }
    }

    private func smartPlanWatchItem(for lens: ResidentLens, brief: [ResidentBriefItem]) -> TownPlanItem? {
        switch lens {
        case .parent:
            if let alerts = anchorService(\.alertsServiceID) {
                return servicePlanItem(alerts, slot: "Keep in mind", summary: "Make sure local notices can reach you before weather, school, or borough changes affect plans.", actionLabel: alerts.actionLabel)
            }
        case .commuter:
            if let boroughHall = anchorService(\.townHallServiceID) {
                return servicePlanItem(boroughHall, slot: "Keep in mind", summary: "Use Borough Hall for commuter parking decals, local routing, and resident follow-up.", actionLabel: boroughHall.actionLabel)
            }
        case .homeowner:
            if let trash = anchorService(\.trashServiceID) {
                return servicePlanItem(trash, slot: "Keep in mind", summary: "Keep trash, recycling, DPW, and water-service chores in one official path.", actionLabel: trash.actionLabel)
            }
        case .newcomer:
            if let library = anchorPlace(\.indoorFallbackPlaceID) {
                return placePlanItem(library, slot: "Keep in mind", summary: "Use the library as the community hub for cards, events, museum passes, and resident discovery.", actionLabel: "Open place")
            }
        case .nightOut:
            if let steakhouse = anchorPlace(\.dinnerPlaceID) {
                return placePlanItem(steakhouse, slot: "Keep in mind", summary: "Save a more polished dinner option when the night calls for steak, wine, or private dining.", actionLabel: "Open place")
            }
        case .today:
            if let alert = alerts.first {
                return alertPlanItem(alert, slot: "Keep in mind", summary: alert.summary)
            }
        }

        return brief.dropFirst(2).first.map { planItem(from: $0, slot: "Keep in mind") }
    }

    private var shouldUseIndoorFallback: Bool {
        guard let weatherSnapshot else { return false }
        return (weatherSnapshot.precipitationChance ?? 0) >= 40 ||
            weatherSnapshot.shortForecast.localizedCaseInsensitiveContains("rain") ||
            weatherSnapshot.shortForecast.localizedCaseInsensitiveContains("storm")
    }

    private var weatherContext: String {
        weatherSnapshot.map { "\($0.summaryLine) \($0.outdoorAdvice)" } ?? "Weather has not loaded yet."
    }

    private func planItem(from item: ResidentBriefItem, slot: String) -> TownPlanItem {
        TownPlanItem(
            id: "\(slot)-\(item.id)",
            slot: slot,
            title: item.title,
            summary: item.summary,
            category: item.category,
            source: item.source,
            actionLabel: item.actionLabel,
            placeID: item.placeID,
            serviceID: item.serviceID,
            eventID: item.eventID
        )
    }

    private func placePlanItem(_ place: LocalPlace, slot: String, summary: String, actionLabel: String) -> TownPlanItem {
        TownPlanItem(
            id: "\(slot)-place-\(place.id)",
            slot: slot,
            title: place.name,
            summary: summary,
            category: place.category,
            source: place.source,
            actionLabel: actionLabel,
            placeID: place.id,
            serviceID: nil,
            eventID: nil
        )
    }

    private func servicePlanItem(_ service: CivicService, slot: String, summary: String, actionLabel: String) -> TownPlanItem {
        TownPlanItem(
            id: "\(slot)-service-\(service.id)",
            slot: slot,
            title: service.name,
            summary: summary,
            category: service.category,
            source: service.source,
            actionLabel: actionLabel,
            placeID: nil,
            serviceID: service.id,
            eventID: nil
        )
    }

    private func eventPlanItem(_ event: TownEvent, slot: String) -> TownPlanItem {
        TownPlanItem(
            id: "\(slot)-event-\(event.id)",
            slot: slot,
            title: event.title,
            summary: "\(event.dateText)\(event.timeText.isEmpty ? "" : " at \(event.timeText)") - \(event.summary)",
            category: event.category,
            source: event.source,
            actionLabel: "Ask AI",
            placeID: nil,
            serviceID: nil,
            eventID: event.id
        )
    }

    private func alertPlanItem(_ alert: TownAlert, slot: String, summary: String) -> TownPlanItem {
        TownPlanItem(
            id: "\(slot)-alert-\(alert.id)",
            slot: slot,
            title: alert.title,
            summary: summary,
            category: .government,
            source: alert.source,
            actionLabel: "Ask AI",
            placeID: nil,
            serviceID: nil,
            eventID: nil
        )
    }

    private func briefItems(for lens: ResidentLens) -> [ResidentBriefItem] {
        switch lens {
        case .today:
            return [
                alerts.first.map(alertBrief),
                featuredEvents.first.map { eventBrief($0, kicker: "Highest-signal event") },
                anchorService(\.alertsServiceID).map { serviceBrief($0, kicker: "Stay reachable") }
            ].compactMap { $0 }
        case .parent:
            return [
                anchorPlace(\.indoorFallbackPlaceID).map { placeBrief($0, kicker: "Indoor fallback") },
                featuredEvents.first(where: { $0.category == .kids }).map { eventBrief($0, kicker: "Plan ahead") },
                anchorPlace(\.outdoorParkPlaceID).map { placeBrief($0, kicker: "After-school energy") },
                anchorService(\.schoolsServiceID).map { serviceBrief($0, kicker: "School logistics") }
            ].compactMap { $0 }
        case .commuter:
            return [
                anchorService(\.commuterServiceID).map { serviceBrief($0, kicker: "Train, bus, parking") },
                anchorService(\.seniorRideServiceID).map { serviceBrief($0, kicker: "Local rides") },
                anchorService(\.townHallServiceID).map { serviceBrief($0, kicker: "Decals and routing") }
            ].compactMap { $0 }
        case .homeowner:
            return [
                alerts.first(where: { $0.title.localizedCaseInsensitiveContains("water") }).map(alertBrief),
                anchorService(\.trashServiceID).map { serviceBrief($0, kicker: "This week's chores") },
                anchorService(\.formsServiceID).map { serviceBrief($0, kicker: "Permits and zoning") },
                anchorService(\.waterSewerServiceID).map { serviceBrief($0, kicker: "Utilities") }
            ].compactMap { $0 }
        case .newcomer:
            return [
                anchorService(\.townHallServiceID).map { serviceBrief($0, kicker: "Start here") },
                anchorService(\.alertsServiceID).map { serviceBrief($0, kicker: "Do this first") },
                anchorPlace(\.indoorFallbackPlaceID).map { placeBrief($0, kicker: "Community hub") },
                topPlaces.first.map { placeBrief($0, kicker: "First local bite") }
            ].compactMap { $0 }
        case .nightOut:
            return [
                anchorPlace(\.nightOutPlaceID).map { placeBrief($0, kicker: "Drinks and brunch") },
                anchorPlace(\.dinnerPlaceID).map { placeBrief($0, kicker: "Dinner plan") },
                featuredEvents.first(where: { $0.category == .recreation }).map { eventBrief($0, kicker: "Town night") }
            ].compactMap { $0 }
        }
    }

    private func alertBrief(_ alert: TownAlert) -> ResidentBriefItem {
        ResidentBriefItem(
            id: "alert-\(alert.id)",
            title: alert.title,
            kicker: alert.effectiveText,
            summary: alert.summary,
            category: .government,
            source: alert.source,
            actionLabel: "Read source",
            placeID: nil,
            serviceID: nil,
            eventID: nil
        )
    }

    private func eventBrief(_ event: TownEvent, kicker: String) -> ResidentBriefItem {
        ResidentBriefItem(
            id: "event-\(event.id)",
            title: event.title,
            kicker: kicker,
            summary: "\(event.dateText)\(event.timeText.isEmpty ? "" : " at \(event.timeText)") - \(event.summary)",
            category: event.category,
            source: event.source,
            actionLabel: "Ask AI",
            placeID: nil,
            serviceID: nil,
            eventID: event.id
        )
    }

    private func placeBrief(_ place: LocalPlace, kicker: String) -> ResidentBriefItem {
        ResidentBriefItem(
            id: "place-\(place.id)",
            title: place.name,
            kicker: kicker,
            summary: place.summary,
            category: place.category,
            source: place.source,
            actionLabel: "Open place",
            placeID: place.id,
            serviceID: nil,
            eventID: nil
        )
    }

    private func serviceBrief(_ service: CivicService, kicker: String) -> ResidentBriefItem {
        ResidentBriefItem(
            id: "service-\(service.id)",
            title: service.name,
            kicker: kicker,
            summary: service.summary,
            category: service.category,
            source: service.source,
            actionLabel: service.actionLabel,
            placeID: nil,
            serviceID: service.id,
            eventID: nil
        )
    }

    func mergeAlerts(existing: [TownAlert], incoming: [TownAlert]) -> [TownAlert] {
        var seen = Set(existing.map(\.id))
        var merged = existing

        for alert in incoming {
            guard !seen.contains(alert.id),
                  !merged.contains(where: { isLikelyDuplicateAlert($0, alert) }) else {
                continue
            }
            seen.insert(alert.id)
            merged.append(alert)
        }

        return merged
    }

    private func merge<T: Identifiable>(existing: [T], incoming: [T]) -> [T] where T.ID == String {
        var seen = Set(existing.map(\.id))
        var merged = existing
        for item in incoming where !seen.contains(item.id) {
            seen.insert(item.id)
            merged.append(item)
        }
        return merged
    }

    private func mergePlaces(existing: [LocalPlace], incoming: [LocalPlace]) -> [LocalPlace] {
        var merged = existing
        var indexesByKey = Dictionary(uniqueKeysWithValues: existing.enumerated().map { ($0.element.dedupeKey, $0.offset) })

        for place in incoming {
            if let index = indexesByKey[place.dedupeKey] {
                merged[index] = mergedPlace(existing: merged[index], incoming: place)
            } else {
                indexesByKey[place.dedupeKey] = merged.count
                merged.append(place)
            }
        }

        return merged
    }

    private func mergedPlace(existing: LocalPlace, incoming: LocalPlace) -> LocalPlace {
        LocalPlace(
            id: existing.id,
            name: existing.name,
            category: existing.category,
            subcategory: existing.subcategory,
            summary: existing.summary,
            address: existing.address ?? incoming.address,
            phone: existing.phone ?? incoming.phone,
            website: existing.website ?? incoming.website,
            imageURL: existing.imageURL ?? incoming.imageURL,
            highlights: (existing.highlights + incoming.highlights).uniqued(),
            tags: (existing.tags + incoming.tags).uniqued(),
            source: existing.source
        )
    }

    private func isLikelyDuplicateAlert(_ lhs: TownAlert, _ rhs: TownAlert) -> Bool {
        let lhsTokens = alertTokens(lhs.title + " " + lhs.summary)
        let rhsTokens = alertTokens(rhs.title + " " + rhs.summary)
        let sharedTokenCount = lhsTokens.intersection(rhsTokens).count
        let smallerTokenCount = min(lhsTokens.count, rhsTokens.count)

        return smallerTokenCount >= 2 && sharedTokenCount >= min(3, smallerTokenCount)
    }

    private func alertTokens(_ text: String) -> Set<String> {
        let stopWords: Set<String> = [
            "and", "announced", "borough", "department", "detected", "effective", "for", "from",
            "homepage", "implementing", "item", "latest", "live", "official", "park", "ridge",
            "that", "the", "this", "through", "with"
        ]

        return Set(
            text
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count > 2 && !stopWords.contains($0) }
        )
    }
}

private extension LocalPlace {
    var dedupeKey: String {
        let nameKey = name.normalizedPlaceComponent
        let addressKey = address?.normalizedPlaceComponent ?? ""
        return addressKey.isEmpty ? nameKey : "\(nameKey)-\(addressKey)"
    }
}

private extension String {
    var normalizedPlaceComponent: String {
        lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined()
    }
}

private extension Array where Element == String {
    func uniqued() -> [String] {
        var seen: Set<String> = []
        return filter { seen.insert($0).inserted }
    }
}
