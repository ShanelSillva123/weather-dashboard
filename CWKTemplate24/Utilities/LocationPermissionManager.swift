//
//  LocationPermissionManager.swift
//  CWKTemplate24
//
//  Created by Shanel Silva on 2026-01-02.
//

import CoreLocation

final class LocationPermissionManager: NSObject, CLLocationManagerDelegate {

    static let shared = LocationPermissionManager()

    private let manager = CLLocationManager()

    private override init() {
        super.init()
        manager.delegate = self
    }

    func request() {
        manager.requestWhenInUseAuthorization()
    }
}
