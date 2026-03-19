import FirebaseFirestore
import MapKit
import FirebaseAuth
import CoreLocation
import UIKit
internal import Combine
import SwiftUI

class MapViewModel: ObservableObject {
    
    private let dataBase = Firestore.firestore()

    @Published var pins: [PinInfo] = []

//MARK: - DELETE FUCNTION
    func deletePin(_ pin: PinInfo) async {
        guard let pinID = pin.id else { return }
        do {
            try await dataBase.collection("pins").document(pinID).delete()
            print("Pin deleted!")
        } catch {
            print("Error deleting pin: \(error)")
        }
    }
    
//MARK: - LOAD ALL PINS ON SKATEMAPS
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
    
//MARK: - SEARCH RESULTS
    @Published var searchResults: [MKMapItem] = [] // move this here too
    func searchLocation(query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        Task {
            if let response = try? await search.start() {
                DispatchQueue.main.async {
                    self.searchResults = Array(response.mapItems.prefix(4))
                }
            }
        }
    }
    
//MARK: - ADD PIN TO SKATEMAPS
    func addPin(name: String, details: String, coordinate: CLLocationCoordinate2D, username: String, images: [UIImage] = [], spotType: SpotType = .other) async {
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

        let newPin = PinInfo(
            pinName: name,
            pinDetails: details,
            time: Date(),
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            createdByUID: uid,
            createdByUsername: username,
            imageURls: uploadedURLs,
            spotType: spotType
        )

        do {
            try dataBase.collection("pins").addDocument(from: newPin)
            print("Pin saved!")
        } catch {
            print("Error saving pin: \(error)")
        }
    }

//MARK: - ADD PHOTO TO A SPOT
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
    
//MARK: - COMBINED PIN FUNCIONALLITY
    func clusteredPins(for region: MKCoordinateRegion, from pins: [PinInfo]) -> [[PinInfo]] {
        let threshold = region.span.latitudeDelta * 0.1
        var clusters: [[PinInfo]] = []
        var assigned = Set<String>()

        for pin in pins {
            guard let id = pin.id, !assigned.contains(id) else { continue }
            var cluster = [pin]
            assigned.insert(id)

            for other in pins {
                guard let otherId = other.id, !assigned.contains(otherId) else { continue }
                if abs(pin.latitude - other.latitude) < threshold &&
                   abs(pin.longitude - other.longitude) < threshold {
                    cluster.append(other)
                    assigned.insert(otherId)
                }
            }
            clusters.append(cluster)
        }
        return clusters
    }
    
//MARK: - LOCATION OF COMBINED PIN
    func centerCoordinate(of cluster: [PinInfo]) -> CLLocationCoordinate2D {
        let avgLat = cluster.map { $0.latitude }.reduce(0, +) / Double(cluster.count)
        let avgLon = cluster.map { $0.longitude }.reduce(0, +) / Double(cluster.count)
        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
    }
    
//MARK: - COMBINED PIN UI
    struct ClusterBubble: View {
        let count: Int
        @State private var scale: CGFloat = 0.0

        var body: some View {
            ZStack {
                Circle()
                    .frame(width: 40, height: 40)
                Text("\(count)")
                    .foregroundStyle(.white)
                    .bold()
            }
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.smooth(duration: 0.4)) {
                    scale = 1.0
                }
            }
        }
    }
    
// MARK: - SINGLE PIN UI
    struct PinMarker: View {
        let action: () -> Void
        @State private var scale: CGFloat = 0.0

        var body: some View {
            Button(action: action) {
                Image(systemName: "mappin")
                    .frame(width: 5, height: 15)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.glassProminent)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.smooth(duration: 0.4)) {
                    scale = 1.0
                }
            }
        }
    }
    
//MARK: - PLACEMENT PIN
    struct CircularTextPin: View {
        let text = "CHOOSE A SPOT"
        
        var body: some View {
            ZStack {
                
                Circle()
                    .frame(width: 80, height: 80)
                    .opacity(0.6)
                
                // TEXT AROUND CIRCLE
//                ForEach(Array(text.enumerated()), id: \.offset) { index, letter in
//                    Text(String(letter))
//                        .font(.caption2)
//                        .bold()
//                        .foregroundStyle(.black)
//                        .position(x: 40, y: 40)
//                        .offset(y: -35)
//                        .rotationEffect(.degrees(Double(index) / Double(text.count) * 300))
//                }
                
                // CENTER PIN
//                Image(systemName: "figure.mixed.cardio")
//                    .foregroundStyle(.red)
//                    .shadow(radius: 4)
                Text("X")
                    .bold()
                    .foregroundStyle(.black)
            }
            .frame(width: 80, height: 80)
        }
    }
    
//MARK: - SAVE/FAVORITE PINS
    @Published var savedPinIDs: [String] = []//WHY IS THIS PUBLISHED
    
//MARK: - LOAD USERS SAVED PINS
    func fetchSavedPins() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid)
            .addSnapshotListener { snapshot, _ in
                let data = snapshot?.data()
                self.savedPinIDs = data?["savedPinIDs"] as? [String] ?? []
            }
    }
    
//MARK: -SAVE/UNSAVE TOGGLE
    func toggleSave(pin: PinInfo) {
        guard let uid = Auth.auth().currentUser?.uid,
              let pinID = pin.id else { return }

        let userRef = Firestore.firestore().collection("users").document(uid)

        if savedPinIDs.contains(pinID) {
            // Unsave
            userRef.setData(["savedPinIDs": FieldValue.arrayRemove([pinID])], merge: true)
        } else {
            // Save
            userRef.setData(["savedPinIDs": FieldValue.arrayUnion([pinID])], merge: true)
        }
    }
    
//MARK: - CHECKING IF PIN IS SAVED
    func isSaved(_ pin: PinInfo) -> Bool {
        guard let id = pin.id else { return false }
        return savedPinIDs.contains(id)
    }
    
    init() {
        fetchPins()
        fetchSavedPins()
    }
}
