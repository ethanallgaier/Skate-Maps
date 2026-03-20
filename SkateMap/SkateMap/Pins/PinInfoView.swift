//
//  PinInfoView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/2/26.
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import MapKit

struct PinInfoView: View {
    var pin: PinInfo
    
    @ObservedObject var viewModel: MapViewModel
    
    @State private var userRating: Int = 0
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isUploading = false
    @State private var showCamera = false
    @State private var showDeleteConfirm = false
    
    @Environment(\.dismiss) var dismiss
    
    // Check if the logged in user is the one who created this pin
    var isOwner: Bool {
        Auth.auth().currentUser?.uid == currentPin.createdByUID
    }
    
    // Looks up the latest version of the pin from viewModel so it updates in real time
    var currentPin: PinInfo {
        viewModel.pins.first(where: { $0.id == pin.id }) ?? pin
    }
    // computed — looks up this user's existing rating
    var myRating: Int {
        guard let uid = Auth.auth().currentUser?.uid else { return 0 }
        return currentPin.ratings[uid] ?? 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    //  TOP PHOTOS
                    if !currentPin.imageURls.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(pin.imageURls, id: \.self) { url in
                                    AsyncImage(url: URL(string: url)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 280, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        
                        
 // MARK: - WHAT USER CREATED THE PIN
                        Label(currentPin.createdByUsername, systemImage: "person.circle")
                            .foregroundStyle(.secondary)
                        
// MARK: - DATE MADE
                        Label(currentPin.time.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .foregroundStyle(.secondary)
                        
                        Divider()
                        Text(currentPin.pinName)
//MARK: - PIN DETAILS
                        if !currentPin.pinDetails.isEmpty {
                            Text(pin.pinDetails)
                                .foregroundStyle(.secondary)
                        }
                        Divider()
                        
 // MARK: - FAVORITE/BOOKMARK BUTTON
                        HStack {
                            Button {
                                viewModel.toggleSave(pin: currentPin)
                            } label: {
                                Image(systemName: viewModel.isSaved(currentPin) ? "bookmark.fill" : "bookmark")
                                    .foregroundStyle(.blue)
                            }
                            
                            Spacer()
                            
// MARK: - STAR RATING
                            StarRatingView(rating: currentPin.averageRating, userRating: myRating) { stars in
                                Task { await viewModel.ratePin(currentPin, stars: stars) }
                            }
                        }
                        
  // MARK: - ADD PHOTOS — only shown to the owner
                        if isOwner {
                            HStack {
                                PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
                                    Label(isUploading ? "Uploading..." : "Library", systemImage: "photo.on.rectangle.angled")
                                }
                                .disabled(isUploading)
                                
                                .onChange(of: selectedItems) { _, newItems in
                                    guard !newItems.isEmpty else { return }
                                    isUploading = true
                                    Task {
                                        for item in newItems {
                                            if let data = try? await item.loadTransferable(type: Data.self),
                                               let image = UIImage(data: data) {
                                                selectedImages.append(image)
                                            }
                                        }
                                        await viewModel.addPhotos(to: currentPin, images: selectedImages)
                                        selectedItems = []
                                        selectedImages = []
                                        isUploading = false
                                    }
                                }
                                
                                Divider().frame(height: 20)
                                
                                Button {
                                    showCamera = true
                                } label: {
                                    Label(isUploading ? "Uploading..." : "Camera", systemImage: "camera")
                                }
                                .disabled(isUploading)
                            }
                        }
                       
                        Spacer()
// MARK: -  MAP DIRECTIONS
                        PinMiniMapView(pin: currentPin)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("Spot Info")
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
 //MARK: - DELETE BUTTON— only shown to the owner
                if isOwner {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .confirmationDialog("Delete this pin?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                            Button("Delete", role: .destructive) {
                                Task {
                                    await viewModel.deletePin(currentPin)
                                    dismiss()
                                }
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
                }
            }
            
            //DELETE BUTTON
            
            //SHOW CAMERA
            .fullScreenCover(isPresented: $showCamera, onDismiss: {
                guard !selectedImages.isEmpty else { return }
                isUploading = true
                Task {
                    await viewModel.addPhotos(to: currentPin, images: selectedImages)
                    selectedImages = []
                    isUploading = false
                }
            }) {
                CameraPicker(images: $selectedImages)
            }
        }
    }
}








//MARK: - GET DIRECTIONS VIEW
struct PinMiniMapView: View {
    var pin: PinInfo

    var body: some View {
        VStack(spacing: 0) {
            Map(initialPosition: .region(MKCoordinateRegion(
                center: pin.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))) {
                Marker(pin.pinName, coordinate: pin.coordinate)
                    .tint(.red)
            }
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(true)

            Button {
                openInMaps()
            } label: {
                Label("Get Directions", systemImage: "map.fill")
                    .frame(maxWidth: .infinity)
                  
            }
            .buttonStyle(.glass)
            .padding(.top, 8)
        }
        .mapStyle(.hybrid)
    }

    func openInMaps() {
        let location = CLLocation(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = pin.pinName
        mapItem.openInMaps()
    }
}


















#Preview {
    
    let mockPin = PinInfo(
        id: "1",
        pinName: "Orem Skatepark",
        pinDetails: "Super smooth ledges and a nice bowl.",
        latitude: 40.2969,
        longitude: -111.6946,
        createdByUID: "test",
        createdByUsername: "Ethan",
  
        imageURls: [
            "https://picsum.photos/400"
        ]
    )
    
    PinInfoView(
        pin: mockPin,
        viewModel: MapViewModel()
    )
}

