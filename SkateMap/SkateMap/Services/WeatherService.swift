//
//  WeatherService.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 4/3/26.
//

import Foundation
import CoreLocation

struct SpotWeather {
    let temperature: Double // Fahrenheit
    let windSpeed: Double   // mph
    let code: Int           // WMO weather code

    var conditionLabel: String {
        switch code {
        case 0:          return "Clear"
        case 1:          return "Mostly Clear"
        case 2:          return "Partly Cloudy"
        case 3:          return "Overcast"
        case 45, 48:     return "Foggy"
        case 51, 53, 55: return "Drizzle"
        case 61, 63, 65: return "Rain"
        case 66, 67:     return "Freezing Rain"
        case 71, 73, 75: return "Snow"
        case 77:         return "Snow Grains"
        case 80, 81, 82: return "Showers"
        case 85, 86:     return "Snow Showers"
        case 95:         return "Thunderstorm"
        case 96, 99:     return "Hail Storm"
        default:         return "Unknown"
        }
    }

    var icon: String {
        switch code {
        case 0:              return "sun.max.fill"
        case 1:              return "sun.min.fill"
        case 2:              return "cloud.sun.fill"
        case 3:              return "cloud.fill"
        case 45, 48:         return "cloud.fog.fill"
        case 51, 53, 55:     return "cloud.drizzle.fill"
        case 61, 63, 65:     return "cloud.rain.fill"
        case 66, 67:         return "cloud.sleet.fill"
        case 71, 73, 75, 77: return "cloud.snow.fill"
        case 80, 81, 82:     return "cloud.heavyrain.fill"
        case 85, 86:         return "cloud.snow.fill"
        case 95, 96, 99:     return "cloud.bolt.rain.fill"
        default:             return "cloud.fill"
        }
    }

    /// Whether the ground is likely wet (bad for skating)
    var isWet: Bool {
        [51, 53, 55, 61, 63, 65, 66, 67, 80, 81, 82, 95, 96, 99].contains(code)
    }

    var skateVerdict: String {
        if isWet { return "Too wet to skate" }
        if windSpeed > 25 { return "Super windy" }
        if temperature < 35 { return "Bundle up" }
        if temperature > 100 { return "Stay hydrated" }
        return "Good to skate"
    }

    var verdictColor: String {
        if isWet { return "red" }
        if windSpeed > 25 { return "orange" }
        if temperature < 35 || temperature > 100 { return "orange" }
        return "green"
    }
}

actor WeatherService {
    static let shared = WeatherService()

    private var cache: [String: (weather: SpotWeather, fetched: Date)] = [:]
    private let cacheLifetime: TimeInterval = 600 // 10 minutes

    func fetchWeather(latitude: Double, longitude: Double) async -> SpotWeather? {
        let key = "\(String(format: "%.2f", latitude)),\(String(format: "%.2f", longitude))"

        if let cached = cache[key], Date().timeIntervalSince(cached.fetched) < cacheLifetime {
            return cached.weather
        }

        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,weathercode,windspeed_10m&temperature_unit=fahrenheit&windspeed_unit=mph"

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let current = json?["current"] as? [String: Any],
                  let temp = current["temperature_2m"] as? Double,
                  let wind = current["windspeed_10m"] as? Double,
                  let code = current["weathercode"] as? Int else { return nil }

            let weather = SpotWeather(temperature: temp, windSpeed: wind, code: code)
            cache[key] = (weather, Date())
            return weather
        } catch {
            // Weather fetch failed
            return nil
        }
    }
}
