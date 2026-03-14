//
//  PinPreviewCard.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/14/26.
//

import SwiftUI

struct PinPreviewCard: View {
    var pin: PinInfo
    var onTap: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {

                // Photo or placeholder
                if let firstImage = pin.imageURls.first {
                    AsyncImage(url: URL(string: firstImage)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
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
                    Text(pin.pinName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Label(pin.spotType.rawValue, systemImage: pin.spotType.icon)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(pin.createdByUsername)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        spotType: .rail
    )
    PinPreviewCard(pin: mockPin) {
        print("tapped")
    } onDismiss: {
        print("dismissed")
    }
}

