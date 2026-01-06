//
//  CurrentWeatherView.swift
//  CWKTemplate24
//
//  Tab 1: "Now"
//  Displays current weather, key metrics, icons, advisory message,
//  and hourly temperature graph
//

import SwiftUI

struct CurrentWeatherView: View {

    // MARK: - Environment
    @EnvironmentObject var weatherMapPlaceViewModel: WeatherMapPlaceViewModel

    var body: some View {
        ZStack {

            // MARK: - Dynamic Gradient Background
            WeatherGradientProvider.gradient(
                for: currentWeatherMain
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {

                    // MARK: - Location & Date
                    VStack(spacing: 6) {
                        Text(weatherMapPlaceViewModel.newLocation)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text(weatherMapPlaceViewModel.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    // MARK: - Main Weather Icon & Temperature
                    VStack(spacing: 10) {

                        if let iconURL = weatherMapPlaceViewModel.weatherIconURL {
                            AsyncImage(url: iconURL) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                            .frame(width: 90, height: 90)
                        }

                        Text(weatherMapPlaceViewModel.formattedTemperature)
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(.white)

                        Text(weatherMapPlaceViewModel.weatherDescription)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))

                        // MARK: - High / Low Temperatures
                        HStack(spacing: 24) {

                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up")
                                Text(highTemperature)
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down")
                                Text(lowTemperature)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    }

                    // =================================================
                    // ⏱️ HOURLY TEMPERATURE GRAPH (NEXT 12 HOURS)
                    // =================================================
                    HourlyTemperatureChartView()
                        .padding(.horizontal)
                        .padding(.top, 4)

                    // MARK: - Advisory Message
                    Text(weatherMapPlaceViewModel.weatherAdvisory.message)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .foregroundColor(.white)

                    // MARK: - Sunrise / Sunset
                    HStack(spacing: 36) {

                        VStack(spacing: 6) {
                            Image(systemName: "sunrise.fill")
                            Text("Sunrise")
                                .font(.caption)
                            Text(weatherMapPlaceViewModel.formattedSunrise)
                                .fontWeight(.semibold)
                        }

                        VStack(spacing: 6) {
                            Image(systemName: "sunset.fill")
                            Text("Sunset")
                                .font(.caption)
                            Text(weatherMapPlaceViewModel.formattedSunset)
                                .fontWeight(.semibold)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))

                    // MARK: - Key Metrics Grid
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 16
                    ) {

                        WeatherMetricView(
                            title: "Feels Like",
                            value: weatherMapPlaceViewModel.formattedFeelsLike,
                            systemImage: "thermometer"
                        )

                        WeatherMetricView(
                            title: "Humidity",
                            value: weatherMapPlaceViewModel.formattedHumidity,
                            systemImage: "drop.fill"
                        )

                        WeatherMetricView(
                            title: "Wind",
                            value: weatherMapPlaceViewModel.formattedWindSpeed,
                            systemImage: "wind"
                        )

                        WeatherMetricView(
                            title: "Pressure",
                            value: weatherMapPlaceViewModel.formattedPressure,
                            systemImage: "gauge"
                        )
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Derived Values (View-safe)

    private var currentWeatherMain: String {
        weatherMapPlaceViewModel
            .weatherDataModel?
            .current
            .weather
            .first?
            .main
            .rawValue ?? "Clear"
    }

    private var highTemperature: String {
        guard let max = weatherMapPlaceViewModel.weatherDataModel?.daily.first?.temp.max else {
            return "--°C"
        }
        return "\(Int(max.rounded()))°C"
    }

    private var lowTemperature: String {
        guard let min = weatherMapPlaceViewModel.weatherDataModel?.daily.first?.temp.min else {
            return "--°C"
        }
        return "\(Int(min.rounded()))°C"
    }
}

#Preview {
    CurrentWeatherView()
        .environmentObject(WeatherMapPlaceViewModel())
}
