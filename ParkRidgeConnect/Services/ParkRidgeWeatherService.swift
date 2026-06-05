import Foundation

protocol WeatherFetching {
    func refreshSnapshot() async throws -> TownWeatherSnapshot
}

struct ParkRidgeWeatherService: WeatherFetching {
    private static let pointsURL = URL(string: "https://api.weather.gov/points/40.9912,-74.0326")!
    private static let fallbackHourlyForecastURL = URL(string: "https://api.weather.gov/gridpoints/OKX/30,54/forecast/hourly")!
    private static let userAgent = "ParkRidgeConnect/1.0 (chris.john.dimarco@gmail.com)"

    func refreshSnapshot() async throws -> TownWeatherSnapshot {
        let forecastURL = try await hourlyForecastURL()
        let data = try await fetchData(from: forecastURL)
        return try Self.parseHourlyForecast(data)
    }

    static func parseHourlyForecast(_ data: Data, fallbackGeneratedAt: Date = Date()) throws -> TownWeatherSnapshot {
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
            source: ParkRidgeSeedData.weather
        )
    }

    private func hourlyForecastURL() async throws -> URL {
        do {
            let data = try await fetchData(from: Self.pointsURL)
            let point = try JSONDecoder().decode(NWSPoint.self, from: data)
            return point.properties.forecastHourly ?? Self.fallbackHourlyForecastURL
        } catch {
            return Self.fallbackHourlyForecastURL
        }
    }

    private func fetchData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
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
