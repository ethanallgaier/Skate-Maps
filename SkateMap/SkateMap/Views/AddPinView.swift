//
//  AddPinView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/10/26.
//

import SwiftUI
import CoreLocation

struct AddPinView: View {
    @State private var pinName: String = ""
    @State private var pinDetails: String = ""
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Spot Info") {
                    TextField("Name", text: $pinName)
                    TextField("Details", text: $pinDetails)
                }
                
                //                Text("Risk level")
                //                Text("add phots")
                //                Text("diffuculty level")
                //                Text("type, rail, stairs")
            }
            .navigationTitle("New Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let coordinate = locationManager.userLocation {
                            viewModel.addPin(name: pinName,
                                             details: pinDetails,
                                             coordinate: coordinate,
                                             username: "test"
                            )
                        }
                        dismiss()//what is this??
                    }
                }
            }
        }
    }
}



#Preview {
    AddPinView(viewModel: MapViewModel(), locationManager: LocationManager())
}
