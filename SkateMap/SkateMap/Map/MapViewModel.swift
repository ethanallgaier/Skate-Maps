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

    // MARK: - Skateparks (from OpenStreetMap)
    @Published var skateparks: [Skatepark] = []
    @Published var showSkateparks = true
    private var lastSkateparkFetchRegion: MKCoordinateRegion?

    // 🚨 Add this line to track the active network task
    private var fetchTask: Task<Void, Never>?

    func fetchSkateparksIfNeeded(for region: MKCoordinateRegion) {
        // 1. Cancel the previous task immediately to stop "spamming" the API
        fetchTask?.cancel()

        // 2. Significant movement check (Keep your existing logic)
        if let last = lastSkateparkFetchRegion {
            let latDiff = abs(last.center.latitude - region.center.latitude)
            let lonDiff = abs(last.center.longitude - region.center.longitude)
            let spanChange = abs(last.span.latitudeDelta - region.span.latitudeDelta)
            
            if latDiff < region.span.latitudeDelta * 0.3 &&
               lonDiff < region.span.longitudeDelta * 0.3 &&
               spanChange < region.span.latitudeDelta * 0.5 {
                return
            }
        }
        
        // 3. Create the new task with a slight debounce delay
        fetchTask = Task {
            do {
                // ⏱️ Debounce: Wait 0.4 seconds before hitting the server.
                // If the user moves the map again during this window, this task gets cancelled.
                try await Task.sleep(nanoseconds: 400_000_000)
                
                // Safety check: Don't proceed if the user moved the map again
                guard !Task.isCancelled else { return }

                lastSkateparkFetchRegion = region
                
                var expanded = region
                expanded.span.latitudeDelta *= 1.3
                expanded.span.longitudeDelta *= 1.3
                
                let parks = try await SkateparkService.fetchSkateparks(in: expanded)
                
                // Final check before updating UI
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    // Cap at 50 to keep the map performant
                    self.skateparks = Array(parks.prefix(50))
                    print("✅ Successfully updated map with \(self.skateparks.count) parks.")
                }
            } catch is CancellationError {
                // Normal behavior when user is dragging the map; ignore it.
            } catch {
                print("Error fetching skateparks: \(error)")
            }
        }
    }

    /// Resolve the name of an unnamed skatepark via reverse geocoding
    func resolveNameIfNeeded(for park: Skatepark) {
        guard !park.hasRealName else { return }
        Task {
            let resolved = await SkateparkService.resolveLocationName(for: park)
            await MainActor.run {
                if let index = self.skateparks.firstIndex(where: { $0.id == park.id }) {
                    self.skateparks[index] = resolved
                }
            }
        }
    }

    // MARK: - Username Cache (live lookup by UID)
    @Published var usernameCache: [String: String] = [:]

    func username(for uid: String) -> String {
        if let cached = usernameCache[uid] {
            return cached
        }
        // Kick off a fetch if we haven't yet
        Task { await fetchUsername(for: uid) }
        return "..."
    }

    private func fetchUsername(for uid: String) async {
        // Don't re-fetch if already cached
        guard usernameCache[uid] == nil else { return }
        do {
            let doc = try await dataBase.collection("users").document(uid).getDocument()
            let name = doc.data()?["username"] as? String ?? "Unknown"
            await MainActor.run {
                self.usernameCache[uid] = name
            }
        } catch {
            print("Error fetching username for \(uid): \(error)")
        }
    }

    // MARK: - Report Pin
    func reportPin(_ pin: PinInfo, reason: String) async {
        guard let pinID = pin.id,
              let uid = Auth.auth().currentUser?.uid else { return }
        let report: [String: Any] = [
            "pinID": pinID,
            "reportedBy": uid,
            "reason": reason,
            "timestamp": Timestamp()
        ]
        do {
            try await dataBase.collection("reports").addDocument(data: report)
            print("Report submitted for pin \(pinID)")
        } catch {
            print("Error reporting pin: \(error)")
        }
    }

