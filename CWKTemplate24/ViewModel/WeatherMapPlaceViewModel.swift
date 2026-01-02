//
//  WeatherMapPlaceViewModel.swift
//  CWKTemplate24
//

import Foundation
import CoreLocation
import MapKit
import SwiftData
import SwiftUI

/// Central ViewModel for the whole app.
/// Owns the selected location, weather, POIs, and all user-facing alerts.
/// All tabs observe this as a single source of truth.
@MainActor
final class WeatherMapPlaceViewModel: ObservableObject {

    // MARK: - Published State (Observed by all tabs)

    /// Latest weather payload from One Call 3.0 (current + hourly + daily).
    @Published var weatherDataModel: WeatherDataModel?

    /// Current city name displayed across tabs (default must be London).
    @Published var newLocation: String = "London"

    /// Selected coordinates for the current city (set via geocoding).
    @Published var latitude: Double = 51.5074   // London safe default
    @Published var longitude: Double = -0.1278  // London safe default

    /// Map/list POIs for Place Map tab (top 5 tourist attractions).
    @Published var annotations: [PlaceAnnotationDataModel] = []

    /// Global loading indicator state (optional to show in UI).
    @Published var isLoading: Bool = false

    /// Alert binding fields (views should present these via .alert).
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""

    /// Tab selection so Stored Places can jump back to Now tab.
    /// (If your TabView uses tags 0..3 this works out-of-the-box)
    @Published var selectedTab: Int = 0

    // MARK: - Control Flags
    private var hasLoadedOnce: Bool = false

    // MARK: - Constants
    private let oneCallBaseURL = "https://api.openweathermap.org/data/3.0/onecall"
    private let units = "metric"
    private let poiLimit = 5

    // MARK: - MARKING-SCHEME / UI HELPERS (used by views)

    var currentLocationName: String { newLocation }

