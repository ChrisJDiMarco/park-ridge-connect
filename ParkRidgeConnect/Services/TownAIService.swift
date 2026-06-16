import Foundation

struct TownAIResponse {
    let text: String
    let sourceTitles: [String]
}

struct TownAIService {
    /// Injected from TownConfig so responses speak the active town's name.
    var townName: String = "Park Ridge"

    func placePlan(for place: LocalPlace, nearbyPlaces: [LocalPlace], events: [TownEvent]) -> TownAIResponse {
        let relatedTags = Set(place.tags)
        let relatedPlaces = nearbyPlaces
            .filter { $0.id != place.id && !Set($0.tags).intersection(relatedTags).isEmpty }
            .prefix(2)
        let relatedEvents = events
            .filter { event in
                event.category == place.category ||
                (place.tags.contains("kids") && [.kids, .recreation].contains(event.category)) ||
                (place.tags.contains("family") && [.kids, .recreation].contains(event.category))
            }
            .prefix(2)

        let bestFit = bestFitLine(for: place)
        let highlights = place.highlights.prefix(3).joined(separator: ", ")
        let pairings = relatedPlaces.map { "- Pair with \($0.name) when you want \($0.subcategory.lowercased())." }.joined(separator: "\n")
        let eventText = relatedEvents.map { "- Watch for \($0.title), \($0.dateText) \(($0.timeText.isEmpty ? "" : "at \($0.timeText)"))" }.joined(separator: "\n")
        let sourceTitles = Array(Set([place.source.title] + relatedPlaces.map(\.source.title) + relatedEvents.map(\.source.title)))

        return TownAIResponse(
            text: """
            \(place.name) is a best fit for \(bestFit)

            Use it when you want: \(highlights).

            \(pairings.isEmpty ? "Nearby pairing: check the Map action for the fastest next stop." : pairings)

            \(eventText.isEmpty ? "Town timing: save it here so it is easy to pull up when you are deciding fast." : "Town timing:\n\(eventText)")
            """,
            sourceTitles: sourceTitles
        )
    }

    func answer(
        question: String,
        places: [LocalPlace],
        services: [CivicService],
        events: [TownEvent],
        alerts: [TownAlert],
        notices: [TownNotice],
        workflows: [CivicWorkflow] = [],
        weather: TownWeatherSnapshot? = nil
    ) -> TownAIResponse {
        let query = question.lowercased()

        if query.contains("smart town plan") {
            return smartPlanAnswer(question: question, weather: weather)
        }

        if query.contains("civic workflow"),
           let workflow = workflowFromPrompt(question: question, workflows: workflows) {
            return civicWorkflowAnswer(workflow)
        }

        if let workflow = bestWorkflowMatch(query: query, workflows: workflows) {
            return civicWorkflowAnswer(workflow)
        }

        if isWeatherQuestion(query) {
            return weatherAnswer(weather: weather, places: places, events: events)
        }

        if query.contains("parent") || query.contains("kid") || query.contains("play") || query.contains("toddler") || query.contains("family") {
            return kidPlan(places: places, events: events, weather: weather)
        }

        if query.contains("eat") || query.contains("food") || query.contains("dinner") || query.contains("lunch") || query.contains("date") {
            return foodPlan(places: places, query: query)
        }

        if query.contains("train") || query.contains("bus") || query.contains("commute") || query.contains("parking") || query.contains("senior ride") {
            return serviceAnswer(services: services, matching: ["train", "bus", "commute", "parking", "senior", "ride"])
        }

        if query.contains("trash") || query.contains("recycling") || query.contains("water") || query.contains("electric") || query.contains("permit") || query.contains("tax") || query.contains("form") {
            return serviceAnswer(services: services, matching: ["trash", "recycling", "water", "electric", "permit", "tax", "form", "zoning"])
        }

        if query.contains("today") || query.contains("week") || query.contains("event") || query.contains("meeting") || query.contains("happening") {
            return townPulse(events: events, alerts: alerts, notices: notices, weather: weather)
        }

        return searchAnswer(query: query, places: places, services: services, events: events, alerts: alerts, notices: notices, weather: weather)
    }

