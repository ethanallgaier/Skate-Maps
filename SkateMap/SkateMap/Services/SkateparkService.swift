//  SkateparkService.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 4/2/26.
//

import Foundation
import MapKit

/// Fetches skateparks from the OpenStreetMap Overpass API.
/// Free, no API key required.
enum SkateparkService {
    private static let endpoint = "https://overpass-api.de/api/interpreter"

    /// Fetches skateparks visible within the given map region.
    static func fetchSkateparks(in region: MKCoordinateRegion) async throws -> [Skatepark] {
        let south = region.center.latitude - region.span.latitudeDelta / 2
        let north = region.center.latitude + region.span.latitudeDelta / 2
        let west = region.center.longitude - region.span.longitudeDelta / 2
        let east = region.center.longitude + region.span.longitudeDelta / 2
        let bbox = "(\(south),\(west),\(north),\(east))"

        // Query for both tagging conventions:
        //  leisure=pitch + sport=skateboard  (traditional)
        //  leisure=skate_park                (newer proposal)
        let query = """
        [out:json][timeout:15];
        (
          node["leisure"="pitch"]["sport"~"skateboard"]\(bbox);
          way["leisure"="pitch"]["sport"~"skateboard"]\(bbox);
          node["leisure"="skate_park"]\(bbox);
          way["leisure"="skate_park"]\(bbox);
        );
        out center;
        """

        var components = URLComponents(string: endpoint)!
        components.queryItems = [URLQueryItem(name: "data", value: query)]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        let response = try JSONDecoder().decode(OverpassResponse.self, from: data)

        return response.elements.compactMap { element -> Skatepark? in
            // Ways use "center" coords; nodes use top-level lat/lon
            let lat = element.center?.lat ?? element.lat
            let lon = element.center?.lon ?? element.lon
            guard let lat, let lon else { return nil }

            // Try multiple OSM tags to find a real name
            let tags = element.tags ?? [:]
            let name = tags["name"]
                ?? tags["alt_name"]
                ?? tags["description"]
                ?? tags["operator"]
                ?? "Skatepark"

            let surface = tags["surface"]

            return Skatepark(id: element.id, name: name, latitude: lat, longitude: lon, surface: surface)
        }
    }

    /// Reverse geocodes a single skatepark to get a city/state name.
    /// Call this lazily when the user taps on an unnamed park.
    static func resolveLocationName(for park: Skatepark) async -> Skatepark {
        guard !park.hasRealName else { return park }
        let location = CLLocation(latitude: park.latitude, longitude: park.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return park }

        return await withCheckedContinuation { continuation in
            request.getMapItems { mapItems, _ in
                if let item = mapItems?.first,
                   let city = item.addressRepresentations?.cityWithContext {
                    let resolved = Skatepark(id: park.id, name: "Skatepark — \(city)", latitude: park.latitude, longitude: park.longitude, surface: park.surface)
                    continuation.resume(returning: resolved)
                } else {
                    continuation.resume(returning: park)
                }
            }
        }
    }
}

// MARK: - Overpass JSON Models

private struct OverpassResponse: Decodable, Sendable {
    let elements: [OverpassElement]
}

private struct OverpassElement: Decodable, Sendable {
    let id: Int64
    let lat: Double?
    let lon: Double?
    let center: OverpassCenter?
    let tags: [String: String]?
}

private struct OverpassCenter: Decodable, Sendable {
    let lat: Double
    let lon: Double
}
