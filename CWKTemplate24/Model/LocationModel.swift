//
//  LocationModel.swift
//  CWKTemplate24
//
//  Created by girish lukka on 23/10/2024.
//


//
//  LocationModel.swift
//  CWKTemplate24
//
//  Created by girish lukka on 23/10/2024.
//
//  LocationModel class to be used with SwiftData
//  Stores user-searched locations for the "Stored Places" tab
//

import Foundation
import SwiftData

/// A stored place/location the user has searched for.
/// Persisted using SwiftData and displayed in the "Stored Places" tab.
@Model
final class LocationModel {

    // MARK: - Stored Properties

    /// Display name of the location (e.g., "London", "Tunis").
    var name: String

    /// Latitude in decimal degrees.
    var latitude: Double

    /// Longitude in decimal degrees.
    var longitude: Double

    /// Stable deduplication key (name + rounded coordinates).
    /// Prevents duplicate locations from being saved.
    @Attribute(.unique)
    var dedupeKey: String

    /// Tourist points of interest for this location.
    /// Cascade delete ensures POIs are removed when the location is deleted.
    @Relationship(deleteRule: .cascade, inverse: \POIModel.location)
    var pois: [POIModel]

    // MARK: - Initializer

    init(
        name: String,
        latitude: Double,
        longitude: Double,
        pois: [POIModel] = []
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        self.name = trimmedName
        self.latitude = latitude
        self.longitude = longitude
        self.dedupeKey = LocationModel.makeDedupeKey(
            name: trimmedName,
            latitude: latitude,
            longitude: longitude
        )
        self.pois = pois
    }

    // MARK: - Computed Properties

    /// Google search URL for long-press behaviour in the Stored Places tab.
    var googleSearchURL: URL {
        let query = name.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? name

        return URL(string: "https://www.google.com/search?q=\(query)")!
    }

    // MARK: - Helpers

    /// Creates a stable, unique key using a normalized name and rounded coordinates.
    /// 4 decimal places ≈ 11m precision — ideal for deduplication.
    static func makeDedupeKey(
        name: String,
        latitude: Double,
        longitude: Double
    ) -> String {

        let normalizedName = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let latRounded = (latitude * 10_000).rounded() / 10_000
        let lonRounded = (longitude * 10_000).rounded() / 10_000

        return "\(normalizedName)|\(latRounded)|\(lonRounded)"
    }
}
