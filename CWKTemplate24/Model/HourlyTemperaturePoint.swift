//
//  HourlyTemperaturePoint.swift
//  CWKTemplate24
//
//  Created by Shanel Silva on 2026-01-06.
//

import Foundation

struct HourlyTemperaturePoint: Identifiable {
    let id = UUID()
    let date: Date
    let temperature: Double
}
