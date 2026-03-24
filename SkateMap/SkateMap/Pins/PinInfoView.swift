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

// MARK: - Main View

struct PinInfoView: View {
    var pin: PinInfo

    @ObservedObject var viewModel: MapViewModel

    @State private var currentPage: Int = 0
    @State private var isExpanded: Bool = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isUploading = false
    @State private var showCamera = false
    @State private var showDeleteConfirm = false

    @Environment(\.dismiss) var dismiss

    var isOwner: Bool {
        Auth.auth().currentUser?.uid == currentPin.createdByUID
    }

    var currentPin: PinInfo {
        viewModel.pins.first(where: { $0.id == pin.id }) ?? pin
    }

    var myRating: Int {
        guard let uid = Auth.auth().currentUser?.uid else { return 0 }
        return currentPin.ratings[uid] ?? 0
    }

    private let overviewPreviewLength = 120

    var overviewText: String {
        let details = currentPin.pinDetails
        if isExpanded || details.count <= overviewPreviewLength {
            return details
        }
        return String(details.prefix(overviewPreviewLength))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // MARK: Hero Carousel
                        heroCarousel

                        // MARK: Content
                        VStack(alignment: .leading, spacing: 20) {

                            //MARK: - Title + Delete (owner only)
                            HStack(alignment: .top) {
                                Text(currentPin.pinName)
                                    .font(.system(size: 26, weight: .bold))
                                Spacer()
                                if isOwner {
                                    Button(role: .destructive) {
                                        showDeleteConfirm = true
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 20))
                                            .foregroundColor(.red)
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

                            // MARK: Creator + Date
                            HStack(spacing: 4) {
                              
                                Label(currentPin.createdByUsername, systemImage: "person.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text("·")
                                    .foregroundColor(.secondary)
                                Text(currentPin.time.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            // MARK: Bookmark + Star Rating row
                            HStack {
                                // Save button
                                Button {
                                    viewModel.toggleSave(pin: currentPin)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: viewModel.isSaved(currentPin) ? "bookmark.fill" : "bookmark")
                                        Text(viewModel.isSaved(currentPin) ? "Saved" : "Save")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1), in: Capsule())
                                }

                                Spacer()

                                StarRatingView(rating: currentPin.averageRating, userRating: myRating) { stars in
                                    Task { await viewModel.ratePin(currentPin, stars: stars) }
                                }
                                // Star rating (interactive)
                            }

                            Divider()
                            
                         

                            // MARK: Overview
                            if !currentPin.pinDetails.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Overview")
                                        .font(.system(size: 18, weight: .bold))
                                   
                                    Text(overviewText)
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                        .lineSpacing(4)

                                    if !isExpanded && currentPin.pinDetails.count > overviewPreviewLength {
                                        HStack(spacing: 0) {
                                            Text("… ")
                                                .foregroundColor(.secondary)
                                                .font(.system(size: 15))
                                            Button("read more...") {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    isExpanded = true
                                                }
                                            }
                                            .font(.system(size: 15))
                                            .foregroundColor(.blue)
                                        }
                                    }
                                }

                                Divider()
                                
                                Text("Spot Type")
                                    .font(.system(size: 18, weight: .bold))
                                HStack(spacing: 4) {
                                    ForEach(Array(pin.spotTypes.enumerated()), id: \.element) { index, type in
                                        Label(type.rawValue, systemImage: type.icon)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        // Add "+" after every item except the last
                                        if index < pin.spotTypes.count - 1 {
                                            Text("+")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                Divider()
                            }

                            // MARK: Add Photos (owner only)
                            if isOwner {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Add Photos")
                                        .font(.system(size: 18, weight: .bold))

                                    HStack(spacing: 10) {
                                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
                                            Label(isUploading ? "Uploading…" : "Library", systemImage: "photo.on.rectangle.angled")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.blue)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
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

                                        Button {
                                            showCamera = true
                                        } label: {
                                            Label(isUploading ? "Uploading…" : "Camera", systemImage: "camera")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.blue)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                                        }
                                        .disabled(isUploading)
                                    }
                                }

                                Divider()
                            }

                            // MARK: Location Map
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Location")
                                    .font(.system(size: 18, weight: .bold))

                                Map(initialPosition: .region(MKCoordinateRegion(
                                    center: currentPin.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                ))) {
                                    Marker(currentPin.pinName, coordinate: currentPin.coordinate)
                                        .tint(.red)
                                }
                                .mapStyle(.hybrid)
                                .frame(height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .disabled(true)
                            }

                            // Space so content clears the bottom bar
                            Spacer(minLength: 90)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
                .ignoresSafeArea(edges: .top)

                // MARK: Sticky Bottom Bar
                bottomBar
            }
            .navigationBarHidden(true)
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

    // MARK: - Hero Carousel

    @ViewBuilder
    private var heroCarousel: some View {
        ZStack(alignment: .bottom) {
            // Images or fallback gradient
            if currentPin.imageURls.isEmpty {
                LinearGradient(
                    colors: [Color(red: 0.12, green: 0.12, blue: 0.16), Color(red: 0.22, green: 0.22, blue: 0.28)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: "figure.skateboarding")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.18))
                )
            } else {
                TabView(selection: $currentPage) {
                    ForEach(Array(currentPin.imageURls.enumerated()), id: \.offset) { index, url in
                        AsyncImage(url: URL(string: url)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay(ProgressView())
                        }
                        .tag(index)
                        .clipped()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            // Bottom gradient fade on image
            LinearGradient(
                colors: [.clear, .black.opacity(0.25)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            // Dismiss + Heart buttons
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                    Button {
                        viewModel.toggleSave(pin: currentPin)
                    } label: {
                        Image(systemName: viewModel.isSaved(currentPin) ? "heart.fill" : "heart")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(viewModel.isSaved(currentPin) ? .red : .white)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 56)
                Spacer()
            }

            // Page indicator dots
            if currentPin.imageURls.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<currentPin.imageURls.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.blue : Color.white.opacity(0.6))
                            .frame(width: currentPage == index ? 20 : 7, height: 7)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 14)
            }
        }
        .frame(height: 300)
    }

    // MARK: - Bottom Bar (mirrors the Destination detail style)

    private var bottomBar: some View {
        HStack {
            // Rating on the left (mirrors "$35 /person")
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                    Text(String(format: "%.1f", currentPin.averageRating))
                        .font(.system(size: 26, weight: .bold))
                }
                Text("rating")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Get Directions — capsule button matching "Book Now"
            Button {
                openInMaps()
            } label: {
                Label("Get Directions", systemImage: "map.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
                    .background(Color.blue, in: Capsule())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            .ultraThinMaterial
                .shadow(.drop(color: .black.opacity(0.08), radius: 12, y: -4))
        )
    }

    // MARK: - Helpers

    func openInMaps() {
        let location = CLLocation(latitude: currentPin.coordinate.latitude, longitude: currentPin.coordinate.longitude)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = currentPin.pinName
        mapItem.openInMaps()
    }
}

// MARK: - Preview

#Preview {
    let mockPin = PinInfo(
        id: "1",
        pinName: "Orem Skatepark",
        pinDetails: "Super smooth ledges and a nice bowl. Great spot for all skill levels with freshly poured concrete and good lighting at night.",
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
