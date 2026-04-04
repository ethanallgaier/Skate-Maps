//
//  PinInfo.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/9/26.
//

import Foundation
import FirebaseFirestore
import CoreLocation
import SwiftUI

enum RiskLevel: Int, Codable, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3

    var label: String {
        switch self {
        case .low:    return "Chill"
        case .medium: return "Kinda Risky"
        case .high:   return "Very Risky"
        }
    }

    var subtitle: String {
        switch self {
        case .low:    return "Skate freely"
        case .medium: return "Keep an eye out"
        case .high:   return "Security on sight"
        }
    }

    var icon: String {
        switch self {
        case .low:    return "checkmark.shield.fill"
        case .medium: return "eye.trianglebadge.exclamationmark.fill"
        case .high:   return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .low:    return .green
        case .medium: return .orange
        case .high:   return .red
        }
    }
}

enum SurfaceQuality: Int, Codable, CaseIterable {
    case rough = 1
    case decent = 2
    case smooth = 3
    case buttery = 4

    var label: String {
        switch self {
        case .rough:   return "Rough"
        case .decent:  return "Decent"
        case .smooth:  return "Smooth"
        case .buttery: return "Buttery"
        }
    }

    var icon: String {
        switch self {
        case .rough:   return "square.grid.3x3.fill"
        case .decent:  return "square.grid.2x2.fill"
        case .smooth:  return "rectangle.fill"
        case .buttery: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .rough:   return .red
        case .decent:  return .orange
        case .smooth:  return .blue
        case .buttery: return .green
        }
    }
}

enum BestTime: String, Codable, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case night = "Night"

    var icon: String {
        switch self {
        case .morning:   return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening:   return "sunset.fill"
        case .night:     return "moon.stars.fill"
        }
    }

    var color: Color {
        switch self {
        case .morning:   return .orange
        case .afternoon: return .yellow
        case .evening:   return .pink
        case .night:     return .indigo
        }
    }
}

enum DifficultyLevel: Int, Codable, CaseIterable {
    case beginner = 1
    case intermediate = 2
    case advanced = 3

    var label: String {
        switch self {
        case .beginner:     return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced:     return "Advanced"
        }
    }

    var icon: String {
        switch self {
        case .beginner:     return "figure.walk"
        case .intermediate: return "figure.run"
        case .advanced:     return "figure.snowboarding"
        }
    }

    var color: Color {
        switch self {
        case .beginner:     return .green
        case .intermediate: return .orange
        case .advanced:     return .red
        }
    }
}

enum SpotType: String, Codable, CaseIterable {
    case rail = "Rail"
    case stairs = "Stair"
    case ledge = "Ledge"
    case bowl = "Bowl"
    case manualPad = "Manual Pad"
    case bank = "Bank"
    case gap = "Gap"
    case flatground = "Flat Ground"
    case hubba = "Hubba"
    case curb = "Curb"
    case halfPipe = "Half Pipe"
    case ditch = "Ditch"
    case plaza = "Plaza"
    case parking = "Parking Lot"
    case other = "Other"

    var icon: String {
        switch self {
        case .rail:      return "minus.rectangle"
        case .stairs:    return "figure.stairs"
        case .ledge:     return "square.lefthalf.filled"
        case .gap:       return "arrowshape.right"
        case .bank:      return "angle"
        case .bowl:      return "circle.bottomhalf.filled"
        case .manualPad: return "rectangle.fill"
        case .flatground: return "road.lanes"
        case .hubba:     return "triangle.fill"
        case .curb:      return "rectangle.bottomhalf.filled"
        case .halfPipe:  return "semicircle.bottomhalf.filled"
        case .ditch:     return "chevron.down"
        case .plaza:     return "building.columns"
        case .parking:   return "car.fill"
        case .other:     return "mappin"
        }
    }
}


struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    var text: String = ""
    var authorUID: String = ""
    var authorUsername: String = ""
    var time: Date = Date()
}

// Firestore's decoder already handles missing fields by using default values,
// and it handles @DocumentID injection automatically. No custom decoder needed.
struct PinInfo: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var pinName: String = ""
    var pinDetails: String = ""
    var time: Date = Date()
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var createdByUID: String = ""
    var createdByUsername: String = ""
    var imageURls: [String] = []
    var spotTypes: [SpotType] = [.other]
    var riskLevel: RiskLevel = .low
    var difficultyLevel: DifficultyLevel = .beginner
    var surfaceQuality: SurfaceQuality?
    var bestTimes: [BestTime]?
    var ratings: [String: Int] = [:]

    var averageRating: Double {
        guard !ratings.isEmpty else { return 0 }
        return Double(ratings.values.reduce(0, +)) / Double(ratings.count)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
