import Foundation

enum TownCategory: String, CaseIterable, Identifiable, Codable {
    case food = "Food"
    case kids = "Kids"
    case recreation = "Recreation"
    case adults = "Adults"
    case government = "Government"
    case services = "Services"
    case schools = "Schools"
    case library = "Library"
    case transit = "Transit"
    case emergency = "Emergency"
    case utilities = "Utilities"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .food: return "fork.knife"
        case .kids: return "figure.and.child.holdinghands"
        case .recreation: return "soccerball"
        case .adults: return "wineglass"
        case .government: return "building.columns"
        case .services: return "checklist"
        case .schools: return "graduationcap"
        case .library: return "books.vertical"
        case .transit: return "tram"
        case .emergency: return "cross.case"
        case .utilities: return "bolt.water"
        }
    }
}

enum NoticeSeverity: String, Codable {
    case info = "Info"
    case advisory = "Advisory"
    case urgent = "Urgent"
}

enum ResidentLens: String, CaseIterable, Identifiable {
    case today = "Today"
    case parent = "Parent"
    case commuter = "Commuter"
    case homeowner = "Homeowner"
    case newcomer = "Newcomer"
    case nightOut = "Night Out"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .today: return "sparkle.magnifyingglass"
        case .parent: return "figure.and.child.holdinghands"
        case .commuter: return "tram"
        case .homeowner: return "house.lodge"
        case .newcomer: return "map"
        case .nightOut: return "moon.stars"
        }
    }
}

struct KnowledgeSource: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let url: URL
    let summary: String
}

struct TownAlert: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let severity: NoticeSeverity
    let summary: String
    let effectiveText: String
    let source: KnowledgeSource
}

struct TownNotice: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let summary: String
    let source: KnowledgeSource
    let tags: [String]
}

struct TownEvent: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let dateText: String
    let timeText: String
    let summary: String
    let category: TownCategory
    let audience: String
    let source: KnowledgeSource
    let priority: Int
}

extension TownEvent {
    func dateRange(calendar: Calendar = .current) -> ClosedRange<Date>? {
        TownEventDateParser.dateRange(from: dateText, timeText: timeText, calendar: calendar)
    }

    func isUpcoming(relativeTo referenceDate: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let range = dateRange(calendar: calendar) else { return false }
        let today = calendar.startOfDay(for: referenceDate)
        return calendar.startOfDay(for: range.upperBound) >= today
    }
}

extension Sequence where Element == TownEvent {
    func upcomingEvents(relativeTo referenceDate: Date = Date(), calendar: Calendar = .current) -> [TownEvent] {
        let today = calendar.startOfDay(for: referenceDate)
        return compactMap { event -> (event: TownEvent, range: ClosedRange<Date>)? in
            guard let range = event.dateRange(calendar: calendar),
                  calendar.startOfDay(for: range.upperBound) >= today else {
                return nil
            }
            return (event, range)
        }
        .sorted { lhs, rhs in
            let leftStart = calendar.startOfDay(for: lhs.range.lowerBound)
            let rightStart = calendar.startOfDay(for: rhs.range.lowerBound)
            if leftStart != rightStart {
                return leftStart < rightStart
            }
            if lhs.event.priority != rhs.event.priority {
                return lhs.event.priority > rhs.event.priority
            }
            return lhs.event.title < rhs.event.title
        }
        .map(\.event)
    }
}

private enum TownEventDateParser {
    private static let monthNumbers: [String: Int] = [
        "jan": 1, "january": 1,
        "feb": 2, "february": 2,
        "mar": 3, "march": 3,
        "apr": 4, "april": 4,
        "may": 5,
        "jun": 6, "june": 6,
        "jul": 7, "july": 7,
        "aug": 8, "august": 8,
        "sep": 9, "sept": 9, "september": 9,
        "oct": 10, "october": 10,
        "nov": 11, "november": 11,
        "dec": 12, "december": 12
    ]

