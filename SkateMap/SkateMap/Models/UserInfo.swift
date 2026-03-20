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
    @DocumentID var id: String?
    var username: String = ""
    var bio: String = ""
    var profilePicture: String = ""

    init(id: String? = nil, username: String = "", bio: String = "", profilePicture: String = "") {
        self.id = id
        self.username = username
        self.bio = bio
        self.profilePicture = profilePicture
    }

    // ✅ Add this so missing fields fall back to defaults instead of crashing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        bio = try container.decodeIfPresent(String.self, forKey: .bio) ?? ""
        profilePicture = try container.decodeIfPresent(String.self, forKey: .profilePicture) ?? ""
    }
}





//Why: Firestore's @DocumentID property wrapper automatically maps the document's ID field when decoding. Without it, id is always empty after a fetch


//Codable = is the important one here — it lets Swift automatically convert these structs to and from Firestore data. Without it, you'd have to manually map every single field yourself, which is tedious and error-prone.

//Identifiable = just requires an id field so SwiftUI can tell items apart when displaying them in lists or on the map.
