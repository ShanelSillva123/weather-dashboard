//
//  WeatherMetricView.swift
//  CWKTemplate24
//
//  Created by Shanel Silva on 2026-01-02.
//

import SwiftUI

struct WeatherMetricView: View {

    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))

            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
