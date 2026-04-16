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
    @State private var selectedRiskLevel: RiskLevel = .low
    @State private var selectedDifficulty: DifficultyLevel = .beginner
    @State private var selectedSurface: SurfaceQuality = .decent
    @State private var selectedBestTimes: Set<BestTime> = []
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
                    FlowLayout(spacing: 8) {
                        ForEach(SpotType.allCases, id: \.self) { type in
                            Button {
                                if selectedTypes.contains(type) {
                                    selectedTypes.remove(type)
                                } else {
                                    selectedTypes.insert(type)
                                }
                            } label: {
                                Text(type.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedTypes.contains(type) ? Color.blue : Color(.systemGray5))
                                    .foregroundStyle(selectedTypes.contains(type) ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Difficulty level
                Section("Difficulty") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How hard is this spot to skate?")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            ForEach(DifficultyLevel.allCases, id: \.self) { level in
                                Button {
                                    selectedDifficulty = level
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: level.icon)
                                            .font(.system(size: 18))
                                        Text(level.label)
                                            .font(.system(size: 11, weight: .medium))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedDifficulty == level ? level.color.opacity(0.15) : Color(.systemGray6))
                                    .foregroundStyle(selectedDifficulty == level ? level.color : .secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(selectedDifficulty == level ? level.color.opacity(0.5) : .clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Bust Factor
                Section("Bust Factor") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How likely are you to get kicked out?")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            ForEach(RiskLevel.allCases, id: \.self) { level in
                                Button {
                                    selectedRiskLevel = level
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: level.icon)
                                            .font(.system(size: 18))
                                        Text(level.label)
                                            .font(.system(size: 11, weight: .medium))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedRiskLevel == level ? level.color.opacity(0.15) : Color(.systemGray6))
                                    .foregroundStyle(selectedRiskLevel == level ? level.color : .secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(selectedRiskLevel == level ? level.color.opacity(0.5) : .clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Surface Quality
                Section("Surface Quality") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How smooth is the ground?")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            ForEach(SurfaceQuality.allCases, id: \.self) { level in
                                Button {
                                    selectedSurface = level
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: level.icon)
                                            .font(.system(size: 18))
                                        Text(level.label)
                                            .font(.system(size: 11, weight: .medium))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedSurface == level ? level.color.opacity(0.15) : Color(.systemGray6))
                                    .foregroundStyle(selectedSurface == level ? level.color : .secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(selectedSurface == level ? level.color.opacity(0.5) : .clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Best Time to Skate
                Section("Best Time to Skate") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("When does this spot work best? Select all that apply.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            ForEach(BestTime.allCases, id: \.self) { time in
                                Button {
                                    if selectedBestTimes.contains(time) {
                                        selectedBestTimes.remove(time)
                                    } else {
                                        selectedBestTimes.insert(time)
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: time.icon)
                                            .font(.system(size: 18))
                                        Text(time.rawValue)
                                            .font(.system(size: 11, weight: .medium))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedBestTimes.contains(time) ? time.color.opacity(0.15) : Color(.systemGray6))
                                    .foregroundStyle(selectedBestTimes.contains(time) ? time.color : .secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(selectedBestTimes.contains(time) ? time.color.opacity(0.5) : .clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
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

                                guard let coord = coordinate else { return }
                                await viewModel.addPin(
                                    name: pinName,
                                    details: pinDetails,
                                    coordinate: coord,
                                    username: authService.currentUser?.username ?? "Unknown",
                                    images: images,
                                    spotTypes: Array(selectedTypes),
                                    riskLevel: selectedRiskLevel,
                                    difficultyLevel: selectedDifficulty,
                                    surfaceQuality: selectedSurface,
                                    bestTimes: Array(selectedBestTimes)
                                )
                                isSaving = false
                                dismiss()
                            }
                        }
                        .disabled(isSaving || coordinate == nil || pinName.trimmingCharacters(in: .whitespaces).isEmpty)
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

