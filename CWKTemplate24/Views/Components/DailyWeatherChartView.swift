//
//  DailyWeatherChartView.swift
//  CWKTemplate24
//
//  Displays an 8-day temperature range chart (min → max)
//  Apple-style, clean, and coursework-ready
//

import SwiftUI
import Charts

struct DailyWeatherChartView: View {

    @EnvironmentObject private var weatherMapPlaceViewModel: WeatherMapPlaceViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // MARK: - Title
            Text("8-Day Temperature Forecast")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            if let dailyForecast = weatherMapPlaceViewModel.weatherDataModel?.daily {

                Chart {
                    ForEach(dailyForecast.prefix(8), id: \.dt) { day in

                        BarMark(
                            x: .value(
                                "Day",
                                shortDay(from: day.dt)
                            ),
                            yStart: .value("Min Temp", day.temp.min),
                            yEnd: .value("Max Temp", day.temp.max)
                        )
                        .cornerRadius(6)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.7),
                                    Color.orange.opacity(0.85)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.15))
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .chartXAxis {
                    AxisMarks {
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .frame(height: 220)
                .padding(.horizontal)

            } else {
                Text("Weather forecast unavailable")
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.vertical)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func shortDay(from unix: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unix))
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

#Preview {
    DailyWeatherChartView()
        .environmentObject(WeatherMapPlaceViewModel())
}
