//
//  ImageUploader.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/12/26.
//

import FirebaseStorage
import UIKit

//  Handles uploading a UIImage to Firebase Storage and returns the download URL


struct ImageUploader {
    static func upload(image: UIImage, path: String? = nil) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            throw URLError(.badServerResponse)
        }
        let storagePath = path ?? "pin_images/\(UUID().uuidString)"
        let ref = Storage.storage().reference(withPath: storagePath)
        _ = try await ref.putDataAsync(imageData)
        return try await ref.downloadURL().absoluteString
    }
}
