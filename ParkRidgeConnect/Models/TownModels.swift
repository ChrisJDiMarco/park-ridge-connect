import Foundation

enum TownCategory: String, CaseIterable, Identifiable {
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

enum NoticeSeverity: String {
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

struct KnowledgeSource: Identifiable, Hashable {
    let id: String
    let title: String
    let url: URL
    let summary: String
}

struct TownAlert: Identifiable, Hashable {
    let id: String
    let title: String
    let severity: NoticeSeverity
    let summary: String
    let effectiveText: String
    let source: KnowledgeSource
}

struct TownNotice: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let source: KnowledgeSource
    let tags: [String]
}

struct TownEvent: Identifiable, Hashable {
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

struct LocalPlace: Identifiable, Hashable {
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
        return URL(string: "http://maps.apple.com/?q=\(query)")
    }
}

struct CivicService: Identifiable, Hashable {
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

struct CivicWorkflowStep: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let serviceID: String?
    let source: KnowledgeSource
}

struct CivicWorkflow: Identifiable, Hashable {
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
            return "Build in an indoor fallback before playgrounds, fields, or the Town Picnic."
        }
        if temperature >= 88 {
            return "Good to go outside, but plan shade, water, and shorter park windows."
        }
        if temperature <= 40 {
            return "Layer up before walking, commuting, or staying out at borough events."
        }
        if shortForecast.localizedCaseInsensitiveContains("Sunny") {
            return "Strong outdoor window for Memorial Park, Mill Pond, errands, and after-school energy."
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
