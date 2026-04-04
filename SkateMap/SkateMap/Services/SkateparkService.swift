//  SkateparkService.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 4/2/26.
//

import Foundation
import MapKit

/// Fetches skateparks using Apple's MapKit search.
/// Reliable, fast, no external API or key needed.
enum SkateparkService {

    /// Searches for skateparks within the given map region.
    static func fetchSkateparks(in region: MKCoordinateRegion) async throws -> [Skatepark] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "skatepark"
        request.region = region
        request.resultTypes = .pointOfInterest

        let response = try await MKLocalSearch(request: request).start()

        return response.mapItems.map { item in
            let coord = item.location.coordinate
            let id = String(format: "%.6f,%.6f", coord.latitude, coord.longitude)
            return Skatepark(
                id: id,
                name: item.name ?? "Skatepark",
                latitude: coord.latitude,
                longitude: coord.longitude,
                surface: nil
            )
        }
    }

    /// Reverse geocodes a skatepark to get a city/state name.
    static func resolveLocationName(for park: Skatepark) async -> Skatepark {
        guard !park.hasRealName else { return park }
        let location = CLLocation(latitude: park.latitude, longitude: park.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return park }

        return await withCheckedContinuation { continuation in
            request.getMapItems { mapItems, _ in
                if let item = mapItems?.first,
                   let city = item.addressRepresentations?.cityWithContext {
                    let resolved = Skatepark(
                        id: park.id,
                        name: "Skatepark — \(city)",
                        latitude: park.latitude,
                        longitude: park.longitude,
                        surface: park.surface
                    )
                    continuation.resume(returning: resolved)
                } else {
                    continuation.resume(returning: park)
                }
            }
        }
    }
}
