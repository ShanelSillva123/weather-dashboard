//
//  ForecastWeatherView.swift
//  CWKTemplate24
//
//  Created by girish lukka on 23/10/2024.
//  Fully aligned with ViewModel & gradient provider
//

import SwiftUI

struct ForecastWeatherView: View {

    // MARK: - Environment
    @EnvironmentObject var weatherMapPlaceViewModel: WeatherMapPlaceViewModel

    var body: some View {
        ZStack {

            // MARK: - Dynamic Gradient Background
            WeatherGradientProvider.gradient(
                for: weatherMapPlaceViewModel.currentWeatherMainString
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {

                // MARK: - Chart Section
                DailyWeatherChartView()

                // MARK: - List Section
                if let dailyForecast = weatherMapPlaceViewModel.weatherDataModel?.daily {

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(dailyForecast.prefix(8)) { day in
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
}

#Preview {
    ForecastWeatherView()
        .environmentObject(WeatherMapPlaceViewModel())
}
