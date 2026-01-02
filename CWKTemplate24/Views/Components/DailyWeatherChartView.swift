//
//  DailyWeatherChartView.swift
//  CWKTemplate24
//
//  Created by Shanel Silva on 2026-01-02.
//

import SwiftUI
import Charts

struct DailyWeatherChartView: View {

    @EnvironmentObject var weatherMapPlaceViewModel: WeatherMapPlaceViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("8-Day Temperature Forecast")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.leading)

            if let dailyForecast = weatherMapPlaceViewModel.weatherDataModel?.daily {

                Chart {
                    ForEach(dailyForecast.prefix(8)) { day in

                        // High temperature bar
                        BarMark(
                            x: .value(
                                "Day",
                                DateFormatterUtils.formattedDateWithWeekdayAndDay(
                                    from: TimeInterval(day.dt)
                                )
                            ),
                            y: .value("Max Temp", day.temp.max)
                        )
                        .foregroundStyle(.red.opacity(0.8))

                        // Low temperature bar
                        BarMark(
                            x: .value(
                                "Day",
                                DateFormatterUtils.formattedDateWithWeekdayAndDay(
                                    from: TimeInterval(day.dt)
                                )
                            ),
                            y: .value("Min Temp", day.temp.min)
                        )
                        .foregroundStyle(.blue.opacity(0.8))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .frame(height: 220)
                .padding(.horizontal)

            } else {
                Text("Weather forecast unavailable.")
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.vertical)
    }
}

#Preview {
    DailyWeatherChartView()
        .environmentObject(WeatherMapPlaceViewModel())
}
