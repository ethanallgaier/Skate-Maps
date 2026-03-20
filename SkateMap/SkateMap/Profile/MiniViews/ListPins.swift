//
//  ListPins.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/20/26.
//

import SwiftUI

struct PinListRow: View {
    let pin: PinInfo
    var body: some View {
        HStack(spacing: 12) {
            // ✅ show first image if available, otherwise fall back to icon
            if let firstURL = pin.imageURls.first, let url = URL(string: firstURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.secondary.opacity(0.2)
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: pin.spotType.icon)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pin.pinName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(pin.spotType.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    VStack(spacing: 12) {
        PinListRow(pin: PinInfo(
            id: "1",
            pinName: "Orem Skatepark",
            pinDetails: "Nice bowl.",
            latitude: 40.2969,
            longitude: -111.6946,
            createdByUID: "abc",
            createdByUsername: "Ethan",
            spotType: .bowl
        ))
        PinListRow(pin: PinInfo(
            id: "2",
            pinName: "Provo Gap",
            pinDetails: "Sketchy.",
            latitude: 40.2338,
            longitude: -111.6585,
            createdByUID: "abc",
            createdByUsername: "Ethan",
            spotType: .gap
        ))
    }
    .padding()
}


