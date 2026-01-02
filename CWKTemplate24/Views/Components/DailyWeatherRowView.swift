//
//  DailyWeatherRowView.swift
//  CWKTemplate24
//
//  Created by Shanel Silva on 2026-01-02.
//

import SwiftUI

struct DailyWeatherRowView: View {

    let day: Daily

    var body: some View {
        HStack(spacing: 16) {

            // Day & Date
            VStack(alignment: .leading, spacing: 4) {
                Text(
                    DateFormatterUtils.formattedDateWithWeekdayAndDay(
                        from: TimeInterval(day.dt)
                    )
                )
                .font(.headline)
                .foregroundColor(.white)

                Text(day.weather.first?.weatherDescription.rawValue.capitalized ?? "")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            // Weather icon
            Image(systemName: weatherIconName)
                .font(.title2)
                .foregroundColor(.white)

            // Min / Max temperatures
            VStack(alignment: .trailing) {
                Text("H: \(Int(day.temp.max))°")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("L: \(Int(day.temp.min))°")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Weather Icon Mapping
    private var weatherIconName: String {
        switch day.weather.first?.main {
        case .clear:
            return "sun.max.fill"
        case .clouds:
            return "cloud.fill"
        case .rain, .drizzle:
            return "cloud.rain.fill"
        case .thunderstorm:
            return "cloud.bolt.fill"
        case .snow:
            return "snowflake"
        case .mist, .fog, .haze:
            return "cloud.fog.fill"
        default:
            return "questionmark"
        }
    }
}

#Preview {
    DailyWeatherRowView(
        day: Daily(
            dt: Int(Date().timeIntervalSince1970),
            sunrise: 0,
            sunset: 0,
            moonrise: 0,
            moonset: 0,
            moonPhase: 0.5,
            temp: Temp(day: 20, min: 12, max: 24, night: 14, eve: 18, morn: 13),
            feelsLike: FeelsLike(day: 20, night: 14, eve: 18, morn: 13),
            pressure: 1012,
            humidity: 60,
            dewPoint: 10,
            windSpeed: 5,
            windDeg: 120,
            windGust: 7,
            weather: [
                Weather(id: 800, main: .clear, weatherDescription: .clearSky, icon: "01d")
            ],
            clouds: 10,
            pop: 0.1,
            rain: nil,
            uvi: 6
        )
    )
}
