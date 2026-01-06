//
//  ForecastWeatherView.swift
//  CWKTemplate24
//
//  Displays multi-day weather forecast
//

import SwiftUI

struct ForecastWeatherView: View {

    // MARK: - Environment
    @EnvironmentObject var weatherMapPlaceViewModel: WeatherMapPlaceViewModel

    var body: some View {
        ZStack {

            // MARK: - Dynamic Gradient Background
            WeatherGradientProvider.gradient(
                for: currentWeatherMain
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {

                // MARK: - Chart Section
                DailyWeatherChartView()

                // MARK: - Forecast List
                if let dailyForecast = weatherMapPlaceViewModel.weatherDataModel?.daily {

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(dailyForecast.prefix(8), id: \.dt) { day in
                                DailyWeatherRowView(day: day)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }

                } else {
                    Spacer()
                    Text("Forecast data unavailable.")
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                }
            }
            .padding(.top)
        }
    }

    // MARK: - View-derived Weather State (Safe)
    private var currentWeatherMain: String {
        weatherMapPlaceViewModel
            .weatherDataModel?
            .current
            .weather
            .first?
            .main
            .rawValue ?? "Clear"
    }
}

#Preview {
    ForecastWeatherView()
        .environmentObject(WeatherMapPlaceViewModel())
}
