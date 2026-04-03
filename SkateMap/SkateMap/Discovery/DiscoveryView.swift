//
//  DiscoveryView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/31/26.
//

import SwiftUI

// MARK: - Curated Collection Model

struct CuratedCollection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let pins: [PinInfo]
}

// MARK: - Discovery View

struct DiscoveryView: View {
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject var locationManager: LocationManager

    @State private var selectedPin: PinInfo?
    @State private var selectedCollection: CuratedCollection?
    @Namespace private var pinTransition

    // MARK: - Data

    var spotOfTheDay: PinInfo? {
        let pins = viewModel.pins
        guard !pins.isEmpty else { return nil }
        let daysSinceEpoch = Calendar.current.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: Date()).day ?? 0
        let sorted = pins.sorted { ($0.id ?? "") < ($1.id ?? "") }
        return sorted[daysSinceEpoch % sorted.count]
    }

    private let maxDistanceMeters: Double = 25 * 1609.34 // 25 miles

    var nearMeSpots: [PinInfo] {
        guard locationManager.userLocation != nil else { return [] }
        return viewModel.pins
            .compactMap { pin -> (PinInfo, Double)? in
                guard let dist = locationManager.distance(to: pin.coordinate),
                      dist <= maxDistanceMeters else { return nil }
                return (pin, dist)
            }
            .sorted { $0.1 < $1.1 }
            .prefix(15)
            .map { $0.0 }
    }

    var newSpots: [PinInfo] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        return viewModel.pins
            .filter { $0.time >= cutoff }
            .sorted { $0.time > $1.time }
    }

    var trendingSpots: [PinInfo] {
        Array(
            viewModel.pins
                .filter { !$0.ratings.isEmpty }
                .sorted { a, b in
                    let scoreA = Double(a.ratings.count) * a.averageRating
                    let scoreB = Double(b.ratings.count) * b.averageRating
                    return scoreA > scoreB
                }
                .prefix(10)
        )
    }

    var curatedCollections: [CuratedCollection] {
        let allPins = viewModel.pins
        var collections: [CuratedCollection] = []

        // Best Rails
        let bestRails = allPins.filter { $0.spotTypes.contains(.rail) }
            .sorted { $0.averageRating > $1.averageRating }
        if !bestRails.isEmpty {
            collections.append(CuratedCollection(title: "Best Rails", subtitle: "\(bestRails.count) spots", icon: "minus.rectangle", pins: bestRails))
        }

        // Mellow Spots — low risk, well rated
        let mellowSpots = allPins.filter { $0.riskLevel == .low && $0.averageRating >= 3.0 }
            .sorted { $0.averageRating > $1.averageRating }
        if !mellowSpots.isEmpty {
            collections.append(CuratedCollection(title: "Mellow Spots", subtitle: "Low risk, high vibes", icon: "shield.checkered", pins: mellowSpots))
        }

        // Stair Sets
        let stairSets = allPins.filter { $0.spotTypes.contains(.stairs) }
            .sorted { $0.averageRating > $1.averageRating }
        if !stairSets.isEmpty {
            collections.append(CuratedCollection(title: "Stair Sets", subtitle: "\(stairSets.count) spots", icon: "figure.stairs", pins: stairSets))
        }

        // Top Rated
        let topRated = allPins.filter { $0.averageRating >= 4.0 && $0.ratings.count >= 2 }
            .sorted { $0.averageRating > $1.averageRating }
        if !topRated.isEmpty {
            collections.append(CuratedCollection(title: "Top Rated", subtitle: "Community favorites", icon: "star.fill", pins: topRated))
        }

        // Gnarly Spots — high risk
        let gnarlySpots = allPins.filter { $0.riskLevel == .high }
            .sorted { $0.averageRating > $1.averageRating }
        if !gnarlySpots.isEmpty {
            collections.append(CuratedCollection(title: "Gnarly Spots", subtitle: "Skate at your own risk", icon: "light.beacon.max", pins: gnarlySpots))
        }

        return collections
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // MARK: Spot of the Day
                    if let spot = spotOfTheDay {
                        sectionHeader("Spot of the Day", icon: "sparkles")
                        SpotOfTheDayCard(pin: spot, viewModel: viewModel) {
                            selectedPin = spot
                        }
                        .matchedTransitionSource(id: spot.id, in: pinTransition)
                        .padding(.horizontal)
                    }

                    // MARK: Near Me
                    if !nearMeSpots.isEmpty {
                        sectionHeader("Near Me", icon: "location.fill")
                        horizontalCards(nearMeSpots, showDistance: true)
                    }

                    // MARK: New Spots
                    if !newSpots.isEmpty {
                        sectionHeader("New Spots", icon: "clock.badge")
                        horizontalCards(newSpots, showDistance: false)
                    }

                    // MARK: Trending
                    if !trendingSpots.isEmpty {
                        sectionHeader("Trending", icon: "flame.fill")
                        horizontalCards(trendingSpots, showDistance: false)
                    }

                    // MARK: Collections
                    if !curatedCollections.isEmpty {
                        sectionHeader("Collections", icon: "rectangle.stack.fill")
                        collectionsGrid
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Discover")
            .fullScreenCover(item: $selectedPin) { pin in
                PinInfoView(pin: pin, viewModel: viewModel)
                    .navigationTransition(.zoom(sourceID: pin.id, in: pinTransition))
            }
            .sheet(item: $selectedCollection) { collection in
                CollectionDetailView(collection: collection, viewModel: viewModel)
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            Text(title)
                .font(.title3.bold())
        }
        .padding(.horizontal)
    }

    private func horizontalCards(_ pins: [PinInfo], showDistance: Bool) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(pins) { pin in
                    SpotCard(
                        pin: pin,
                        distance: showDistance ? locationManager.distance(to: pin.coordinate) : nil
                    ) {
                        selectedPin = pin
                    }
                    .matchedTransitionSource(id: pin.id, in: pinTransition)
                }
            }
            .padding(.horizontal)
        }
    }

    private var collectionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(curatedCollections) { collection in
                Button {
                    selectedCollection = collection
                } label: {
                    CollectionCard(collection: collection)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }
}
