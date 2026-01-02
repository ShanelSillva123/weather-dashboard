import SwiftUI
import SwiftData
import MapKit

struct NavBarView: View {

    // MARK: - Environment
    @EnvironmentObject private var weatherMapPlaceViewModel: WeatherMapPlaceViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var searchCompleter: LocationSearchCompleter

    // MARK: - API Key
    private let apiKey = "d484edb87e7d9cc561818f19c3e1d833"

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

            // Background
            WeatherGradientProvider
                .gradient(for: weatherMapPlaceViewModel.currentWeatherMainString)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // =================================================
                // SEARCH BAR + DROPDOWN (SAME ZSTACK – THIS IS KEY)
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

                            // BLUE ARROW (kept)
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

                    // 🔽 AUTOCOMPLETE DROPDOWN (NOW VISIBLE)
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
        .alert(
            weatherMapPlaceViewModel.alertTitle,
            isPresented: $weatherMapPlaceViewModel.showAlert
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(weatherMapPlaceViewModel.alertMessage)
        }
        .onAppear {
            weatherMapPlaceViewModel.loadDefaultIfNeeded(
                modelContext: modelContext,
                apiKey: apiKey
            )
        }
    }

    // =========================
    // SEARCH SUBMIT
    // =========================
    private func submitSearch(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 3 else {
            weatherMapPlaceViewModel.presentError(
                "Please enter a full city name.",
                title: "Invalid Location"
            )
            return
        }

        isSearchFocused = false
        searchCompleter.results = []

        Task {
            await weatherMapPlaceViewModel.searchLocation(
                by: trimmed,
                modelContext: modelContext,
                apiKey: apiKey
            )
            weatherMapPlaceViewModel.selectedTab = 0
            searchText = ""
        }
    }

    // =========================
    // SUGGESTION SELECT
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
                apiKey: apiKey
            )
            weatherMapPlaceViewModel.selectedTab = 0
            searchText = ""
        }
    }
}

#Preview {
    NavBarView()
        .environmentObject(WeatherMapPlaceViewModel())
        .environmentObject(LocationSearchCompleter())
}

