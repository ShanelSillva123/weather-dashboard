//
//  CWKTemplate24App.swift
//  CWKTemplate24
//
//  Created by girish lukka on 23/10/2024.
//

//
//  CWKTemplate24App.swift
//  CWKTemplate24
//

import SwiftUI
import SwiftData

@main
struct CWKTemplate24App: App {

    // MARK: - SwiftData Container

    /// Shared SwiftData container for the entire app.
    /// Includes LocationModel and POIModel as required by the coursework.
    private let modelContainer: ModelContainer = {
        do {
            let schema = Schema([
                LocationModel.self,
                POIModel.self
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }()

    // MARK: - Global ViewModel

    /// Single shared ViewModel to keep all tabs in sync.
    @StateObject private var weatherMapPlaceViewModel = WeatherMapPlaceViewModel()
    @StateObject private var locationSearchCompleter = LocationSearchCompleter()

    var body: some Scene {
        WindowGroup {
            NavBarView()
                .task {
                    LocationPermissionManager.shared.request()
                }
                .environmentObject(weatherMapPlaceViewModel)
                .environmentObject(locationSearchCompleter)
                .modelContainer(modelContainer)
                
        }
    }
}
