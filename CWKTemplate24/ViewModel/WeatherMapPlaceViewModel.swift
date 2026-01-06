//
//  WeatherMapPlaceViewModel.swift
//  CWKTemplate24
//
//  Core shared ViewModel for WeatherDashboard
//  Acts as a single source of truth across all tabs
//

import Foundation
import CoreLocation
import MapKit
import SwiftData
import SwiftUI

@MainActor
final class WeatherMapPlaceViewModel: ObservableObject {

    // MARK: - API CONFIGURATION

    private let apiKey = "0ec037a2635a0382dc2627d1e7ada6f5"
    private let oneCallBaseURL = "https://api.openweathermap.org/data/3.0/onecall"
    private let units = "metric"
    private let poiLimit = 5
    private var isInitialStartup = true

    // MARK: - SHARED STATE

    @Published var weatherDataModel: WeatherDataModel?

    @Published var newLocation: String = "London"
    @Published var latitude: Double = 51.5074
    @Published var longitude: Double = -0.1278

    @Published var selectedCoordinate =
        CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)

    @Published var annotations: [PlaceAnnotationDataModel] = []
    @Published var isLoading = false

    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    @Published var selectedTab = 0

    private var hasLoadedOnce = false

    // MARK: - VIEW HELPERS (TAB 1)

    var currentLocationName: String { newLocation }

    var formattedDate: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: Date())
    }
    
    var formattedVisibility: String {
        if let visibility = weatherDataModel?.current.visibility {
            return "\(visibility / 1000) km"
        }
        return "—"
    }

    /// ✅ FIXED: uses `description`
    var weatherDescription: String {
        weatherDataModel?
            .current
            .weather
            .first?
            .description
            .capitalized
        ?? "Loading..."
    }

    var formattedTemperature: String {
        guard let t = weatherDataModel?.current.temp else { return "--°C" }
        return "\(Int(t.rounded()))°C"
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

    var formattedSunrise: String {
        guard let s = weatherDataModel?.current.sunrise else { return "--:--" }
        return formatTime(from: s)
    }

    var formattedSunset: String {
        guard let s = weatherDataModel?.current.sunset else { return "--:--" }
        return formatTime(from: s)
    }

    // MARK: - OPENWEATHER ICON

    var weatherIconURL: URL? {
        guard let icon = weatherDataModel?.current.weather.first?.icon else {
            return nil
        }
        return URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png")
    }

    // MARK: - WEATHER ADVISORY
    struct WeatherRisk {
        let priority: Int
        let reason: String
    }

    enum WeatherAdvisory {
        case perfect
        case caution(reasons: [String])
        case stayInside(reasons: [String])

        var message: String {
            switch self {
            case .perfect:
                return "Perfect weather for outdoor activities."
            case .caution(let reasons),
                 .stayInside(let reasons):
                return reasons.joined(separator: " ")
            }
        }

        var priority: Int {
            switch self {
            case .stayInside: return 3
            case .caution: return 2
            case .perfect: return 1
            }
        }
    }


    var weatherAdvisory: WeatherAdvisory {

        guard let current = weatherDataModel?.current else {
            return .caution(reasons: ["Weather data unavailable. Please try again later."])
        }

        let temp = current.temp
        let wind = current.windSpeed
        let uvi = current.uvi
        let main = current.weather.first?.main ?? .clouds

        var risks: [WeatherRisk] = []

        // Temperature intelligence
        if temp >= 38 {
            risks.append(.init(priority: 3,
                reason: "Extreme heat detected. Stay indoors and hydrated."
            ))
        } else if temp >= 33 {
            risks.append(.init(priority: 2,
                reason: "High temperatures expected. Avoid prolonged sun exposure."
            ))
        } else if temp <= 0 {
            risks.append(.init(priority: 3,
                reason: "Freezing conditions. Outdoor exposure is risky."
            ))
        } else if temp <= 5 {
            risks.append(.init(priority: 2,
                reason: "Very cold weather. Dress warmly if going outside."
            ))
        }

        // Wind intelligence
        if wind >= 18 {
            risks.append(.init(priority: 3,
                reason: "Dangerously strong winds. Remain indoors."
            ))
        } else if wind >= 12 {
            risks.append(.init(priority: 2,
                reason: "Strong winds expected. Secure loose items outdoors."
            ))
        }

        // UV intelligence
        if uvi >= 10 {
            risks.append(.init(priority: 3,
                reason: "Extreme UV levels. Avoid outdoor activity."
            ))
        } else if uvi >= 7 {
            risks.append(.init(priority: 2,
                reason: "High UV levels. Use sunscreen and protective clothing."
            ))
        }

        // Short-term rain prediction (smart use of hourly data)
        if let hourly = weatherDataModel?.hourly.prefix(3),
           hourly.contains(where: { $0.pop > 0.65 }) {
            risks.append(.init(priority: 2,
                reason: "Rain likely soon. Carry an umbrella."
            ))
        }

        // Severe weather intelligence
        switch main {
        case .thunderstorm, .tornado:
            risks.append(.init(priority: 3,
                reason: "Severe weather warning. Stay indoors."
            ))
        case .snow:
            risks.append(.init(priority: 2,
                reason: "Snowy conditions. Travel carefully."
            ))
        case .fog, .mist, .haze:
            risks.append(.init(priority: 2,
                reason: "Low visibility conditions. Take extra care."
            ))
        default:
            break
        }

        // Decision logic
        guard !risks.isEmpty else {
            if (18...30).contains(temp) && wind < 8 && uvi < 6 {
                return .perfect
            }
            return .caution(reasons: ["Conditions are generally good. Stay aware of changes."])
        }

        let maxPriority = risks.map(\.priority).max() ?? 2
        let reasons = risks
            .filter { $0.priority == maxPriority }
            .map(\.reason)

        if maxPriority == 3 {
            return .stayInside(reasons: reasons)
        } else {
            return .caution(reasons: reasons)
        }
    }


    
    var next12HoursTemperature: [HourlyTemperaturePoint] {
        guard let hourly = weatherDataModel?.hourly else { return [] }

        return hourly
            .prefix(12)
            .map {
                HourlyTemperaturePoint(
                    date: Date(timeIntervalSince1970: TimeInterval($0.dt)),
                    temperature: $0.temp
                )
            }
    }

    // MARK: - INITIAL LOAD

    @MainActor
    func loadDefaultLocationIfNeeded(modelContext: ModelContext) {

        guard weatherDataModel == nil else { return }

        print("🟡 loadDefaultLocationIfNeeded called")

        Task {
            // 🔥 Allow network stack to initialise
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s

            print("🟢 Loading default London")

            await applyLocationChange(
                name: "London",
                lat: 51.5074,
                lon: -0.1278,
                modelContext: modelContext,
                silent: false
            )
            isInitialStartup = false
        }
    }



    // MARK: - SEARCH

    func searchLocation(
        by cityName: String,
        modelContext: ModelContext,
        silent: Bool = false
    ) async {

        let trimmed = cityName.trimmingCharacters(in: .whitespacesAndNewlines)

        // ✅ VALIDATION (RESTORED, BUT IN VIEWMODEL)
        let validPattern = #"^[A-Za-z\s]+$"#
        guard !trimmed.isEmpty,
              trimmed.range(of: validPattern, options: .regularExpression) != nil
        else {
            await handleInvalidCity(modelContext: modelContext)
            return
        }

        do {
            let placemark = try await CLGeocoder().geocodeAddressString(trimmed).first

            guard let location = placemark?.location else {
                await handleInvalidCity(modelContext: modelContext)
                return
            }

            let resolvedName =
                placemark?.locality ??
                placemark?.administrativeArea ??
                placemark?.name ??
                trimmed

            await applyLocationChange(
                name: resolvedName,
                lat: location.coordinate.latitude,
                lon: location.coordinate.longitude,
                modelContext: modelContext,
                silent: silent
            )

        } catch {
            await handleInvalidCity(modelContext: modelContext)
        }
    }


    // MARK: - CORE LOCATION LOGIC

    private func applyLocationChange(
        name: String,
        lat: Double,
        lon: Double,
        modelContext: ModelContext?,
        silent: Bool
    ) async {

        print("🟡 applyLocationChange started for \(name)")

        isLoading = true
        defer {
            isLoading = false
            print("🟢 applyLocationChange finished for \(name)")
        }

        do {
            // 1️⃣ Fetch weather FIRST
            try await fetchWeatherData(lat: lat, lon: lon)

            // 2️⃣ Commit location ONLY after success
            newLocation = name
            latitude = lat
            longitude = lon
            selectedCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)

            // If no persistence context, just show weather
            guard let ctx = modelContext else {
                selectedTab = 0
                return
            }

            // CASE 1: Already saved
            if let saved = fetchSavedLocation(lat: lat, lon: lon, modelContext: ctx) {

                annotations = saved.places.map {
                    PlaceAnnotationDataModel(from: $0)
                }

                if !silent || isInitialStartup {
                    presentAlert(
                        title: "Saved Location",
                        message: "\(name) loaded from stored places."
                    )
                }

            }
            // CASE 2: New location
            else {

                let fetchedAnnotations = try await fetchTouristPOIs(lat: lat, lon: lon)
                annotations = fetchedAnnotations

                let poiModels = fetchedAnnotations.map {
                    POIModel(
                        name: $0.name,
                        latitude: $0.latitude,
                        longitude: $0.longitude,
                        subtitle: $0.subtitle
                    )
                }

                let location = LocationModel(
                    name: name,
                    latitude: lat,
                    longitude: lon,
                    places: poiModels
                )

                ctx.insert(location)

                if !silent || isInitialStartup {
                    presentAlert(
                        title: "Location Saved",
                        message: "\(name) has been saved successfully."
                    )
                }
            }

            selectedTab = 0
            isInitialStartup = false

        } catch {
            // 🔁 HARD revert to London on ANY failure
            newLocation = "London"
            latitude = 51.5074
            longitude = -0.1278
            selectedCoordinate = CLLocationCoordinate2D(
                latitude: 51.5074,
                longitude: -0.1278
            )

            selectedTab = 0

            presentAlert(
                title: "Invalid Location",
                message: "Showing London weather instead."
            )
        }
    }


    private func handleInvalidCity(modelContext: ModelContext) async {

        isInitialStartup = false
        selectedTab = 0

        await applyLocationChange(
            name: "London",
            lat: 51.5074,
            lon: -0.1278,
            modelContext: modelContext,
            silent: true
        )

        presentAlert(
            title: "Invalid Location",
            message: "Invalid Location : Showing London weather instead."
        )
    }



    // MARK: - API

    private func fetchWeatherData(lat: Double, lon: Double) async throws {

        let urlString =
        "https://api.openweathermap.org/data/3.0/onecall?lat=\(lat)&lon=\(lon)&units=metric&appid=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        print("🌍 Request URL:", url.absoluteString)

        let (data, response) = try await URLSession.shared.data(from: url)

        // ✅ LOG RESPONSE
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        print("📡 Status Code:", httpResponse.statusCode)
        print("📦 Data Size:", data.count)

        // 🚨 THIS IS WHAT WAS MISSING
        guard !data.isEmpty else {
            print("❌ Empty response body")
            throw URLError(.zeroByteResource)
        }

        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP Error:", httpResponse.statusCode)
            throw URLError(.badServerResponse)
        }

        do {
            let decoded = try JSONDecoder().decode(
                WeatherDataModel.self,
                from: data
            )
            self.weatherDataModel = decoded
            print("✅ Weather decoded successfully")
        } catch {
            print("❌ Decoding error:", error)
            throw error
        }
    }


    // MARK: - MAPKIT POIs

    private func fetchTouristPOIs(
        lat: Double,
        lon: Double
    ) async throws -> [PlaceAnnotationDataModel] {

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            latitudinalMeters: 8_000,
            longitudinalMeters: 8_000
        )

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "tourist attractions"
        request.region = region

        let response = try await MKLocalSearch(request: request).start()

        return response.mapItems
            .prefix(poiLimit)
            .filter { $0.name != nil }   // ✅ NO nils allowed past this point
            .map { item in
                let coordinate = item.placemark.coordinate

                return PlaceAnnotationDataModel(
                    id: UUID(),
                    name: item.name!,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    subtitle: item.placemark.locality
                )
            }
    }



    // MARK: - SWIFTDATA HELPERS

    private func fetchSavedLocation(
        lat: Double,
        lon: Double,
        modelContext: ModelContext
    ) -> LocationModel? {

        let fetch = FetchDescriptor<LocationModel>()
        guard let saved = try? modelContext.fetch(fetch) else { return nil }

        return saved.first {
            abs($0.latitude - lat) < 0.0001 &&
            abs($0.longitude - lon) < 0.0001
        }
    }

    // MARK: - UTILITIES

    private func formatTime(from unix: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unix))
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - ERRORS

enum ViewModelError: Error {
    case api(String)
}
