import SwiftUI
import SwiftData

@main
struct CWKTemplate24App: App {

    // MARK: - SwiftData Container
    private let modelContainer: ModelContainer = {
        do {
            let schema = Schema([
                LocationModel.self,
                POIModel.self
            ])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }()

    // ✅ SINGLE, STABLE INSTANCES (THIS IS THE FIX)
    @StateObject private var weatherMapPlaceViewModel =
        WeatherMapPlaceViewModel()

    @StateObject private var locationSearchCompleter =
        LocationSearchCompleter()

    var body: some Scene {
        
        WindowGroup {
            
            NavBarView()
                .environmentObject(weatherMapPlaceViewModel)
                .environmentObject(locationSearchCompleter)
                .modelContainer(modelContainer)
                .task {
                    // Let SwiftUI finish attaching EnvironmentObjects
                    await Task.yield()

                    LocationPermissionManager.shared.request()

                    let context = ModelContext(modelContainer)
                    await weatherMapPlaceViewModel.loadDefaultLocationIfNeeded(
                        modelContext: context
                    )
                }


        }
    }
}
