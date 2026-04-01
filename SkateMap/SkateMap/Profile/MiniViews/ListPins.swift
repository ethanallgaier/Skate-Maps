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
            if let firstURL = pin.imageURls.first, let url = URL(string: firstURL) {
                CachedAsyncImage(url: url) {
                    Color.secondary.opacity(0.2)
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: pin.spotTypes.first?.icon ?? "mappin")
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(pin.pinName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                // Show all types joined by commas
                Text(pin.spotTypes.map(\.rawValue).joined(separator: ", "))
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
