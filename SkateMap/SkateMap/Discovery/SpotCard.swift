//
//  SpotCard.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/31/26.
//

import SwiftUI

struct SpotCard: View {
    let pin: PinInfo
    var distance: Double? // meters
    let onTap: () -> Void

    private var formattedDistance: String? {
        guard let distance else { return nil }
        let miles = distance / 1609.34
        if miles < 0.1 {
            return String(format: "%.0f ft", distance * 3.28084)
        } else if miles < 10 {
            return String(format: "%.1f mi", miles)
        } else {
            return String(format: "%.0f mi", miles)
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Photo
                if let firstURL = pin.imageURls.first, let url = URL(string: firstURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color(.systemGray5)
                            .overlay(ProgressView())
                    }
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: pin.spotTypes.first?.icon ?? "mappin")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .frame(width: 170, height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(pin.pinName)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                if let type = pin.spotTypes.first {
                    HStack(spacing: 4) {
                        Image(systemName: type.icon)
                            .font(.caption2)
                        Text(type.rawValue)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    if pin.averageRating > 0 {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", pin.averageRating))
                            .font(.caption2.bold())
                            .foregroundStyle(.primary)
                    }

                    if let dist = formattedDistance {
                        if pin.averageRating > 0 {
                            Text("·")
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text(dist)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 170)
        .padding(8)
        .glassEffect(in: .rect(cornerRadius: 16))
        .buttonStyle(.plain)
    }
}
