import FirebaseFirestore
import MapKit
import FirebaseAuth
import CoreLocation
import UIKit
internal import Combine
import SwiftUI

/// Unified pin type that wraps both user pins and skateparks for clustering
enum MapPin: Identifiable {
    case userPin(PinInfo)
    case skatepark(Skatepark)

    var id: String {
        switch self {
        case .userPin(let pin): return pin.id ?? ""
        case .skatepark(let park): return "sp_\(park.id)"
        }
    }

    var latitude: Double {
        switch self {
        case .userPin(let pin): return pin.latitude
        case .skatepark(let park): return park.latitude
        }
    }

    var longitude: Double {
        switch self {
        case .userPin(let pin): return pin.longitude
        case .skatepark(let park): return park.longitude
        }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

class MapViewModel: ObservableObject {
    
    private let dataBase = Firestore.firestore()

    @Published var pins: [PinInfo] = []

    // MARK: - Skateparks (from OpenStreetMap)
    @Published var skateparks: [Skatepark] = []
    @Published var showSkateparks = true
    @Published var isLoadingSkateparks = false
    private var lastSkateparkFetchRegion: MKCoordinateRegion?

    // 🚨 Add this line to track the active network task
    private var fetchTask: Task<Void, Never>?

    func fetchSkateparksIfNeeded(for region: MKCoordinateRegion) {
        fetchTask?.cancel()

        // Skip fetching when zoomed out too far (results would be too spread out)
        guard region.span.latitudeDelta < 1.0 else { return }

        if let last = lastSkateparkFetchRegion {
            let latDiff = abs(last.center.latitude - region.center.latitude)
            let lonDiff = abs(last.center.longitude - region.center.longitude)
            let refSpan = min(last.span.latitudeDelta, region.span.latitudeDelta)
            let pannedFar = latDiff > refSpan * 0.3 || lonDiff > refSpan * 0.3
            let zoomRatio = region.span.latitudeDelta / max(last.span.latitudeDelta, 0.0001)
            let zoomedSignificantly = zoomRatio > 1.5 || zoomRatio < 0.5

            if !pannedFar && !zoomedSignificantly { return }
        }

        fetchTask = Task {
            do {
                try await Task.sleep(nanoseconds: 250_000_000)
                guard !Task.isCancelled else { return }

                await MainActor.run { self.isLoadingSkateparks = true }
                lastSkateparkFetchRegion = region

                let parks = try await SkateparkService.fetchSkateparks(in: region)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    // Merge new parks into existing — keep previously discovered ones
                    let existingIDs = Set(self.skateparks.map { $0.id })
                    let newParks = parks.filter { !existingIDs.contains($0.id) }
                    self.skateparks.append(contentsOf: newParks)
                    self.isLoadingSkateparks = false
                }
            } catch is CancellationError {
                await MainActor.run { self.isLoadingSkateparks = false }
            } catch {
                print("[Skateparks] Error: \(error.localizedDescription)")
                await MainActor.run { self.isLoadingSkateparks = false }
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

    // MARK: - Location Name Cache (reverse geocoding)
    @Published var locationNameCache: [String: String] = [:]
    private var locationFetchingKeys: Set<String> = []

    func locationName(for pin: PinInfo) -> String? {
        let key = "\(pin.latitude),\(pin.longitude)"
        if let cached = locationNameCache[key] {
            return cached
        }
        guard !locationFetchingKeys.contains(key) else { return nil }
        locationFetchingKeys.insert(key)
        Task {
            let location = CLLocation(latitude: pin.latitude, longitude: pin.longitude)
            guard let request = MKReverseGeocodingRequest(location: location) else { return }
            do {
                let items = try await request.mapItems
                if let item = items.first,
                   let city = item.addressRepresentations?.cityWithContext(.short) {
                    await MainActor.run {
                        self.locationNameCache[key] = city
                    }
                } else {
                    await MainActor.run {
                        self.locationNameCache[key] = "Unknown"
                    }
                }
            } catch {
                await MainActor.run {
                    self.locationNameCache[key] = "Unknown"
                }
            }
        }
        return nil
    }

    // MARK: - Username Cache (live lookup by UID)
    @Published var usernameCache: [String: String] = [:]
    @Published var profilePictureCache: [String: String] = [:]

    func username(for uid: String) -> String {
        if let cached = usernameCache[uid] {
            return cached
        }
        Task { await fetchUserInfo(for: uid) }
        return "..."
    }

    func profilePicture(for uid: String) -> String? {
        if let cached = profilePictureCache[uid] {
            return cached.isEmpty ? nil : cached
        }
        Task { await fetchUserInfo(for: uid) }
        return nil
    }

    private func fetchUserInfo(for uid: String) async {
        guard usernameCache[uid] == nil else { return }
        do {
            let doc = try await dataBase.collection("users").document(uid).getDocument()
            let data = doc.data()
            let name = data?["username"] as? String ?? "Unknown"
            let pic = data?["profilePicture"] as? String ?? ""
            await MainActor.run {
                self.usernameCache[uid] = name
                self.profilePictureCache[uid] = pic
            }
        } catch {
            print("Error fetching user info for \(uid): \(error)")
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
    func addPin(name: String, details: String, coordinate: CLLocationCoordinate2D, username: String, images: [UIImage] = [], spotTypes: [SpotType] = [.other], riskLevel: RiskLevel = .low, difficultyLevel: DifficultyLevel = .beginner, surfaceQuality: SurfaceQuality = .decent, bestTimes: [BestTime] = []) async {
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
            difficultyLevel: difficultyLevel,
            surfaceQuality: surfaceQuality,
            bestTimes: bestTimes
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
    
//MARK: - UNIFIED PIN CLUSTERING
    func clusteredMapPins(for region: MKCoordinateRegion, from pins: [MapPin]) -> [[MapPin]] {
        // Only cluster when zoomed far out — keep pins separate at close zoom
        guard region.span.latitudeDelta > 0.3 else {
            return pins.map { [$0] }
        }

        let threshold = region.span.latitudeDelta * 0.03
        var clusters: [[MapPin]] = []
        var assigned = Set<String>()

        for pin in pins {
            guard !assigned.contains(pin.id) else { continue }
            var cluster = [pin]
            assigned.insert(pin.id)

            for other in pins {
                guard !assigned.contains(other.id) else { continue }
                if abs(pin.latitude - other.latitude) < threshold &&
                   abs(pin.longitude - other.longitude) < threshold {
                    cluster.append(other)
                    assigned.insert(other.id)
                }
            }
            clusters.append(cluster)
        }
        return clusters
    }

//MARK: - LOCATION OF COMBINED PIN
    func centerCoordinate(of cluster: [MapPin]) -> CLLocationCoordinate2D {
        let avgLat = cluster.map { $0.latitude }.reduce(0, +) / Double(cluster.count)
        let avgLon = cluster.map { $0.longitude }.reduce(0, +) / Double(cluster.count)
        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
    }
    
// MARK: - CLUSTER BUBBLE UI
    struct ClusterBubble: View {
        let count: Int
        @State private var scale: CGFloat = 0.0

        var body: some View {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

                Text("\(count)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                    scale = 1.0
                }
            }
        }
    }

// MARK: - USER PIN UI
    struct PinMarker: View {
        let action: () -> Void
        @State private var scale: CGFloat = 0.0

        var body: some View {
            Button(action: action) {
                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(Color.darkblue)
                            .frame(width: 34, height: 34)
                            .shadow(color: Color.darkblue.opacity(0.4), radius: 4, y: 2)

                        Image(systemName: "skateboard.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }

                    // Pin tail
                    Triangle()
                        .fill(Color.darkblue)
                        .frame(width: 12, height: 8)
                        .offset(y: -1)
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
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
                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(.darkgreen)
                            .frame(width: 34, height: 34)
                            .shadow(color: .green.opacity(0.4), radius: 4, y: 2)

                        Image(systemName: "figure.skating")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }

                    // Pin tail
                    Triangle()
                        .fill(.darkgreen)
                        .frame(width: 12, height: 8)
                        .offset(y: -1)
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                    scale = 1.0
                }
            }
        }
    }

// MARK: - Pin Tail Shape
    struct Triangle: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
            return path
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
                "ratings.\(uid)": stars
            ])
        } catch {
            print("❌ Error rating pin: \(error)")
        }
    }

    func removeRating(_ pin: PinInfo) async {
        guard let pinID = pin.id,
              let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await dataBase.collection("pins").document(pinID).updateData([
                "ratings.\(uid)": FieldValue.delete()
            ])
        } catch {
            print("❌ Error removing rating: \(error)")
        }
    }
    // MARK: - COMMENTS

