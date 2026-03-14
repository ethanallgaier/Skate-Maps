//
//  PinInfoView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/2/26.
//

import SwiftUI
import PhotosUI
import FirebaseAuth

struct PinInfoView: View {
    var pin: PinInfo
    @ObservedObject var viewModel: MapViewModel

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Photos gallery
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

                      
                      

                        // Pin details
                        if !currentPin.pinDetails.isEmpty {
                            Text(pin.pinDetails)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        // Who created it
                        Label(currentPin.createdByUsername, systemImage: "person.circle")
                            .foregroundStyle(.secondary)

                        // Date added
                        Label(currentPin.time.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .foregroundStyle(.secondary)

                        Divider()

                        // Add photos — only shown to the owner
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
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle(currentPin.pinName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Delete button — only shown to the owner
                if isOwner {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
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
            .sheet(isPresented: $showCamera, onDismiss: {
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

//#Preview {
//    PinInfoView()
//}
