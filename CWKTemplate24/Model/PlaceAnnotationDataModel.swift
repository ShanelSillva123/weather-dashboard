//
//  PlaceAnnotationDataModel.swift
//  CWKTemplate24
//
//  Created by girish lukka on 23/10/2024.
//

//
//  PlaceAnnotationDataModel.swift
//  CWKTemplate24
//

import Foundation
import CoreLocation

/* Code  to manage tourist place map pins */

struct PlaceAnnotationDataModel: Identifiable, Hashable {

    // MARK: - Attributes to map pins

    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var subtitle: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Google search URL for long-press behaviour in map/list.
    var googleSearchURL: URL? {
        let query = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        return URL(string: "https://www.google.com/search?q=\(query)")
    }
}