    var formattedDate: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: Date())
    }

    var formattedTemperature: String {
        guard let t = weatherDataModel?.current.temp else { return "--°C" }
        return "\(Int(t.rounded()))°C"
    }

    var weatherDescription: String {
        guard let desc = weatherDataModel?.current.weather.first?.weatherDescription.rawValue else {
            return "Loading..."
        }
        return desc.capitalized
    }

    var formattedFeelsLike: String {
        guard let t = weatherDataModel?.current.feelsLike else { return "--°C" }
        return "\(Int(t.rounded()))°C"
    }

    var formattedHumidity: String {
        guard let h = weatherDataModel?.current.humidity else { return "--%" }
        return "\(h)%"
    }

    var formattedWindSpeed: String {
        guard let w = weatherDataModel?.current.windSpeed else { return "-- m/s" }
        return String(format: "%.1f m/s", w)
    }

    var formattedPressure: String {
        guard let p = weatherDataModel?.current.pressure else { return "-- hPa" }
        return "\(p) hPa"
    }

    /// Main weather enum as String (for gradient provider / UI logic)
    var currentWeatherMainString: String? {
        weatherDataModel?.current.weather.first?.main.rawValue
    }
    
    // MARK: - High / Low Temperatures (Today)

    var formattedHighLow: String {
        guard let today = weatherDataModel?.daily.first else {
            return "--°C / --°C"
        }
        let high = Int(today.temp.max.rounded())
        let low = Int(today.temp.min.rounded())
        return "\(high)°C / \(low)°C"
    }

    // MARK: - Sunrise & Sunset

    var formattedSunrise: String {
        guard let sunrise = weatherDataModel?.current.sunrise else { return "--:--" }
        return formatTime(from: sunrise)
    }

    var formattedSunset: String {
        guard let sunset = weatherDataModel?.current.sunset else { return "--:--" }
        return formatTime(from: sunset)
    }

    // MARK: - Time Formatter Helper

    private func formatTime(from unix: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unix))
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }


    /// Icon mapping for the "Now" tab.
    var weatherIconName: String {
        guard let main = weatherDataModel?.current.weather.first?.main else { return "cloud" }
        switch main {
        case .clear: return "sun.max.fill"
        case .clouds: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .drizzle: return "cloud.drizzle.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .snow: return "snow"
        case .mist, .fog, .haze, .smoke, .dust, .sand, .ash:
            return "cloud.fog.fill"
        case .tornado: return "tornado"
        case .squall: return "wind"
        }
    }

    // MARK: - Advisory (ENUM REQUIRED BY RUBRIC)

    enum WeatherAdvisory {
        case perfect
        case caution
        case stayInside

        var message: String {
            switch self {
            case .perfect: return "Perfect weather for a walk!"
            case .caution: return "Take precautions when heading outside."
            case .stayInside: return "Better to stay indoors today."
            }
        }
    }

    var weatherAdvisory: WeatherAdvisory {
        guard let main = weatherDataModel?.current.weather.first?.main else { return .caution }
        switch main {
        case .clear, .clouds:
            return .perfect
        case .rain, .drizzle, .mist, .fog, .haze, .smoke, .dust, .sand, .ash, .squall:
            return .caution
        case .thunderstorm, .snow, .tornado:
            return .stayInside
        }
    }

    // MARK: - Gradient support (NavBarView error mentions currentGradient)

    /// If your NavBarView expects `weatherMapPlaceViewModel.currentGradient` use this.
    var currentGradient: LinearGradient {
        WeatherGradientProvider.gradient(for: currentWeatherMainString)
    }

    // MARK: - Public API expected by NavBarView (FIXES YOUR ERRORS)

    /// Older navbars call this name.
    func loadDefaultLocationIfNeeded(modelContext: ModelContext, apiKey: String) {
        loadDefaultIfNeeded(modelContext: modelContext, apiKey: apiKey)
    }

    /// Newer name you already used.
    func loadDefaultIfNeeded(modelContext: ModelContext, apiKey: String) {
        guard !hasLoadedOnce else { return }
        hasLoadedOnce = true

        Task {
            self.searchAndSyncLocation("London", modelContext: modelContext, apiKey: apiKey)
        }
    }

    /// NavBarView error mentions `searchAndSyncLocation`
    func searchAndSyncLocation(_ city: String, modelContext: ModelContext, apiKey: String) {
        Task { await searchLocation(by: city, modelContext: modelContext, apiKey: apiKey) }
    }

    /// NavBarView error mentions `presentError`
    func presentError(_ message: String, title: String = "Error") {
        presentAlert(title: title, message: message)
    }

    /// Used by Stored Places to jump to Now tab after loading.
    func switchToNowTab() {
        selectedTab = 0
    }

    // MARK: - Core Search (required behaviour)

    /// Unified search used by any tab:
    /// - If location exists in SwiftData: load POIs from storage, fetch weather only.
    /// - If new: fetch weather + POIs, save both, then update all tabs.
    func searchLocation(
        by cityName: String,
        modelContext: ModelContext,
        apiKey: String
    ) async {

        let trimmed = cityName
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // =========================
        // 1️⃣ HARD INPUT VALIDATION
        // =========================

        // Only letters and spaces, min length 3
        let basicPattern = #"^[A-Za-z\s]{3,}$"#
        guard trimmed.range(of: basicPattern, options: .regularExpression) != nil else {
            await handleInvalidLocation(modelContext: modelContext, apiKey: apiKey)
            return
        }

        // Reject short tokens like "col"
        let words = trimmed.split(separator: " ")
        guard words.allSatisfy({ $0.count >= 3 }) else {
            await handleInvalidLocation(modelContext: modelContext, apiKey: apiKey)
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // =========================
            // 2️⃣ GEOCODE
            // =========================
            let placemarks = try await CLGeocoder().geocodeAddressString(trimmed)

            guard let placemark = placemarks.first,
                  let location = placemark.location else {
                await handleInvalidLocation(modelContext: modelContext, apiKey: apiKey)
                return
            }

            let resolvedCity = placemark.locality
            let resolvedCountry = placemark.country

            // =========================
            // 3️⃣ STRICT SEMANTIC MATCH
            // =========================
            // Must EXACTLY match city OR country (case-insensitive)
            let inputLower = trimmed.lowercased()

            let cityMatch = resolvedCity?.lowercased() == inputLower
            let countryMatch = resolvedCountry?.lowercased() == inputLower

            guard cityMatch || countryMatch else {
                await handleInvalidLocation(modelContext: modelContext, apiKey: apiKey)
                return
            }

            let resolvedName = resolvedCity ?? resolvedCountry!
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude

            // =========================
            // 4️⃣ DEDUPE CHECK
            // =========================
            let key = LocationModel.makeDedupeKey(
                name: resolvedName,
                latitude: lat,
                longitude: lon
            )

            if let existing = try fetchStoredLocation(by: key, modelContext: modelContext) {

                newLocation = existing.name
                latitude = existing.latitude
                longitude = existing.longitude

                annotations = existing.pois
                    .prefix(poiLimit)
                    .map { PlaceAnnotationDataModel(from: $0) }

                try await fetchWeatherData(
                    lat: latitude,
                    lon: longitude,
                    apiKey: apiKey
                )

                presentAlert(
                    title: "Location Loaded",
                    message: "\(existing.name) was loaded from saved locations."
                )

                selectedTab = 0
                return
            }

            // =========================
            // 5️⃣ SAVE NEW VALID LOCATION
            // =========================
            newLocation = resolvedName
            latitude = lat
            longitude = lon

            try await fetchWeatherData(lat: lat, lon: lon, apiKey: apiKey)

            let poiAnnotations = try await fetchTouristPOIs(
                lat: lat,
                lon: lon,
                cityName: resolvedName
            )

            annotations = poiAnnotations

            try saveNewLocation(
                name: resolvedName,
                latitude: lat,
                longitude: lon,
                annotations: poiAnnotations,
                modelContext: modelContext
            )

            presentAlert(
                title: "Location Saved",
                message: "\(resolvedName) was saved successfully."
            )

            selectedTab = 0

        } catch {
            await handleInvalidLocation(modelContext: modelContext, apiKey: apiKey)
        }
    }

    
    private func handleInvalidLocation(
        modelContext: ModelContext,
        apiKey: String
    ) async {

        // Revert to London (CW requirement)
        newLocation = "London"
        latitude = 51.5074
        longitude = -0.1278

        try? await fetchWeatherData(
            lat: latitude,
            lon: longitude,
            apiKey: apiKey
        )

        annotations = []

        presentAlert(
            title: "Invalid Location",
            message: "Please enter a valid city or country name."
        )

        selectedTab = 0
    }






    // MARK: - Template scaffold functions (keep, but safe)

    func getCoordinatesForCity() async throws {
        _ = try await geocodeCity(newLocation)
    }

    func fetchWeatherData(lat: Double, lon: Double) async throws {
        throw ViewModelError.misuse("Use fetchWeatherData(lat:lon:apiKey:) which requires an API key.")
    }

    func setAnnotations() async throws {
        _ = try await fetchTouristPOIs(lat: latitude, lon: longitude, cityName: newLocation)
    }

    // MARK: - Private: Geocoding

    private func geocodeCity(_ city: String) async throws -> CLLocationCoordinate2D {

        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)

        // 🔒 HARD BLOCK SHORT INPUTS (FIXES "col", "uk", "us")
        guard trimmed.count >= 4 else {
            throw ViewModelError.invalidLocation
        }

        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(trimmed)

        guard
            let placemark = placemarks.first,
            let coordinate = placemark.location?.coordinate
        else {
            throw ViewModelError.invalidLocation
        }

        return coordinate
    }


    // MARK: - Private: Weather Fetch (One Call 3.0)

    private func fetchWeatherData(lat: Double, lon: Double, apiKey: String) async throws {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ViewModelError.configuration("Missing OpenWeather API key.")
        }

        var components = URLComponents(string: oneCallBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "units", value: units),
            URLQueryItem(name: "appid", value: apiKey)
        ]

        guard let url = components?.url else {
            throw ViewModelError.configuration("Failed to build One Call API URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ViewModelError.network("Invalid server response.")
        }

        switch http.statusCode {
        case 200: break
        case 400: throw ViewModelError.api("Bad request (400).")
        case 401: throw ViewModelError.api("Unauthorized (401). Check your API key.")
        case 404: throw ViewModelError.api("Not found (404).")
        case 429: throw ViewModelError.api("Too many requests (429). Please try again later.")
        case 500...599: throw ViewModelError.api("Server error (\(http.statusCode)). Please try again later.")
        default: throw ViewModelError.api("Unexpected API response (\(http.statusCode)).")
        }

        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(WeatherDataModel.self, from: data)
            self.weatherDataModel = decoded
        } catch {
            throw ViewModelError.decoding("Failed to decode weather data.")
        }
    }

    // MARK: - Private: POI Fetch (MapKit)

    private func fetchTouristPOIs(lat: Double, lon: Double, cityName: String) async throws -> [PlaceAnnotationDataModel] {

        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 8_000, longitudinalMeters: 8_000)

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "tourist attractions"
        request.region = region

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            let items = response.mapItems

            var seen = Set<String>()
            var results: [PlaceAnnotationDataModel] = []

            for item in items {
                guard let name = item.name, !name.isEmpty else { continue }
                let coord = item.placemark.coordinate

                let key = "\(name.lowercased())|\((coord.latitude * 10_000).rounded() / 10_000)|\((coord.longitude * 10_000).rounded() / 10_000)"
                guard !seen.contains(key) else { continue }
                seen.insert(key)

                let subtitle = item.placemark.locality ?? item.placemark.title

                results.append(
                    PlaceAnnotationDataModel(
                        id: UUID(),
                        name: name,
                        latitude: coord.latitude,
                        longitude: coord.longitude,
                        subtitle: subtitle
                    )
                )

                if results.count == poiLimit { break }
            }

            return results
        } catch {
            throw ViewModelError.mapSearch("Failed to fetch tourist places. Please try again.")
        }
    }

    // MARK: - Private: SwiftData Load/Save

    private func fetchStoredLocation(by dedupeKey: String, modelContext: ModelContext) throws -> LocationModel? {
        let descriptor = FetchDescriptor<LocationModel>(
            predicate: #Predicate { $0.dedupeKey == dedupeKey }
        )
        return try modelContext.fetch(descriptor).first
    }

    private func saveNewLocation(
        name: String,
        latitude: Double,
        longitude: Double,
        annotations: [PlaceAnnotationDataModel],
        modelContext: ModelContext
    ) throws {
        let location = LocationModel(name: name, latitude: latitude, longitude: longitude)

        let poiModels: [POIModel] = annotations.map {
            POIModel(
                name: $0.name,
                latitude: $0.latitude,
                longitude: $0.longitude,
                subtitle: $0.subtitle,
                location: location
            )
        }

        location.pois = poiModels

        modelContext.insert(location)
        try modelContext.save()
    }

    // MARK: - Alerts & Error Handling

    private func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }

    private func handleViewModelError(_ error: ViewModelError) {
        switch error {
        case .invalidLocation:
            presentAlert(title: "Invalid Location", message: "Location not found. Please enter a valid city name.")
        case .configuration(let message),
             .network(let message),
             .api(let message),
             .decoding(let message),
             .mapSearch(let message),
             .misuse(let message):
            presentAlert(title: "Error", message: message)
        }
    }
}

// MARK: - ViewModel Error Type

enum ViewModelError: Error {
    case invalidLocation
    case configuration(String)
    case network(String)
    case api(String)
    case decoding(String)
    case mapSearch(String)
    case misuse(String)
}

// MARK: - PlaceAnnotationDataModel helpers (POIModel -> map pins)

extension PlaceAnnotationDataModel {
    init(from poi: POIModel) {
        self.id = UUID()
        self.name = poi.name
        self.latitude = poi.latitude
        self.longitude = poi.longitude
        self.subtitle = poi.subtitle
    }
}

