//
//  AddPinView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/10/26.
//

import SwiftUI
import CoreLocation
import PhotosUI
import MapKit

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct AddPinView: View {
    @State private var pinName: String = ""
    @State private var pinDetails: String = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isSaving: Bool = false
    @State private var showCamera: Bool = false
    @State private var selectedTypes: Set<SpotType> = []
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var locationName: String?
    @State private var showLocationPicker = false
    
    @Environment(AuthService.self) var authService
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MapViewModel

    var initialRegion: MKCoordinateRegion

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Location
                Section("Location") {
                    Button {
                        showLocationPicker = true
                    } label: {
                        HStack {
                            Label(
                                coordinate != nil ? "Change Location" : "Choose Location",
                                systemImage: coordinate != nil ? "mappin.circle.fill" : "mappin.circle"
                            )
                            Spacer()
                            if let name = locationName {
                                Text(name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            } else if coordinate != nil {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("Required")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                Section("Spot Info") {
                    TextField("Name", text: $pinName)
                    TextField("Spot Details", text: $pinDetails)
                }

                // Spot type — multi-select
                Section("Spot Type") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SpotType.allCases, id: \.self) { type in
                                Button {
                                    if selectedTypes.contains(type) {
                                        selectedTypes.remove(type)
                                    } else {
                                        selectedTypes.insert(type)
                                    }
                                } label: {
                                    Label(type.rawValue, systemImage: type.icon)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(selectedTypes.contains(type) ? Color.black : Color.gray.opacity(0.2))
                                        .foregroundStyle(selectedTypes.contains(type) ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Photos") {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
                        Label("Add Photos", systemImage: "photo.on.rectangle.angled")
                    }
                    .onChange(of: selectedItems) { _, newItems in
                        Task {
                            selectedImages = []
                            for item in newItems {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    selectedImages.append(image)
                                }
                            }
                        }
                    }

                    Button {
                        showCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera")
                    }
                }

                if !selectedImages.isEmpty {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(selectedImages.indices, id: \.self) { i in
                                Image(uiImage: selectedImages[i])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Spot")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker(images: $selectedImages)
            }
            .fullScreenCover(isPresented: $showLocationPicker) {
                LocationPickerView(coordinate: $coordinate, initialRegion: initialRegion)
            }
            .onChange(of: coordinate) { _, newCoord in
                guard let newCoord else {
                    locationName = nil
                    return
                }
                Task {
                    let location = CLLocation(latitude: newCoord.latitude, longitude: newCoord.longitude)
                    if let request = MKReverseGeocodingRequest(location: location),
                       let mapItem = try? await request.mapItems.first {
                        locationName = mapItem.address?.shortAddress ?? mapItem.name ?? mapItem.address?.fullAddress
                    } else {
                        locationName = String(format: "%.4f, %.4f", newCoord.latitude, newCoord.longitude)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Create") {
                            isSaving = true
                            Task {
                                var images: [UIImage] = []
                                for item in selectedItems {
                                    if let data = try? await item.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        images.append(image)
                                    }
                                }

                                await viewModel.addPin(
                                    name: pinName,
                                    details: pinDetails,
                                    coordinate: coordinate!,
                                    username: authService.currentUser?.username ?? "Unknown",
                                    images: images,
                                    spotTypes: Array(selectedTypes)
                                )
                                isSaving = false
                                dismiss()
                            }
                        }
                        .disabled(coordinate == nil || pinName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }
}

#Preview {
    let mockVM = {
        let vm = MapViewModel()
        vm.pins = [
            PinInfo(
                pinName: "Orem Skatepark",
                pinDetails: "Smooth ledges and a nice bowl.",
                latitude: 40.2969,
                longitude: -111.6946,
                createdByUID: "mock",
                createdByUsername: "Ethan",
                imageURls: [],
                spotTypes: [.ledge, .bowl]
            )
        ]
        return vm
    }()
    let mockAuth = {
        let auth = AuthService()
        auth.currentUser = UserInfo(id: "mock", username: "Ethan")
        return auth
    }()

    AddPinView(
        viewModel: mockVM,
        initialRegion: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.2969, longitude: -111.6946),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    .environment(mockAuth)
}

