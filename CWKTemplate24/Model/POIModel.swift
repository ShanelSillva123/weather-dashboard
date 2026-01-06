import Foundation
import SwiftData

@Model
final class POIModel {

    var name: String
    var latitude: Double
    var longitude: Double
    var subtitle: String?

    var location: LocationModel?

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
