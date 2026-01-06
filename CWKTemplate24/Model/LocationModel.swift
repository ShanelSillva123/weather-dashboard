import Foundation
import SwiftData

@Model
final class LocationModel {

    var name: String
    var latitude: Double
    var longitude: Double

    @Attribute(.unique)
    var dedupeKey: String

    @Relationship(deleteRule: .cascade, inverse: \POIModel.location)
    var places: [POIModel]

    init(
        name: String,
        latitude: Double,
        longitude: Double,
        places: [POIModel] = []
    ) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        self.name = trimmed
        self.latitude = latitude
        self.longitude = longitude
        self.dedupeKey = LocationModel.makeDedupeKey(
            name: trimmed,
            latitude: latitude,
            longitude: longitude
        )
        self.places = places
    }

    static func makeDedupeKey(
        name: String,
        latitude: Double,
        longitude: Double
    ) -> String {
        let lat = (latitude * 10_000).rounded() / 10_000
        let lon = (longitude * 10_000).rounded() / 10_000
        return "\(name.lowercased())|\(lat)|\(lon)"
    }
}