    func fetchComments(for pin: PinInfo) async -> [Comment] {
        guard let pinID = pin.id else { return [] }
        do {
            let snapshot = try await dataBase.collection("pins").document(pinID)
                .collection("comments")
                .order(by: "time", descending: true)
                .getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: Comment.self) }
        } catch {
            print("❌ Error fetching comments: \(error)")
            return []
        }
    }

    func addComment(to pin: PinInfo, text: String, username: String) async {
        guard let pinID = pin.id,
              let uid = Auth.auth().currentUser?.uid else { return }
        let comment = Comment(text: text, authorUID: uid, authorUsername: username, time: Date())
        do {
            try dataBase.collection("pins").document(pinID)
                .collection("comments")
                .addDocument(from: comment)
        } catch {
            print("❌ Error adding comment: \(error)")
        }
    }

    func deleteComment(from pin: PinInfo, commentID: String) async {
        guard let pinID = pin.id else { return }
        do {
            try await dataBase.collection("pins").document(pinID)
                .collection("comments")
                .document(commentID)
                .delete()
        } catch {
            print("❌ Error deleting comment: \(error)")
        }
    }

    //MARK: -   UPDATE/EDIT
    func updatePin(_ pin: PinInfo, name: String, details: String, spotTypes: [SpotType], riskLevel: RiskLevel, difficultyLevel: DifficultyLevel, surfaceQuality: SurfaceQuality = .decent, bestTimes: [BestTime] = []) async {
        guard let id = pin.id else { return }
        try? await Firestore.firestore().collection("pins").document(id).updateData([
            "pinName": name,
            "pinDetails": details,
            "spotTypes": spotTypes.map { $0.rawValue },
            "riskLevel": riskLevel.rawValue,
            "difficultyLevel": difficultyLevel.rawValue,
            "surfaceQuality": surfaceQuality.rawValue,
            "bestTimes": bestTimes.map { $0.rawValue }
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
