//
//  POIModel.swift
//  CWKTemplate24
//
//  Created by Shanel Silva on 2026-01-02.
//

//
//  POIModel.swift
//  CWKTemplate24
//
//  SwiftData model for tourist Points of Interest (POIs) saved per location.
//

import Foundation
import SwiftData

/// A tourist attraction/POI associated with a stored location.
@Model
final class POIModel {

    // MARK: - Stored Properties

    /// The name/title of the POI (e.g., "Eiffel Tower").
    var name: String

    /// Latitude in decimal degrees.
    var latitude: Double

    /// Longitude in decimal degrees.
    var longitude: Double

    /// Optional subtitle/extra info (e.g., locality, category).
    var subtitle: String?

    /// Parent location relationship.
    var location: LocationModel?

    // MARK: - Initializer

    init(
        name: String,
        latitude: Double,
        longitude: Double,
        subtitle: String? = nil,
        location: LocationModel? = nil
    ) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.latitude = latitude
        self.longitude = longitude
        self.subtitle = subtitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.location = location
    }
}
