//
//  AddPinView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/10/26.
//

import SwiftUI
import CoreLocation
import PhotosUI

struct AddPinView: View {
    @State private var pinName: String = ""
    @State private var pinDetails: String = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isSaving: Bool = false
    @State private var showCamera: Bool = false
    @State private var selectedTypes: Set<SpotType> = []   // ← now a Set

    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MapViewModel

    @Binding var coordinate: CLLocationCoordinate2D

    var body: some View {
        NavigationStack {
            Form {

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
                                    // Toggle: add if absent, remove if already selected
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
                                    coordinate: coordinate,
                                    username: "test",
                                    images: images,
                                    spotTypes: Array(selectedTypes)  // ← pass the full array
                                )
                                isSaving = false
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var coordinate = CLLocationCoordinate2D(
        latitude: 40.2969,
        longitude: -111.6946
    )
    AddPinView(
        viewModel: MapViewModel(),
        coordinate: $coordinate
    )
}
