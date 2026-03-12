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
    @State private var selectedItems: [PhotosPickerItem] = []//holds raw picker selections
    @State private var selectedImages: [UIImage] = []//holds converted UIImages for preview + upload
    @State private var isSaving: Bool = false//disables Save button and shows spinner while uploading
    @State private  var showCamera: Bool = false
    
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject var locationManager: LocationManager
    
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Spot Info") {
                    TextField("Name", text: $pinName)
                    
                    TextEditor(text: $pinDetails)
                            .frame(height: 100)
                            .padding(4)
                    
                }
             
                
                Section("Photos") {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
                        Label("Add Photos", systemImage: "photo.on.rectangle.angled")
                    }
                    .onChange(of: selectedItems) { _, newItems in
                        // converts each PhotosPickerItem into a UIImage when user picks photos
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
                    
                    
                    // Camera
                    Button {
                        showCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera")
                    }
                }
                
                //Preview of Images
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
            
            .fullScreenCover(isPresented: $showCamera) {//Show camera
                CameraPicker(images: $selectedImages)
            }
            .toolbar {//cancel Button
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
 //Save Button
                    if isSaving{
                        ProgressView()
                    } else {
                        
                        Button("Save") {
                            guard let coordinate = locationManager.userLocation else { return }
                            isSaving = true
                            Task {
                                // Convert picker items to UIImages HERE, right before upload
                                // so we know they're ready
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
                                    images: images // uses freshly converted images
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
    AddPinView(viewModel: MapViewModel(), locationManager: LocationManager())
}