    static func dateRange(from dateText: String, timeText: String, calendar: Calendar) -> ClosedRange<Date>? {
        let combined = "\(dateText) \(timeText)"
        if let range = monthNameRange(in: dateText, calendar: calendar) {
            return range
        }
        if let date = numericDate(in: combined, calendar: calendar) {
            return date...date
        }
        if let date = monthNameDate(in: dateText, calendar: calendar) {
            return date...date
        }
        return nil
    }

    private static func numericDate(in text: String, calendar: Calendar) -> Date? {
        if let date = firstMatch(
            in: text,
            pattern: #"(?<!\d)(\d{4})-(\d{1,2})-(\d{1,2})(?!\d)"#,
            calendar: calendar,
            parser: { groups, calendar in
                guard groups.count == 3,
                      let year = Int(groups[0]),
                      let month = Int(groups[1]),
                      let day = Int(groups[2]) else {
                    return nil
                }
                return makeDate(year: year, month: month, day: day, calendar: calendar)
            }
        ) {
            return date
        }

        return firstMatch(
            in: text,
            pattern: #"(?<!\d)(\d{1,2})[\/.](\d{1,2})[\/.](\d{2}|\d{4})(?!\d)"#,
            calendar: calendar,
            parser: { groups, calendar in
                guard groups.count == 3,
                      let month = Int(groups[0]),
                      let day = Int(groups[1]),
                      var year = Int(groups[2]) else {
                    return nil
                }
                if year < 100 {
                    year += 2000
                }
                return makeDate(year: year, month: month, day: day, calendar: calendar)
            }
        )
    }

    private static func monthNameRange(in text: String, calendar: Calendar) -> ClosedRange<Date>? {
        let pattern = #"(?i)\b([A-Za-z]{3,9})\s+(\d{1,2})\s*(?:-|–|—|to)\s*([A-Za-z]{3,9})?\s*(\d{1,2}),?\s*(\d{4})\b"#
        guard let groups = firstGroups(in: text, pattern: pattern),
              groups.count == 5,
              let startMonth = monthNumber(for: groups[0]),
              let startDay = Int(groups[1]),
              let endDay = Int(groups[3]),
              let year = Int(groups[4]) else {
            return nil
        }

        let endMonth = monthNumber(for: groups[2]) ?? startMonth
        guard let start = makeDate(year: year, month: startMonth, day: startDay, calendar: calendar),
              let end = makeDate(year: year, month: endMonth, day: endDay, calendar: calendar),
              start <= end else {
            return nil
        }

        return start...end
    }

    private static func monthNameDate(in text: String, calendar: Calendar) -> Date? {
        firstMatch(
            in: text,
            pattern: #"(?i)\b([A-Za-z]{3,9})\s+(\d{1,2}),?\s+(\d{4})\b"#,
            calendar: calendar,
            parser: { groups, calendar in
                guard groups.count == 3,
                      let month = monthNumber(for: groups[0]),
                      let day = Int(groups[1]),
                      let year = Int(groups[2]) else {
                    return nil
                }
                return makeDate(year: year, month: month, day: day, calendar: calendar)
            }
        )
    }

    private static func firstMatch(
        in text: String,
        pattern: String,
        calendar: Calendar,
        parser: ([String], Calendar) -> Date?
    ) -> Date? {
        guard let groups = firstGroups(in: text, pattern: pattern) else { return nil }
        return parser(groups, calendar)
    }

    private static func firstGroups(in text: String, pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }

        return (1..<match.numberOfRanges).map { index in
            guard match.range(at: index).location != NSNotFound,
                  let range = Range(match.range(at: index), in: text) else {
                return ""
            }
            return String(text[range])
        }
    }

    private static func monthNumber(for text: String) -> Int? {
        monthNumbers[text.lowercased()]
    }

    private static func makeDate(year: Int, month: Int, day: Int, calendar: Calendar) -> Date? {
        guard (1...12).contains(month), (1...31).contains(day) else { return nil }
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return nil
        }
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard components.year == year, components.month == month, components.day == day else {
            return nil
        }
        return date
    }
}