    private func workflowFromPrompt(question: String, workflows: [CivicWorkflow]) -> CivicWorkflow? {
        let lowercased = question.lowercased()
        return workflows.first { workflow in
            lowercased.contains("civic workflow: \(workflow.title.lowercased())") ||
                lowercased.contains(workflow.title.lowercased())
        }
    }

    private func bestWorkflowMatch(query: String, workflows: [CivicWorkflow]) -> CivicWorkflow? {
        guard !workflows.isEmpty else { return nil }
        let terms = Set(query.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 2 })
        guard !terms.isEmpty else { return nil }

        let scored = workflows.map { workflow in
            let workflowTerms = Set(
                ([workflow.title, workflow.kicker, workflow.summary, workflow.category.rawValue] + workflow.tags + workflow.steps.flatMap { [$0.title, $0.detail, $0.source.title] })
                    .joined(separator: " ")
                    .lowercased()
                    .components(separatedBy: CharacterSet.alphanumerics.inverted)
                    .filter { $0.count > 2 }
            )
            let score = terms.intersection(workflowTerms).count * 10 + workflow.priority
            return (workflow: workflow, matchCount: terms.intersection(workflowTerms).count, score: score)
        }

        guard let best = scored.max(by: { first, second in
            if first.score == second.score {
                return first.workflow.title > second.workflow.title
            }
            return first.score < second.score
        }), best.matchCount >= 2 else {
            return nil
        }

