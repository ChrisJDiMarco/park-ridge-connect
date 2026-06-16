import Foundation

protocol WeatherFetching {
    func refreshSnapshot() async throws -> TownWeatherSnapshot
}

/// NWS-backed weather, configured per town via `WeatherConfig`.
struct ParkRidgeWeatherService: WeatherFetching {
    private let config: WeatherConfig

    init(config: WeatherConfig = ParkRidgeSeedData.config.weather) {
        self.config = config
    }

    private var pointsURL: URL {
        URL(string: "https://api.weather.gov/points/\(config.latitude),\(config.longitude)")!
    }

    private var userAgent: String {
        "TownConnect/1.0 (\(config.contactEmail))"
    }

    private var source: KnowledgeSource {
        KnowledgeSource(
            id: "nws-weather",
            title: "National Weather Service",
            url: config.fallbackHourlyForecastURL ?? pointsURL,
            summary: "Official National Weather Service hourly forecast for the area."
        )
    }

    func refreshSnapshot() async throws -> TownWeatherSnapshot {
        let forecastURL = try await hourlyForecastURL()
        let data = try await fetchData(from: forecastURL)
        return try Self.parseHourlyForecast(data, source: source)
    }

    static func parseHourlyForecast(_ data: Data, source: KnowledgeSource = ParkRidgeSeedData.weather, fallbackGeneratedAt: Date = Date()) throws -> TownWeatherSnapshot {
        let forecast = try JSONDecoder().decode(NWSHourlyForecast.self, from: data)
        guard let current = forecast.properties.periods.first else {
            throw WeatherError.missingCurrentPeriod
        }

        let generatedAt = forecast.properties.generatedAt
            .flatMap(Self.parseDate)
            ?? fallbackGeneratedAt

        return TownWeatherSnapshot(
            temperature: current.temperature,
            temperatureUnit: current.temperatureUnit,
            shortForecast: current.shortForecast,
            precipitationChance: current.probabilityOfPrecipitation?.value,
            windSpeed: current.windSpeed,
            windDirection: current.windDirection,
            generatedAt: generatedAt,
            source: source
        )
    }

    private func hourlyForecastURL() async throws -> URL {
        do {
            let data = try await fetchData(from: pointsURL)
            let point = try JSONDecoder().decode(NWSPoint.self, from: data)
            if let url = point.properties.forecastHourly ?? config.fallbackHourlyForecastURL {
                return url
            }
            throw WeatherError.badResponse
        } catch {
            if let fallback = config.fallbackHourlyForecastURL {
                return fallback
            }
            throw error
        }
    }

    private func fetchData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw WeatherError.badResponse
        }
        return data
    }

    private static func parseDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

private enum WeatherError: Error {
    case badResponse
    case missingCurrentPeriod
}

private struct NWSPoint: Decodable {
    let properties: Properties

    struct Properties: Decodable {
        let forecastHourly: URL?
    }
}

private struct NWSHourlyForecast: Decodable {
    let properties: Properties

    struct Properties: Decodable {
        let generatedAt: String?
        let periods: [Period]
    }

    struct Period: Decodable {
        let temperature: Int
        let temperatureUnit: String
        let probabilityOfPrecipitation: Probability?
        let windSpeed: String
        let windDirection: String
        let shortForecast: String
    }

    struct Probability: Decodable {
        let value: Int?

        enum CodingKeys: CodingKey {
            case value
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let integerValue = try? container.decodeIfPresent(Int.self, forKey: .value) {
                value = integerValue
            } else if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: .value) {
                value = Int(doubleValue.rounded())
            } else {
                value = nil
            }
        }
    }
}
