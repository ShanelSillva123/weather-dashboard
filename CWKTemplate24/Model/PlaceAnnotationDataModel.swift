//
//  PlaceAnnotationDataModel.swift
//  CWKTemplate24
//

import Foundation
import CoreLocation

struct PlaceAnnotationDataModel: Identifiable, Hashable {

    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let subtitle: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var googleSearchURL: URL {
        let query = name.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? name
        return URL(string: "https://www.google.com/search?q=\(query)")!
    }

    init(
        id: UUID,
        name: String,
        latitude: Double,
        longitude: Double,
        subtitle: String? = nil
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.subtitle = subtitle
    }
}

// MARK: - SwiftData → View Mapping (Deterministic UUID)

extension PlaceAnnotationDataModel {

    init(from poi: POIModel) {

        let stableKey =
            "\(poi.name.lowercased())|\(poi.latitude)|\(poi.longitude)"

        let stableID = UUID(
            uuidString: UUIDGenerator.uuidString(from: stableKey)
        ) ?? UUID()

        self.init(
            id: stableID,
            name: poi.name,
            latitude: poi.latitude,
            longitude: poi.longitude,
            subtitle: poi.subtitle
        )
    }
}

// MARK: - Deterministic UUID Generator

enum UUIDGenerator {

    /// Generates a deterministic UUID string from a given value.
    static func uuidString(from value: String) -> String {

        let data = Data(value.utf8)
        let hash = data.reduce(0) { ($0 &* 31) &+ Int($1) }

        let hex = String(format: "%032x", hash)

        return "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-\(hex.dropFirst(12).prefix(4))-\(hex.dropFirst(16).prefix(4))-\(hex.dropFirst(20))"
    }
}
