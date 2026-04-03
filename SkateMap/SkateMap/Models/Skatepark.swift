//
//  Skatepark.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 4/2/26.
//

import Foundation
import CoreLocation

/// Represents a skatepark found via MapKit search.
/// These are read-only — users can't edit or rate them.
struct Skatepark: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let surface: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// True if the name came from MapKit (not a generic fallback)
    var hasRealName: Bool {
        name != "Skatepark"
    }
}
