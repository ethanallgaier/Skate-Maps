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
    @State private var selectedType: SpotType = .other
    
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MapViewModel
    
    @Binding var  coordinate: CLLocationCoordinate2D//pin placement
    
    var body: some View {
        NavigationStack {
            Form {
                
                Section("Spot Info") {
                    TextField("Name", text: $pinName)
                    
                    TextField("Spot Details", text: $pinDetails)
                            
                }
                //Spot type
                Section("Spot type") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SpotType.allCases, id: \.self){ type in
                                Button {
                                    selectedType = type
                                } label: {
                                    Label(type.rawValue, systemImage: type.icon)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(selectedType == type ? Color.black : Color.gray.opacity(0.2))
                                        .foregroundStyle(selectedType == type ? .white : .primary)
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
                        
                        Button("Create") {
//                            guard let coordinate = locationManager.userLocation else { return }
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
                                    images: images, // uses freshly converted images
                                    spotType: selectedType
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
