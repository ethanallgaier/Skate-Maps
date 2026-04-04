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
            VStack(alignment: .leading, spacing: 10) {
                // Photo
                Group {
                    if let firstURL = pin.imageURls.first, let url = URL(string: firstURL) {
                        CachedAsyncImage(url: url) {
                            Color(.systemGray5)
                                .overlay(ProgressView())
                        }
                    } else {
                        Rectangle()
                            .fill(.gray.opacity(0.2))
                            .overlay(
                                Image(systemName: pin.spotTypes.first?.icon ?? "mappin")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Info
                VStack(alignment: .leading, spacing: 5) {
                    Text(pin.pinName)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .foregroundStyle(.primary)

                    if let type = pin.spotTypes.first {
                        Label(type.rawValue, systemImage: type.icon)
                            .font(.caption2)
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
                .padding(.horizontal, 2)
            }
            .padding(8)
            .frame(width: 175)
            .glassEffect(in: .rect(cornerRadius: 16))
        }
        .buttonStyle(CardPressStyle())
    }
}
