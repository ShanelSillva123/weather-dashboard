//
//  LocationSearchCompleter.swift
//  CWKTemplate24
//
//  Created by Shanel Silva on 2026-01-02.
//


import Foundation
import MapKit

@MainActor
final class LocationSearchCompleter: NSObject, ObservableObject {

    @Published var results: [MKLocalSearchCompletion] = []

    private let completer: MKLocalSearchCompleter

    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()

        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]

        // IMPORTANT: give it a wide region
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
        )

        print("LocationSearchCompleter initialised")
    }

    func updateQuery(_ text: String) {
        print("Query set:", text)
        completer.queryFragment = text
    }
}

extension LocationSearchCompleter: MKLocalSearchCompleterDelegate {

    func completer(
        _ completer: MKLocalSearchCompleter,
        didUpdateResults results: [MKLocalSearchCompletion]
    ) {
        print("Results received:", results.count)

        self.results = Array(results.prefix(5))
    }

    func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: Error
    ) {
        print("Completer error:", error.localizedDescription)
        self.results = []
    }
}
