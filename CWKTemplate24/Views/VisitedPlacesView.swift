//
//  VisitedPlacesView.swift
//  CWKTemplate24
//
//  Tab 4: Stored Places
//

import SwiftUI
import SwiftData

struct VisitedPlacesView: View {

    // MARK: - SwiftData
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LocationModel.name) private var savedLocations: [LocationModel]

    // MARK: - Environment
    @EnvironmentObject private var weatherMapPlaceViewModel: WeatherMapPlaceViewModel
    @Environment(\.openURL) private var openURL

    // MARK: - UI State
    @State private var googleSearchURL: URL?

    var body: some View {
        ZStack {

            // MARK: - Dynamic Background
            WeatherGradientProvider
                .gradient(for: currentWeatherMain)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {

                // MARK: - Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Visited Places")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("Tap to load • Long-press for options")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.horizontal)

                // MARK: - Content
                if savedLocations.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(savedLocations) { location in
                            locationRow(location)
                                .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deleteLocation)
                    }
                    .listStyle(.plain)
                }
            }
            .padding(.top)
        }

        // MARK: - Google Search Dialog
        .confirmationDialog(
            "Search on Google?",
            isPresented: Binding(
                get: { googleSearchURL != nil },
                set: { if !$0 { googleSearchURL = nil } }
            )
        ) {
            Button("Open Google Search") {
                if let url = googleSearchURL {
                    openURL(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "map")
                .font(.system(size: 42))
                .foregroundColor(.white.opacity(0.9))

            Text("No saved locations")
                .font(.headline)
                .foregroundColor(.white)

            Text("Search for a city to save it here.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }

    // MARK: - Row
    private func locationRow(_ location: LocationModel) -> some View {
        Button {
            loadLocation(location)
        } label: {
            HStack(spacing: 14) {

                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.25))
                        .frame(width: 44, height: 44)

                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.headline)

                    Text(
                        String(
                            format: "Lat %.4f • Lon %.4f",
                            location.latitude,
                            location.longitude
                        )
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                googleSearchURL = googleURL(for: location)
            } label: {
                Label("Search on Google", systemImage: "magnifyingglass")
            }
        }
    }

    // MARK: - Actions

    private func loadLocation(_ location: LocationModel) {
        Task {
            await weatherMapPlaceViewModel.searchLocation(
                by: location.name,
                modelContext: modelContext,
                silent: false
            )
        }
    }

    private func deleteLocation(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(savedLocations[index])
        }
    }

    // MARK: - Helpers

    private func googleURL(for location: LocationModel) -> URL {
        let query = location.name.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? location.name

        return URL(string: "https://www.google.com/search?q=\(query)")!
    }

    // MARK: - View-derived weather state
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
