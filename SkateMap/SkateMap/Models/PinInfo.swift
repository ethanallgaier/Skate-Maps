//
//  PinInfo.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/9/26.
//

import Foundation
import FirebaseFirestore
import CoreLocation

//What is @DocumentID?

//Need to kno what these mean
enum SpotType: String, Codable, CaseIterable {
    case rail = "Rail"
    case stairs = "Stairs"
    case ledge = "Ledge"
    case bowl = "Bowl"
    case manualPad = "Manual Pad"
    case bank = "Bank"
    case gap = "Gap"
    case other = "Other"
    
    
    //SPOT TYPE IMAGE
    var icon: String {
        switch self {
        case .rail:      return "minus.rectangle"
        case .stairs:    return "figure.stairs"
        case .ledge:     return "square.lefthalf.filled"
        case .gap:       return "arrowshape.right"
        case .bank:      return "angle"
        case .bowl:      return "circle.bottomhalf.filled"
        case .manualPad: return "rectangle.fill"
        case .other:     return "mappin"
        }
    }
}



struct PinInfo: Identifiable, Codable, Equatable{
    @DocumentID var id: String?
    var pinName: String = ""
    var pinDetails: String = ""
    var time: Date = Date()
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var createdByUID: String = ""
    var createdByUsername: String = ""
    var imageURls: [String] = []
    var spotType: SpotType = .other
    var ratings: [String: Int] = [:] 

        // computed — not stored in Firestore
        var averageRating: Double {
            guard !ratings.isEmpty else { return 0 }
            return Double(ratings.values.reduce(0, +)) / Double(ratings.count)
        }

    
    
    var coordinate: CLLocationCoordinate2D {//Format for placing pin.
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
}



//Codable = is the important one here — it lets Swift automatically convert these structs to and from Firestore data. Without it, you'd have to manually map every single field yourself, which is tedious and error-prone.

//Identifiable = just requires an id field so SwiftUI can tell items apart when displaying them in lists or on the map.
