//
//  WeatherGradientProvider.swift
//  CWKTemplate24
//
//  Created by Shanel Silva on 2026-01-02.
//

import SwiftUI

/// Provides background gradients based on weather condition.
/// This is UI-only logic (no API / no model responsibility).
struct WeatherGradientProvider {

    static func gradient(for condition: String?) -> LinearGradient {
        switch condition?.lowercased() {
        case "clear":
            return LinearGradient(
                colors: [.blue, .cyan],
                startPoint: .top,
                endPoint: .bottom
            )

        case "clouds":
            return LinearGradient(
                colors: [.gray, .blue.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )

        case "rain", "drizzle":
            return LinearGradient(
                colors: [.indigo, .gray],
                startPoint: .top,
                endPoint: .bottom
            )

        case "thunderstorm":
            return LinearGradient(
                colors: [.black, .purple],
                startPoint: .top,
                endPoint: .bottom
            )

        case "snow":
            return LinearGradient(
                colors: [.white, .blue.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )

        default:
            // Safe fallback (also used before API loads)
            return LinearGradient(
                colors: [.blue, .mint],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
