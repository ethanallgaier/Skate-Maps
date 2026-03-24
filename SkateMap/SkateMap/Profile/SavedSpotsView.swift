//
//  SavedSpotsView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/18/26.
//

import SwiftUI
import FirebaseAuth

struct SavedSpotsView: View {

    @ObservedObject var viewModel: MapViewModel
    @Environment(\.dismiss) var dismiss

    var savedPins: [PinInfo] {
        viewModel.pins.filter { pin in
            guard let id = pin.id else { return false }
            return viewModel.savedPinIDs.contains(id)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if savedPins.isEmpty {
                    ContentUnavailableView(
                        "No Saved Spots",
                        systemImage: "bookmark",
                        description: Text("Bookmark a spot to see it here.")
                    )
                } else {
                    VStack(spacing: 12) {
                        ForEach(savedPins) { pin in
                            NavigationLink(destination: PinInfoView(pin: pin, viewModel: viewModel)) {
                                HStack {
                                    Image(systemName: pin.spotTypes.first?.icon ?? "mappin")
                                        .font(.title2)
                                        .frame(width: 40)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(pin.pinName)
                                            .font(.headline)
                                        Text(pin.spotTypes.map(\.rawValue).joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Saved Spots")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                }
            }
        }
    }
}

#Preview {
    let viewModel = MapViewModel()
    viewModel.pins = [
        PinInfo(
            id: "1",
            pinName: "Orem Skatepark",
            pinDetails: "Nice bowl and ledges.",
            latitude: 40.2969,
            longitude: -111.6946,
            createdByUID: "previewUID",
            createdByUsername: "Ethan",
            spotTypes: [.bowl]
        )
    ]
    viewModel.savedPinIDs = ["1"]
    return SavedSpotsView(viewModel: viewModel)
}
