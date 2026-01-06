//
//  HourlyTemperatureChartView.swift
//  CWKTemplate24
//
//  Created by Shanel Silva on 2026-01-06.
//

//
//  HourlyTemperatureChartView.swift
//  CWKTemplate24
//
//  Displays temperature vs time for the next 12 hours
//

import SwiftUI
import Charts

struct HourlyTemperatureChartView: View {

    @EnvironmentObject var weatherMapPlaceViewModel: WeatherMapPlaceViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Next 12 Hours")
                .font(.headline)
                .foregroundColor(.white)

            if let hourlyData = weatherMapPlaceViewModel.weatherDataModel?.hourly {

                Chart(hourlyData.prefix(12), id: \.dt) { hour in
                    LineMark(
                        x: .value("Time", date(from: hour.dt)),
                        y: .value("Temperature", hour.temp)
                    )
                    .foregroundStyle(.white)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Time", date(from: hour.dt)),
                        y: .value("Temperature", hour.temp)
                    )
                    .foregroundStyle(.white)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 3)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 180)

            } else {
                Text("Hourly data unavailable")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helper

    private func date(from unix: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(unix))
    }
}

#Preview {
    HourlyTemperatureChartView()
        .environmentObject(WeatherMapPlaceViewModel())
}