struct LocalPlace: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let category: TownCategory
    let subcategory: String
    let summary: String
    let address: String?
    let phone: String?
    let website: URL?
    let imageURL: URL?
    let highlights: [String]
    let tags: [String]
    let source: KnowledgeSource

    var mapURL: URL? {
        guard let address else { return nil }
        let query = "\(name), \(address)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        return URL(string: "https://maps.apple.com/?q=\(query)")
    }
}

struct CivicService: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let department: String
    let summary: String
    let phone: String?
    let website: URL?
    let actionLabel: String
    let category: TownCategory
    let tags: [String]
    let source: KnowledgeSource
}

struct CivicWorkflowStep: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let detail: String
    let serviceID: String?
    let source: KnowledgeSource
}

struct CivicWorkflow: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let kicker: String
    let summary: String
    let category: TownCategory
    let symbol: String
    let priority: Int
    let tags: [String]
    let steps: [CivicWorkflowStep]

    var sourceTitles: [String] {
        Array(Set(steps.map(\.source.title))).sorted()
    }
}

struct TownWeatherSnapshot: Hashable {
    let temperature: Int
    let temperatureUnit: String
    let shortForecast: String
    let precipitationChance: Int?
    let windSpeed: String
    let windDirection: String
    let generatedAt: Date
    let source: KnowledgeSource

    var temperatureText: String {
        "\(temperature)°\(temperatureUnit)"
    }

    var precipitationText: String {
        guard let precipitationChance else { return "Rain n/a" }
        return "Rain \(precipitationChance)%"
    }

    var windText: String {
        "\(windDirection) \(windSpeed)"
    }

    var summaryLine: String {
        "\(temperatureText) and \(shortForecast.lowercased()), \(precipitationText.lowercased()), wind \(windText)."
    }

    var systemImage: String {
        let forecast = shortForecast.lowercased()
        if forecast.contains("thunder") {
            return "cloud.bolt.rain.fill"
        }
        if forecast.contains("rain") || forecast.contains("shower") {
            return "cloud.rain.fill"
        }
        if forecast.contains("snow") {
            return "cloud.snow.fill"
        }
        if forecast.contains("cloud") {
            return "cloud.sun.fill"
        }
        if forecast.contains("wind") {
            return "wind"
        }
        return "sun.max.fill"
    }

    var outdoorAdvice: String {
        if let precipitationChance, precipitationChance >= 50 {
            return "Build in an indoor fallback before playgrounds, fields, or outdoor events."
        }
        if temperature >= 88 {
            return "Good to go outside, but plan shade, water, and shorter park windows."
        }
        if temperature <= 40 {
            return "Layer up before walking, commuting, or staying out at town events."
        }
        if shortForecast.localizedCaseInsensitiveContains("Sunny") {
            return "Strong outdoor window for parks, errands, and after-school energy."
        }
        return "Good enough for quick errands; check again before longer outdoor plans."
    }
}

struct ResidentBriefItem: Identifiable, Hashable {
    let id: String
    let title: String
    let kicker: String
    let summary: String
    let category: TownCategory
    let source: KnowledgeSource
    let actionLabel: String
    let placeID: String?
    let serviceID: String?
    let eventID: String?
}

struct TownPlanItem: Identifiable, Hashable {
    let id: String
    let slot: String
    let title: String
    let summary: String
    let category: TownCategory
    let source: KnowledgeSource
    let actionLabel: String
    let placeID: String?
    let serviceID: String?
    let eventID: String?

    var symbol: String {
        switch slot {
        case "Do now": return "bolt.fill"
        case "Plan next": return "calendar.badge.clock"
        default: return "eye.fill"
        }
    }
}

enum ChatRole {
    case user
    case assistant
}

