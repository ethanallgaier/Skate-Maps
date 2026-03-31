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

    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedDetails = ""
    @State private var editedSpotTypes: Set<SpotType> = []
    @State private var editedRiskLevel: RiskLevel = .low
    @State private var isSaving = false

    @Environment(\.dismiss) var dismiss
    
    

    var isOwner: Bool {
        Auth.auth().currentUser?.uid == currentPin.createdByUID
    }

    @State private var currentPin: PinInfo
    
    init(pin: PinInfo, viewModel: MapViewModel) {
        self.pin = pin
        self.viewModel = viewModel
        _currentPin = State(initialValue: pin)
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
       
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // MARK: Photos
                        captures

                        // MARK: - Content
                        VStack(alignment: .leading, spacing: 20) {

                            // MARK: - Title + Edit/Delete (owner only)
                            HStack(alignment: .top) {
                                if isEditing {
                                    TextField("Spot name", text: $editedName)
                                        .font(.system(size: 34, weight: .bold))
                                        .submitLabel(.done)
                                } else {
                                    Text(currentPin.pinName)
                                        .font(.system(size: 34, weight: .bold))
                                }

                                Spacer()

                                if isOwner {
                                    HStack(spacing: 14) {
                                        // Edit button
                                        Button {
                                            if isEditing {
                                                // Cancel — restore original values
                                                isEditing = false
                                            } else {
                                                editedName = currentPin.pinName
                                                editedDetails = currentPin.pinDetails
                                                editedSpotTypes = Set(currentPin.spotTypes)
                                                editedRiskLevel = currentPin.riskLevel
                                                isEditing = true
                                            }
                                        } label: {
                                            Image(systemName: isEditing ? "xmark" : "pencil.and.outline")
                                                .font(.system(size: 18))
                                                .foregroundColor(.blue)
                                                .padding()
                                        }

                                        // Delete button (hidden while editing)
                                        if !isEditing {
                                            Button(role: .destructive) {
                                                showDeleteConfirm = true
                                            } label: {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.red)
                                                    .padding()
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
                            }

                            // MARK: - Creator + Date
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
                            if !isEditing {
                                HStack {
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
                                }
                            }

                            Divider()

                            // MARK: OVERVIEW
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Overview")
                                    .font(.system(size: 18, weight: .bold))

                                if isEditing {
                                    TextEditor(text: $editedDetails)
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                        .frame(minHeight: 80, maxHeight: 150)
                                        .scrollContentBackground(.hidden)
                                        .padding(10)
                                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                                } else if !currentPin.pinDetails.isEmpty {
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
                            }

                            if !currentPin.pinDetails.isEmpty || isEditing {
                                Divider()
                            }

                            // MARK: - SPOT TYPE
                            Text("Spot Type")
                                .font(.system(size: 18, weight: .bold))

                            if isEditing {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(SpotType.allCases, id: \.self) { type in
                                            Button {
                                                if editedSpotTypes.contains(type) {
                                                    editedSpotTypes.remove(type)
                                                } else {
                                                    editedSpotTypes.insert(type)
                                                }
                                            } label: {
                                                Label(type.rawValue, systemImage: type.icon)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .background(editedSpotTypes.contains(type) ? Color.blue : Color.gray.opacity(0.2))
                                                    .foregroundStyle(editedSpotTypes.contains(type) ? .white : .primary)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            } else {
                                HStack(spacing: 4) {
                                    ForEach(Array(currentPin.spotTypes.enumerated()), id: \.element) { index, type in
                                        Label(type.rawValue, systemImage: type.icon)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        if index < currentPin.spotTypes.count - 1 {
                                            Text("+")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            Divider()

                            // MARK: - RISK LEVEL
                            Text("Risk Level")
                                .font(.system(size: 18, weight: .bold))

                            if isEditing {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("How likely are you to get kicked out?")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Picker("Risk", selection: $editedRiskLevel) {
                                        ForEach(RiskLevel.allCases, id: \.self) { level in
                                            Text(level.label).tag(level)
                                        }
                                    }
                                    .pickerStyle(.segmented)

                                    HStack {
                                        Image(systemName: editedRiskLevel.icon)
                                        Text(editedRiskLevel.label)
                                            .font(.subheadline.weight(.medium))
                                    }
                                    .foregroundStyle(editedRiskLevel.color)
                                }
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: currentPin.riskLevel.icon)
                                    Text(currentPin.riskLevel.label)
                                        .font(.subheadline.weight(.medium))
                                }
                                .foregroundStyle(currentPin.riskLevel.color)
                            }

                            Divider()

                            // MARK: Add / Manage Photos (owner only)
                            if isOwner {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(isEditing ? "Manage Photos" : "Add Photos")
                                        .font(.system(size: 18, weight: .bold))

                                    // Deletable photo thumbnails when editing
                                    if isEditing && !currentPin.imageURls.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 10) {
                                                ForEach(Array(currentPin.imageURls.enumerated()), id: \.offset) { index, url in
                                                    ZStack(alignment: .topTrailing) {
                                                        AsyncImage(url: URL(string: url)) { image in
                                                            image
                                                                .resizable()
                                                                .scaledToFill()
                                                        } placeholder: {
                                                            Rectangle()
                                                                .fill(Color(.systemGray5))
                                                                .overlay(ProgressView())
                                                        }
                                                        .frame(width: 90, height: 90)
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))

                                                        Button {
                                                            Task {
                                                                await viewModel.deletePhoto(from: currentPin, at: index)
                                                            }
                                                        } label: {
                                                            Image(systemName: "xmark.circle.fill")
                                                                .font(.system(size: 20))
                                                                .foregroundStyle(.white, .black.opacity(0.7))
                                                                .padding(4)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

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
                                                var images: [UIImage] = []
                                                for item in newItems {
                                                    if let data = try? await item.loadTransferable(type: Data.self),
                                                       let image = UIImage(data: data) {
                                                        images.append(image)
                                                    }
                                                }
                                                await viewModel.addPhotos(to: currentPin, images: images)
                                                await MainActor.run {
                                                    selectedItems = []
                                                    selectedImages = []
                                                    isUploading = false
                                                }
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
                            if !isEditing {
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
                            }

                            Spacer(minLength: 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
                
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom) {
                    bottomBar
                }
            }
            .navigationBarHidden(true)
            .onChange(of: viewModel.pins) { _, newPins in
                if let updated = newPins.first(where: { $0.id == currentPin.id }) {
                    currentPin = updated
                }
            }
            .fullScreenCover(isPresented: $showCamera, onDismiss: {
                guard !selectedImages.isEmpty else { return }
                let imagesToUpload = selectedImages
                isUploading = true
                Task {
                    await viewModel.addPhotos(to: currentPin, images: imagesToUpload)
                    await MainActor.run {
                        selectedImages = []
                        isUploading = false
                    }
                }
            }) {
                CameraPicker(images: $selectedImages)
            }
        
    }

    // MARK: - Top Picture Bar
    @ViewBuilder
    private var captures: some View {
        ZStack(alignment: .bottom) {
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

            LinearGradient(
                colors: [.clear, .black.opacity(0.25)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

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

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            if isEditing {
                // Save button
                Button {
                    isSaving = true
                    Task {
                        await viewModel.updatePin(currentPin, name: editedName, details: editedDetails, spotTypes: Array(editedSpotTypes), riskLevel: editedRiskLevel)
                        isSaving = false
                        isEditing = false
                    }
                } label: {
                    Label(isSaving ? "Saving…" : "Save Changes", systemImage: isSaving ? "hourglass" : "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue, in: Capsule())
                }
                .disabled(isSaving || editedName.trimmingCharacters(in: .whitespaces).isEmpty)
            } else {
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
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            .ultraThinMaterial
                .shadow(.drop(color: .black.opacity(0.08), radius: 12, y: -4))
        )
        .animation(.easeInOut(duration: 0.2), value: isEditing)
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

//#Preview {
//    let mockPin = PinInfo(
//        id: "1",
//        pinName: "Orem Skatepark",
//        pinDetails: "Super smooth ledges and a nice bowl.",
//        latitude: 40.2969,
//        longitude: -111.6946,
//        createdByUID: "test",
//        createdByUsername: "Ethan",
//        imageURls: [],
//        spotTypes: [.ledge, .bowl]
//    )
//
//    PinInfoView(pin: mockPin, viewModel: MapViewModel())
//}
