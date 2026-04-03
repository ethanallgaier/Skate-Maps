//
//  Skatepark.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 4/2/26.
//

import Foundation
import CoreLocation

/// Represents a skatepark fetched from OpenStreetMap data.
/// These are read-only — users can't edit or rate them.
struct Skatepark: Identifiable, Equatable, Sendable {
    let id: Int64
    let name: String
    let latitude: Double
    let longitude: Double
    let surface: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// True if the name is just a generic fallback (not from OSM data)
    var hasRealName: Bool {
        name != "Skatepark"
    }
}