struct ChatMessage: Identifiable, Hashable {
    let id: UUID
    let role: ChatRole
    let text: String
    let timestamp: Date
    let relatedSourceTitles: [String]

    init(role: ChatRole, text: String, relatedSourceTitles: [String] = []) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.timestamp = Date()
        self.relatedSourceTitles = relatedSourceTitles
    }
}

struct BoroughRefreshResult {
    let notices: [TownNotice]
    let events: [TownEvent]
    let alerts: [TownAlert]
    let fetchedAt: Date
}

// MARK: - Town Template Configuration
//
// Everything town-specific lives in a TownPack (config + content). The app is
// a generic engine: drop in a different TownPack.json and it becomes another
// town's app. Packs are drafted by Tools/town-onboarding and human-reviewed.

struct TownConfig: Codable, Hashable {
    /// "Park Ridge"
    var townName: String
    /// "Park Ridge Connect" — header + app branding
    var appTitle: String
    /// "NJ"
    var state: String
    /// First assistant message shown in Ask
    var assistantWelcome: String
    var assistantWelcomeSourceTitles: [String]
    /// Horizontal suggestion chips in Ask
    var assistantSuggestedPrompts: [String]
    var townHall: TownHallInfo
    var weather: WeatherConfig
    var refresh: RefreshConfig
    var placeDirectory: PlaceDirectoryConfig?
    var anchors: TownAnchors
}

/// The official seat-of-government contact card shown on Services.
struct TownHallInfo: Codable, Hashable {
    var name: String
    var addressLine: String
    var hoursLine: String
    var phone: String
}

/// National Weather Service lookup. Lat/lon resolves the hourly grid via
/// api.weather.gov/points; the fallback URL is used if that lookup fails.
struct WeatherConfig: Codable, Hashable {
    var latitude: Double
    var longitude: Double
    var fallbackHourlyForecastURL: URL?
    /// Contact email NWS asks for in the User-Agent header
    var contactEmail: String
}

/// Live homepage scrape settings for the town's official site.
struct RefreshConfig: Codable, Hashable {
    var homepageURL: URL
    var sourceTitle: String
    var sourceSummary: String
    /// Heading text that precedes the news list (e.g. "News & Announcements")
    var newsSectionMarker: String
    /// Heading text that precedes the calendar list (e.g. "Borough Calendar")
    var calendarSectionMarker: String
    /// Lines containing any of these become live alerts
    var alertKeywords: [String]
}

/// A compliant live place directory source. Prefer `remoteCatalogURL` for
/// production because it lets us cache and review data server-side before the
/// app consumes it. `overpassAPIURL` is a small, attributed fallback.
struct PlaceDirectoryConfig: Codable, Hashable {
    var remoteCatalogURL: URL?
    var openStreetMapSourceURL: URL
    var overpassAPIURL: URL
    var minimumRefreshIntervalHours: Int
    var southLatitude: Double
    var westLongitude: Double
    var northLatitude: Double
    var eastLongitude: Double
}

/// IDs of pack content the lens engine pins into briefs and plans.
/// All optional — missing anchors simply fall back to generic picks.
struct TownAnchors: Codable, Hashable {
    var indoorFallbackPlaceID: String?
    var outdoorParkPlaceID: String?
    var nightOutPlaceID: String?
    var dinnerPlaceID: String?
    var townHallServiceID: String?
    var alertsServiceID: String?
    var trashServiceID: String?
    var commuterServiceID: String?
    var seniorRideServiceID: String?
    var schoolsServiceID: String?
    var formsServiceID: String?
    var waterSewerServiceID: String?
}

/// One complete, self-contained town: configuration plus seeded content.
struct TownPack: Codable {
    var config: TownConfig
    var alerts: [TownAlert]
    var notices: [TownNotice]
    var events: [TownEvent]
    var places: [LocalPlace]
    var services: [CivicService]
    var civicWorkflows: [CivicWorkflow]
}
