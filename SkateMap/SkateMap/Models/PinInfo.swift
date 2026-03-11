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
struct PinInfo: Identifiable, Codable {
    @DocumentID var id: String?
    var pinName: String = ""
    var pinDetails: String = ""
    var time: Date = Date()
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var createdByUID: String = ""
    var createdByUsername: String = ""
    var imageURls: [String] = []
    
    
    var coordinate: CLLocationCoordinate2D {//Format for placing pin.
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}



//Codable = is the important one here — it lets Swift automatically convert these structs to and from Firestore data. Without it, you'd have to manually map every single field yourself, which is tedious and error-prone.

//Identifiable = just requires an id field so SwiftUI can tell items apart when displaying them in lists or on the map.
