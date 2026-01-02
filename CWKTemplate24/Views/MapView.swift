//
//  MapView.swift
//  CWKTemplate24
//
//  Created by girish lukka on 23/10/2024.
//

//
//  MapView.swift
//  CWKTemplate24
//
//  Tab 3: "Place Map"
//  - Top: Interactive map with 5 pins (tourist attractions)
//  - Bottom: Scrollable list of same places
//  - Tap list item: center map on that pin
//  - Tap pin: zoom OUT to show ~500m region around it
//  - Long press pin: open Google search for the place
//

import SwiftUI
import MapKit

struct MapView: View {

    // MARK: - Environment
    @EnvironmentObject var weatherMapPlaceViewModel: WeatherMapPlaceViewModel

    // MARK: - Map State
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), // London default
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )

    @State private var selectedPlaceID: UUID?
    @State private var showPinActionSheet: Bool = false
    @State private var pendingSearchURL: URL?

    var body: some View {
        ZStack {
            // Gradient background (required: LinearGradient; dynamic is fine)
            WeatherGradientProvider.gradient(
                for: weatherMapPlaceViewModel.currentWeatherMainString
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {

                // MARK: - Map (Top)
                mapSection
                    .frame(height: 330)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal)

                // MARK: - POI List (Bottom)
                listSection
            }
            .padding(.top)
        }
        .confirmationDialog(
            "Search on Google?",
            isPresented: $showPinActionSheet,
            titleVisibility: .visible
        ) {
            Button("Open Google Search") {
                if let url = pendingSearchURL {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will open your browser.")
        }
        .onAppear {
            // Keep map aligned with current location on launch
            recenterToCurrentCity()
        }
        .onChange(of: weatherMapPlaceViewModel.latitude) { _, _ in
            // When location changes, center map on new city
            recenterToCurrentCity()
        }
        .onChange(of: weatherMapPlaceViewModel.longitude) { _, _ in
            recenterToCurrentCity()
        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        Map(position: $cameraPosition) {
            // City center marker is optional; pins are required
            ForEach(weatherMapPlaceViewModel.annotations) { place in
                Annotation(place.name, coordinate: place.coordinate) {
                    pinView(for: place)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }

    // MARK: - Pin View (Tap + Long Press)

    private func pinView(for place: PlaceAnnotationDataModel) -> some View {
        VStack(spacing: 2) {
            Image(systemName: selectedPlaceID == place.id
                  ? "mappin.circle.fill"
                  : "mappin.circle")
                .font(.title)
                .foregroundColor(.red)

            Text(place.name)
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .lineLimit(1)
                .frame(maxWidth: 140)
        }
        .onTapGesture {
            // REQUIRED: tap zooms out to 500m region
            selectedPlaceID = place.id
            zoomOutAround(place: place, meters: 500)
        }
        .contextMenu {
            Button {
                if let url = place.googleSearchURL {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Search on Google", systemImage: "magnifyingglass")
            }
        }
    }

    // MARK: - List Section

    private var listSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top Tourist Places")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            if weatherMapPlaceViewModel.annotations.isEmpty {
                Text("Places unavailable. Search a location to load attractions.")
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal)
                    .padding(.bottom, 12)

                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(weatherMapPlaceViewModel.annotations) { place in
                            placeRow(place)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
    }

    private func placeRow(_ place: PlaceAnnotationDataModel) -> some View {
        Button {
            // Requirement: tapping list item centers the map on that pin
            selectedPlaceID = place.id
            centerMap(on: place)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let subtitle = place.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "location.fill")
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Map Helpers

    private func recenterToCurrentCity() {
        let center = CLLocationCoordinate2D(
            latitude: weatherMapPlaceViewModel.latitude,
            longitude: weatherMapPlaceViewModel.longitude
        )
        cameraPosition = .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        )
    }

    private func centerMap(on place: PlaceAnnotationDataModel) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: place.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            )
        )
    }

    private func zoomOutAround(place: PlaceAnnotationDataModel, meters: CLLocationDistance) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: place.coordinate,
                latitudinalMeters: meters,
                longitudinalMeters: meters
            )
        )
    }
}
