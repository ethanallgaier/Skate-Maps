//
//  Models.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/3/26.
//

import Foundation
import FirebaseFirestore
import CoreLocation


struct UserInfo: Identifiable, Codable {
    var username: String = ""
    var bio: String = ""
    var profilePicture: String = "" 
    var id: String = ""
}








//Codable = is the important one here — it lets Swift automatically convert these structs to and from Firestore data. Without it, you'd have to manually map every single field yourself, which is tedious and error-prone.

//Identifiable = just requires an id field so SwiftUI can tell items apart when displaying them in lists or on the map.
