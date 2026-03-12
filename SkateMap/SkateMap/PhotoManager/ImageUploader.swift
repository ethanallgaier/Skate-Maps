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
    static func upload(image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            throw URLError(.badServerResponse)
        }
        let filename = UUID().uuidString // unique name so images don't overwrite each other
        let ref = Storage.storage().reference(withPath: "pin_images/\(filename)") // ADDED: stores under pin_images/ folder in Firebase Storage
        _ = try await ref.putDataAsync(imageData) // uploads the image data
        let url = try await ref.downloadURL() //  gets the public URL after upload
        return url.absoluteString
    }
}
