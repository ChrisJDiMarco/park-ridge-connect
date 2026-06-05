import Foundation

struct BoroughRefreshService {
    private let homeURL = URL(string: "https://parkridgeboro.com/")!
    private let referenceDate: Date
    private let calendar: Calendar

    init(referenceDate: Date = Date(), calendar: Calendar = .current) {
        self.referenceDate = referenceDate
        self.calendar = calendar
    }

    func refresh() async throws -> BoroughRefreshResult {
        let (data, _) = try await URLSession.shared.data(from: homeURL)
        let html = String(decoding: data, as: UTF8.self)
        let lines = normalizedLines(from: html)
        let source = ParkRidgeSeedData.borough

        let notices = extractNews(from: lines, source: source)
        let events = extractCalendar(from: lines, source: source)
        let alerts = extractAlerts(from: lines, source: source)

        return BoroughRefreshResult(
            notices: notices,
            events: events,
            alerts: alerts,
            fetchedAt: Date()
        )
    }

    private func normalizedLines(from html: String) -> [String] {
        html
            .replacingOccurrences(of: "<[^>]+>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#8211;", with: "-")
            .replacingOccurrences(of: "&#8217;", with: "'")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("fas ") && !$0.hasPrefix("far ") }
    }

    func extractNews(from lines: [String], source: KnowledgeSource) -> [TownNotice] {
        guard let start = lines.firstIndex(where: { $0.localizedCaseInsensitiveContains("News & Announcements") }) else {
            return []
        }

        let slice = lines.dropFirst(start + 1).prefix(18)
        let titles = slice.filter { line in
            line.count > 8 &&
            isHumanContent(line) &&
            !isPastDatedItem(line) &&
            !line.localizedCaseInsensitiveContains("See all") &&
            !line.localizedCaseInsensitiveContains("Recent Documents") &&
            !line.localizedCaseInsensitiveContains("recreation")
        }

        return Array(titles.prefix(5)).enumerated().map { index, title in
            TownNotice(
                id: "live-notice-\(index)-\(title.hashValue)",
                title: title,
                summary: "Pulled from the borough homepage. Open the official source for full details and latest attachments.",
                source: source,
                tags: ["live", "borough"]
            )
        }
    }

    func extractAlerts(from lines: [String], source: KnowledgeSource) -> [TownAlert] {
        let alertLines = lines.filter {
            isHumanContent($0) &&
            !isPastDatedItem($0) && (
                $0.localizedCaseInsensitiveContains("water restrictions") ||
                $0.localizedCaseInsensitiveContains("budget public hearing") ||
                $0.localizedCaseInsensitiveContains("livestream")
            )
        }

        return Array(alertLines.prefix(3)).enumerated().map { index, title in
            TownAlert(
                id: "live-alert-\(index)-\(title.hashValue)",
                title: title,
                severity: title.localizedCaseInsensitiveContains("restriction") ? .advisory : .info,
                summary: "Live item detected on the official borough homepage.",
                effectiveText: "Latest borough item",
                source: source
            )
        }
    }

    func extractCalendar(from lines: [String], source: KnowledgeSource) -> [TownEvent] {
        guard let start = lines.lastIndex(where: { $0.localizedCaseInsensitiveContains("Borough Calendar") }) else {
            return []
        }

        var events: [TownEvent] = []
        let calendarLines = Array(lines.dropFirst(start + 1).prefix(45))
        var index = 0

        while index + 2 < calendarLines.count && events.count < 8 {
            let possibleDay = calendarLines[index]
            let title = calendarLines[index + 1]
            let detail = calendarLines[index + 2]

            if possibleDay.range(of: #"^\d{1,2}\s[A-Z][a-z]{2}$"#, options: .regularExpression) != nil,
               detail.range(of: #"\d{2}\.\d{2}\.\d{4}"#, options: .regularExpression) != nil,
               !isPastDatedItem(detail) {
                events.append(
                    TownEvent(
                        id: "live-event-\(events.count)-\(title.hashValue)",
                        title: title.replacingOccurrences(of: "Date ", with: ""),
                        dateText: possibleDay,
                        timeText: detail.replacingOccurrences(of: "Date ", with: ""),
                        summary: "Live borough calendar item. Open the official calendar for full agenda details.",
                        category: category(for: title),
                        audience: "Park Ridge residents",
                        source: source,
                        priority: 6
                    )
                )
                index += 3
            } else {
                index += 1
            }
        }

        return events
    }

    private func isPastDatedItem(_ text: String) -> Bool {
        guard let date = firstDate(in: text) else { return false }
        return calendar.startOfDay(for: date) < calendar.startOfDay(for: referenceDate)
    }

    private func firstDate(in text: String) -> Date? {
        let patterns = [
            #"(?<!\d)(\d{1,2})[\/.-](\d{1,2})[\/.-](\d{2}|\d{4})(?!\d)"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  match.numberOfRanges == 4,
                  let monthRange = Range(match.range(at: 1), in: text),
                  let dayRange = Range(match.range(at: 2), in: text),
                  let yearRange = Range(match.range(at: 3), in: text),
                  let month = Int(text[monthRange]),
                  let day = Int(text[dayRange]),
                  var year = Int(text[yearRange])
            else {
                continue
            }

            if year < 100 {
                year += 2000
            }

            return calendar.date(from: DateComponents(year: year, month: month, day: day))
        }

        return nil
    }

    private func category(for title: String) -> TownCategory {
        let lowercase = title.lowercased()
        if lowercase.contains("recreation") || lowercase.contains("picnic") || lowercase.contains("concert") {
            return .recreation
        }
        if lowercase.contains("school") || lowercase.contains("education") {
            return .schools
        }
        return .government
    }

    private func isHumanContent(_ line: String) -> Bool {
        line.count < 160 &&
        !line.contains("{") &&
        !line.contains("}") &&
        !line.contains(";") &&
        !line.contains("#") &&
        !line.localizedCaseInsensitiveContains(".sp-") &&
        !line.localizedCaseInsensitiveContains("page-builder") &&
        !line.localizedCaseInsensitiveContains("function(")
    }
}
