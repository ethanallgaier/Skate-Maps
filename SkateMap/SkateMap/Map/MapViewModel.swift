import FirebaseFirestore
import FirebaseAuth
import CoreLocation
import UIKit
internal import Combine

class MapViewModel: ObservableObject {
    private let dataBase = Firestore.firestore()

    @Published var pins: [PinInfo] = []

    
//Delete Pin
    func deletePin(_ pin: PinInfo) async {
        guard let pinID = pin.id else { return }
        do {
            try await dataBase.collection("pins").document(pinID).delete()
            print("Pin deleted!")
        } catch {
            print("Error deleting pin: \(error)")
        }
    }
    
    
  //Grab Pins
    func fetchPins() {
        dataBase.collection("pins")
            .order(by: "time", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching pins: \(error)")
                    return
                }
                self.pins = snapshot?.documents.compactMap {
                    try? $0.data(as: PinInfo.self)
                } ?? []
            }
    }
//Add Pin
    func addPin(name: String, details: String, coordinate: CLLocationCoordinate2D, username: String, images: [UIImage] = []) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No user logged in!")
            return
        }
        print("📸 Images to upload: \(images.count)") // how many images are we getting?

        // Upload all images first, collect their download URLs
        var uploadedURLs: [String] = []
        
        for image in images {
            do {
                        let url = try await ImageUploader.upload(image: image)
                        print("✅ Uploaded: \(url)")
                        uploadedURLs.append(url)
                    } catch {
                        print("❌ Upload failed: \(error)") // now we can see the actual error
                    }
                }
        print("🔗 URLs to save: \(uploadedURLs)")

        let newPin = PinInfo(
            pinName: name,
            pinDetails: details,
            time: Date(),
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            createdByUID: uid,
            createdByUsername: username,
            imageURls: uploadedURLs
        )

        do {
            try dataBase.collection("pins").addDocument(from: newPin)
            print("Pin saved!")
        } catch {
            print("Error saving pin: \(error)")
        }
    }

    // Adds more photos to an already existing pin
    func addPhotos(to pin: PinInfo, images: [UIImage]) async {
        guard let pinID = pin.id else { return }

        var newURLs: [String] = []
        for image in images {
            if let url = try? await ImageUploader.upload(image: image) {
                newURLs.append(url)
            }
        }

        let updatedURLs = pin.imageURls + newURLs
        do {
            try await dataBase.collection("pins").document(pinID).updateData([
                "imageURls": updatedURLs
            ])
        } catch {
            print("Error updating photos: \(error)")
        }
    }
}
