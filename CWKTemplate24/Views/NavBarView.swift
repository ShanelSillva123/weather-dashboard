//
//  NavBarView.swift
//  CWKTemplate24
//
//  Root container view with search + tab navigation
//

import SwiftUI
import SwiftData
import MapKit

struct NavBarView: View {

    // MARK: - Environment
    @EnvironmentObject private var weatherMapPlaceViewModel: WeatherMapPlaceViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var searchCompleter: LocationSearchCompleter

    // MARK: - UI State
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool

    // MARK: - Tab Bar Appearance
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack {

            // MARK: - Dynamic Gradient Background
            WeatherGradientProvider
                .gradient(for: currentWeatherMain)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // =================================================
                // SEARCH BAR + AUTOCOMPLETE
                // =================================================
                ZStack(alignment: .top) {

                    VStack(spacing: 8) {

                        HStack {
                            Text("Change Location")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }

                        HStack(spacing: 10) {

                            TextField("Enter New Location", text: $searchText)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.words)
                                .focused($isSearchFocused)
                                .onChange(of: searchText) { _, newValue in
                                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if trimmed.count >= 3 {
                                        searchCompleter.updateQuery(trimmed)
                                    } else {
                                        searchCompleter.results = []
                                    }
                                }
                                .onSubmit {
                                    submitSearch(searchText)
                                }

                            Button {
                                submitSearch(searchText)
                            } label: {
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.blue.opacity(0.85))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.25))
                    .zIndex(2)

                    // =========================
                    // AUTOCOMPLETE DROPDOWN
                    // =========================
                    if isSearchFocused, !searchCompleter.results.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(searchCompleter.results, id: \.self) { result in
                                Button {
                                    selectSuggestion(result)
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.title)
                                            .foregroundColor(.primary)

                                        if !result.subtitle.isEmpty {
                                            Text(result.subtitle)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                }
                                Divider()
                            }
                        }
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .padding(.top, 96)
                        .zIndex(3)
                    }
                }

                // =========================
                // TAB VIEW
                // =========================
                TabView(selection: $weatherMapPlaceViewModel.selectedTab) {

                    CurrentWeatherView()
                        .tabItem { Label("Now", systemImage: "sun.max.fill") }
                        .tag(0)

                    ForecastWeatherView()
                        .tabItem { Label("8-Day Weather", systemImage: "calendar") }
                        .tag(1)

                    MapView()
                        .tabItem { Label("Place Map", systemImage: "map") }
                        .tag(2)

                    VisitedPlacesView()
                        .tabItem { Label("Stored Places", systemImage: "globe") }
                        .tag(3)
                }
                .allowsHitTesting(!(isSearchFocused && !searchCompleter.results.isEmpty))
            }
        }

        // =========================
        // ALERT
        // =========================
        .alert(
            weatherMapPlaceViewModel.alertTitle,
            isPresented: $weatherMapPlaceViewModel.showAlert
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(weatherMapPlaceViewModel.alertMessage)
        }
    }

    // =========================
    // SEARCH SUBMIT
    // =========================
    private func submitSearch(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSearchFocused = false
        searchCompleter.results = []

        Task {
            await weatherMapPlaceViewModel.searchLocation(
                by: trimmed,
                modelContext: modelContext,
                silent: false
            )
            searchText = ""
        }
    }


    // =========================
    // AUTOCOMPLETE SELECTION
    // =========================
    private func selectSuggestion(_ result: MKLocalSearchCompletion) {
        let query = result.subtitle.isEmpty
            ? result.title
            : "\(result.title), \(result.subtitle)"

        isSearchFocused = false
        searchCompleter.results = []

        Task {
            await weatherMapPlaceViewModel.searchLocation(
                by: query,
                modelContext: modelContext,
                silent: false
            )
            weatherMapPlaceViewModel.selectedTab = 0
            searchText = ""
        }
    }

    private func presentInvalidLocationAlert() {
        weatherMapPlaceViewModel.alertTitle = "Invalid Location"
        weatherMapPlaceViewModel.alertMessage = "Please enter a valid city or country name."
        weatherMapPlaceViewModel.showAlert = true
    }

    // =========================
    // VIEW-DERIVED WEATHER STATE
    // =========================
    private var currentWeatherMain: String {
        weatherMapPlaceViewModel
            .weatherDataModel?
            .current
            .weather
            .first?
            .main
            .rawValue ?? "Clear"
    }
}

#Preview {
    NavBarView()
        .environmentObject(WeatherMapPlaceViewModel())
        .environmentObject(LocationSearchCompleter())
}
