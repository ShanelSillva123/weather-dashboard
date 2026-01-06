//
//  DailyWeatherRowView.swift
//  CWKTemplate24
//
//  Displays a single day's forecast in the "Forecast" tab
//  Uses OpenWeather icons for consistency and realism
//

import SwiftUI

struct DailyWeatherRowView: View {

    let day: Daily

    var body: some View {
        HStack(spacing: 16) {

            // MARK: - Day & Description
            VStack(alignment: .leading, spacing: 4) {

                Text(
                    DateFormatterUtils.formattedDateWithWeekdayAndDay(
                        from: TimeInterval(day.dt)
                    )
                )
                .font(.headline)
                .foregroundColor(.white)

                Text(
                    day.weather.first?.description.capitalized ?? ""
                )
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            // MARK: - OpenWeather Icon
            if let iconURL = openWeatherIconURL {
                AsyncImage(url: iconURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                .frame(width: 40, height: 40)
            }

            // MARK: - Min / Max Temperatures
            VStack(alignment: .trailing, spacing: 2) {

                Text("H: \(Int(day.temp.max.rounded()))°")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("L: \(Int(day.temp.min.rounded()))°")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .padding()
        .background(Color.white.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - OpenWeather Icon URL

    private var openWeatherIconURL: URL? {
        guard let icon = day.weather.first?.icon else { return nil }
        return URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png")
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
            summary: nil,
            temp: Temp(
                day: 20,
                min: 12,
                max: 24,
                night: 14,
                eve: 18,
                morn: 13
            ),
            feelsLike: FeelsLike(
                day: 20,
                night: 14,
                eve: 18,
                morn: 13
            ),
            pressure: 1012,
            humidity: 60,
            dewPoint: 10,
            windSpeed: 5,
            windDeg: 120,
            windGust: 7,
            weather: [
                Weather(
                    id: 800,
                    main: .clear,
                    description: "clear sky",
                    icon: "01d"
                )
            ],
            clouds: 10,
            pop: 0.1,
            rain: nil,
            snow: nil,
            uvi: 6
        )
    )
}
