//
//  PinPreviewCard.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/14/26.
//

import SwiftUI

//MARK: - MINI PREVIEW CARD. FIRST TAP ON A PIN
struct PinPreviewCard: View {
    var pin: PinInfo
    @ObservedObject var viewModel: MapViewModel
    var onTap: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {

                // Photo or placeholder
                if let firstImage = pin.imageURls.first {
                    CachedAsyncImage(url: URL(string: firstImage)) {
                        ProgressView()
                    }
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.gray.opacity(0.3))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        )
                }

                // Spot info
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.username(for: pin.createdByUID))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(pin.pinName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        // Spot types
//                        HStack(spacing: 4) {
//                            ForEach(pin.spotTypes, id: \.self) { type in
//                                Label(type.rawValue, systemImage: type.icon)
//                                    .font(.caption)
//                                    .foregroundStyle(.secondary)
//                            }
//                        }

                        // Risk badge
                        HStack(spacing: 3) {
                            Image(systemName: pin.difficultyLevel.icon)
                            Text(pin.difficultyLevel.label)
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(pin.difficultyLevel.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(pin.difficultyLevel.color.opacity(0.15), in: Capsule())
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .glassEffect(in: .rect(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}

#Preview {
    let mockPin = PinInfo(
        pinName: "Hubba Hideout",
        pinDetails: "Classic SF spot",
        time: Date(),
        latitude: 37.7749,
        longitude: -122.4194,
        createdByUID: "123",
        createdByUsername: "skater1",
        imageURls: [],
        spotTypes: [.rail]
    )
    PinPreviewCard(pin: mockPin, viewModel: MapViewModel()) {
        print("tapped")
    } onDismiss: {
        print("dismissed")
    }
}