        return best.workflow
    }

    private func civicWorkflowAnswer(_ workflow: CivicWorkflow) -> TownAIResponse {
        let stepText = workflow.steps.enumerated().map { index, step in
            "\(index + 1). \(step.title): \(step.detail)"
        }.joined(separator: "\n")
        let firstMove = workflow.steps.first.map { "\($0.title) via \($0.source.title)" } ?? "Open the official \(townName) source first"

        return TownAIResponse(
            text: """
            Civic Workflow: \(workflow.title)
            \(workflow.summary)

            Do this in order:
            \(stepText)

            Best first move: \(firstMove). Keep this source-backed and switch to a phone call for anything urgent, time-sensitive, or unclear.
            """,
            sourceTitles: workflow.sourceTitles
        )
    }

    private func smartPlanAnswer(question: String, weather: TownWeatherSnapshot?) -> TownAIResponse {
        let planLines = question
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.hasPrefix("- ") && $0.contains(":") }

        let cleanedPlan = planLines.prefix(3).map { line -> String in
            let withoutDash = String(line.dropFirst(2))
            let sourceSplit = withoutDash.components(separatedBy: " Source: ")
            return "- \(sourceSplit.first ?? withoutDash)"
        }.joined(separator: "\n")
        let planText = cleanedPlan.isEmpty ? "- Do now: Open Today and refresh for the latest \(townName) plan." : cleanedPlan
        let weatherText = weather.map { "\n\nWeather read: \($0.summaryLine) \($0.outdoorAdvice)" } ?? ""

        return TownAIResponse(
            text: """
            Smart Town Plan:
            \(planText)\(weatherText)

            Why this order: handle the immediate best move first, plan around the highest-signal event next, and keep the civic watch item visible so resident logistics do not surprise you.
            """,
            sourceTitles: smartPlanSources(from: question, weather: weather)
        )
    }

    private func smartPlanSources(from question: String, weather: TownWeatherSnapshot?) -> [String] {
        var sources = Set<String>()
        if let weather {
            sources.insert(weather.source.title)
        }

        question
            .components(separatedBy: .newlines)
            .forEach { line in
                guard let range = line.range(of: "Source: ") else { return }
                let title = line[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty {
                    sources.insert(title)
                }
            }

        return sources.sorted()
    }

    private func kidPlan(places: [LocalPlace], events: [TownEvent], weather: TownWeatherSnapshot?) -> TownAIResponse {
        let matches = places.filter { $0.tags.contains("kids") || $0.category == .kids || $0.category == .library }
        let upcoming = events.filter { $0.category == .kids || $0.category == .recreation }.prefix(3)
        let placeText = matches.prefix(4).map { "- \($0.name): \($0.summary)" }.joined(separator: "\n")
        let eventText = upcoming.map { "- \($0.title), \($0.dateText) at \($0.timeText)" }.joined(separator: "\n")
        let weatherText = weather.map { "\n\nWeather read: \($0.summaryLine) \($0.outdoorAdvice)" } ?? ""
        let weatherSources = weather.map { [$0.source.title] } ?? []
        let sources = Array(Set(matches.map(\.source.title) + upcoming.map(\.source.title) + weatherSources))

        return TownAIResponse(
            text: "Best family plan:\n\(placeText)\n\(weatherText)\n\nUpcoming kid/family hooks:\n\(eventText)\n\nMy pick: start with the Library if you want low-friction indoor time, Memorial Park for active play, and the Town Picnic or summer concerts when you want the full town vibe.",
            sourceTitles: sources
        )
    }

    private func foodPlan(places: [LocalPlace], query: String) -> TownAIResponse {
        let tags = query.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        var matches = places.filter { $0.category == .food || $0.category == .adults }

        if tags.contains("breakfast") || tags.contains("brunch") {
            matches = matches.filter { $0.tags.contains("breakfast") || $0.tags.contains("brunch") }
        } else if tags.contains("cocktail") || tags.contains("drinks") || tags.contains("date") {
            matches = matches.filter { $0.tags.contains("cocktails") || $0.tags.contains("date night") }
        } else if tags.contains("pizza") {
            matches = matches.filter { $0.tags.contains("pizza") }
        }

        let picks = (matches.isEmpty ? places.filter { $0.category == .food } : matches).prefix(5)
        let text = picks.map { "- \($0.name): \($0.subcategory). \($0.summary)" }.joined(separator: "\n")
        return TownAIResponse(text: "Here are the strongest \(townName) food picks for that:\n\(text)", sourceTitles: Array(Set(picks.map(\.source.title))))
    }

    private func serviceAnswer(services: [CivicService], matching tags: [String]) -> TownAIResponse {
        let matches = services.filter { service in
            !Set(service.tags).intersection(tags).isEmpty ||
            tags.contains { service.name.lowercased().contains($0) || service.summary.lowercased().contains($0) }
        }
        let text = matches.prefix(4).map { service in
            let phone = service.phone.map { " Call \($0)." } ?? ""
            return "- \(service.name): \(service.summary)\(phone)"
        }.joined(separator: "\n")

        return TownAIResponse(text: "Use these official town paths:\n\(text)", sourceTitles: Array(Set(matches.map(\.source.title))))
    }

    private func townPulse(events: [TownEvent], alerts: [TownAlert], notices: [TownNotice], weather: TownWeatherSnapshot?) -> TownAIResponse {
        let alertText = alerts.prefix(2).map { "- \($0.title): \($0.summary)" }.joined(separator: "\n")
        let eventText = events.sorted { $0.priority > $1.priority }.prefix(5).map { "- \($0.title), \($0.dateText) \(($0.timeText.isEmpty ? "" : "at \($0.timeText)"))" }.joined(separator: "\n")
        let noticeText = notices.prefix(3).map { "- \($0.title)" }.joined(separator: "\n")
        let weatherText = weather.map { "\n\nWeather:\n- \($0.summaryLine) \($0.outdoorAdvice)" } ?? ""
        let weatherSources = weather.map { [$0.source.title] } ?? []
        let sources = Array(Set(alerts.map(\.source.title) + events.map(\.source.title) + notices.map(\.source.title) + weatherSources))

        return TownAIResponse(
            text: "\(townName) pulse:\(weatherText)\n\nAlerts:\n\(alertText)\n\nComing up:\n\(eventText)\n\nNotices:\n\(noticeText)",
            sourceTitles: sources
        )
    }

    private func searchAnswer(
        query: String,
        places: [LocalPlace],
        services: [CivicService],
        events: [TownEvent],
        alerts: [TownAlert],
        notices: [TownNotice],
        weather: TownWeatherSnapshot?
    ) -> TownAIResponse {
        let terms = query.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 2 }
        let placeMatches = places.filter { item in terms.contains { item.name.lowercased().contains($0) || item.summary.lowercased().contains($0) || item.tags.contains($0) } }
        let serviceMatches = services.filter { item in terms.contains { item.name.lowercased().contains($0) || item.summary.lowercased().contains($0) || item.tags.contains($0) } }

        if placeMatches.isEmpty && serviceMatches.isEmpty {
            return townPulse(events: events, alerts: alerts, notices: notices, weather: weather)
        }

        let placeText = placeMatches.prefix(3).map { "- \($0.name): \($0.summary)" }.joined(separator: "\n")
        let serviceText = serviceMatches.prefix(3).map { "- \($0.name): \($0.summary)" }.joined(separator: "\n")
        let sources = Array(Set(placeMatches.map(\.source.title) + serviceMatches.map(\.source.title)))

        return TownAIResponse(text: "Closest \(townName) matches:\n\(placeText)\n\(serviceText)", sourceTitles: sources)
    }

    private func weatherAnswer(weather: TownWeatherSnapshot?, places: [LocalPlace], events: [TownEvent]) -> TownAIResponse {
        guard let weather else {
            return TownAIResponse(
                text: "I do not have the live National Weather Service snapshot yet. Pull to refresh Today, then ask again for the outside, commute, playground, or evening read.",
                sourceTitles: [ParkRidgeSeedData.weather.title]
            )
        }

        let outdoorPicks = places
            .filter { ["memorial-park", "mill-pond", "library"].contains($0.id) }
            .map { "- \($0.name): \($0.summary)" }
            .joined(separator: "\n")
        let upcomingOutdoor = events
            .filter { [.kids, .recreation].contains($0.category) }
            .prefix(2)
            .map { "- \($0.title), \($0.dateText) \(($0.timeText.isEmpty ? "" : "at \($0.timeText)"))" }
            .joined(separator: "\n")

        return TownAIResponse(
            text: """
            \(townName) weather right now: \(weather.summaryLine)

            \(weather.outdoorAdvice)

            Best local calls:
            \(outdoorPicks)

            Watch with weather in mind:
            \(upcomingOutdoor)
            """,
            sourceTitles: Array(Set([weather.source.title] + places.filter { ["memorial-park", "mill-pond", "library"].contains($0.id) }.map(\.source.title) + events.filter { [.kids, .recreation].contains($0.category) }.map(\.source.title)))
        )
    }

    private func isWeatherQuestion(_ query: String) -> Bool {
        let terms = Set(query.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty })
        let weatherTerms: Set<String> = ["weather", "forecast", "rain", "raining", "rainy", "umbrella", "outside", "outdoor", "outdoors"]
        return !terms.intersection(weatherTerms).isEmpty
    }

    private func bestFitLine(for place: LocalPlace) -> String {
        if place.tags.contains("cocktails") || place.tags.contains("date night") {
            return "a date night, drinks plan, or adult dinner where atmosphere matters."
        }
        if place.tags.contains("kids") || place.tags.contains("family") {
            return "a low-friction family stop where kids can come along without over-planning."
        }
        if place.tags.contains("pizza") || place.tags.contains("takeout") || place.tags.contains("delivery") {
            return "quick takeout, casual dinner, or feeding a group without making it complicated."
        }
        if place.category == .library {
            return "indoor community time, kid programs, museum passes, or a quiet reset."
        }
        if place.category == .recreation || place.category == .kids {
            return "getting outside, burning energy, or anchoring a family afternoon."
        }
        return "a practical \(townName) stop that solves the moment without leaving town."
    }
}