//MARK: - DELETE FUCNTION
    func deletePin(_ pin: PinInfo) async {
        guard let pinID = pin.id else { return }
        do {
            try await dataBase.collection("pins").document(pinID).delete()
            print("Pin deleted!")

            // ✅ Remove the deleted pin from savedPinIDs locally
            savedPinIDs.removeAll { $0 == pinID }

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
    func addPin(name: String, details: String, coordinate: CLLocationCoordinate2D, username: String, images: [UIImage] = [], spotTypes: [SpotType] = [.other], riskLevel: RiskLevel = .low, difficultyLevel: DifficultyLevel = .beginner) async {
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
            spotTypes: spotTypes,
            riskLevel: riskLevel,
            difficultyLevel: difficultyLevel
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
    
// MARK: - COMBINED(MULTIPLE) PIN UI
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
                Image(systemName: "skateboard")
                    .frame(width: 5, height: 15)
                    .foregroundStyle(Color.darkblue)
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
    
// MARK: - SKATEPARK PIN UI
    struct SkateparkMarker: View {
        let action: () -> Void
        @State private var scale: CGFloat = 0.0

        var body: some View {
            Button(action: action) {
                Image(systemName: "staroflife")
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
    
//MARK: - PLACEMENT PIN(WHEN CHOOSING A SPOT)
    struct CircularTextPin: View {
        let text = "CHOOSE A SPOT"
        
        var body: some View {
            ZStack {
                
//                Circle()
//                    .frame(width: 80, height: 80)
//                    .opacity(0.6)
                

                Text("X")
                    .bold()
                    .foregroundStyle(.red)
            }
            .frame(width: 80, height: 80)
        }
    }
    
//MARK: - SAVE/FAVORITE PINS
    @Published var savedPinIDs: [String] = []//WHY IS THIS PUBLISHED
    
//MARK: - LOAD USERS SAVED PINS
    private var savedPinsListener: ListenerRegistration?

    func fetchSavedPins() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        savedPinsListener?.remove()

        savedPinsListener = Firestore.firestore()
            .collection("users")
            .document(uid)
            .addSnapshotListener { snapshot, _ in
                let data = snapshot?.data()
                let ids = data?["savedPinIDs"] as? [String] ?? []

                DispatchQueue.main.async {
                    self.savedPinIDs = ids
                }
            }
    }
    
//MARK: -SAVE/UNSAVE TOGGLE
    func toggleSave(pin: PinInfo) {
        guard let uid = Auth.auth().currentUser?.uid,
              let pinID = pin.id else { return }

        let userRef = Firestore.firestore().collection("users").document(uid)

        if savedPinIDs.contains(pinID) {
            // 🔥 REMOVE LOCALLY FIRST
            savedPinIDs.removeAll { $0 == pinID }

            userRef.setData([
                "savedPinIDs": FieldValue.arrayRemove([pinID])
            ], merge: true)
        } else {
            // 🔥 ADD LOCALLY FIRST
            savedPinIDs.append(pinID)

            userRef.setData([
                "savedPinIDs": FieldValue.arrayUnion([pinID])
            ], merge: true)
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
    
    // MARK: - RATE A SPOT
    func ratePin(_ pin: PinInfo, stars: Int) async {
        guard let pinID = pin.id,
              let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await dataBase.collection("pins").document(pinID).updateData([
                "ratings.\(uid)": stars  // ✅ stores as ratings.uid = stars in Firestore
            ])
        } catch {
            print("❌ Error rating pin: \(error)")
        }
    }
    //MARK: -   UPDATE/EDIT
    func updatePin(_ pin: PinInfo, name: String, details: String, spotTypes: [SpotType], riskLevel: RiskLevel, difficultyLevel: DifficultyLevel) async {
        guard let id = pin.id else { return }
        try? await Firestore.firestore().collection("pins").document(id).updateData([
            "pinName": name,
            "pinDetails": details,
            "spotTypes": spotTypes.map { $0.rawValue },
            "riskLevel": riskLevel.rawValue,
            "difficultyLevel": difficultyLevel.rawValue
        ])
    }
    //MARK: - DELETE PHOTO
    func deletePhoto(from pin: PinInfo, at index: Int) async {
        guard let id = pin.id else { return }
        var urls = pin.imageURls
        // Optionally delete from Storage here
        urls.remove(at: index)
        try? await Firestore.firestore().collection("pins").document(id).updateData([
            "imageURls": urls
        ])
    }
}
